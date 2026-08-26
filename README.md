# Delphi Philips Hue

`THueBridge` is a non-visual VCL component for the Philips Hue local REST API. This release keeps the established `uses untHueBridge;` object model while moving protocol, JSON, errors, and HTTP into focused runtime units. API v1 remains the default; API v2 is an explicit opt-in.

## Requirements

- A current Delphi release with `System.JSON`, `System.Net.HttpClient`, and generics (Delphi 11/12/13 recommended).
- A Hue Bridge reachable on the local network.
- An application key created while the bridge link button is pressed.

Runtime code no longer uses Indy or external OpenSSL DLLs. `THTTPClient` performs HTTPS and the operating system's normal certificate validation. Use the bridge's `<bridge-id>.local` host name and install/trust the official Hue/Signify local-bridge CA as described in the [official Hue HTTPS guide](https://developers.meethue.com/develop/application-design-guidance/using-https/). The component intentionally has no “accept every certificate” switch.

## Install

Add the repository root to the Delphi library path, add `untHueBridge.pas` to a runtime package, and compile `HueBridge.rc` into the design-time package if the palette bitmap is wanted. Call `Register` or install the package to place `THueBridge` on the **ERDesigns** palette. The component remains VCL-only and non-visual; none of the runtime API clients require a form.

## Quick start

```pascal
uses untHueBridge, Hue.Types;

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
- A v2-only object has `HueIndex = 0`; zero is **not** a fabricated mapping.
- UUID overloads accept native v2 request JSON. This makes behavior explicit where v1 and v2 color/state semantics differ.

## Unit structure

| Unit | Responsibility |
|---|---|
| `untHueBridge.pas` | Backward-compatible component and established model classes |
| `Hue.Types.pas` | API version, HTTP method, resource reference |
| `Hue.Errors.pas` | HTTP, API, and unsupported-capability exceptions |
| `Hue.JSON.pas` | Safe `System.JSON` parsing/access and Unicode quoting |
| `Hue.Transport.pas` | Shared injectable `THTTPClient` transport |
| `Hue.API.pas` | Small common adapter contract/base |
| `Hue.API.V1.pas` | v1 URL/authentication adapter |
| `Hue.API.V2.pas` | v2 URL/header/capability and brightness adapter |

`untJSONParser.pas` remains temporarily because legacy model loaders are part of the compatibility facade. All new API v2 and transport code uses `System.JSON`; new code should use `Hue.JSON` rather than the custom parser.

## Migration from the original component

1. Keep `uses untHueBridge` and existing component creation/design-time forms.
2. Existing applications remain on `hav1` by default.
3. Remove deployment of Indy OpenSSL DLLs; HTTPS now uses the platform stack.
4. Expect `EHueHTTPError`, `EHueAPIError`, or `EHueUnsupportedOperation` rather than an empty response that hides the failure.
5. Opt into v2 with `APIVersion := hav2` and persist/use `ResourceID` strings. Do not store v2 IDs in integers.
6. Use UUID overloads for v2 light/group control and scene recall. Schedules and integer-ID mutation methods remain v1-only.
7. `HTTP: TIdHTTP` is no longer public because exposing a concrete transport prevented secure replacement. Use `SetTransport` for a test double; protocol internals remain hidden in normal use.

No other legacy classes, collection names, loading events, or update flags were removed. Direct Indy customization is the intentional breaking change.

## Tests and validation

Synthetic v1/v2 fixtures are under `tests/fixtures`. `tests/TestHueCore.pas` uses DUnitX and an injected transport to check URL construction, authentication headers, brightness conversion, malformed JSON, explicit v2 capability errors, and UUID handling without a physical bridge. The fixture documents cover v1/v2 light parsing and v2 room shape. Add the unit to a standard DUnitX runner in your installed Delphi environment.

This repository has not been validated against a physical bridge. Certificate trust, pairing, discovery, firmware-specific resource availability, scene recall, and actual lamp color behavior require bridge hardware on the local network.
