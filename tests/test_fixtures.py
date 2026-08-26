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


def test_no_real_credentials_or_obsolete_transport():
    root = Path(__file__).parents[1]
    source = (root / "untHueBridge.pas").read_text(encoding="utf-8-sig")
    assert "TIdSSLIOHandlerSocketOpenSSL" not in source
    assert "hue-application-key" in (root / "Hue.API.V2.pas").read_text()
    assert "hav1" in source and "hav2" in source


def test_payload_and_endpoint_contracts():
    v1 = (Path(__file__).parents[1] / "Hue.API.V1.pas").read_text()
    v2 = (Path(__file__).parents[1] / "Hue.API.V2.pas").read_text()
    bridge = (Path(__file__).parents[1] / "untHueBridge.pas").read_text(encoding="utf-8-sig")
    assert "/api/%s%s" in v1
    assert "/clip/v2/resource%s" in v2
    assert '"recall":{"action":"active"}' in bridge
    assert "EHueUnsupportedOperation" in bridge
