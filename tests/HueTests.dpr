program HueTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  TestHueCore in 'TestHueCore.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
begin
  TDUnitX.CheckCommandLine;
  Runner := TDUnitX.CreateRunner;
  Runner.UseRTTI := True;
  Runner.AddLogger(TDUnitXConsoleLogger.Create(True));
  Runner.AddLogger(TDUnitXXMLNUnitFileLogger.Create);
  Results := Runner.Execute;
  if not Results.AllPassed then
    ExitCode := EXIT_ERRORS;
end.
