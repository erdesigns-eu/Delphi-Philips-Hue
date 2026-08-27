unit HomeAutomationMain;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  Hue.Bridge, Hue.Types;

type
  /// <summary>Reference home-automation form with reusable morning, evening, and away routines.</summary>
  TAutomationForm = class(TForm)
    HostEdit: TEdit;
    KeyEdit: TEdit;
    ConnectButton: TButton;
    MorningButton: TButton;
    EveningButton: TButton;
    AwayButton: TButton;
    LogMemo: TMemo;
    AutomationTimer: TTimer;
    /// <summary>Loads lights and rooms from the configured v2 bridge.</summary>
    procedure ConnectButtonClick(Sender: TObject);
    /// <summary>Runs the bright, cool morning routine.</summary>
    procedure MorningButtonClick(Sender: TObject);
    /// <summary>Runs the warm, dim evening routine.</summary>
    procedure EveningButtonClick(Sender: TObject);
    /// <summary>Switches every loaded room off.</summary>
    procedure AwayButtonClick(Sender: TObject);
    /// <summary>Demonstrates where time/sensor automation decisions can be scheduled.</summary>
    procedure AutomationTimerTimer(Sender: TObject);
  private
    FHue: THueBridge;
    /// <summary>Applies a shared light state to all currently loaded lights.</summary>
    procedure ApplyLightRoutine(const ABrightness, AMirek: Integer);
    /// <summary>Adds a timestamped line to the automation log.</summary>
    procedure Log(const AText: string);
  public
    /// <summary>Creates the owned Hue bridge.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Releases the owned Hue bridge.</summary>
    destructor Destroy; override;
  end;

var AutomationForm: TAutomationForm;

implementation

{$R *.dfm}

uses System.SysUtils, System.DateUtils;

constructor TAutomationForm.Create(AOwner: TComponent);
begin
  inherited;
  FHue := THueBridge.Create(Self);
  FHue.APIVersion := hav2;
end;

destructor TAutomationForm.Destroy;
begin
  FHue.Free;
  inherited;
end;

procedure TAutomationForm.Log(const AText: string);
begin
  LogMemo.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + AText);
end;

procedure TAutomationForm.ConnectButtonClick(Sender: TObject);
begin
  FHue.IP := HostEdit.Text;
  FHue.Username := KeyEdit.Text;
  FHue.LoadLights;
  FHue.LoadGroups;
  Log(Format('Loaded %d lights and %d rooms/zones', [FHue.Lights.Count, FHue.Groups.Count]));
end;

procedure TAutomationForm.ApplyLightRoutine(const ABrightness, AMirek: Integer);
var I: Integer;
begin
  for I := 0 to FHue.Lights.Count - 1 do
  begin
    FHue.SetLightOn(FHue.Lights[I], True);
    FHue.SetLightBrightness(FHue.Lights[I], ABrightness);
    FHue.SetLightColorTemperature(FHue.Lights[I], AMirek);
  end;
end;

procedure TAutomationForm.MorningButtonClick(Sender: TObject);
begin
  ApplyLightRoutine(220, 200);
  Log('Morning routine applied');
end;

procedure TAutomationForm.EveningButtonClick(Sender: TObject);
begin
  ApplyLightRoutine(90, 400);
  Log('Evening routine applied');
end;

procedure TAutomationForm.AwayButtonClick(Sender: TObject);
var I: Integer;
begin
  for I := 0 to FHue.Groups.Count - 1 do FHue.SetGroupOn(FHue.Groups[I], False);
  Log('Away routine applied');
end;

procedure TAutomationForm.AutomationTimerTimer(Sender: TObject);
begin
  if MinuteOfTheHour(Now) = 0 then Log('Hourly automation evaluation point');
end;

end.
