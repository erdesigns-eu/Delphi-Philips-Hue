program HomeAutomationDemo;

uses
  Vcl.Forms,
  HomeAutomationMain in 'HomeAutomationMain.pas' {AutomationForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TAutomationForm, AutomationForm);
  Application.Run;
end.
