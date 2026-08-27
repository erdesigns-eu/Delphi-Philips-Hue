# Delphi Philips Hue

`THueBridge` is a non-visual VCL component for the Philips Hue local REST API. This breaking release moves the public component unit to `Hue.Bridge`, retains the established `THueBridge` object model, and separates protocol, JSON, errors, and HTTP into focused runtime units. API v1 remains the default; API v2 is an explicit opt-in.

## Requirements

- A current Delphi release with `System.JSON`, `System.Net.HttpClient`, and generics (Delphi 11/12/13 recommended).
- A Hue Bridge reachable on the local network.
- An application key created while the bridge link button is pressed.

Runtime code no longer uses Indy or external OpenSSL DLLs. `THTTPClient` performs HTTPS and the operating system's normal certificate validation. Use the bridge's `<bridge-id>.local` host name and install/trust the official Hue/Signify local-bridge CA as described in the [official Hue HTTPS guide](https://developers.meethue.com/develop/application-design-guidance/using-https/). The component intentionally has no “accept every certificate” switch.

## Install

Add the repository root to the Delphi library path, add `Hue.Bridge.pas` to a runtime package, and compile `HueBridge.rc` into the design-time package if the palette bitmap is wanted. Call `Register` or install the package to place `THueBridge` on the **ERDesigns** palette. The component remains VCL-only and non-visual; none of the runtime API clients require a form.

## Quick start

```pascal
uses Hue.Bridge, Hue.Types;

var Hue: THueBridge;
begin
  Hue := THueBridge.Create(nil);
  try
    Hue.IP := '001788fffe123456.local';
    Hue.Username := ApplicationKey;
    Hue.APIVersion := hav1; // default; existing source may omit this
    Hue.LoadLights;
    Hue.Lights[0].State.ON := True;
  finally
    Hue.Free;
  end;
end;
```

To use v2, change only the selection and use UUID overloads when addressing a resource directly:

```pascal
Hue.APIVersion := hav2;
Hue.LoadLights;
Hue.SetLightOn(Hue.Lights[0], True);
Hue.SetLightBrightness(Hue.Lights[0], 127);
Hue.SetLightColorTemperature(Hue.Lights[0], 250);
Hue.SetLightXY(Hue.Lights[0], 0.30, 0.30);
```

The same `SetLightOn`, `SetLightBrightness`, `SetLightColorTemperature`, and `SetGroupOn`
calls work under `hav1` and `hav2`; the component chooses numeric IDs/v1 payloads or UUIDs/v2
payloads internally. `RecallScene(THueScene)` provides the equivalent version-neutral scene operation.
Raw `UpdateLightState` and `UpdateGroupAction` overloads remain available
for native API features not represented by these convenience methods.

`examples/ConsoleHueDemo.dpr` provides a minimal example. `examples/VersionNeutralControl.dpr`
demonstrates version-neutral light/group control and resource lookup. Both read configuration from
environment variables, and no credentials are committed.

## Pairing

1. Discover or configure the bridge (`DetectBridgeIP` or `IP`). Prefer replacing a discovered numeric address with the bridge's mDNS host name for HTTPS identity validation.
2. Press the bridge link button.
3. Call `PairBridge('my-application#device')`.
4. Persist `Username` securely. The returned username is the application key used in the `hue-application-key` header by v2 and in the v1 URL by v1.

The official developer portal documents [getting started](https://developers.meethue.com/develop/get-started-2/) and the authenticated [Hue API v2 reference](https://developers.meethue.com/develop/hue-api-v2/).

## Support matrix

The matrix distinguishes implemented compatibility behavior from resources merely present in the Hue API.

| Feature | API v1 | API v2 in this component |
|---|---:|---:|
| Pair/application key | Yes | Yes (same pairing endpoint/key) |
| Lights and state parsing | Yes | Yes (`light`) |
| On/off, dimming, color temperature | Yes | Yes via native UUID payload |
| Native CIE xy color | Yes | Yes; bridge performs device-gamut handling |
| Hue/saturation legacy payload | Yes | No silent conversion; use native v2 color `xy` payload |
| Rooms and zones | Groups | Yes, including grouped-light on/brightness state |
| Grouped-light control | Group action | Yes via UUID overload |
| Scenes/list/recall | Yes | Yes (`scene`, UUID recall) |
| Bridge/resource identification | Config/numeric IDs | Bridge resource and UUID properties |
| Search/delete lights | Yes | No; explicit `EHueUnsupportedOperation` |
| Create/update/delete groups | Yes | No integer-ID emulation; explicit exception |
| Schedules | Yes | No; v1-only API resource |
| Rules | Legacy Hue v1 resource | No v2 equivalent; not newly exposed |
| Legacy sensors | Existing model scope | v2 uses typed resources; not flattened into a misleading v1 sensor |
| Entertainment configuration | Group type in v1 | Not yet exposed by the compatibility facade |

Hue v2 models devices, services, rooms, zones, `grouped_light`, scenes, and sensor services as UUID-addressed resources. This update implements the portions with sound mappings to the existing facade rather than pretending all v1 automation resources exist in v2.

Hue v2 light loading also resolves each light's owning `device` resource. Existing
`ManufacturerName`, `ModelID`, `ProductID`, and `ProductName` properties are populated from
`product_data`, while `DeviceResourceID` retains the relationship for advanced callers.

## Resource identifiers

- Existing `HueIndex: Integer` remains intact for v1.
- `THueLight.ResourceID`, `THueGroup.ResourceID`, `THueScene.ResourceID`, and `Configuration.ResourceID` carry v2 UUIDs.
- `THueGroup.GroupedLightResourceID` carries the `grouped_light` service UUID needed by the v2 group-control overload.
- A v2-only object has `HueIndex = 0`; zero is **not** a fabricated mapping.
- UUID overloads accept native v2 request JSON. This makes behavior explicit where v1 and v2 color/state semantics differ.
- Collections provide `GetLightByResourceID`, `GetGroupByResourceID`,
  `GetGroupByGroupedLightResourceID`, and `GetSceneByResourceID` lookups for v2 callers.

The legacy writable model properties still emit v1-shaped payloads. Under `hav2` they now raise
`EHueUnsupportedOperation` rather than sending an invalid request; use the documented UUID overloads
with native v2 JSON. `LoadGroups` resolves the associated `grouped_light` resources and maps aggregate
on/off and brightness into the compatibility `State` and `Action` objects. Because v2 exposes only an
aggregate `on` value, `gsAnyOn` is used when the grouped light is on rather than claiming every member is on.

## Native xy color

`SetLightXY` and `SetGroupXY` accept CIE 1931 xy values. They validate the chromaticity domain
(`x >= 0`, `y > 0`, and `x + y <= 1`) and serialize numbers with `System.JSON`. The helpers do not
guess or clip against a product gamut: Hue Bridge/device gamut handling remains authoritative. This is
intentional and avoids an inaccurate conversion from the legacy hue/saturation model.

## Hue v2 event stream

`Hue.EventStream.pas` provides `THueEventStream`, a cancellable background SSE client for
`/eventstream/clip/v2`. Callbacks run on the worker thread so console/server applications can process
events directly; VCL applications should queue UI work with `TThread.Queue`, as shown by the Event Monitor demo.

```pascal
Stream := THueEventStream.Create(BridgeHost, ApplicationKey);
Stream.OnData := HandleHueEvent;
Stream.OnError := HandleHueError;
Stream.Start;
```

Destroy the stream, or call `Stop`, before shutting down the application. The component uses normal
platform TLS validation and never disables certificate checks.

## Unit structure

| Unit | Responsibility |
|---|---|
| `Hue.Bridge.pas` | Backward-compatible component and established model classes |
| `Hue.Types.pas` | API version, HTTP method, resource reference |
| `Hue.Errors.pas` | HTTP, API, and unsupported-capability exceptions |
| `Hue.JSON.pas` | Safe `System.JSON` parsing/access and Unicode quoting |
| `Hue.Transport.pas` | Shared injectable `THTTPClient` transport |
| `Hue.EventStream.pas` | Background Hue v2 Server-Sent Events client |
| `Hue.API.pas` | Small common adapter contract/base |
| `Hue.API.V1.pas` | v1 URL/authentication adapter |
| `Hue.API.V2.pas` | v2 URL/header/capability and brightness adapter |

`Hue.JSON.pas` now uses `System.JSON` for both API generations. A small compatibility node view keeps the established v1 model loaders readable, but the handwritten `untJSONParser.pas` parser has been removed; parsing, Unicode decoding, scalar handling, and malformed-document detection are provided by the Delphi runtime.

Applications that directly imported `untJSONParser` must migrate that unrelated parser usage to
`System.JSON` or the documented helpers in `Hue.JSON`; only the Hue component's model-facing compatibility
view is retained.

## Packages and tests

- `packages/HueRuntime.dpk` builds all runtime units.
- `packages/HueDesign.dpk` installs `THueBridge` and its palette resource; build the runtime package first.
- `tests/HueTests.dpr` is the DUnitX console runner.

Example command lines from a configured RAD Studio developer prompt:

```bat
build.cmd
```

`build.cmd` compiles both packages, compiles the DUnitX runner, and runs it. Run the script from a RAD Studio developer prompt with DUnitX on the Delphi library path. Outputs are written below `build/`.

## Demo applications

| Demo | Purpose |
|---|---|
| `examples/SimpleVCL` | One-form v1/v2 light list with on/off control |
| `examples/HomeAutomation` | Morning, evening, and away routines suitable as a home-automation starting point |
| `examples/SceneBrowser` | Version-neutral scene discovery, identity display, and recall |
| `examples/EventMonitor` | Thread-safe VCL display of raw Hue v2 event-stream JSON |
| `examples/ConsoleHueDemo.dpr` | Minimal console usage |
| `examples/VersionNeutralControl.dpr` | Broader console light/group/scene and resource-ID example |

The demos contain no credentials. Enter bridge settings in the forms or use the documented environment
variables for console examples.

## Migration from the original component

1. Replace `uses untHueBridge` with `uses Hue.Bridge`. This unit rename is an intentional breaking change.
2. Existing DFM files do not contain the unit name. Their declaration remains `object HueBridge1: THueBridge`, so no DFM class-name edit is required. If a form was edited manually, ensure its component line still names `THueBridge`.
3. Existing applications remain on `hav1` by default.
4. Remove deployment of Indy OpenSSL DLLs; HTTPS now uses the platform stack.
5. Expect `EHueHTTPError`, `EHueAPIError`, or `EHueUnsupportedOperation` rather than an empty response that hides the failure.
6. Opt into v2 with `APIVersion := hav2` and persist/use `ResourceID` strings. Do not store v2 IDs in integers.
7. Use UUID overloads for v2 light/group control and scene recall. Schedules and integer-ID mutation methods remain v1-only.
8. `HTTP: TIdHTTP` is no longer public because exposing a concrete transport prevented secure replacement. Use `SetTransport` for a test double; protocol internals remain hidden in normal use.

No other legacy classes, collection names, loading events, or update flags were removed. Direct Indy customization is the intentional breaking change.

## Tests and validation

Synthetic v1/v2 fixtures are under `tests/fixtures`. `tests/TestHueCore.pas` uses DUnitX and an injected transport to check URL construction, authentication headers, brightness conversion, malformed JSON, explicit v2 capability errors, and UUID handling without a physical bridge. The fixture documents cover v1/v2 light parsing and v2 room shape. Add the unit to a standard DUnitX runner in your installed Delphi environment.

This repository has not been validated against a physical bridge. Certificate trust, pairing, discovery, firmware-specific resource availability, scene recall, and actual lamp color behavior require bridge hardware on the local network.
