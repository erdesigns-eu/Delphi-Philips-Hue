program SimpleHueDemo;

uses
  Vcl.Forms,
  SimpleHueMain in 'SimpleHueMain.pas' {SimpleHueForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSimpleHueForm, SimpleHueForm);
  Application.Run;
end.
