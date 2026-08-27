unit SimpleHueMain;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Hue.Bridge, Hue.Types;

type
  /// <summary>Minimal form demonstrating the same light controls with Hue API v1 or v2.</summary>
  TSimpleHueForm = class(TForm)
    HostEdit: TEdit;
    KeyEdit: TEdit;
    VersionBox: TComboBox;
    LoadButton: TButton;
    OnButton: TButton;
    OffButton: TButton;
    LightsList: TListBox;
    /// <summary>Loads lights using the selected API version.</summary>
    procedure LoadButtonClick(Sender: TObject);
    /// <summary>Switches the selected light on.</summary>
    procedure OnButtonClick(Sender: TObject);
    /// <summary>Switches the selected light off.</summary>
    procedure OffButtonClick(Sender: TObject);
  private
    FHue: THueBridge;
    /// <summary>Applies host, key, and API selection from the form controls.</summary>
    procedure ConfigureBridge;
    /// <summary>Returns the selected light or raises a helpful error.</summary>
    function SelectedLight: THueLight;
  public
    /// <summary>Creates the owned Hue bridge component.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Releases the owned Hue bridge component.</summary>
    destructor Destroy; override;
  end;

var
  SimpleHueForm: TSimpleHueForm;

implementation

{$R *.dfm}

uses System.SysUtils;

constructor TSimpleHueForm.Create(AOwner: TComponent);
begin
  inherited;
  FHue := THueBridge.Create(Self);
end;

destructor TSimpleHueForm.Destroy;
begin
  FHue.Free;
  inherited;
end;

procedure TSimpleHueForm.ConfigureBridge;
begin
  FHue.IP := HostEdit.Text;
  FHue.Username := KeyEdit.Text;
  if VersionBox.ItemIndex = 1 then FHue.APIVersion := hav2 else FHue.APIVersion := hav1;
end;

procedure TSimpleHueForm.LoadButtonClick(Sender: TObject);
var I: Integer;
begin
  ConfigureBridge;
  FHue.LoadLights;
  LightsList.Clear;
  for I := 0 to FHue.Lights.Count - 1 do LightsList.Items.Add(FHue.Lights[I].Name);
  if LightsList.Count > 0 then LightsList.ItemIndex := 0;
end;

function TSimpleHueForm.SelectedLight: THueLight;
begin
  if LightsList.ItemIndex < 0 then raise Exception.Create('Select a light first');
  Result := FHue.Lights[LightsList.ItemIndex];
end;

procedure TSimpleHueForm.OnButtonClick(Sender: TObject);
begin
  FHue.SetLightOn(SelectedLight, True);
end;

procedure TSimpleHueForm.OffButtonClick(Sender: TObject);
begin
  FHue.SetLightOn(SelectedLight, False);
end;

end.
