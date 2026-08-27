unit Hue.API.V1;

interface

uses Hue.Types, Hue.API;

type
  /// <summary>Adapter for the legacy Hue local REST API rooted at /api/{username}.</summary>
  THueAPIV1 = class(THueAPIBase)
  public
    /// <summary>Returns hav1.</summary>
    function Version: THueAPIVersion; override;
    /// <summary>Builds an HTTPS v1 URL containing the application username.</summary>
    function BuildURL(const APath: string): string; override;
    /// <summary>Accepts all operations currently exposed by the legacy facade.</summary>
    procedure RequireCapability(const AOperation: string); override;
  end;

implementation

uses System.SysUtils;

function THueAPIV1.Version: THueAPIVersion;
begin Result := hav1; end;

function THueAPIV1.BuildURL(const APath: string): string;
begin Result := Format('https://%s/api/%s%s', [FBridgeHost, FApplicationKey, APath]); end;

procedure THueAPIV1.RequireCapability(const AOperation: string);
begin
  { The compatibility surface was originally implemented against v1. }
end;

end.
