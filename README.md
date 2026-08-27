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
Hue.UpdateLightState(Hue.Lights[0].ResourceID, '{"on":{"on":true}}');
```

`examples/ConsoleHueDemo.dpr` provides a complete minimal example. It reads the key from `HUE_APPLICATION_KEY`; no credentials are committed.

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
| Hue/saturation legacy payload | Yes | No silent conversion; use native v2 color `xy` payload |
| Rooms and zones | Groups | Yes (`room`/`zone` compatibility views) |
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

## Resource identifiers

- Existing `HueIndex: Integer` remains intact for v1.
- `THueLight.ResourceID`, `THueGroup.ResourceID`, `THueScene.ResourceID`, and `Configuration.ResourceID` carry v2 UUIDs.
- `THueGroup.GroupedLightResourceID` carries the `grouped_light` service UUID needed by the v2 group-control overload.
- A v2-only object has `HueIndex = 0`; zero is **not** a fabricated mapping.
- UUID overloads accept native v2 request JSON. This makes behavior explicit where v1 and v2 color/state semantics differ.

The legacy writable model properties still emit v1-shaped payloads. Under `hav2` they now raise
`EHueUnsupportedOperation` rather than sending an invalid request; use the documented UUID overloads
with native v2 JSON. Room/zone compatibility views currently report membership and identity, but their
aggregate on/off state is not populated until a separate `grouped_light` resource is requested.

## Unit structure

| Unit | Responsibility |
|---|---|
| `Hue.Bridge.pas` | Backward-compatible component and established model classes |
| `Hue.Types.pas` | API version, HTTP method, resource reference |
| `Hue.Errors.pas` | HTTP, API, and unsupported-capability exceptions |
| `Hue.JSON.pas` | Safe `System.JSON` parsing/access and Unicode quoting |
| `Hue.Transport.pas` | Shared injectable `THTTPClient` transport |
| `Hue.API.pas` | Small common adapter contract/base |
| `Hue.API.V1.pas` | v1 URL/authentication adapter |
| `Hue.API.V2.pas` | v2 URL/header/capability and brightness adapter |

`untJSONParser.pas` remains temporarily because legacy model loaders are part of the compatibility facade. All new API v2 and transport code uses `System.JSON`; new code should use `Hue.JSON` rather than the custom parser.

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
