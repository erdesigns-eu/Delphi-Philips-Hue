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
    /// <summary>Stores the last request body passed by an adapter.</summary>
    LastBody: string;
    /// <summary>Stores the last HTTP method passed by an adapter.</summary>
    LastMethod: THueHTTPMethod;
    /// <summary>Enables synthetic v2 device, light, room, zone, and grouped-light responses.</summary>
    UseResourceFixtures: Boolean;
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
    /// <summary>Verifies v1 model access is backed by System.JSON compatibility nodes.</summary>
    [Test] procedure LegacyV1CompatibilityParsing;
    /// <summary>Verifies schedules fail explicitly under v2.</summary>
    [Test] procedure UnsupportedV2Operation;
    /// <summary>Verifies UUID identifiers remain strings.</summary>
    [Test] procedure ResourceIdentifiers;
    /// <summary>Verifies version-neutral controls generate native v2 requests.</summary>
    [Test] procedure VersionNeutralV2Control;
    /// <summary>Verifies native v2 xy payload generation and chromaticity validation.</summary>
    [Test] procedure NativeXYControl;
    /// <summary>Verifies device product data and grouped-light state are mapped into compatibility models.</summary>
    [Test] procedure V2DeviceAndGroupedLightParsing;
  end;

implementation

uses
  System.SysUtils, Hue.API, Hue.API.V1, Hue.API.V2, Hue.Bridge, Hue.JSON,
  Hue.Errors;

function THueMockTransport.Execute(const AMethod: THueHTTPMethod;
  const AURL, ABody: string; const AHeaders: THueHeaders): string;
begin
  LastURL := AURL;
  LastBody := ABody;
  LastMethod := AMethod;
  HasApplicationKey := AHeaders.ContainsKey('hue-application-key');
  if UseResourceFixtures and AURL.EndsWith('/device') then
    Result := '{"errors":[],"data":[{"id":"device-id","metadata":{"name":"Desk device"},"product_data":{"manufacturer_name":"Signify Netherlands B.V.","model_id":"LCT001","product_id":"9290012573A","product_name":"Hue lamp"}}]}'
  else if UseResourceFixtures and AURL.EndsWith('/light') then
    Result := '{"errors":[],"data":[{"id":"light-id","owner":{"rid":"device-id","rtype":"device"},"metadata":{"name":"Desk"},"on":{"on":true},"dimming":{"brightness":50},"color_temperature":{"mirek":250}}]}'
  else if UseResourceFixtures and AURL.EndsWith('/grouped_light') then
    Result := '{"errors":[],"data":[{"id":"grouped-id","on":{"on":true},"dimming":{"brightness":42.5}}]}'
  else if UseResourceFixtures and (AURL.EndsWith('/room') or AURL.EndsWith('/zone')) then
    Result := '{"errors":[],"data":[{"id":"space-id","metadata":{"name":"Office"},"services":[{"rid":"grouped-id","rtype":"grouped_light"}]}]}'
  else
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

procedure THueCoreTests.LegacyV1CompatibilityParsing;
var
  Document: TJSON;
begin
  Document := TJSON.Parse('{"name":"Bureau \u2605","state":{"on":true,"bri":127}}');
  try
    Assert.AreEqual('Bureau ' + WideChar($2605), Document.Items['name'].AsString);
    Assert.IsTrue(Document.Items['state'].Items['on'].AsBoolean);
    Assert.AreEqual(127, Document.Items['state'].Items['bri'].AsInteger);
  finally
    Document.Free;
  end;
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

procedure THueCoreTests.VersionNeutralV2Control;
var
  Bridge: THueBridge;
  Light: THueLight;
  Mock: THueMockTransport;
begin
  Bridge := THueBridge.Create(nil);
  try
    Mock := THueMockTransport.Create;
    Bridge.SetTransport(Mock);
    Bridge.IP := 'bridge.local';
    Bridge.Username := 'key';
    Bridge.APIVersion := hav2;
    Light := Bridge.Lights.Add;
    Light.LoadLightV2('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      'dddddddd-1111-2222-3333-444444444444', 'Desk',
      'Signify Netherlands B.V.', 'LCT001', '9290012573A', 'Hue lamp',
      True, 127, 250);

    Assert.IsTrue(Bridge.SetLightOn(Light, False));
    Assert.AreEqual(hhmPut, Mock.LastMethod);
    Assert.AreEqual('https://bridge.local/clip/v2/resource/light/' +
      Light.ResourceID, Mock.LastURL);
    Assert.AreEqual('{"on":{"on":false}}', Mock.LastBody);

    Assert.IsTrue(Bridge.SetLightBrightness(Light, 127));
    Assert.Contains(Mock.LastBody, '"dimming"');
    Assert.Contains(Mock.LastBody, '"brightness"');
  finally
    Bridge.Free;
  end;
end;

procedure THueCoreTests.NativeXYControl;
var
  Bridge: THueBridge;
  Light: THueLight;
  Mock: THueMockTransport;
begin
  Bridge := THueBridge.Create(nil);
  try
    Mock := THueMockTransport.Create;
    Bridge.SetTransport(Mock);
    Bridge.IP := 'bridge.local';
    Bridge.Username := 'key';
    Bridge.APIVersion := hav2;
    Light := Bridge.Lights.Add;
    Light.LoadLightV2('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      'dddddddd-1111-2222-3333-444444444444', 'Desk',
      'Signify Netherlands B.V.', 'LCT001', '9290012573A', 'Hue lamp',
      True, 127, 250);
    Assert.IsTrue(Bridge.SetLightXY(Light, 0.3, 0.3));
    Assert.Contains(Mock.LastBody, '"color"');
    Assert.Contains(Mock.LastBody, '"xy"');
    Assert.WillRaise(
      procedure begin Bridge.SetLightXY(Light, 0.8, 0.4); end,
      EArgumentOutOfRangeException);
  finally
    Bridge.Free;
  end;
end;

procedure THueCoreTests.V2DeviceAndGroupedLightParsing;
var
  Bridge: THueBridge;
  Mock: THueMockTransport;
begin
  Bridge := THueBridge.Create(nil);
  try
    Mock := THueMockTransport.Create;
    Mock.UseResourceFixtures := True;
    Bridge.SetTransport(Mock);
    Bridge.IP := 'bridge.local';
    Bridge.Username := 'key';
    Bridge.APIVersion := hav2;
    Bridge.LoadLights;
    Assert.AreEqual(1, Bridge.Lights.Count);
    Assert.AreEqual('device-id', Bridge.Lights[0].DeviceResourceID);
    Assert.AreEqual('Signify Netherlands B.V.', Bridge.Lights[0].ManufacturerName);
    Assert.AreEqual('9290012573A', Bridge.Lights[0].ProductID);
    Bridge.LoadGroups;
    Assert.AreEqual(2, Bridge.Groups.Count);
    Assert.AreEqual('grouped-id', Bridge.Groups[0].GroupedLightResourceID);
    Assert.AreEqual(gsAnyOn, Bridge.Groups[0].State);
    Assert.AreEqual(108, Bridge.Groups[0].Action.Brightness);
  finally
    Bridge.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(THueCoreTests);

end.
