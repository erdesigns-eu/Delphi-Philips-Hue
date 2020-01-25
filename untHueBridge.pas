unit untHueBridge;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Forms, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  untJSONParser, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  Generics.Collections, Generics.Defaults;

// Maximum Lights, Groups, Schedules, Scenes, Sensors, Rules
const
  MaxLights    = 150;
  MaxGroups    = 150;
  MaxSchedules = 100;
  MaxScenes    = 200;

type
  // Array of Integer
  TAIntegerList = array of Integer;

  // Events
  TLightChangeEventType  = (etState, etLight);
  THueLightChangeEvent   = procedure(Sender: TObject; EventType: TLightChangeEventType; PUTData: string) of object;
  THueUpdateLightEvent   = procedure(Sender: TObject; URL: string; PUTData: string) of object;
  THueLightIdentifyEvent = procedure(Sender: TObject; ID: Integer) of object;

  // Hue Light State Alerts
  THueLightStateAlert = (saNone, saSelect, saLSelect);
  // Hue Light State Color Mode
  THueLightStateColorMode = (cmNone, cmHueSatuarion, cmXY, cmColorTemprature);
  // Hue Light State Effect
  THueLightStateEffect = (seNone, seColorLoop);

  // Forward declarations
  THueLight = class;

  // Hue Light State
  THueLightState = class(TPersistent)
  private
    FOwner: TObject;
    FAlert: THueLightStateAlert;
    FBrightness: Integer;
    FColorMode: THueLightStateColorMode;
    FColorTemperature: Integer;
    FEffect: THueLightStateEffect;
    FHue: Integer;
    FMode: string;
    FON: Boolean;
    FReachable: Boolean;
    FSaturation: Integer;

    FOnChange: THueLightChangeEvent;

    procedure SetBrightness(const ABrightness: Integer); // Min 1 - Max 254
    procedure SetColorTemperature(const ATemperature: Integer);
    procedure SetEffect(const AEffect: THueLightStateEffect);
    procedure SetHue(const AHue: Integer);
    procedure SetON(const AON: Boolean);
    procedure SetSaturation(const ASaturation: Integer); // Min 0 - Max 254
  protected
    procedure UpdateState(const APutData: string);
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TObject);
    procedure LoadLight(AAlert: THueLightStateAlert; ABrightness: Integer;
      AColorMode: THueLightStateColorMode; AColorTemperature: Integer; AEffect: THueLightStateEffect;
      AHue: Integer; AMode: string; AON: Boolean; AReachable: Boolean; ASaturation: Integer);
  published
    property Alert: THueLightStateAlert read FAlert;
    property Brightness: Integer read FBrightness write SetBrightness;
    property ColorMode: THueLightStateColorMode read FColorMode;
    property ColorTemperature: Integer read FColorTemperature write SetColorTemperature;
    property Effect: THueLightStateEffect read FEffect write SetEffect;
    property Hue: Integer read FHue write SetHue;
    property Mode: string read FMode;
    property ON: Boolean read FON write SetON;
    property Reachable: Boolean read FReachable;
    property Saturation: Integer read FSaturation write SetSaturation;

    property OnChange: THueLightChangeEvent read FOnChange write FOnChange;
  end;

  // Hue Light Class
  THueLight = class(TCollectionItem)
  private
    FHueIndex: Integer;
    FManufacturerName: string;
    FModelID: string;
    FName: string;
    FProductID: string;
    FProductName: string;
    FLightType: string;
    FUniqueID: string;
    FState: THueLightState;

    FOnChange: THueLightChangeEvent;
    FOnIdentify: THueLightIdentifyEvent;

    procedure SetName(const AName: string);
  protected
    function GetDisplayName: string; override;
    procedure UpdateChange(Sender: TObject; EventType: TLightChangeEventType; PUTData: string);
  public
    constructor Create(AOWner: TCollection); override;
    destructor Destroy; override;

    procedure LoadLight(AIndex: Integer; ALight: TJSON);
    procedure Assign(Source: TPersistent); override;
    procedure Identify;
  published
    property HueIndex: Integer read FHueIndex;
    property ManufacturerName: string read FManufacturerName;
    property ModelID: string read FModelID;
    property Name: string read FName write SetName;
    property ProductID: string read FProductID;
    property ProductName: string read FProductName;
    property LightType: string read FLightType;
    property UniqueID: string read FUniqueID;
    property State: THueLightState read FState write FState;

    property OnChange: THueLightChangeEvent read FOnChange write FOnChange;
    property OnIdentify: THueLightIdentifyEvent read FOnIdentify write FOnIdentify;
  end;

  // Hue Lights Collection
  THueLights = class(TOwnedCollection)
  private
    FOnLightChange: THueUpdateLightEvent;
    FOnIdentify: THueLightIdentifyEvent;

    function GetItem(Index: Integer): THueLight;
    procedure SetItem(Index: Integer; const Value: THueLight);
  protected
    procedure UpdateLightChange(Sender: TObject; EventType: TLightChangeEventType; PUTData: string);
    procedure IdentifyLight(Sender: TObject; ID: Integer);
  public
    constructor Create(AOwner: TPersistent);
    function Add: THueLight;
    function GetLightByID(const AID: Integer) : THueLight;

    property Items[Index: Integer]: THueLight read GetItem write SetItem;
    property OnLightChanged: THueUpdateLightEvent read FOnLightChange write FOnLightChange;
    property OnLightIdentify: THueLightIdentifyEvent read FOnIdentify write FOnIdentify;
  end;

  // Hue group class
  THueGroupClass = (gcLivingRoom, gcKitchen, gcDining, gcBedroom, gcKidsBedroom,
                    gcBathroom, gcNursery, gcRecreation, gcOffice, gcGym, gcHallway,
                    gcToilet, gcFrontDoor, gcGarage, gcTerrace, gcGarden, gcDriveway,
                    gcCarport, gcHome, gcDownstairs, gcUpstairs, gcTopFloor, gcAttic,
                    gcGuestRoom, gcStaircase, gcLounge, gcManCave, gcComputer, gcStudio,
                    gcMusic, gcTV, gcReading, gcCloset, gcStorage, gcLaundryRoom,
                    gcBalcony, gcPorch, gcBarbecue, gcPool, gcOther);
  // Hue group types
  THueGroupType = (gtZero, gtLuminaire, gtLightsource, gtLightGroup, gtRoom, gtEntertainment, gtZone);
  // Hue group light state
  THueGroupState = (gsAnyOn, gsAllOn, gsAllOff);

  // Events
  TGroupChangeEventType = (etGroupState, etGroup);
  THueGroupChangeEvent = procedure(Sender: TObject; EventType: TGroupChangeEventType; PUTData: string) of object;
  THueUpdateGroupEvent = procedure(Sender: TObject; URL: string; PUTData: string) of object;
  THueGroupIdentifyEvent = procedure(Sender: TObject; ID: Integer) of object;

  // Hue Group Class
  THueGroup = class(TCollectionItem)
  private
    FHueIndex: Integer;
    FAction: THueLightState;
    FClass: THueGroupClass;
    FLights: TAIntegerList;
    FName: string;
    FSensors: TAIntegerList;
    FType: THueGroupType;
    FState: THueGroupState;

    FOnChange: THueGroupChangeEvent;
    FOnIdentify: THueGroupIdentifyEvent;

    procedure SetClass(const AClass: THueGroupClass);
    procedure SetLights(const ALights: TAIntegerList);
    procedure SetName(const AName: string);
  protected
    function GetDisplayName: string; override;
    procedure UpdateActionChange(Sender: TObject; EventType: TLightChangeEventType; PUTData: string);
    procedure UpdateChange(Sender: TObject; EventType: TGroupChangeEventType; PUTData: string);
  public
    constructor Create(AOWner: TCollection); override;
    destructor Destroy; override;

    procedure LoadGroup(AIndex: Integer; AGroup: TJSON);
    procedure Assign(Source: TPersistent); override;
    procedure Identify;
  published
    property HueIndex: Integer read FHueIndex;
    property Action: THueLightState read FAction write FAction;
    property GroupClass: THueGroupClass read FClass write SetClass;
    property Lights: TAIntegerList read FLights write SetLights;
    property Name: string read FName write SetName;
    property Sensors: TAIntegerList read FSensors;
    property GroupType: THueGroupType read FType;
    property State: THueGroupState read FState;

    property OnChange: THueGroupChangeEvent read FOnChange write FOnChange;
    property OnIdentify: THueGroupIdentifyEvent read FOnIdentify write FOnIdentify;
  end;

  // Hue Group Collection
  THueGroups = class(TOwnedCollection)
  private
    FOnGroupChange: THueUpdateGroupEvent;
    FOnIdentify: THueGroupIdentifyEvent;

    function GetItem(Index: Integer): THueGroup;
    procedure SetItem(Index: Integer; const Value: THueGroup);
  protected
    procedure UpdateGroupChange(Sender: TObject; EventType: TGroupChangeEventType; PUTData: string);
    procedure IdentifyGroup(Sender: TObject; ID: Integer);
  public
    constructor Create(AOwner: TPersistent);
    function Add: THueGroup;
    function GetGroupByID(const AID: Integer) : THueGroup;

    property Items[Index: Integer]: THueGroup read GetItem write SetItem;
    property OnGroupChanged: THueUpdateGroupEvent read FOnGroupChange write FOnGroupChange;
    property OnGroupIdentify: THueGroupIdentifyEvent read FOnIdentify write FOnIdentify;
  end;

  // Events
  THueScheduleEvent = procedure(Sender: TObject; URL: string; PUTData: string) of object;
  // Hue Schedule Command Methods
  THueScheduleCommandMethod = (cmGET, cmPOST, cmPUT, cmDELETE);

  // Hue Schedule Command
  THueScheduleCommand = class(TPersistent)
  private
    FOwner: TObject;
    FAddress: string;
    FBody: string;
    FMethod: THueScheduleCommandMethod;

    FOnChange: THueScheduleEvent;

    procedure SetAddress(const AAddress: string);
    procedure SetBody(const ABody: string);
    procedure SetMethod(const AMethod: THueScheduleCommandMethod);
  protected
    procedure UpdateCommand(const APutData: string);
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TObject);
    procedure LoadCommand(AAdress: string; ABody: string; AMethod: THueScheduleCommandMethod);
  published
    property Address: string read FAddress write SetAddress;
    property Body: string read FBody write SetBody;
    property Method: THueScheduleCommandMethod read FMethod write SetMethod;

    property OnChange: THueScheduleEvent read FOnChange write FOnChange;
  end;

  // Hue Schedule Class
  THueSchedule = class(TCollectionItem)
  private
    FHueIndex: Integer;
    FCommand: THueScheduleCommand;
    FName: string;
    FDescription: string;
    FLocalTime: string;
    FStartTime: string;
    FCreated: string;
    FStatus: Boolean;
    FAutoDelete: Boolean;
    FRecycle: Boolean;

    FOnChange: THueScheduleEvent;

    procedure SetName(const AName: string);
    procedure SetDescription(const ADescription: string);
    procedure SetLocalTime(const ATime: string);
    procedure SetStartTime(const ATime: string);
    procedure SetStatus(const AStatus: Boolean);
    procedure SetAutoDelete(const ADelete: Boolean);
  protected
    function GetDisplayName: string; override;
    procedure UpdateSchedule(Sender: TObject; URL: string; PUTData: string);
  public
    constructor Create(AOWner: TCollection); override;
    destructor Destroy; override;

    procedure LoadSchedule(AIndex: Integer; ASchedule: TJSON);
    procedure Assign(Source: TPersistent); override;
  published
    property HueIndex: Integer read FHueIndex;
    property Command: THueScheduleCommand read FCommand write FCommand;
    property Name: string read FName write SetName;
    property Description: string read FDescription write SetDescription;
    property LocalTime: string read FLocalTime write SetLocalTime;
    property StartTime: string read FStartTime write SetStartTime;
    property Created: string read FCreated;
    property Status: Boolean read FStatus write SetStatus;
    property AutoDelete: Boolean read FAutoDelete write SetAutoDelete;
    property Recycle: Boolean read FRecycle;

    property OnChange: THueScheduleEvent read FOnChange write FOnChange;
  end;

  // Hue Schedule Collection
  THueSchedules = class(TOwnedCollection)
  private
    FOnScheduleChange: THueScheduleEvent;

    function GetItem(Index: Integer): THueSchedule;
    procedure SetItem(Index: Integer; const Value: THueSchedule);
  protected
    procedure UpdateScheduleChange(Sender: TObject; URL: string; PUTData: string);
  public
    constructor Create(AOwner: TPersistent);
    function Add: THueSchedule;
    function GetScheduleByID(const AID: Integer) : THueSchedule;

    property Items[Index: Integer]: THueSchedule read GetItem write SetItem;
    property OnScheduleChanged: THueScheduleEvent read FOnScheduleChange write FOnScheduleChange;
  end;

  // Hue Scene Class
  THueScene = class(TCollectionItem)
  private
    FHueIndex: string;
    FGroup: Integer;
    FName: string;
    FPicture: string;
    FOwner: string;
    FLights: TAIntegerList;
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(AOWner: TCollection); override;
    destructor Destroy; override;

    procedure LoadScene(AIndex: string; AScene: TJSON);
    procedure Assign(Source: TPersistent); override;
  published
    property HueIndex: string read FHueIndex;
    property Group: Integer read FGroup;
    property Name: string read FName;
    property Picture: string read FPicture;
    property Owner: string read FOwner;
    property Lights: TAIntegerList read FLights;
  end;

  // Hue Scene Collection
  THueScenes = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): THueScene;
    procedure SetItem(Index: Integer; const Value: THueScene);
  public
    constructor Create(AOwner: TPersistent);
    function Add: THueScene;
    function GetSceneByID(const AID: string) : THueScene;

    property Items[Index: Integer]: THueScene read GetItem write SetItem;
  end;

  // Events
  THueConfigurationChanged = procedure(Sender: TObject; URL: string; PUTData: string) of object;

  // Hue Bridge Configuration
  THueBridgeConfiguration = class(TPersistent)
  private
    FOwner: TObject;
    FAPIVersion: string;
    FBridgeID: string;
    FDataStoreversion: string;
    FFactoryNew: Boolean;
    FLinkButton: Boolean;
    FModelID: string;
    FName: string;
    FStarterKitID: string;
    FSWVersion: string;
    FTimezone: string;
    FZigbeeChannel: Integer;

    FOnChange: THueConfigurationChanged;

    procedure SetName(const AName: string);
    procedure SetTimezone(const ATimezone: string);
    procedure SetZigbeeChannel(const AChannel: Integer);
  protected
    procedure LoadConfiguration(AConfig: TJSON);
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create(AOwner: TObject);
  published
    property APIVersion: string read FAPIVersion;
    property BridgeID: string read FBridgeID;
    property DataStoreVersion: string read FDataStoreversion;
    property FactoryNew: Boolean read FFactoryNew default False;
    property LinkButton: Boolean read FLinkButton default False;
    property ModelID: string read FModelID;
    property Name: string read FName write SetName;
    property StarterKitdID: string read FStarterKitID;
    property SWVersion: string read FSWVersion;
    property TimeZone: string read FTimezone write SetTimeZone;
    property ZigbeeChannel: Integer read FZigbeeChannel write SetZigbeeChannel;

    property OnChange: THueConfigurationChanged read FOnChange write FOnChange;
  end;

  // Hue Bridge Network
  THueBridgeNetwork = class(TPersistent)
  private
    FOwner: TObject;
    FGateway: string;
    FIPAddress: string;
    FMAC: string;
    FDHCP: Boolean;
    FNetMask: string;
    FProxyAddress: string;
    FProxyPort: Integer;
    FPortalConnection: string;
    FPortalServices: Boolean;
    FPortalIncoming: Boolean;
    FPortalOutgoing: Boolean;
    FPortalSignedOn: Boolean;
    FInternet: string;
    FRemoteAccess: string;
    FSWUpdate: string;
    FTime: string;

    FOnChange: THueConfigurationChanged;

    procedure SetDHCP(const ADHCP: Boolean);
    procedure SetProxyAddress(const AAddress: string);
    procedure SetProxyPort(const APort: Integer);
    procedure SetNetmask(const ANetmask: string);
    procedure SetGateway(const AGateway: string);
  protected
    procedure LoadConfiguration(AConfig: TJSON);
    procedure AssignTo(Dest: TPersistent); override;
    procedure UpdateConfiguration(const APUTData: string);
  public
    constructor Create(AOwner: TObject);
  published
    property Gateway: string read FGateway write SetGateway;
    property IPAddress: string read FIPAddress;
    property MAC: string read FMAC;
    property DHCP: Boolean read FDHCP write SetDHCP default True;
    property NetMask: string read FNetMask write SetNetmask;
    property ProxyAddress: string read FProxyAddress write SetProxyAddress;
    property ProxyPort: Integer read FProxyPort write SetProxyPort;
    property PortalConnection: string read FPortalConnection;
    property PortalServices: Boolean read FPortalServices;
    property PortalIncoming: Boolean read FPortalIncoming;
    property PortalOutgoing: Boolean read FPortalOutgoing;
    property PortalSignedOn: Boolean read FPortalSignedOn;
    property Internet: string read FInternet;
    property RemoteAccess: string read FRemoteAccess;
    property SWUpdate: string read FSWUpdate;
    property Time: string read FTime;

    property OnChange: THueConfigurationChanged read FOnChange write FOnChange;
  end;

  // Hue Bridge Class
  THueBridge = class(TComponent)
  private
    { Private declarations }
    FHTTP: TidHTTP;
    FSSL: TIdSSLIOHandlerSocketOpenSSL;
    FLights: THueLights;
    FGroups: THueGroups;
    FSchedules: THueSchedules;
    FScenes: THueScenes;
    FConfiguration: THueBridgeConfiguration;
    FNetwork: THueBridgeNetwork;

    FLastError: string;
    FLastResponse: string;
    FBridgeIP: string;
    FUsername: string;
    FUpdateOnLightChange: Boolean;
    FUpdateOnGroupChange: Boolean;
    FUpdateOnScheduleChange: Boolean;

    FOnLightsLoaded: TNotifyEvent;
    FOnLightsUpdated: TNotifyEvent;
    FOnGroupsLoaded: TNotifyEvent;
    FOnGroupsUpdated: TNotifyEvent;
    FOnSchedulesLoaded: TNotifyEvent;
    FOnSchedulesUpdated: TNotifyEvent;
    FOnScenesLoaded: TNotifyEvent;
    FOnConfigurationLoaded: TNotifyEvent;

    procedure SetLights(const ALights: THueLights);
    procedure SetGroups(const AGroups: THueGroups);
    procedure SetSchedules(const ASchedule: THueSchedules);
    procedure SetScenes(const AScenes: THueScenes);
    procedure SetConfiguration(const AConfiguration: THueBridgeConfiguration);
    procedure SetNetwork(const ANetwork: THueBridgeNetwork);
    procedure SetUseragent(const AUseragent: string);
    function GetUseragent: string;
  protected
    { Protected declarations }
    procedure UpdateLightChange(Sender: TObject; URL: string; PUTData: string);
    procedure UpdateGroupChange(Sender: TObject; URL: string; PUTData: string);
    procedure UpdateScheduleChange(Sender: TObject; URL: string; PUTData: string);
    procedure UpdateConfiguration(Sender: TObject; URL: string; PUTData: string);
    procedure IdentifyLight(Sender: TObject; ID: Integer);
    procedure IdentifyGroup(Sender: TObject; ID: Integer);

    function HTTPGet(const AURL: string) : string;
    function HTTPPost(const AURL: string; const AText: string) : string;
    function HTTPPut(const  AURL: string; const AText: string) : string;
    function HTTPDelete(const AURL: string) : string;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Bridge
    function DetectBridgeIP(const ABridge: Integer = 0): Boolean;
    function PairBridge(const AName: string) : Boolean;
    procedure LoadBridgeConfiguration;

    // Lights
    procedure LoadLights;
    procedure UpdateLights;
    function SearchNewLights : Boolean;
    function DeleteLight(const AID: Integer) : Boolean;
    function UpdateLight(const AID: Integer) : Boolean;
    function UpdateLightState(const AID: Integer; const AData: string) : Boolean;

    // Groups
    procedure LoadGroups;
    procedure UpdateGroups;
    function CreateGroup(const AName: string; const ALights: TAIntegerList;
      const GroupType: THueGroupType; const GroupClass: THueGroupClass) : Boolean;
    function DeleteGroup(const AID: Integer) : Boolean;
    function UpdateGroup(const AID: Integer) : Boolean;
    function UpdateGroupAction(const AID: Integer; const AData: string) : Boolean;

    // Schedules
    procedure LoadSchedules;
    procedure UpdateSchedules;
    function CreateSchedule(const AName: string; const ADescription: string; const AAddress: string;
      const AMethod: THueScheduleCommandMethod; const ABody: string; const ALocalTime: string;
      const AStatus: Boolean; const AAutoDelete: Boolean; const ARecycle: Boolean) : Boolean;
    function DeleteSchedule(const AID: Integer) : Boolean;
    function UpdateSchedule(const AID: Integer) : Boolean; overload;
    function UpdateSchedule(const AID: Integer; const APUTData: string) : Boolean; overload;

    // Scenes
    procedure LoadScenes;
    function RecallScene(const AGroup: Integer; const AScene: string) : Boolean;

    property Lights: THueLights read FLights write SetLights;
    property Groups: THueGroups read FGroups write SetGroups;
    property Schedules: THueSchedules read FSchedules write SetSchedules;
    property Scenes: THueScenes read FScenes write SetScenes;
    property HTTP: TidHTTP read FHTTP;
    property LastResponse: string read FLastResponse;
    property LastError: string read FLastError;
  published
    { Published declarations }
    property IP: string read FBridgeIP write FBridgeIP;
    property Username: string read FUsername write FUSername;
    property UpdateOnLightChange: Boolean read FUpdateOnLightChange write FUpdateOnLightChange default True;
    property UpdateOnGroupChange: Boolean read FUpdateOnGroupChange write FUpdateOnGroupChange default True;
    property UpdateOnScheduleChange: Boolean read FUpdateOnScheduleChange write FUpdateOnScheduleChange default True;
    property Useragent: string read GetUseragent write SetUseragent;
    property Configuration: THueBridgeConfiguration read FConfiguration write SetConfiguration;
    property Network: THueBridgeNetwork read FNetwork write SetNetwork;

    property OnLightsLoaded: TNotifyEvent read FOnLightsLoaded write FOnLightsLoaded;
    property OnLightsUpdated: TNotifyEvent read FOnLightsUpdated write FOnLightsUpdated;
    property OnGroupsLoaded: TNotifyEvent read FOnGroupsLoaded write FOnGroupsLoaded;
    property OnGroupsUpdated: TNotifyEvent read FOnGroupsUpdated write FOnGroupsUpdated;
    property OnSchedulesLoaded: TNotifyEvent read FOnSchedulesLoaded write FOnSchedulesLoaded;
    property OnSchedulesUpdated: TNotifyEvent read FOnSchedulesUpdated write FOnSchedulesUpdated;
    property OnScenesLoaded: TNotifyEvent read FOnScenesLoaded write FOnScenesLoaded;
    property OnConfigurationLoaded: TNotifyEvent read FOnConfigurationLoaded write FOnConfigurationLoaded;
  end;

procedure Register;

implementation

// URL Constants
//------------------------------------------------------------------------------

const
  BridgeIPURL   = 'https://discovery.meethue.com/';
  BridgePairURL = 'https://%s/api';
  BaseURL       = 'https://%s/api/%s';

  LightsURL     = '/lights';
  LightURL      = '/lights/%d';
  LightStateURL = '/lights/%d/state';

  GroupsURL     = '/groups';
  GroupURL      = '/groups/%d';
  GroupStateURL = '/groups/%d/action';

  SchedulesURL  = '/schedules';
  ScheduleURL   = '/schedules/%d';

  ScenesURL     = '/scenes';
  SceneURL      = '/scenes/%d';

  ConfigURL     = '/config';

// Common used
//------------------------------------------------------------------------------

const
  SCL : array [THueGroupClass] of string = ('Living room', 'Kitchen', 'Dining',
    'Bedroom', 'Kids bedroom', 'Bathroom', 'Nursery', 'Recreation', 'Office', 'Gym',
    'Hallway', 'Toilet', 'Front door', 'Garage', 'Terrace', 'Garden', 'Driveway',
    'Carport', 'Home', 'Downstairs', 'Upstairs', 'Top floor', 'Attic', 'Guest room',
    'Staircase', 'Lounge', 'Man cave', 'Computer', 'Studio', 'Music', 'TV', 'Reading',
    'Closet', 'Storage', 'Laundry room', 'Balcony', 'Porch', 'Barbecue', 'Pool', 'Other');

  SGT : array [THueGroupType] of string = ('0', 'Luminaire', 'Lightsource',
    'LightGroup', 'Room', 'Entertainment', 'Zone');

function GetLightsJSON(ALights: TAIntegerList) : string;
var
  I : Integer;
begin
  Result := '';
  for I := Low(Alights) to High(ALights) do
  begin
    Result := Result + Format('"%d"', [ALights[I]]);
    if I < High(ALights) then Result := Result + ',';
  end;
end;

// THueLightState Class
//------------------------------------------------------------------------------

constructor THueLightState.Create(AOwner: TObject);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure THueLightState.LoadLight(AAlert: THueLightStateAlert;
  ABrightness: Integer; AColorMode: THueLightStateColorMode; AColorTemperature: Integer;
  AEffect: THueLightStateEffect; AHue: Integer; AMode: string; AON: Boolean;
  AReachable: Boolean; ASaturation: Integer);
begin
  FAlert            := AAlert;
  FBrightness       := ABrightness;
  FColorMode        := AColorMode;
  FColorTemperature := AColorTemperature;
  FEffect           := AEffect;
  FHue              := AHue;
  FMode             := AMode;
  FON               := AON;
  FReachable        := AReachable;
  FSaturation       := ASaturation;
end;

procedure THueLightState.UpdateState(const APutData: string);
begin
  if Assigned(FOnChange) then FOnChange(FOwner, etState, APutData);
end;

procedure THueLightState.AssignTo(Dest: TPersistent);
begin
  if Dest is THueLightState then
  begin
    with THueLightState(Dest) do
    begin
      FAlert            := Self.Alert;
      FBrightness       := Self.Brightness;
      FColorMode        := Self.ColorMode;
      FColorTemperature := Self.ColorTemperature;
      FEffect           := Self.Effect;
      FHue              := Self.Hue;
      FMode             := Self.Mode;
      FON               := Self.ON;
      FReachable        := Self.Reachable;
      FSaturation       := Self.Saturation;
    end
  end
  else
    inherited AssignTo(Dest);
end;

procedure THueLightState.SetBrightness(const ABrightness: Integer);
begin
  if ABrightness <> Brightness then
  begin
    if (ABrightness < 1) then
      FBrightness := 1;
    if (ABrightness > 254) then
      FBrightness := 254;
    if (ABrightness >= 1) and (ABrightness <= 254) then
      FBrightness := ABrightness;
    UpdateState(Format('{"bri": %d}', [Brightness]));
  end;
end;

procedure THueLightState.SetColorTemperature(const ATemperature: Integer);
begin
  if ATemperature <> ColorTemperature then
  begin
    FColorTemperature := ATemperature;
    UpdateState(Format('{"ct": %d}', [ColorTemperature]));
  end;
end;

procedure THueLightState.SetEffect(const AEffect: THueLightStateEffect);
const
  SEffect : array [THueLightStateEffect] of string = ('none', 'colorloop');
begin
  if AEffect <> Effect then
  begin
    FEffect := AEffect;
    UpdateState(Format('{"effect": %s}', [SEffect[Effect]]));
  end;
end;

procedure THueLightState.SetHue(const AHue: Integer);
begin
  if AHue <> Hue then
  begin
    FHue := AHue;
    UpdateState(Format('{"hue": %d}', [Hue]));
  end;
end;

procedure THueLightState.SetON(const AON: Boolean);
const
  SON : array [Boolean] of string = ('false', 'true');
begin
  FON := AON;
  UpdateState(Format('{"on": %s}', [SON[AON]]));
end;

procedure THueLightState.SetSaturation(const ASaturation: Integer);
begin
  if ASaturation <> Saturation then
  begin
    if (ASaturation < 0) then
      FSaturation := 0;
    if (ASaturation > 254) then
      FSaturation := 254;
    if (ASaturation >= 0) and (ASaturation <= 254) then
      FSaturation := ASaturation;
    UpdateState(Format('{"sat": %d}', [Saturation]));
  end;
end;

// THueLight Class
//------------------------------------------------------------------------------

constructor THueLight.Create(AOWner: TCollection);
begin
  inherited Create(AOwner);
  FState := THueLightState.Create(Self);
  FState.OnChange := UpdateChange;
end;

destructor THueLight.Destroy;
begin
  FState.Free;
  inherited Destroy;
end;

procedure THueLight.SetName(const AName: string);
begin
  if AName <> Name then
  begin
    FName := AName;
    UpdateChange(Self, etLight, Format('{"name": "%s"}', [JSONEscapeValue(AName)]));
  end;
end;

function THueLight.GetDisplayName : string;
begin
  if (Name <> '') then
    Result := Name
  else
    Result := inherited GetDisplayName;
end;

procedure THueLight.UpdateChange(Sender: TObject; EventType: TLightChangeEventType; PUTData: string);
begin
  if Assigned(FOnChange) then FOnChange(Sender, EventType, PUTData);
end;

procedure THueLight.LoadLight(AIndex: Integer; ALight: TJSON);
var
  AAlert            : THueLightStateAlert;
  ABrightness       : Integer;
  AColorMode        : THueLightStateColorMode;
  AColorTemperature : Integer;
  AEffect           : THueLightStateEffect;
  AHue              : Integer;
  AMode             : string;
  AON               : Boolean;
  AReachable        : Boolean;
  ASaturation       : Integer;
  AState            : TJSON;
begin
  FHueIndex := AIndex;
  if ALight.Items.ContainsKey('manufacturername') then
    FManufacturerName := ALight.Items.Items['manufacturername'].AsString;
  if ALight.Items.ContainsKey('modelid') then
    FModelID := ALight.Items.Items['modelid'].AsString;
  if ALight.Items.ContainsKey('name') then
    FName := ALight.Items.Items['name'].AsString;
  if ALight.Items.ContainsKey('productid') then
    FProductID := ALight.Items.Items['productid'].AsString;
  if ALight.Items.ContainsKey('productname') then
    FProductName := ALight.Items.Items['productname'].AsString;
  if ALight.Items.ContainsKey('type') then
    FLightType := ALight.Items.Items['type'].AsString;
  if ALight.Items.ContainsKey('uniqueid') then
    FUniqueID := ALight.Items.Items['uniqueid'].AsString;
  if ALight.Items.ContainsKey('state') then
  begin
    AState := ALight.Items.Items['state'];
    // Alert
    if AState.Items.ContainsKey('alert') then
    begin
      if (AState.Items.Items['alert'].AsString = 'select') then
        AAlert := saSelect
      else
      if (AState.Items.Items['alert'].AsString = 'lselect') then
        AAlert := saLSelect
      else
        AAlert := saNone;
    end;
    // Brightness
    if AState.Items.ContainsKey('bri') then
      ABrightness := AState.Items.Items['bri'].AsInteger;
    // Color Mode
    if AState.Items.ContainsKey('colormode') then
    begin
      if (AState.Items.Items['colormode'].AsString = 'hs') then
        AColorMode := cmHueSatuarion
      else
      if (AState.Items.Items['colormode'].AsString = 'ct') then
         AColorMode := cmColorTemprature
      else
      if (AState.Items.Items['colormode'].AsString = 'xy') then
         AColorMode := cmXY
      else
         AColorMode := cmNone;
    end;
    // Color Temperature
    if AState.Items.ContainsKey('ct') then
      AColorTemperature := AState.Items.Items['ct'].AsInteger;
    // Effect
    if AState.Items.ContainsKey('effect') then
    begin
      if (AState.Items.Items['colormode'].AsString = 'colorloop') then
        AEffect := seColorLoop
      else
        AEffect := seNone;
    end;
    // Hue
    if AState.Items.ContainsKey('hue') then
      AHue := AState.Items.Items['hue'].AsInteger;
    // Mode
    if AState.Items.ContainsKey('mode') then
      AMode := AState.Items.Items['mode'].AsString;
    // ON
    if AState.Items.ContainsKey('on') then
      AON := AState.Items.Items['on'].AsBoolean;
    // Reachable
    if AState.Items.ContainsKey('reachable') then
      AReachable := AState.Items.Items['reachable'].AsBoolean;
    // Saturation
    if AState.Items.ContainsKey('sat') then
      ASaturation := AState.Items.Items['sat'].AsInteger;
    FState.LoadLight(AAlert, ABrightness, AColorMode, AColorTemperature, AEffect, AHue, AMode, AON, AReachable, ASaturation);
  end;
end;

procedure THueLight.Assign(Source: TPersistent);
begin
  inherited;
  if Source is THueLight then
  begin
    FHueIndex         := THueLight(Source).HueIndex;
    FManufacturerName := THueLight(Source).ManufacturerName;
    FModelID          := THueLight(Source).ModelID;
    FName             := THueLight(Source).Name;
    FProductID        := THueLight(Source).ProductID;
    FProductName      := THueLight(Source).ProductName;
    FLightType        := THueLight(Source).LightType;
    FUniqueID         := THueLight(Source).UniqueID;
    THueLight(Source).State.AssignTo(State);
  end;
end;

procedure THueLight.Identify;
begin
  if Assigned(FOnIdentify) then FOnIdentify(Self, HueIndex);
end;

// THueLights Class
//------------------------------------------------------------------------------

constructor THueLights.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, THueLight);
end;

function THueLights.GetItem(Index: Integer): THueLight;
begin
  Result := inherited GetItem(Index) as THueLight;
end;

procedure THueLights.SetItem(Index: Integer; const Value: THueLight);
begin
  inherited SetItem(Index, Value);
end;

procedure THueLights.UpdateLightChange(Sender: TObject; EventType: TLightChangeEventType; PUTData: string);
begin
  case EventType of
    etState : if Assigned(FOnLightChange) then FOnLightChange(Sender, Format(LightStateURL, [(Sender as THueLight).HueIndex]), PUTData);
    etLight : if Assigned(FOnLightChange) then FOnLightChange(Sender, Format(LightURL, [(Sender as THueLight).HueIndex]), PUTData);
  end;
end;

procedure THueLights.IdentifyLight(Sender: TObject; ID: Integer);
begin
  if Assigned(FOnIdentify) then FOnIdentify(Self, ID);
end;

function THueLights.Add : THueLight;
begin
  Result := THueLight(inherited Add);
  Result.OnChange   := UpdateLightChange;
  Result.OnIdentify := IdentifyLight;
end;

function THueLights.GetLightByID(const AID: Integer) : THueLight;
var
  I : Integer;
begin
  Result := nil;
  for I := 0 to Count -1 do
  if Items[I].HueIndex = AID then
  begin
    Result := Items[I];
    Break;
  end;
end;

// THueGroup class
//------------------------------------------------------------------------------

constructor THueGroup.Create(AOWner: TCollection);
begin
  inherited Create(AOwner);
  FAction := THueLightState.Create(Self);
  FAction.OnChange := UpdateActionChange;
end;

destructor THueGroup.Destroy;
begin
  FAction.Free;
  inherited Destroy;
end;

procedure THueGroup.SetClass(const AClass: THueGroupClass);
begin
  if AClass <> GroupClass then
  begin
    FClass := AClass;
    UpdateChange(Self, etGroup, Format('{"class":"%s"}', [JSONEscapeValue(SCL[AClass])]));
  end;
end;

procedure THueGroup.SetLights(const ALights: TAIntegerList);
begin
  if ALights <> Lights then
  begin
    FLights := ALights;
    UpdateChange(Self, etGroup, Format('{"lights":[%s]}', [GetLightsJSON(Alights)]));
  end;
end;

procedure THueGroup.SetName(const AName: string);
begin
  if AName <> Name then
  begin
    FName := AName;
    UpdateChange(Self, etGroup, Format('{"name":"%s"}', [JSONEscapeValue(AName)]));
  end;
end;

function THueGroup.GetDisplayName : string;
begin
  if (Name <> '') then
    Result := Name
  else
    Result := inherited GetDisplayName;
end;

procedure THueGroup.UpdateActionChange(Sender: TObject; EventType: TLightChangeEventType; PUTData: string);
begin
  case EventType of
    etState : if Assigned(FOnChange) then FOnChange(Sender, etGroupState, PUTData);
    etLight : if Assigned(FOnChange) then FOnChange(Sender, etGroup, PUTData);
  end;
end;

procedure THueGroup.UpdateChange(Sender: TObject; EventType: TGroupChangeEventType; PUTData: string);
begin
  if Assigned(FOnChange) then FOnChange(Sender, EventType, PUTData);
end;

procedure THueGroup.LoadGroup(AIndex: Integer; AGroup: TJSON);

  function GetGroupClassFromString(const AClass: string) : THueGroupClass;
  var
    S : string;
  begin
    S := AClass.ToLower;
    Result := gcOther;
    if (S = 'living room')  then Result := gcLivingRoom;
    if (S = 'kitchen')      then Result := gcKitchen;
    if (S = 'dining')       then Result := gcDining;
    if (S = 'bedroom')      then Result := gcBedroom;
    if (S = 'kids bedroom') then Result := gcKidsBedroom;
    if (S = 'bathroom')     then Result := gcBathroom;
    if (S = 'nursery')      then Result := gcNursery;
    if (S = 'recreation')   then Result := gcRecreation;
    if (S = 'office')       then Result := gcOffice;
    if (S = 'gym')          then Result := gcGym;
    if (S = 'hallway')      then Result := gcHallway;
    if (S = 'toilet')       then Result := gcToilet;
    if (S = 'front door')   then Result := gcFrontDoor;
    if (S = 'garage')       then Result := gcGarage;
    if (S = 'terrace')      then Result := gcTerrace;
    if (S = 'garden')       then Result := gcGarden;
    if (S = 'driveway')     then Result := gcDriveway;
    if (S = 'carport')      then Result := gcCarport;
    if (S = 'home')         then Result := gcHome;
    if (S = 'downstairs')   then Result := gcDownstairs;
    if (S = 'upstairs')     then Result := gcUpstairs;
    if (S = 'top floor')    then Result := gcTopFloor;
    if (S = 'attic')        then Result := gcAttic;
    if (S = 'guest room')   then Result := gcGuestRoom;
    if (S = 'staircase')    then Result := gcStaircase;
    if (S = 'lounge')       then Result := gcLounge;
    if (S = 'man cave')     then Result := gcManCave;
    if (S = 'computer')     then Result := gcComputer;
    if (S = 'studio')       then Result := gcStudio;
    if (S = 'music')        then Result := gcMusic;
    if (S = 'tv')           then Result := gcTV;
    if (S = 'reading')      then Result := gcReading;
    if (S = 'closet')       then Result := gcCloset;
    if (S = 'storage')      then Result := gcStorage;
    if (S = 'laundry room') then Result := gcLaundryRoom;
    if (S = 'balcony')      then Result := gcBalcony;
    if (S = 'porch')        then Result := gcPorch;
    if (S = 'barbeque')     then Result := gcBarbecue;
    if (S = 'pool')         then Result := gcPool;
  end;

  function GetGroupTypeFromString(const AType: string) : THueGroupType;
  var
    S : string;
  begin
    Result := gtLightGroup;
    S := AType.ToLower;
    if (S = '0')             then Result := gtZero; // Reserved!
    if (S = 'luminaire')     then Result := gtLuminaire;
    if (S = 'lightsource')   then Result := gtLightsource;
    if (S = 'lightgroup')    then Result := gtLightGroup;
    if (S = 'room')          then Result := gtRoom;
    if (S = 'entertainment') then Result := gtEntertainment;
    if (S = 'zone')          then Result := gtZone;
  end;

var
  AAlert            : THueLightStateAlert;
  ABrightness       : Integer;
  AColorMode        : THueLightStateColorMode;
  AColorTemperature : Integer;
  AEffect           : THueLightStateEffect;
  AHue              : Integer;
  AMode             : string;
  AON               : Boolean;
  AReachable        : Boolean;
  ASaturation       : Integer;
  AAction           : TJSON;
  I                 : Integer;
begin
  FHueIndex := AIndex;
  // Class
  if AGroup.Items.ContainsKey('class') then
    FClass := GetGroupClassFromString(AGroup.Items.Items['class'].AsString)
  else
    FClass := gcOther;
  // Lights
  if AGroup.Items.ContainsKey('lights') and (AGroup.Items.Items['lights'].IsList) then
  begin
    SetLength(FLights, AGroup.Items.Items['lights'].ListItems.Count);
    for I := 0 to AGroup.Items.Items['lights'].ListItems.Count -1 do
    FLights[I] := AGroup.Items.Items['lights'].ListItems[I].AsInteger;
  end else
  begin
    SetLength(FLights, 0);
  end;
  // Name
  if AGroup.Items.ContainsKey('name') then
  begin
    FName := AGroup.Items.Items['name'].AsString;
  end;
  // Sensors
  if AGroup.Items.ContainsKey('sensors') and (AGroup.Items.Items['sensors'].IsList) then
  begin
    SetLength(FSensors, AGroup.Items.Items['sensors'].ListItems.Count);
    for I := 0 to AGroup.Items.Items['sensors'].ListItems.Count -1 do
    FSensors[I] := AGroup.Items.Items['sensors'].ListItems[I].AsInteger;
  end else
  begin
    SetLength(FSensors, 0);
  end;
  // Group Type
  if AGroup.Items.ContainsKey('type') then
    FType := GetGroupTypeFromString(AGroup.Items.Items['type'].AsString)
  else
    FType := gtLightGroup;
  // State
  if AGroup.Items.ContainsKey('state') and AGroup.Items.Items['state'].Items.ContainsKey('all_on') and
     AGroup.Items.Items['state'].Items.ContainsKey('any_on') then
  begin
    if AGroup.Items.Items['state'].Items.Items['all_on'].AsBoolean then
      FState := gsAllOn
    else
    if AGroup.Items.Items['state'].Items.Items['any_on'].AsBoolean then
      FState := gsAnyOn
    else
      FState := gsAllOff;
  end else
    FState := gsAllOff;
  if AGroup.Items.ContainsKey('action') then
  begin
    AAction := AGroup.Items.Items['action'];
    // Alert
    if AAction.Items.ContainsKey('alert') then
    begin
      if (AAction.Items.Items['alert'].AsString = 'select') then
        AAlert := saSelect
      else
      if (AAction.Items.Items['alert'].AsString = 'lselect') then
        AAlert := saLSelect
      else
        AAlert := saNone;
    end;
    // Brightness
    if AAction.Items.ContainsKey('bri') then
      ABrightness := AAction.Items.Items['bri'].AsInteger;
    // Color Mode
    if AAction.Items.ContainsKey('colormode') then
    begin
      if (AAction.Items.Items['colormode'].AsString = 'hs') then
        AColorMode := cmHueSatuarion
      else
      if (AAction.Items.Items['colormode'].AsString = 'ct') then
         AColorMode := cmColorTemprature
      else
      if (AAction.Items.Items['colormode'].AsString = 'xy') then
         AColorMode := cmXY
      else
         AColorMode := cmNone;
    end;
    // Color Temperature
    if AAction.Items.ContainsKey('ct') then
      AColorTemperature := AAction.Items.Items['ct'].AsInteger;
    // Effect
    if AAction.Items.ContainsKey('effect') then
    begin
      if (AAction.Items.Items['colormode'].AsString = 'colorloop') then
        AEffect := seColorLoop
      else
        AEffect := seNone;
    end;
    // Hue
    if AAction.Items.ContainsKey('hue') then
      AHue := AAction.Items.Items['hue'].AsInteger;
    // Mode
    if AAction.Items.ContainsKey('mode') then
      AMode := AAction.Items.Items['mode'].AsString;
    // ON
    if AAction.Items.ContainsKey('on') then
      AON := AAction.Items.Items['on'].AsBoolean;
    // Reachable
    if AAction.Items.ContainsKey('reachable') then
      AReachable := AAction.Items.Items['reachable'].AsBoolean;
    // Saturation
    if AAction.Items.ContainsKey('sat') then
      ASaturation := AAction.Items.Items['sat'].AsInteger;
    FAction.LoadLight(AAlert, ABrightness, AColorMode, AColorTemperature, AEffect, AHue, AMode, AON, AReachable, ASaturation);
  end;
end;

procedure THueGroup.Assign(Source: TPersistent);
begin
  inherited;
  if Source is THueGroup then
  begin
    FHueIndex := THueGroup(Source).HueIndex;
    FClass    := THueGroup(Source).GroupClass;
    FLights   := THueGroup(Source).Lights;
    FName     := THueGroup(Source).Name;
    FSensors  := THueGroup(Source).Sensors;
    FType     := THueGroup(Source).GroupType;
    FState    := THueGroup(Source).State;
    THueGroup(Source).Action.AssignTo(Action);
  end;
end;

procedure THueGroup.Identify;
begin
  if Assigned(FOnIdentify) then FOnIdentify(Self, HueIndex);
end;

// THueGroups Class
//------------------------------------------------------------------------------

constructor THueGroups.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, THueGroup);
end;

function THueGroups.GetItem(Index: Integer): THueGroup;
begin
  Result := inherited GetItem(Index) as THueGroup;
end;

procedure THueGroups.SetItem(Index: Integer; const Value: THueGroup);
begin
  inherited SetItem(Index, Value);
end;

procedure THueGroups.UpdateGroupChange(Sender: TObject; EventType: TGroupChangeEventType; PUTData: string);
begin
  case EventType of
    etGroupState : if Assigned(FOnGroupChange) then FOnGroupChange(Sender, Format(GroupStateURL, [(Sender as THueGroup).HueIndex]), PUTData);
    etGroup      : if Assigned(FOnGroupChange) then FOnGroupChange(Sender, Format(GroupURL, [(Sender as THueGroup).HueIndex]), PUTData);
  end;
end;

procedure THueGroups.IdentifyGroup(Sender: TObject; ID: Integer);
begin
  if Assigned(FOnIdentify) then FOnIdentify(Self, ID);
end;

function THueGroups.Add : THueGroup;
begin
  Result := THueGroup(inherited Add);
  Result.OnChange   := UpdateGroupChange;
  Result.OnIdentify := IdentifyGroup;
end;

function THueGroups.GetGroupByID(const AID: Integer) : THueGroup;
var
  I : Integer;
begin
  Result := nil;
  for I := 0 to Count -1 do
  if Items[I].HueIndex = AID then
  begin
    Result := Items[I];
    Break;
  end;
end;

// THueScheduleCommand Class
//------------------------------------------------------------------------------

constructor THueScheduleCommand.Create(AOwner: TObject);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure THueScheduleCommand.LoadCommand(AAdress: string; ABody: string; AMethod: THueScheduleCommandMethod);
begin
  FAddress := AAdress;
  FBody    := ABody;
  FMethod  := AMethod;
end;

procedure THueScheduleCommand.UpdateCommand(const APutData: string);
begin
  if Assigned(FOnChange) then FOnChange(FOwner, ScheduleURL, APutData);
end;

procedure THueScheduleCommand.AssignTo(Dest: TPersistent);
begin
  if Dest is THueScheduleCommand then
  begin
    with THueLightState(Dest) do
    begin
      FAddress := Self.Address;
      FBody    := Self.Body;
      FMethod  := Self.Method;
    end
  end
  else
    inherited AssignTo(Dest);
end;

procedure THueScheduleCommand.SetAddress(const AAddress: string);
begin
  if (FAddress <> AAddress) then
  begin
    FAddress := AAddress;
    UpdateCommand(Format('{"command":{"address":"%s"}}', [AAddress]));
  end;
end;

procedure THueScheduleCommand.SetBody(const ABody: string);
begin
  if (FBody <> ABody) then
  begin
    FBody := ABody;
    UpdateCommand(Format('{"command":{"body":"%s"}}', [ABody]));
  end;
end;

procedure THueScheduleCommand.SetMethod(const AMethod: THueScheduleCommandMethod);
const
  SMethod : array [THueScheduleCommandMethod] of string = ('GET', 'POST', 'PUT', 'DELETE');
begin
  if (FMethod <> AMethod) then
  begin
    FMethod := AMethod;
    UpdateCommand(Format('{"command":{"method":"%s"}}', [SMethod[AMethod]]));
  end;
end;

// THueSchedule Class
//------------------------------------------------------------------------------

constructor THueSchedule.Create(AOWner: TCollection);
begin
  inherited Create(AOwner);
  FCommand := THueScheduleCommand.Create(Self);
  FCommand.OnChange := UpdateSchedule;
end;

destructor THueSchedule.Destroy;
begin
  FCommand.Free;
  inherited Destroy;
end;

function THueSchedule.GetDisplayName : string;
begin
  if (Name <> '') then
    Result := Name
  else
    Result := inherited GetDisplayName;
end;

procedure THueSchedule.Assign(Source: TPersistent);
begin
  inherited;
  if Source is THueSchedule then
  begin
    FHueIndex    := THueSchedule(Source).HueIndex;
    FName        := THueSchedule(Source).Name;
    FDescription := THueSchedule(Source).Description;
    FLocalTime   := THueSchedule(Source).LocalTime;
    FStartTime   := THueSchedule(Source).StartTime;
    FCreated     := THueSchedule(Source).Created;
    FStatus      := THueSchedule(Source).Status;
    FAutoDelete  := THueSchedule(Source).AutoDelete;
    FRecycle     := THueSchedule(Source).Recycle;
    THueSchedule(Source).Command.AssignTo(FCommand);
  end;
end;

procedure THueSchedule.SetName(const AName: string);
begin
  if (FName <> AName) then
  begin
    FName := AName;
    UpdateSchedule(Self, ScheduleURL, Format('{"name":"%s"}', [AName]));
  end;
end;

procedure THueSchedule.SetDescription(const ADescription: string);
begin
  if (FDescription <> ADescription) then
  begin
    FDescription := ADescription;
    UpdateSchedule(Self, ScheduleURL, Format('{"description":"%s"}', [ADescription]));
  end;
end;

procedure THueSchedule.SetLocalTime(const ATime: string);
begin
  if (FLocalTime <> ATime) then
  begin
    FLocalTime := ATime;
    UpdateSchedule(Self, ScheduleURL, Format('{"localtime":"%s"}', [Atime]));
  end;
end;

procedure THueSchedule.SetStartTime(const ATime: string);
begin
  if (FStartTime <> ATime) then
  begin
    FStartTime := ATime;
    UpdateSchedule(Self, ScheduleURL, Format('{"starttime":"%s"}', [Atime]));
  end;
end;

procedure THueSchedule.SetStatus(const AStatus: Boolean);
const
  SStatus : array [Boolean] of string = ('disabled', 'enabled');
begin
  if (FStatus <> AStatus) then
  begin
    FStatus := AStatus;
    UpdateSchedule(Self, ScheduleURL, Format('{"status":"%s"}', [SStatus[AStatus]]));
  end;
end;

procedure THueSchedule.SetAutoDelete(const ADelete: Boolean);
const
  SAutoDelete : array [Boolean] of string = ('false', 'true');
begin
  if (FAutoDelete <> ADelete) then
  begin
    FAutoDelete := ADelete;
    UpdateSchedule(Self, ScheduleURL, Format('{"autodelete":"%s"}', [SAutoDelete[ADelete]]));
  end;
end;

procedure THueSchedule.UpdateSchedule(Sender: TObject; URL: string; PUTData: string);
begin
  if Assigned(FOnChange) then FOnChange(Sender, Format(URL, [HueIndex]), PUTData);
end;

procedure THueSchedule.LoadSchedule(AIndex: Integer; ASchedule: TJSON);
var
  AAdress : string;
  ABody   : string;
  AMethod : THueScheduleCommandMethod;
begin
  FHueIndex    := AIndex;
  if ASchedule.Items.ContainsKey('name') then
    FName := ASchedule.Items.Items['name'].AsString;
  if ASchedule.Items.ContainsKey('description') then
    FDescription := ASchedule.Items.Items['description'].AsString;
  if ASchedule.Items.ContainsKey('localtime') then
    FLocalTime := ASchedule.Items.Items['localtime'].AsString;
  if ASchedule.Items.ContainsKey('starttime') then
    FStartTime := ASchedule.Items.Items['starttime'].AsString;
  if ASchedule.Items.ContainsKey('created') then
    FCreated := ASchedule.Items.Items['created'].AsString;
  if ASchedule.Items.ContainsKey('status') then
    FStatus :=  ASchedule.Items.Items['status'].AsString.ToUpper = 'ENABLED';
  if ASchedule.Items.ContainsKey('autodelete') then
    FAutoDelete := ASchedule.Items.Items['autodelete'].AsBoolean;
  if ASchedule.Items.ContainsKey('reqycle') then
    FRecycle := ASchedule.Items.Items['recycle'].AsBoolean;
  if ASchedule.Items.ContainsKey('command') then
  begin
    if ASchedule.Items.Items['command'].Items.ContainsKey('address') then
      AAdress := ASchedule.Items.Items['command'].Items.Items['address'].AsString;
    if ASchedule.Items.Items['command'].Items.ContainsKey('body') then
      ABody := ASchedule.Items.Items['command'].Items.Items['body'].AsString;
    if ASchedule.Items.Items['command'].Items.ContainsKey('method') then
    begin
      if ASchedule.Items.Items['command'].Items.Items['method'].AsString.ToUpper = 'GET'    then AMethod := cmGET;
      if ASchedule.Items.Items['command'].Items.Items['method'].AsString.ToUpper = 'POST'   then AMethod := cmPOST;
      if ASchedule.Items.Items['command'].Items.Items['method'].AsString.ToUpper = 'PUT'    then AMethod := cmPUT;
      if ASchedule.Items.Items['command'].Items.Items['method'].AsString.ToUpper = 'DELETE' then AMethod := cmDELETE;
    end;
    FCommand.LoadCommand(AAdress, ABody, AMethod);
  end;
end;

// THueSchedules Class
//------------------------------------------------------------------------------

constructor THueSchedules.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, THueSchedule);
end;

function THueSchedules.GetItem(Index: Integer): THueSchedule;
begin
  Result := inherited GetItem(Index) as THueSchedule;
end;

procedure THueSchedules.SetItem(Index: Integer; const Value: THueSchedule);
begin
  inherited SetItem(Index, Value);
end;

procedure THueSchedules.UpdateScheduleChange(Sender: TObject; URL: string; PUTData: string);
begin
  if Assigned(FOnScheduleChange) then FOnScheduleChange(Sender, URL, PUTData);
end;

function THueSchedules.Add : THueSchedule;
begin
  Result := THueSchedule(inherited Add);
  Result.OnChange := UpdateScheduleChange;
end;

function THueSchedules.GetScheduleByID(const AID: Integer) : THueSchedule;
var
  I : Integer;
begin
  Result := nil;
  for I := 0 to Count -1 do
  if Items[I].HueIndex = AID then
  begin
    Result := Items[I];
    Break;
  end;
end;

// THueScene class
//------------------------------------------------------------------------------

constructor THueScene.Create(AOWner: TCollection);
begin
  inherited Create(AOwner);
end;

destructor THueScene.Destroy;
begin
  inherited Destroy;
end;

function THueScene.GetDisplayName : string;
begin
  if (Name <> '') then
    Result := Name
  else
    Result := inherited GetDisplayName;
end;

procedure THueScene.Assign(Source: TPersistent);
begin
  inherited;
  if Source is THueScene then
  begin
    FHueIndex := THueScene(Source).HueIndex;
    FName     := THueScene(Source).Name;
    FGroup    := THueScene(Source).Group;
    FPicture  := THueScene(Source).Picture;
    FOwner    := THueScene(Source).Owner;
  end;
end;

procedure THueScene.LoadScene(AIndex: string; AScene: TJSON);
var
  I : Integer;
begin
  FHueIndex := AIndex;
  if AScene.Items.ContainsKey('group') then
    FGroup := AScene.Items.Items['group'].AsInteger;
  if AScene.Items.ContainsKey('name') then
    FName := AScene.Items.Items['name'].AsString;
  if AScene.Items.ContainsKey('picture') then
    FPicture := AScene.Items.Items['picture'].AsString;
  if AScene.Items.ContainsKey('owner') then
    FOwner := AScene.Items.Items['owner'].AsString;
  if AScene.Items.ContainsKey('lights') and (AScene.Items.Items['lights'].IsList) then
  begin
    SetLength(FLights, AScene.Items.Items['lights'].ListItems.Count);
    for I := 0 to AScene.Items.Items['lights'].ListItems.Count -1 do
    FLights[I] := AScene.Items.Items['lights'].ListItems[I].AsInteger;
  end else
  begin
    SetLength(FLights, 0);
  end;
end;

// THueScenes Class
//------------------------------------------------------------------------------

constructor THueScenes.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, THueScene);
end;

function THueScenes.GetItem(Index: Integer): THueScene;
begin
  Result := inherited GetItem(Index) as THueScene;
end;

procedure THueScenes.SetItem(Index: Integer; const Value: THueScene);
begin
  inherited SetItem(Index, Value);
end;

function THueScenes.Add : THueScene;
begin
  Result := THueScene(inherited Add);
end;

function THueScenes.GetSceneByID(const AID: string) : THueScene;
var
  I : Integer;
begin
  Result := nil;
  for I := 0 to Count -1 do
  if Items[I].HueIndex = AID then
  begin
    Result := Items[I];
    Break;
  end;
end;

// THueBridgeConfiguration Class
//------------------------------------------------------------------------------

constructor THueBridgeConfiguration.Create(AOwner: TObject);
begin
  inherited Create;
  FOwner := AOwner;
  FFactoryNew := False;
  FLinkButton := False;
  FZigbeeChannel := 0;
end;

procedure THueBridgeConfiguration.AssignTo(Dest: TPersistent);
begin
  if Dest is THueBridgeConfiguration then
  begin
    with THueBridgeConfiguration(Dest) do
    begin
      FAPIVersion       := Self.APIVersion;
      FBridgeID         := Self.BridgeID;
      FDataStoreversion := Self.DataStoreVersion;
      FFactoryNew       := Self.FactoryNew;
      FLinkButton       := Self.LinkButton;
      FModelID          := Self.ModelID;
      FName             := Self.Name;
      FStarterKitID     := Self.StarterKitdID;
      FSWVersion        := Self.SWVersion;
      FTimezone         := Self.TimeZone;
      FZigbeeChannel    := Self.ZigbeeChannel;
    end
  end
  else
    inherited AssignTo(Dest);
end;

procedure THueBridgeConfiguration.SetName(const AName: string);
begin
  if (FName <> AName) then
  begin
    FName := AName;
    if Assigned(FOnChange) then FOnChange(Self, ConfigURL, Format('{"name":"%s"}', [AName]));
  end;
end;

procedure THueBridgeConfiguration.SetTimezone(const ATimezone: string);
begin
  if (FTimeZone <> ATimezone) then
  begin
    FTimeZone := ATimeZone;
    if Assigned(FOnChange) then FOnChange(Self, ConfigURL, Format('{"timezone":"%s"}', [ATimezone]));
  end;
end;

procedure THueBridgeConfiguration.SetZigbeeChannel(const AChannel: Integer);
begin
  if (FZigbeeChannel <> AChannel) and ((AChannel = 11) or (AChannel = 15) or (AChannel = 20) or (AChannel = 25)) then
  begin
    FZigbeeChannel := AChannel;
    if Assigned(FOnChange) then FOnChange(Self, ConfigURL, Format('{"zigbeechannel":%d}', [AChannel]));
  end;
end;

procedure THueBridgeConfiguration.LoadConfiguration(AConfig: TJSON);
begin
  if AConfig.Items.ContainsKey('apiversion') then
    FAPIVersion := AConfig.Items.Items['apiversion'].AsString;
  if AConfig.Items.ContainsKey('bridgeid') then
    FBridgeID := AConfig.Items.Items['bridgeid'].AsString;
  if AConfig.Items.ContainsKey('datastoreversion') then
    FDataStoreVersion := AConfig.Items.Items['datastoreversion'].AsString;
  if AConfig.Items.ContainsKey('factorynew') then
    FFactoryNew := AConfig.Items.Items['factorynew'].AsBoolean;
  if AConfig.Items.ContainsKey('linkbutton') then
    FLinkButton := AConfig.Items.Items['linkbutton'].AsBoolean;
  if AConfig.Items.ContainsKey('modelid') then
    FModelID := AConfig.Items.Items['modelid'].AsString;
  if AConfig.Items.ContainsKey('name') then
    FName := AConfig.Items.Items['name'].AsString;
  if AConfig.Items.ContainsKey('starterkitid') then
    FStarterKitID := AConfig.Items.Items['starterkitid'].AsString;
  if AConfig.Items.ContainsKey('swversion') then
    FSWVersion := AConfig.Items.Items['swversion'].AsString;
  if AConfig.Items.ContainsKey('timezone') then
    FTimezone := AConfig.Items.Items['timezone'].AsString;
  if AConfig.Items.ContainsKey('zigbeechannel') then
    FZigbeeChannel := AConfig.Items.Items['zigbeechannel'].AsInteger;
end;

// THueBridgeNetwork Class
//------------------------------------------------------------------------------

constructor THueBridgeNetwork.Create(AOwner: TObject);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure THueBridgeNetwork.AssignTo(Dest: TPersistent);
begin
  if Dest is THueBridgeNetwork then
  begin
    with THueBridgeNetwork(Dest) do
    begin
      FGateway          := Self.Gateway;
      FIPAddress        := Self.IPAddress;
      FMAC              := Self.MAC;
      FDHCP             := Self.DHCP;
      FNetMask          := Self.NetMask;
      FProxyAddress     := Self.ProxyAddress;
      FProxyPort        := Self.ProxyPort;
      FPortalConnection := Self.PortalConnection;
      FPortalServices   := Self.PortalServices;
      FPortalIncoming   := Self.PortalIncoming;
      FPortalOutgoing   := Self.PortalOutgoing;
      FPortalSignedOn   := Self.PortalSignedOn;
      FInternet         := Self.Internet;
      FRemoteAccess     := Self.RemoteAccess;
      FSWUpdate         := Self.SWUpdate;
      FTime             := Self.Time;
    end
  end
  else
    inherited AssignTo(Dest);
end;

procedure THueBridgeNetwork.UpdateConfiguration(const APUTData: string);
begin
  if Assigned(FOnChange) then FOnChange(Self, ConfigURL, APUTData);
end;

procedure THueBridgeNetwork.SetDHCP(const ADHCP: Boolean);
const
  SBool : array [Boolean] of string = ('false', 'true');
begin
  if (FDHCP <> ADHCP) then
  begin
    FDHCP := ADHCP;
    UpdateConfiguration(Format('{"dhcp":%s}', [SBool[ADHCP]]));
  end;
end;

procedure THueBridgeNetwork.SetProxyAddress(const AAddress: string);
begin
  if (FProxyAddress <> AAddress) then
  begin
    FProxyAddress := AAddress;
    UpdateConfiguration(Format('{"proxyaddress":"%s"}', [AAddress]));
  end;
end;

procedure THueBridgeNetwork.SetProxyPort(const APort: Integer);
begin
  if (FProxyPort <> APort) then
  begin
    FProxyPort := APort;
    UpdateConfiguration(Format('{"proxyport":%d}', [APort]));
  end;
end;

procedure THueBridgeNetwork.SetNetmask(const ANetmask: string);
begin
  if (FNetMask <> ANetmask) then
  begin
    FNetMask := ANetmask;
    UpdateConfiguration(Format('{"netmask":"%s"}', [ANetmask]));
  end;
end;

procedure THueBridgeNetwork.SetGateway(const AGateway: string);
begin
  if (FGateway <> AGateway) then
  begin
    FGateway := AGateway;
    UpdateConfiguration(Format('{"gateway":"%s"}', [AGateway]));
  end;
end;

procedure THueBridgeNetwork.LoadConfiguration(AConfig: TJSON);
begin
  if AConfig.Items.ContainsKey('gateway') then
    FGateway := AConfig.Items.Items['gateway'].AsString;
  if AConfig.Items.ContainsKey('ipaddress') then
    FIPAddress := AConfig.Items.Items['ipaddress'].AsString;
  if AConfig.Items.ContainsKey('mac') then
    FMAC := AConfig.Items.Items['mac'].AsString;
  if AConfig.Items.ContainsKey('dhcp') then
    FDHCP := AConfig.Items.Items['dhcp'].AsBoolean;
  if AConfig.Items.ContainsKey('netmask') then
    FNetMask := AConfig.Items.Items['netmask'].AsString;
  if AConfig.Items.ContainsKey('proxyaddress') then
    FProxyAddress := AConfig.Items.Items['proxyaddress'].AsString;
  if AConfig.Items.ContainsKey('proxyport') then
    FProxyPort := AConfig.Items.Items['proxyport'].AsInteger;
  if AConfig.Items.ContainsKey('portalconnection') then
    FPortalConnection := AConfig.Items.Items['portalconnection'].AsString;
  if AConfig.Items.ContainsKey('portalservices') then
    FPortalServices := AConfig.Items.Items['portalservices'].AsBoolean;
  if AConfig.Items.ContainsKey('portalstate') then
  begin
    if AConfig.Items.Items['portalstate'].Items.ContainsKey('incoming') then
      FPortalIncoming := AConfig.Items.Items['portalstate'].Items.Items['incoming'].AsBoolean;
    if AConfig.Items.Items['portalstate'].Items.ContainsKey('outgoing') then
      FPortalOutgoing := AConfig.Items.Items['portalstate'].Items.Items['outgoing'].AsBoolean;
    if AConfig.Items.Items['portalstate'].Items.ContainsKey('signedon') then
      FPortalSignedOn := AConfig.Items.Items['portalstate'].Items.Items['signedon'].AsBoolean;
  end;
  if AConfig.Items.ContainsKey('internetservices') then
  begin
    if AConfig.Items.Items['internetservices'].Items.ContainsKey('internet') then
      FInternet := AConfig.Items.Items['internetservices'].Items.Items['internet'].AsString;
    if AConfig.Items.Items['internetservices'].Items.ContainsKey('remoteaccess') then
      FRemoteAccess := AConfig.Items.Items['internetservices'].Items.Items['remoteaccess'].AsString;
    if AConfig.Items.Items['internetservices'].Items.ContainsKey('swupdate') then
      FSWUpdate := AConfig.Items.Items['internetservices'].Items.Items['swupdate'].AsString;
    if AConfig.Items.Items['internetservices'].Items.ContainsKey('time') then
      FTime := AConfig.Items.Items['internetservices'].Items.Items['time'].AsString;
  end;
end;

// THueBridge Class
//------------------------------------------------------------------------------

constructor THueBridge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHTTP   := TidHTTP.Create(Self);
  FSSL    := TIdSSLIOHandlerSocketOpenSSL.Create(Self);
  FHTTP.IOHandler := FSSL;
  FHTTP.Request.UserAgent :='ERDesigns HueBridge';
  FSSL.SSLOptions.Method  := sslvSSLv23;
  FLights := THueLights.Create(Self);
  FLights.OnLightChanged  := UpdateLightChange;
  FLights.OnLightIdentify := IdentifyLight;
  FGroups := THueGroups.Create(Self);
  FGroups.OnGroupChanged  := UpdateGroupChange;
  FGroups.OnGroupIdentify := IdentifyGroup;
  FSchedules := THueSchedules.Create(Self);
  FSchedules.OnScheduleChanged := UpdateScheduleChange;
  FScenes := THueScenes.Create(Self);
  FConfiguration := THueBridgeConfiguration.Create(Self);
  FConfiguration.OnChange := UpdateConfiguration;
  FNetwork := THueBridgeNetwork.Create(Self);
  FNetwork.OnChange := UpdateConfiguration;
  FUpdateOnLightChange    := True;
  FUpdateOnGroupChange    := True;
  FUpdateOnScheduleChange := True;
end;

destructor THueBridge.Destroy;
begin
  FHTTP.Free;
  FLights.Free;
  FGroups.Free;
  FSchedules.Free;
  FScenes.Free;
  FConfiguration.Free;
  inherited Destroy;
end;

procedure THueBridge.SetLights(const ALights: THueLights);
begin
  FLights.Assign(ALights);
end;

procedure THueBridge.SetGroups(const AGroups: THueGroups);
begin
  FGroups.Assign(AGroups);
end;

procedure THueBridge.SetSchedules(const ASchedule: THueSchedules);
begin
  FSchedules.Assign(ASchedule);
end;

procedure THueBridge.SetScenes(const AScenes: THueScenes);
begin
  FScenes.Assign(AScenes);
end;

procedure THueBridge.SetConfiguration(const AConfiguration: THueBridgeConfiguration);
begin
  FConfiguration.Assign(AConfiguration);
end;

procedure THueBridge.SetNetwork(const ANetwork: THueBridgeNetwork);
begin
  FNetwork.Assign(ANetwork);
end;

procedure THueBridge.SetUseragent(const AUseragent: string);
begin
  FHTTP.Request.UserAgent := AUseragent;
end;

function THueBridge.GetUseragent : string;
begin
  Result := FHTTP.Request.UserAgent;
end;

procedure THueBridge.UpdateLightChange(Sender: TObject; URL: string; PUTData: string);
begin
  if FUpdateOnLightChange then
    FLastResponse := HTTPPut(Format(BaseURL, [IP, Username]) + URL, PUTData);
end;

procedure THueBridge.UpdateGroupChange(Sender: TObject; URL: string; PUTData: string);
begin
  if FUpdateOnGroupChange then
    FLastResponse := HTTPPut(Format(BaseURL, [IP, Username]) + URL, PUTData);
end;

procedure THueBridge.UpdateScheduleChange(Sender: TObject; URL: string; PUTData: string);
begin
  if FUpdateOnScheduleChange then
    FLastResponse := HTTPPut(Format(BaseURL, [IP, Username]) + URL, PUTData);
end;

procedure THueBridge.UpdateConfiguration(Sender: TObject; URL: string; PUTData: string);
begin
  FlastResponse := HTTPPut(Format(BaseURL, [IP, Username]) + URL, PUTData);
end;

procedure THueBridge.IdentifyLight(Sender: TObject; ID: Integer);
begin
  FlastResponse := HTTPPut(Format(BaseURL, [IP, Username]) + Format(LightStateURL, [ID]), '{"alert":"select"}');
end;

procedure THueBridge.IdentifyGroup(Sender: TObject; ID: Integer);
begin
  FlastResponse := HTTPPut(Format(BaseURL, [IP, Username]) + Format(GroupStateURL, [ID]), '{"alert":"select"}');
end;

function THueBridge.HTTPGet(const AURL: string) : string;
begin
  try
    Result := HTTP.Get(AURL);
  except
    Result := '';
  end;
end;

function THueBridge.HTTPPost(const AURL: string; const AText: string) : string;
var
  S : TStringStream;
begin
  S := TStringStream.Create(AText);
  try
    try
      Result := HTTP.Post(AURL, S);
    except
      Result := '';
    end;
  finally
    S.Free;
  end;
end;

function THueBridge.HTTPPut(const AURL: string; const AText: string) : string;
var
  S : TStringStream;
begin
  S := TStringStream.Create(AText);
  try
    try
      Result := HTTP.Put(AURL, S);
    except
      Result := '';
    end;
  finally
    S.Free;
  end;
end;

function THueBridge.HTTPDelete(const AURL: string) : string;
begin
  try
    Result := HTTP.Delete(AURL);
  except
    Result := '';
  end;
end;

// Bridge ----------------------------------------------------------------------
function THueBridge.DetectBridgeIP(const ABridge: Integer = 0) : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
begin
  Result := False;
  R := HTTPGet(BridgeIPURL);
  FLastResponse := R;
  J := TJSON.Parse(R);
  try
    if J.IsList and (J.ListItems.Count >= 1) and (J.ListItems.Count >= ABridge) then
    begin
      B := J.ListItems[ABridge];
      if B.Items.ContainsKey('internalipaddress') then
      begin
        FBridgeIP := B.Items.Items['internalipaddress'].AsString;
        Result := True;
      end else
        FLastError := 'No bridge found.';
    end;
  finally
    J.Free;
  end;
end;

function THueBridge.PairBridge(const AName: string) : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
begin
  Result := False;
  R := HTTPPost(Format(BridgePairURL, [IP]), Format('{"devicetype":"%s"}', [AName]));
  FLastResponse := R;
  J := TJSON.Parse(R);
  try
    if J.IsList and (J.ListItems.Count >= 1) then
    begin
      B := J.ListItems[0];
      if B.Items.ContainsKey('error') then
      begin
        if B.Items.Items['error'].Items.ContainsKey('description') then
        FLastError := B.Items.Items['error'].Items.Items['description'].AsString;
      end else
      if B.Items.ContainsKey('success') then
      begin
        if B.Items.Items['success'].Items.ContainsKey('username') then
        begin
          FUsername := B.Items.Items['success'].Items.Items['username'].AsString;
          Result := True;
        end;
      end;
    end;
  finally
    J.Free;
  end;
end;

procedure THueBridge.LoadBridgeConfiguration;
var
  R : string;
  J : TJSON;
begin
  R := HTTPGet(Format(BaseURL, [IP, Username]) + ConfigURL);
  J := TJSON.Parse(R);
  try
    FConfiguration.LoadConfiguration(J);
    FNetwork.LoadConfiguration(J);
    if Assigned(FOnConfigurationLoaded) then FOnConfigurationLoaded(Self);
  finally
    J.Free;
  end;
end;

// Lights ----------------------------------------------------------------------
procedure THueBridge.LoadLights;
var
  R : string;
  J : TJSON;
  I : Integer;
  A : TArray<string>;
begin
  R := HTTPGet(Format(BaseURL, [IP, Username]) + LightsURL);
  J := TJSON.Parse(R);
  try
    FLights.Clear;
    A := J.Items.Keys.ToArray;
    TArray.Sort<String>(A, TStringComparer.Ordinal);
    for I := 0 to Length(A) -1 do
      with FLights.Add do LoadLight(StrToInt(A[I]), J.Items.Items[A[I]]);
  finally
    J.Free;
    if Assigned(FOnLightsLoaded) then FOnLightsLoaded(Self);
  end;
end;

procedure THueBridge.UpdateLights;
var
  R : string;
  J : TJSON;
  I : Integer;
  L : THueLight;
begin
  R := HTTPGet(Format(BaseURL, [IP, Username]) + LightsURL);
  J := TJSON.Parse(R);
  try
    if J.Items.Count <> FLights.Count then
      LoadLights
    else
    begin
      for I := 1 to MaxLights do
      if J.Items.ContainsKey(I.ToString) then
      begin
        L := Self.Lights.GetLightByID(I);
        L.LoadLight(I, J.Items.Items[I.ToString]);
      end;
    end;
  finally
    J.Free;
    if Assigned(FOnLightsUpdated) then FOnLightsUpdated(Self);
  end;
end;

function THueBridge.SearchNewLights : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
begin
  Result := False;
  R := HTTPPost(Format(BaseURL, [IP, Username]) + LightsURL, '');
  J := TJSON.Parse(R);
  try
    if J.IsList and (J.ListItems.Count >= 1) then
    begin
      B := J.ListItems[0];
      if B.Items.ContainsKey('success') then
      begin
        if B.Items.Items['success'].Items.ContainsKey('/lights') then
          FLastResponse := B.Items.Items['success'].Items.Items['/lights'].AsString;
        Result := True;
      end;
      if B.Items.ContainsKey('error') then
      begin
        if B.Items.Items['error'].Items.ContainsKey('description') then
          FLastError :=  B.Items.Items['error'].Items.Items['description'].AsString;
      end;
    end;
  finally
    J.Free;
  end;
end;

function THueBridge.DeleteLight(const AID: Integer) : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
begin
  Result := False;
  R := HTTPDelete(Format(BaseURL, [IP, Username]) + Format(LightURL, [AID]));
  J := TJSON.Parse(R);
  try
    if J.IsList and (J.ListItems.Count >= 1) then
    begin
      B := J.ListItems[0];
      if B.Items.ContainsKey('success') then
      begin
        FLastResponse := B.Items.Items['success'].AsString;
        Result := True;
      end;
      if B.Items.ContainsKey('error') then
      begin
        if B.Items.Items['error'].Items.ContainsKey('description') then
          FLastError :=  B.Items.Items['error'].Items.Items['description'].AsString;
      end;
    end;
  finally
    J.Free;
  end;
end;

function THueBridge.UpdateLight(const AID: Integer) : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
  L : THueLight;
begin
  Result := False;
  L := Lights.GetLightByID(AID);
  if Assigned(L) then
  begin
    R := HTTPPut(Format(BaseURL, [IP, Username]) + Format(LightURL, [AID]), Format('{"name": "%s"}', [L.Name]));
    J := TJSON.Parse(R);
    try
      if J.IsList and (J.ListItems.Count >= 1) then
      begin
        B := J.ListItems[0];
        if B.Items.ContainsKey('success') then
        begin
          FLastResponse := B.Items.Items['success'].AsString;
          Result := True;
        end;
        if B.Items.ContainsKey('error') then
        begin
          if B.Items.Items['error'].Items.ContainsKey('description') then
            FLastError :=  B.Items.Items['error'].Items.Items['description'].AsString;
        end;
      end;
    finally
      J.Free;
    end;
  end;
end;

function THueBridge.UpdateLightState(const AID: Integer; const AData: string) : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
begin
  Result := False;
  R := HTTPPut(Format(BaseURL, [IP, Username]) + Format(LightURL, [AID]), AData);
  J := TJSON.Parse(R);
  try
    if J.IsList and (J.ListItems.Count >= 1) then
    begin
      B := J.ListItems[0];
      if B.Items.ContainsKey('success') then
      begin
        FLastResponse := B.Items.Items['success'].AsString;
        Result := True;
      end;
      if B.Items.ContainsKey('error') then
      begin
        if B.Items.Items['error'].Items.ContainsKey('description') then
          FLastError :=  B.Items.Items['error'].Items.Items['description'].AsString;
      end;
    end;
  finally
    J.Free;
  end;
end;

// Groups ----------------------------------------------------------------------
procedure THueBridge.LoadGroups;
var
  R : string;
  J : TJSON;
  I : Integer;
  A : TArray<string>;
begin
  R := HTTPGet(Format(BaseURL, [IP, Username]) + GroupsURL);
  J := TJSON.Parse(R);
  try
    FGroups.Clear;
    A := J.Items.Keys.ToArray;
    TArray.Sort<String>(A, TStringComparer.Ordinal);
    for I := 0 to Length(A) -1 do
    with FGroups.Add do LoadGroup(StrToInt(A[I]), J.Items.Items[A[I]]);
  finally
    J.Free;
    if Assigned(FOnGroupsLoaded) then FOnGroupsLoaded(Self);
  end;
end;

procedure THueBridge.UpdateGroups;
var
  R : string;
  J : TJSON;
  I : Integer;
  G : THueGroup;
begin
  R := HTTPGet(Format(BaseURL, [IP, Username]) + GroupsURL);
  J := TJSON.Parse(R);
  try
    if J.Items.Count <> FGroups.Count then
      LoadGroups
    else
    begin
      for I := 1 to MaxGroups do
      if J.Items.ContainsKey(I.ToString) then
      begin
        G := Groups.GetGroupByID(I);
        G.LoadGroup(I, J.Items.Items[I.ToString]);
      end;
    end;
  finally
    J.Free;
    if Assigned(FOnGroupsUpdated) then FOnGroupsUpdated(Self);
  end;
end;

function THueBridge.CreateGroup(const AName: string; const ALights: TAIntegerList;
  const GroupType: THueGroupType; const GroupClass: THueGroupClass) : Boolean;
const
  BodyA = '{"name":"%s", "type":"%s", "class":"%s", "lights":[%s]}';
  BodyB = '{"name":"%s", "type":"%s", "lights":[%s]}';
var
  R : string;
  J : TJSON;
  B : TJSON;
begin
  Result := False;
  if (GroupType = gtRoom) then
    R := HTTPPost(Format(BaseURL, [IP, Username]) + GroupsURL, Format(BodyA, [AName, SGT[GroupType], SCL[GroupClass], GetLightsJSON(Alights)]))
  else
    R := HTTPPost(Format(BaseURL, [IP, Username]) + GroupsURL, Format(BodyB, [AName, SGT[GroupType], GetLightsJSON(Alights)]));
  J := TJSON.Parse(R);
  try
    if J.IsList and (J.ListItems.Count >= 1) then
    begin
      B := J.ListItems[0];
      if B.Items.ContainsKey('success') then
        Result := True;
    end;
  finally
    J.Free;
  end;
end;

function THueBridge.DeleteGroup(const AID: Integer) : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
begin
  Result := False;
  R := HTTPDelete(Format(BaseURL, [IP, Username]) + Format(GroupURL, [AID]));
  J := TJSON.Parse(R);
  try
    if J.IsList and (J.ListItems.Count >= 1) then
    begin
      B := J.ListItems[0];
      if B.Items.ContainsKey('success') then
      begin
        FLastResponse := B.Items.Items['success'].AsString;
        Result := True;
      end;
      if B.Items.ContainsKey('error') then
      begin
        if B.Items.Items['error'].Items.ContainsKey('description') then
          FLastError :=  B.Items.Items['error'].Items.Items['description'].AsString;
      end;
    end;
  finally
    J.Free;
  end;
end;

function THueBridge.UpdateGroup(const AID: Integer) : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
  S : string;
  G : THueGroup;
begin
  Result := False;
  G := Groups.GetGroupByID(AID);
  if Assigned(G) then
  begin
    S := Format('{"name":"%s", "class":"%s", "lights":[%s]}', [G.Name, SCL[G.GroupClass], GetLightsJSON(G.Lights)]);
    R := HTTPPut(Format(BaseURL, [IP, Username]) + Format(GroupURL, [AID]), S);
    J := TJSON.Parse(R);
    try
      if J.IsList and (J.ListItems.Count >= 1) then
      begin
        B := J.ListItems[0];
        if B.Items.ContainsKey('success') then
        begin
          FLastResponse := B.Items.Items['success'].AsString;
          Result := True;
        end;
        if B.Items.ContainsKey('error') then
        begin
          if B.Items.Items['error'].Items.ContainsKey('description') then
            FLastError :=  B.Items.Items['error'].Items.Items['description'].AsString;
        end;
      end;
    finally
      J.Free;
    end;
  end;
end;

function THueBridge.UpdateGroupAction(const AID: Integer; const AData: string) : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
  G : THueGroup;
begin
  Result := False;
  G := Groups.GetGroupByID(AID);
  if Assigned(G) then
  begin
    R := HTTPPut(Format(BaseURL, [IP, Username]) + Format(GroupURL, [AID]), AData);
    J := TJSON.Parse(R);
    try
      if J.IsList and (J.ListItems.Count >= 1) then
      begin
        B := J.ListItems[0];
        if B.Items.ContainsKey('success') then
        begin
          FLastResponse := B.Items.Items['success'].AsString;
          Result := True;
        end;
        if B.Items.ContainsKey('error') then
        begin
          if B.Items.Items['error'].Items.ContainsKey('description') then
            FLastError :=  B.Items.Items['error'].Items.Items['description'].AsString;
        end;
      end;
    finally
      J.Free;
    end;
  end;
end;

// Schedules -------------------------------------------------------------------
procedure THueBridge.LoadSchedules;
var
  R : string;
  J : TJSON;
  I : Integer;
  A : TArray<string>;
begin
  R := HTTPGet(Format(BaseURL, [IP, Username]) + SchedulesURL);
  J := TJSON.Parse(R, True);
  try
    FSchedules.Clear;
    A := J.Items.Keys.ToArray;
    TArray.Sort<String>(A, TStringComparer.Ordinal);
    for I := 0 to Length(A) -1 do
    with FSchedules.Add do LoadSchedule(StrToInt(A[I]), J.Items.Items[A[I]]);
  finally
    J.Free;
    if Assigned(FOnSchedulesLoaded) then FOnSchedulesLoaded(Self);
  end;
end;

procedure THueBridge.UpdateSchedules;
var
  R : string;
  J : TJSON;
  I : Integer;
begin
  R := HTTPGet(Format(BaseURL, [IP, Username]) + SchedulesURL);
  J := TJSON.Parse(R, True);
  try
    if J.Items.Count <> FSchedules.Count then
      LoadSchedules
    else
    begin
      for I := 1 to MaxGroups do
      if J.Items.ContainsKey(I.ToString) then
      FSchedules.Items[I -1].LoadSchedule(I, J.Items.Items[I.ToString]);
    end;
  finally
    J.Free;
    if Assigned(FOnSchedulesUpdated) then FOnSchedulesUpdated(Self);
  end;
end;

function THueBridge.CreateSchedule(const AName: string; const ADescription: string;
  const AAddress: string; const AMethod: THueScheduleCommandMethod; const ABody: string;
  const ALocalTime: string; const AStatus: Boolean; const AAutoDelete: Boolean;
  const ARecycle: Boolean) : Boolean;
const
  SStatus : array [Boolean] of string = ('disabled', 'enabled');
  SBool   : array [Boolean] of string = ('false', 'true');
  SMethod : array [THueScheduleCommandMethod] of string = ('GET', 'POST', 'PUT', 'DELETE');
  Body = '{"name":"%s", "description":"%s", "command":{"address":"%s", "method":"%s", "body":%s}, "localtime":"%s", "status":"%s", "autodelete":%s, "recycle":%s}';
var
  R : string;
  J : TJSON;
  B : TJSON;
begin
  Result := False;
  R := HTTPPost(Format(BaseURL, [IP, Username]) + SchedulesURL, Format(Body, [
    AName, ADescription, AAddress, SMethod[AMethod], ABody, ALocalTime,
    SStatus[AStatus], SBool[AAutoDelete], SBool[ARecycle]
  ]));
  J := TJSON.Parse(R);
  try
    if J.IsList and (J.ListItems.Count >= 1) then
    begin
      B := J.ListItems[0];
      if B.Items.ContainsKey('success') then
        Result := True;
    end;
  finally
    J.Free;
  end;
end;

function THueBridge.DeleteSchedule(const AID: Integer) : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
begin
  Result := False;
  R := HTTPDelete(Format(BaseURL, [IP, Username]) + Format(ScheduleURL, [AID]));
  J := TJSON.Parse(R);
  try
    if J.IsList and (J.ListItems.Count >= 1) then
    begin
      B := J.ListItems[0];
      if B.Items.ContainsKey('success') then
      begin
        FLastResponse := B.Items.Items['success'].AsString;
        Result := True;
      end;
      if B.Items.ContainsKey('error') then
      begin
        if B.Items.Items['error'].Items.ContainsKey('description') then
          FLastError :=  B.Items.Items['error'].Items.Items['description'].AsString;
      end;
    end;
  finally
    J.Free;
  end;
end;

function THueBridge.UpdateSchedule(const AID: Integer) : Boolean;
const
  SStatus : array [Boolean] of string = ('disabled', 'enabled');
  SBool   : array [Boolean] of string = ('false', 'true');
  SMethod : array [THueScheduleCommandMethod] of string = ('GET', 'POST', 'PUT', 'DELETE');
  Body = '{"name":"%s", "description":"%s", "command":{"address":"%s", "method":"%s", "body":%s}, "localtime":"%s", "status":"%s", "autodelete":%s}';
var
  S : THueSchedule;
begin
  Result := False;
  S := Schedules.GetScheduleByID(AID);
  if Assigned(S) then
  begin
    Result := UpdateSchedule(AID, Format(Body, [S.Name, S.Description, S.Command.Address,
    SMethod[S.Command.Method], S.Command.Body, S.LocalTime, SStatus[S.Status], SBool[S.AutoDelete]]));
  end;
end;

function THueBridge.UpdateSchedule(const AID: Integer; const APUTData: string) : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
  S : THueSchedule;
begin
  Result := False;
  S := Schedules.GetScheduleByID(AID);
  if Assigned(S) then
  begin
    R := HTTPPut(Format(BaseURL, [IP, Username]) + Format(ScheduleURL, [AID]), APUTData);
    J := TJSON.Parse(R);
    try
      if J.IsList and (J.ListItems.Count >= 1) then
      begin
        B := J.ListItems[0];
        if B.Items.ContainsKey('success') then
        begin
          FLastResponse := B.Items.Items['success'].AsString;
          Result := True;
        end;
        if B.Items.ContainsKey('error') then
        begin
          if B.Items.Items['error'].Items.ContainsKey('description') then
            FLastError :=  B.Items.Items['error'].Items.Items['description'].AsString;
        end;
      end;
    finally
      J.Free;
    end;
  end;
end;

// Scenes ----------------------------------------------------------------------
procedure THueBridge.LoadScenes;
var
  R : string;
  J : TJSON;
  I : Integer;
  A : TArray<string>;
begin
  R := HTTPGet(Format(BaseURL, [IP, Username]) + ScenesURL);
  J := TJSON.Parse(R, True);
  try
    FScenes.Clear;
    A := J.Items.Keys.ToArray;
    for I := 0 to Length(A) -1 do
    with FScenes.Add do LoadScene(A[I], J.Items.Items[A[I]]);
  finally
    J.Free;
    if Assigned(FOnScenesLoaded) then FOnScenesLoaded(Self);
  end;
end;

function THueBridge.RecallScene(const AGroup: Integer; const AScene: string) : Boolean;
var
  R : string;
  J : TJSON;
  B : TJSON;
begin
  Result := False;
  R := HTTPPUT(Format(BaseURL, [IP, Username]) + Format(GroupStateURL, [AGroup]), Format('{"scene":"%s"}', [AScene]));
  J := TJSON.Parse(R);
  try
    if J.IsList and (J.ListItems.Count >= 1) then
    begin
      B := J.ListItems[0];
      if B.Items.ContainsKey('success') then
      begin
        FLastResponse := B.Items.Items['success'].AsString;
        Result := True;
      end;
      if B.Items.ContainsKey('error') then
      begin
        if B.Items.Items['error'].Items.ContainsKey('description') then
          FLastError :=  B.Items.Items['error'].Items.Items['description'].AsString;
      end;
    end;
  finally
    J.Free;
  end;
end;

// Register THueBridge
//------------------------------------------------------------------------------

procedure Register;
begin
  RegisterComponents('ERDesigns', [THueBridge]);
end;

end.
