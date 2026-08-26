unit Hue.API.V2;

interface

uses Hue.Types, Hue.Transport, Hue.API;

type
  /// <summary>Adapter for Hue API v2 resources rooted at /clip/v2/resource.</summary>
  THueAPIV2 = class(THueAPIBase)
  public
    /// <summary>Returns hav2.</summary>
    function Version: THueAPIVersion; override;
    /// <summary>Builds an HTTPS v2 resource URL.</summary>
    function BuildURL(const APath: string): string; override;
    /// <summary>Adds the required hue-application-key request header.</summary>
    function CreateHeaders: THueHeaders; override;
    /// <summary>Allows mapped resources and rejects v1-only automation operations.</summary>
    procedure RequireCapability(const AOperation: string); override;
    /// <summary>Converts legacy 1..254 brightness to v2 0..100 percent.</summary>
    class function BrightnessToV2(const AValue: Integer): Double; static;
    /// <summary>Converts v2 0..100 percent brightness to legacy 1..254.</summary>
    class function BrightnessFromV2(const AValue: Double): Integer; static;
  end;

implementation

uses System.SysUtils, System.Math, Hue.Errors;

function THueAPIV2.Version: THueAPIVersion;
begin Result := hav2; end;

function THueAPIV2.BuildURL(const APath: string): string;
begin Result := Format('https://%s/clip/v2/resource%s', [FBridgeHost, APath]); end;

function THueAPIV2.CreateHeaders: THueHeaders;
begin
  Result := inherited CreateHeaders;
  Result.Add('hue-application-key', FApplicationKey);
end;

procedure THueAPIV2.RequireCapability(const AOperation: string);
begin
  if SameText(AOperation, 'schedules') or SameText(AOperation, 'rules') or
     SameText(AOperation, 'create group') or SameText(AOperation, 'delete light') or
     SameText(AOperation, 'search new lights') then
    inherited RequireCapability(AOperation);
end;

class function THueAPIV2.BrightnessToV2(const AValue: Integer): Double;
begin Result := EnsureRange(AValue, 1, 254) * 100.0 / 254.0; end;

class function THueAPIV2.BrightnessFromV2(const AValue: Double): Integer;
begin Result := Round(EnsureRange(AValue, 0.0, 100.0) * 254.0 / 100.0); end;

end.
