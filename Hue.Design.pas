unit Hue.Design;

interface

/// <summary>Registers THueBridge on the ERDesigns component palette.</summary>
procedure Register;

implementation

uses
  System.Classes, Hue.Bridge;

{$R HueBridge.res}

procedure Register;
begin
  RegisterComponents('ERDesigns', [THueBridge]);
end;

end.
