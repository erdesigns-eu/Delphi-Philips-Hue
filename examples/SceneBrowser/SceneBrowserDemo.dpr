program SceneBrowserDemo;

uses
  Vcl.Forms,
  SceneBrowserMain in 'SceneBrowserMain.pas' {SceneBrowserForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSceneBrowserForm, SceneBrowserForm);
  Application.Run;
end.
