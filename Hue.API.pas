unit Hue.API;

interface

uses
  Hue.Types, Hue.Transport;

type
  /// <summary>Minimal API adapter contract used by the compatibility component.</summary>
  IHueAPI = interface
    ['{9BBE4405-3E8D-411F-9680-DCC583BA7055}']
    /// <summary>Returns the adapter API generation.</summary>
    function Version: THueAPIVersion;
    /// <summary>Builds the absolute URL for a relative API resource.</summary>
    function BuildURL(const APath: string): string;
    /// <summary>Creates caller-owned authentication and content headers.</summary>
    function CreateHeaders: THueHeaders;
    /// <summary>Executes a request through the shared transport.</summary>
    function Request(const AMethod: THueHTTPMethod; const APath, ABody: string): string;
    /// <summary>Raises a capability exception unless the operation exists in this API.</summary>
    procedure RequireCapability(const AOperation: string);
  end;

  /// <summary>Common implementation for URL construction, headers, and transport dispatch.</summary>
  THueAPIBase = class abstract(TInterfacedObject, IHueAPI)
  protected
    FBridgeHost: string;
    FApplicationKey: string;
    FTransport: IHueTransport;
  public
    /// <summary>Creates an adapter for a bridge hostname and application key.</summary>
    constructor Create(const ABridgeHost, AApplicationKey: string; const ATransport: IHueTransport);
    /// <summary>Returns the adapter API generation.</summary>
    function Version: THueAPIVersion; virtual; abstract;
    /// <summary>Builds the absolute URL for a relative API resource.</summary>
    function BuildURL(const APath: string): string; virtual; abstract;
    /// <summary>Creates caller-owned authentication and content headers.</summary>
    function CreateHeaders: THueHeaders; virtual;
    /// <summary>Executes a request and frees temporary headers reliably.</summary>
    function Request(const AMethod: THueHTTPMethod; const APath, ABody: string): string;
    /// <summary>Raises a capability exception unless overridden by an adapter.</summary>
    procedure RequireCapability(const AOperation: string); virtual;
  end;

implementation

uses System.SysUtils, Hue.Errors, Hue.JSON;

constructor THueAPIBase.Create(const ABridgeHost, AApplicationKey: string;
  const ATransport: IHueTransport);
begin
  inherited Create;
  if not Assigned(ATransport) then
    raise EArgumentNilException.Create('ATransport');
  FBridgeHost := ABridgeHost;
  FApplicationKey := AApplicationKey;
  FTransport := ATransport;
end;

function THueAPIBase.CreateHeaders: THueHeaders;
begin
  Result := THueHeaders.Create;
  Result.Add('Accept', 'application/json');
  Result.Add('Content-Type', 'application/json; charset=utf-8');
end;

function THueAPIBase.Request(const AMethod: THueHTTPMethod;
  const APath, ABody: string): string;
var H: THueHeaders;
begin
  H := CreateHeaders;
  try
    Result := FTransport.Execute(AMethod, BuildURL(APath), ABody, H);
    if Result <> '' then
      THueJSON.RaiseIfHueError(Result);
  finally
    H.Free;
  end;
end;

procedure THueAPIBase.RequireCapability(const AOperation: string);
begin
  raise EHueUnsupportedOperation.Create(AOperation, Version);
end;

end.
