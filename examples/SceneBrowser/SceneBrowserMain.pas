unit SceneBrowserMain;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Hue.Bridge, Hue.Types;

type
  /// <summary>Scene browsing form demonstrating version-neutral scene discovery and recall.</summary>
  TSceneBrowserForm = class(TForm)
    HostEdit: TEdit;
    KeyEdit: TEdit;
    VersionBox: TComboBox;
    LoadButton: TButton;
    RecallButton: TButton;
    ScenesList: TListBox;
    DetailMemo: TMemo;
    /// <summary>Loads scenes through the selected Hue API.</summary>
    procedure LoadButtonClick(Sender: TObject);
    /// <summary>Shows identity details for the selected scene.</summary>
    procedure ScenesListClick(Sender: TObject);
    /// <summary>Recalls the selected scene through the version-neutral overload.</summary>
    procedure RecallButtonClick(Sender: TObject);
  private
    FHue: THueBridge;
    /// <summary>Returns the selected scene or raises a helpful error.</summary>
    function SelectedScene: THueScene;
  public
    /// <summary>Creates the owned bridge.</summary>
    constructor Create(AOwner: TComponent); override;
    /// <summary>Releases the owned bridge.</summary>
    destructor Destroy; override;
  end;

var SceneBrowserForm: TSceneBrowserForm;

implementation

{$R *.dfm}

uses System.SysUtils;

constructor TSceneBrowserForm.Create(AOwner: TComponent);
begin
  inherited;
  FHue := THueBridge.Create(Self);
end;

destructor TSceneBrowserForm.Destroy;
begin
  FHue.Free;
  inherited;
end;

procedure TSceneBrowserForm.LoadButtonClick(Sender: TObject);
var I: Integer;
begin
  FHue.IP := HostEdit.Text;
  FHue.Username := KeyEdit.Text;
  if VersionBox.ItemIndex = 1 then FHue.APIVersion := hav2 else FHue.APIVersion := hav1;
  FHue.LoadScenes;
  ScenesList.Clear;
  for I := 0 to FHue.Scenes.Count - 1 do ScenesList.Items.Add(FHue.Scenes[I].Name);
  if ScenesList.Count > 0 then begin ScenesList.ItemIndex := 0; ScenesListClick(nil); end;
end;

function TSceneBrowserForm.SelectedScene: THueScene;
begin
  if ScenesList.ItemIndex < 0 then raise Exception.Create('Select a scene first');
  Result := FHue.Scenes[ScenesList.ItemIndex];
end;

procedure TSceneBrowserForm.ScenesListClick(Sender: TObject);
var Scene: THueScene;
begin
  Scene := SelectedScene;
  DetailMemo.Lines.Text := Format('Name: %s%sLegacy ID: %s%sResource ID: %s%sGroup: %d',
    [Scene.Name, sLineBreak, Scene.HueIndex, sLineBreak, Scene.ResourceID,
     sLineBreak, Scene.Group]);
end;

procedure TSceneBrowserForm.RecallButtonClick(Sender: TObject);
begin
  FHue.RecallScene(SelectedScene);
end;

end.
