unit EventMonitorMain;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Hue.EventStream;

type
  /// <summary>VCL monitor for the Hue API v2 Server-Sent Events stream.</summary>
  TEventMonitorForm = class(TForm)
    HostEdit: TEdit;
    KeyEdit: TEdit;
    StartButton: TButton;
    StopButton: TButton;
    EventsMemo: TMemo;
    /// <summary>Starts a background event-stream connection.</summary>
    procedure StartButtonClick(Sender: TObject);
    /// <summary>Stops the active event-stream connection.</summary>
    procedure StopButtonClick(Sender: TObject);
  private
    FStream: THueEventStream;
    /// <summary>Queues event JSON from the worker thread onto the VCL thread.</summary>
    procedure StreamData(Sender: TObject; const AJSON: string);
    /// <summary>Queues stream errors from the worker thread onto the VCL thread.</summary>
    procedure StreamError(Sender: TObject; const AMessage: string);
  public
    /// <summary>Stops and releases the event stream.</summary>
    destructor Destroy; override;
  end;

var EventMonitorForm: TEventMonitorForm;

implementation

{$R *.dfm}

uses System.SysUtils, System.Threading;

procedure TEventMonitorForm.StartButtonClick(Sender: TObject);
begin
  FreeAndNil(FStream);
  FStream := THueEventStream.Create(HostEdit.Text, KeyEdit.Text);
  FStream.OnData := StreamData;
  FStream.OnError := StreamError;
  FStream.Start;
end;

procedure TEventMonitorForm.StopButtonClick(Sender: TObject);
begin
  FreeAndNil(FStream);
end;

procedure TEventMonitorForm.StreamData(Sender: TObject; const AJSON: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      EventsMemo.Lines.Add(AJSON);
    end);
end;

procedure TEventMonitorForm.StreamError(Sender: TObject; const AMessage: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      EventsMemo.Lines.Add('ERROR: ' + AMessage);
    end);
end;

destructor TEventMonitorForm.Destroy;
begin
  FStream.Free;
  inherited;
end;

end.
