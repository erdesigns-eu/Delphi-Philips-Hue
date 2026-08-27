program EventMonitorDemo;

uses
  Vcl.Forms,
  EventMonitorMain in 'EventMonitorMain.pas' {EventMonitorForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TEventMonitorForm, EventMonitorForm);
  Application.Run;
end.
