unit Hue.Transport;

interface

uses
  System.Classes, System.Generics.Collections, System.Net.HttpClient,
  System.Net.URLClient, Hue.Types;

type
  /// <summary>Dictionary of HTTP request headers used by API adapters and test doubles.</summary>
  THueHeaders = TDictionary<string, string>;

  /// <summary>Small injectable HTTP boundary shared by both Hue API adapters.</summary>
  IHueTransport = interface
    ['{B6179495-9864-4E03-BD46-819A6FCA57EC}']
    /// <summary>Sends a UTF-8 request and returns its UTF-8 response body.</summary>
    function Execute(const AMethod: THueHTTPMethod; const AURL, ABody: string;
      const AHeaders: THueHeaders): string;
  end;

  /// <summary>System.Net.HttpClient transport with platform TLS validation.</summary>
  THueHTTPTransport = class(TInterfacedObject, IHueTransport)
  private
    FClient: THTTPClient;
    FConnectionTimeout: Integer;
    FResponseTimeout: Integer;
    procedure ConfigureClient;
  public
    /// <summary>Creates a transport using secure platform certificate validation.</summary>
    constructor Create;
    /// <summary>Releases the HTTP client.</summary>
    destructor Destroy; override;
    /// <summary>Sends a UTF-8 request and raises EHueHTTPError for non-success status codes.</summary>
    function Execute(const AMethod: THueHTTPMethod; const AURL, ABody: string;
      const AHeaders: THueHeaders): string;
    /// <summary>Gets or sets the connection timeout in milliseconds.</summary>
    property ConnectionTimeout: Integer read FConnectionTimeout write FConnectionTimeout;
    /// <summary>Gets or sets the response timeout in milliseconds.</summary>
    property ResponseTimeout: Integer read FResponseTimeout write FResponseTimeout;
  end;

implementation

uses
  System.SysUtils, Hue.Errors;

constructor THueHTTPTransport.Create;
begin
  inherited;
  FClient := THTTPClient.Create;
  FConnectionTimeout := 5000;
  FResponseTimeout := 15000;
end;

destructor THueHTTPTransport.Destroy;
begin
  FClient.Free;
  inherited;
end;

procedure THueHTTPTransport.ConfigureClient;
begin
  FClient.ConnectionTimeout := FConnectionTimeout;
  FClient.ResponseTimeout := FResponseTimeout;
  FClient.UserAgent := 'Delphi-Philips-Hue/2';
end;

function THueHTTPTransport.Execute(const AMethod: THueHTTPMethod;
  const AURL, ABody: string; const AHeaders: THueHeaders): string;
var
  HeaderArray: TNetHeaders;
  Pair: TPair<string, string>;
  I: Integer;
  RequestBody: TStringStream;
  Response: IHTTPResponse;
begin
  ConfigureClient;
  SetLength(HeaderArray, AHeaders.Count);
  I := 0;
  for Pair in AHeaders do begin HeaderArray[I] := TNetHeader.Create(Pair.Key, Pair.Value); Inc(I); end;
  RequestBody := nil;
  try
    if ABody <> '' then RequestBody := TStringStream.Create(ABody, TEncoding.UTF8);
    case AMethod of
      hhmGet: Response := FClient.Get(AURL, nil, HeaderArray);
      hhmPost: Response := FClient.Post(AURL, RequestBody, nil, HeaderArray);
      hhmPut: Response := FClient.Put(AURL, RequestBody, nil, HeaderArray);
      hhmDelete: Response := FClient.Delete(AURL, nil, HeaderArray);
    else
      raise EHueError.Create('Unknown HTTP method');
    end;
    Result := Response.ContentAsString(TEncoding.UTF8);
    if (Response.StatusCode < 200) or (Response.StatusCode >= 300) then
      raise EHueHTTPError.Create(Response.StatusCode, Result);
  finally
    RequestBody.Free;
  end;
end;

end.
