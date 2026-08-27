import json
from pathlib import Path


FIXTURES = Path(__file__).parent / "fixtures"


def test_v1_light_shape_and_state():
    light = json.loads((FIXTURES / "v1-lights.json").read_text())["1"]
    assert light["name"] == "Desk"
    assert light["state"] == {"on": True, "bri": 127, "ct": 250, "reachable": True}


def test_v2_light_uuid_and_state():
    light = json.loads((FIXTURES / "v2-lights.json").read_text())["data"][0]
    assert light["id"] == "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    assert light["on"]["on"] is True
    assert light["dimming"]["brightness"] == 50.0


def test_v2_room_grouped_light_reference():
    room = json.loads((FIXTURES / "v2-rooms.json").read_text())["data"][0]
    assert room["type"] == "room"
    assert room["services"][0]["rtype"] == "grouped_light"
    assert room["services"][0]["rid"] == "99999999-8888-7777-6666-555555555555"


def test_v2_grouped_light_state_and_device_product_data():
    grouped = json.loads((FIXTURES / "v2-grouped-lights.json").read_text())["data"][0]
    device = json.loads((FIXTURES / "v2-devices.json").read_text())["data"][0]
    light = json.loads((FIXTURES / "v2-lights.json").read_text())["data"][0]
    assert grouped["on"]["on"] is True
    assert grouped["dimming"]["brightness"] == 42.5
    assert light["owner"]["rid"] == device["id"]
    assert device["product_data"]["manufacturer_name"] == "Signify Netherlands B.V."


def test_no_real_credentials_or_obsolete_transport():
    root = Path(__file__).parents[1]
    source = (root / "Hue.Bridge.pas").read_text(encoding="utf-8-sig")
    assert "TIdSSLIOHandlerSocketOpenSSL" not in source
    assert "hue-application-key" in (root / "Hue.API.V2.pas").read_text()
    assert "hav1" in source and "hav2" in source
    assert not (root / "untJSONParser.pas").exists()
    assert "untJSONParser" not in source


def test_payload_and_endpoint_contracts():
    v1 = (Path(__file__).parents[1] / "Hue.API.V1.pas").read_text()
    v2 = (Path(__file__).parents[1] / "Hue.API.V2.pas").read_text()
    bridge = (Path(__file__).parents[1] / "Hue.Bridge.pas").read_text(encoding="utf-8-sig")
    assert "/api/%s%s" in v1
    assert "/clip/v2/resource%s" in v2
    assert '"recall":{"action":"active"}' in bridge
    assert "EHueUnsupportedOperation" in bridge


def test_reviewed_ownership_and_parser_regressions():
    root = Path(__file__).parents[1]
    bridge = (root / "Hue.Bridge.pas").read_text(encoding="utf-8-sig")
    api = (root / "Hue.API.pas").read_text()
    assert "with THueScheduleCommand(Dest) do" in bridge
    assert "FNetwork.Free" in bridge
    assert "Items['effect'].AsString = 'colorloop'" in bridge
    assert "if Result <> '' then" in api


def test_version_neutral_helpers_and_example():
    root = Path(__file__).parents[1]
    bridge = (root / "Hue.Bridge.pas").read_text(encoding="utf-8-sig")
    example = (root / "examples" / "VersionNeutralControl.dpr").read_text()
    for declaration, usage in (
        ("SetLightOn", "SetLightOn"),
        ("SetLightBrightness", "SetLightBrightness"),
        ("SetLightColorTemperature", "SetLightColorTemperature"),
        ("SetLightXY", None),
        ("SetGroupXY", None),
        ("SetGroupOn", "SetGroupOn"),
        ("RecallScene(const AScene: THueScene)", "RecallScene"),
        ("GetLightByResourceID", "GetLightByResourceID"),
        ("GetGroupByGroupedLightResourceID", None),
    ):
        assert declaration in bridge
        assert usage is None or usage in example


def test_event_stream_packages_and_vcl_demos_exist():
    root = Path(__file__).parents[1]
    stream = (root / "Hue.EventStream.pas").read_text()
    assert "/eventstream/clip/v2" in stream
    assert "text/event-stream" in stream
    assert (root / "packages" / "HueRuntime.dpk").exists()
    assert (root / "packages" / "HueDesign.dpk").exists()
    assert (root / "tests" / "HueTests.dpr").exists()
    for demo in ("SimpleVCL", "HomeAutomation", "SceneBrowser", "EventMonitor"):
        files = list((root / "examples" / demo).iterdir())
        assert any(path.suffix == ".dpr" for path in files)
        assert any(path.suffix == ".dfm" for path in files)
