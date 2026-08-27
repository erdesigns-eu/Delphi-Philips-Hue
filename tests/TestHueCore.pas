unit TestHueCore;

interface

uses
  DUnitX.TestFramework, Hue.Types, Hue.Transport;

type
  /// <summary>Captures adapter requests without requiring a physical bridge.</summary>
  THueMockTransport = class(TInterfacedObject, IHueTransport)
  public
    /// <summary>Stores the last URL passed by an adapter.</summary>
    LastURL: string;
    /// <summary>Stores whether v2 authentication was supplied.</summary>
    HasApplicationKey: Boolean;
    /// <summary>Captures a request and returns an empty successful Hue envelope.</summary>
    function Execute(const AMethod: THueHTTPMethod; const AURL, ABody: string;
      const AHeaders: THueHeaders): string;
    /// <summary>Accepts the component User-Agent value for interface compatibility.</summary>
    procedure SetUserAgent(const AValue: string);
  end;

  [TestFixture]
  /// <summary>Verifies stable API-independent and adapter behavior.</summary>
  THueCoreTests = class
  public
    /// <summary>Verifies the v1 URL embeds the legacy username.</summary>
    [Test] procedure V1URLAndAuthentication;
    /// <summary>Verifies the v2 URL and application-key header.</summary>
    [Test] procedure V2URLAndAuthentication;
    /// <summary>Verifies brightness conversion clamps both API ranges.</summary>
    [Test] procedure BrightnessConversion;
    /// <summary>Verifies malformed JSON produces a Hue-specific exception.</summary>
    [Test] procedure MalformedJSON;
    /// <summary>Verifies structured Hue v1 and v2 errors become API exceptions.</summary>
    [Test] procedure HueErrorParsing;
    /// <summary>Verifies schedules fail explicitly under v2.</summary>
    [Test] procedure UnsupportedV2Operation;
    /// <summary>Verifies UUID identifiers remain strings.</summary>
    [Test] procedure ResourceIdentifiers;
  end;

implementation

uses
  System.SysUtils, Hue.API, Hue.API.V1, Hue.API.V2, Hue.JSON, Hue.Errors;

function THueMockTransport.Execute(const AMethod: THueHTTPMethod;
  const AURL, ABody: string; const AHeaders: THueHeaders): string;
begin
  LastURL := AURL;
  HasApplicationKey := AHeaders.ContainsKey('hue-application-key');
  Result := '{"errors":[],"data":[]}';
end;

procedure THueMockTransport.SetUserAgent(const AValue: string);
begin
  { The test double does not issue network requests. }
end;

procedure THueCoreTests.V1URLAndAuthentication;
var M: THueMockTransport; API: IHueAPI;
begin
  M := THueMockTransport.Create; API := THueAPIV1.Create('bridge.local', 'key', M);
  API.Request(hhmGet, '/lights', '');
  Assert.AreEqual('https://bridge.local/api/key/lights', M.LastURL);
  Assert.IsFalse(M.HasApplicationKey);
end;

procedure THueCoreTests.V2URLAndAuthentication;
var M: THueMockTransport; API: IHueAPI;
begin
  M := THueMockTransport.Create; API := THueAPIV2.Create('bridge.local', 'key', M);
  API.Request(hhmGet, '/light', '');
  Assert.AreEqual('https://bridge.local/clip/v2/resource/light', M.LastURL);
  Assert.IsTrue(M.HasApplicationKey);
end;

procedure THueCoreTests.BrightnessConversion;
begin
  Assert.AreEqual(50.0, THueAPIV2.BrightnessToV2(127), 0.01);
  Assert.AreEqual(254, THueAPIV2.BrightnessFromV2(100));
end;

procedure THueCoreTests.MalformedJSON;
begin
  Assert.WillRaise(procedure begin THueJSON.Parse('{broken'); end, EHueAPIError);
end;

procedure THueCoreTests.HueErrorParsing;
begin
  Assert.WillRaise(
    procedure begin THueJSON.RaiseIfHueError('[{"error":{"type":1,"description":"unauthorized user"}}]'); end,
    EHueAPIError);
  Assert.WillRaise(
    procedure begin THueJSON.RaiseIfHueError('{"errors":[{"description":"bad request"}],"data":[]}'); end,
    EHueAPIError);
end;

procedure THueCoreTests.UnsupportedV2Operation;
var M: THueMockTransport; API: IHueAPI;
begin
  M := THueMockTransport.Create; API := THueAPIV2.Create('bridge.local', 'key', M);
  Assert.WillRaise(procedure begin API.RequireCapability('schedules'); end,
    EHueUnsupportedOperation);
end;

procedure THueCoreTests.ResourceIdentifiers;
var R: THueResourceReference;
begin
  R := THueResourceReference.Create(0, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
  Assert.AreEqual(0, R.LegacyID);
  Assert.AreEqual('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', R.ResourceID);
end;

initialization
  TDUnitX.RegisterTestFixture(THueCoreTests);

end.
