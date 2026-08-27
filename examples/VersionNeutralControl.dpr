program VersionNeutralControl;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Hue.Bridge in '..\Hue.Bridge.pas',
  Hue.Types in '..\Hue.Types.pas';

var
  Hue: THueBridge;
  Light: THueLight;
  Group: THueGroup;
begin
  Hue := THueBridge.Create(nil);
  try
    Hue.IP := GetEnvironmentVariable('HUE_BRIDGE_HOST');
    Hue.Username := GetEnvironmentVariable('HUE_APPLICATION_KEY');
    Hue.APIVersion := hav2; // Change to hav1 without changing the control calls.

    Hue.LoadLights;
    if Hue.Lights.Count = 0 then
      raise Exception.Create('No lights were returned by the bridge');
    Light := Hue.Lights[0];
    Hue.SetLightOn(Light, True);
    Hue.SetLightBrightness(Light, 127);
    Hue.SetLightColorTemperature(Light, 250);

    Hue.LoadGroups;
    if Hue.Groups.Count > 0 then
    begin
      Group := Hue.Groups[0];
      Hue.SetGroupOn(Group, True);
      if Hue.APIVersion = hav2 then
        Writeln('Grouped-light service: ', Group.GroupedLightResourceID);
    end;

    Hue.LoadScenes;
    if Hue.Scenes.Count > 0 then
    begin
      Writeln('Available scene: ', Hue.Scenes[0].Name);
      // Hue.RecallScene(Hue.Scenes[0]); // Uncomment to activate it.
    end;

    if Hue.APIVersion = hav2 then
      Light := Hue.Lights.GetLightByResourceID(Light.ResourceID)
    else
      Light := Hue.Lights.GetLightByID(Light.HueIndex);
    Writeln('Controlled light: ', Light.Name);
  finally
    Hue.Free;
  end;
end.
