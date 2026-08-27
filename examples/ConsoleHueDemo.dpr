program ConsoleHueDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Hue.Bridge in '..\Hue.Bridge.pas',
  Hue.Types in '..\Hue.Types.pas';

var
  Hue: THueBridge;
begin
  Hue := THueBridge.Create(nil);
  try
    Hue.IP := '001788fffe123456.local';
    Hue.Username := GetEnvironmentVariable('HUE_APPLICATION_KEY');
    Hue.APIVersion := hav2; // Omit this line, or use hav1, for legacy behavior.
    Hue.LoadLights;
    if Hue.Lights.Count > 0 then
      Hue.SetLightOn(Hue.Lights[0], True);
    Writeln(Format('Loaded %d lights.', [Hue.Lights.Count]));
  finally
    Hue.Free;
  end;
end.
