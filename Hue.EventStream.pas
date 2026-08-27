unit Hue.EventStream;

interface

uses
  System.Classes, System.Net.HttpClient;

type
  /// <summary>Receives one complete JSON data payload from the Hue v2 SSE stream on the worker thread.</summary>
  THueEventDataEvent = procedure(Sender: TObject; const AJSON: string) of object;

  /// <summary>Receives an event-stream transport or decoding error on the worker thread.</summary>
  THueEventErrorEvent = procedure(Sender: TObject; const AMessage: string) of object;

  /// <summary>Maintains a cancellable background connection to the Hue API v2 Server-Sent Events endpoint.</summary>
  THueEventStream = class
  private
    FBridgeHost: string;
    FApplicationKey: string;
    FClient: THTTPClient;
    FThread: TThread;
    FRunning: Boolean;
    FStopping: Boolean;
    FOnData: THueEventDataEvent;
    FOnError: THueEventErrorEvent;
    /// <summary>Runs the blocking HTTPS event-stream request on the worker thread.</summary>
    procedure Execute;
    /// <summary>Dispatches a decoded JSON event on the worker thread.</summary>
    procedure DispatchData(const AJSON: string);
  public
    /// <summary>Creates an event stream for a bridge hostname and Hue application key.</summary>
    constructor Create(const ABridgeHost, AApplicationKey: string);
    /// <summary>Stops the worker and releases its HTTP client.</summary>
    destructor Destroy; override;
    /// <summary>Starts the background event-stream connection.</summary>
    procedure Start;
    /// <summary>Cancels the active request and waits for the worker to stop.</summary>
    procedure Stop;
    /// <summary>Indicates whether the background event-stream request is active.</summary>
    property Running: Boolean read FRunning;
    /// <summary>Handles complete Hue v2 event JSON on the worker thread.</summary>
    property OnData: THueEventDataEvent read FOnData write FOnData;
    /// <summary>Handles stream errors on the worker thread.</summary>
    property OnError: THueEventErrorEvent read FOnError write FOnError;
  end;

implementation

uses
  System.SysUtils, System.Net.URLClient, Hue.Errors;

type
  /// <summary>Incrementally decodes UTF-8 SSE lines written by THTTPClient.</summary>
  THueSSEStream = class(TStream)
  private
    FBytes: TBytes;
    FEventData: string;
    FOnData: TProc<string>;
    /// <summary>Consumes all complete lines currently held in the byte buffer.</summary>
    procedure ProcessLines;
    /// <summary>Processes one decoded SSE line and emits an event at the blank separator.</summary>
    procedure ProcessLine(const ALine: string);
  public
    /// <summary>Creates a streaming decoder with a JSON payload callback.</summary>
    constructor Create(const AOnData: TProc<string>);
    /// <summary>Reads are unsupported because the stream is an HTTP response sink.</summary>
    function Read(var Buffer; Count: Longint): Longint; override;
    /// <summary>Appends response bytes and decodes complete SSE lines.</summary>
    function Write(const Buffer; Count: Longint): Longint; override;
    /// <summary>Seeking is unsupported because the response is forward-only.</summary>
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

constructor THueSSEStream.Create(const AOnData: TProc<string>);
begin
  inherited Create;
  FOnData := AOnData;
end;

function THueSSEStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := 0;
end;

function THueSSEStream.Write(const Buffer; Count: Longint): Longint;
var
  PreviousLength: Integer;
begin
  PreviousLength := Length(FBytes);
  SetLength(FBytes, PreviousLength + Count);
  if Count > 0 then
    Move(Buffer, FBytes[PreviousLength], Count);
  ProcessLines;
  Result := Count;
end;

function THueSSEStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := 0;
end;

procedure THueSSEStream.ProcessLines;
var
  I, LineLength, Remaining: Integer;
  LineBytes: TBytes;
  Line: string;
begin
  I := 0;
  while I < Length(FBytes) do
  begin
    if FBytes[I] <> 10 then
    begin
      Inc(I);
      Continue;
    end;
    LineLength := I;
    if (LineLength > 0) and (FBytes[LineLength - 1] = 13) then
      Dec(LineLength);
    LineBytes := Copy(FBytes, 0, LineLength);
    Line := TEncoding.UTF8.GetString(LineBytes);
    ProcessLine(Line);
    Remaining := Length(FBytes) - I - 1;
    if Remaining > 0 then
      Move(FBytes[I + 1], FBytes[0], Remaining);
    SetLength(FBytes, Remaining);
    I := 0;
  end;
end;

procedure THueSSEStream.ProcessLine(const ALine: string);
var
  Value: string;
begin
  if ALine = '' then
  begin
    if (FEventData <> '') and Assigned(FOnData) then
      FOnData(FEventData);
    FEventData := '';
    Exit;
  end;
  if ALine.StartsWith('data:') then
  begin
    Value := ALine.Substring(5).TrimLeft;
    if FEventData <> '' then
      FEventData := FEventData + sLineBreak;
    FEventData := FEventData + Value;
  end;
end;

constructor THueEventStream.Create(const ABridgeHost,
  AApplicationKey: string);
begin
  inherited Create;
  FBridgeHost := ABridgeHost;
  FApplicationKey := AApplicationKey;
  FClient := THTTPClient.Create;
  FClient.ConnectionTimeout := 5000;
  FClient.ResponseTimeout := 0;
end;

destructor THueEventStream.Destroy;
begin
  Stop;
  FClient.Free;
  inherited;
end;

procedure THueEventStream.Start;
begin
  if FRunning then
    Exit;
  if Assigned(FThread) then
  begin
    FThread.WaitFor;
    FThread.Free;
    FThread := nil;
  end;
  FStopping := False;
  FThread := TThread.CreateAnonymousThread(Execute);
  FThread.FreeOnTerminate := False;
  FRunning := True;
  FThread.Start;
end;

procedure THueEventStream.Stop;
begin
  if not Assigned(FThread) then
    Exit;
  FStopping := True;
  FClient.CancelAll;
  if TThread.CurrentThread.ThreadID = FThread.ThreadID then
    Exit;
  FThread.WaitFor;
  FThread.Free;
  FThread := nil;
  FRunning := False;
end;

procedure THueEventStream.Execute;
var
  Headers: TNetHeaders;
  Sink: THueSSEStream;
  Response: IHTTPResponse;
begin
  SetLength(Headers, 2);
  Headers[0] := TNetHeader.Create('Accept', 'text/event-stream');
  Headers[1] := TNetHeader.Create('hue-application-key', FApplicationKey);
  Sink := THueSSEStream.Create(DispatchData);
  try
    try
      Response := FClient.Get(Format('https://%s/eventstream/clip/v2', [FBridgeHost]),
        Sink, Headers);
      if (Response.StatusCode < 200) or (Response.StatusCode >= 300) then
        raise EHueHTTPError.Create(Response.StatusCode,
          Response.ContentAsString(TEncoding.UTF8));
    except
      on E: Exception do
        if not FStopping and Assigned(FOnError) then
          FOnError(Self, E.Message);
    end;
  finally
    Sink.Free;
    FRunning := False;
  end;
end;

procedure THueEventStream.DispatchData(const AJSON: string);
begin
  if not FStopping and Assigned(FOnData) then
    FOnData(Self, AJSON);
end;

end.
