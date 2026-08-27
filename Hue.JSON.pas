unit Hue.JSON;

interface

uses
  System.JSON, System.SysUtils, System.Variants, System.Generics.Collections,
  Hue.Errors;

type
  /// <summary>Forward declaration of the System.JSON-backed v1 compatibility node.</summary>
  TJSON = class;

  /// <summary>Owns named compatibility nodes backed by a System.JSON document.</summary>
  TJSONItems = class(TObjectDictionary<string, TJSON>);

  /// <summary>Owns indexed compatibility nodes backed by a System.JSON array.</summary>
  TJSONListItems = class(TObjectList<TJSON>);

  /// <summary>Compatibility view used by the established v1 model loaders; parsing is delegated entirely to System.JSON.</summary>
  TJSON = class
  private
    FParent: TJSON;
    FIsList: Boolean;
    FIsObject: Boolean;
    FValue: Variant;
    FJSONValue: string;
    FItems: TJSONItems;
    FListItems: TJSONListItems;
    /// <summary>Builds a compatibility node recursively from a System.JSON value.</summary>
    constructor CreateFromValue(const AValue: TJSONValue; const AParent: TJSON);
    /// <summary>Resolves a named child or indexed array child.</summary>
    function GetJSONByNameOrIndex(const AData: Variant): TJSON;
    /// <summary>Converts the scalar value to a string.</summary>
    function GetString: string;
    /// <summary>Converts the scalar value to an Integer.</summary>
    function GetInteger: Integer;
    /// <summary>Converts the scalar value to a Boolean.</summary>
    function GetBoolean: Boolean;
    /// <summary>Converts the scalar value to an Int64.</summary>
    function GetInt64: Int64;
  public
    /// <summary>Creates an empty compatibility node.</summary>
    constructor Create(AParent: TJSON = nil);
    /// <summary>Releases all owned child nodes.</summary>
    destructor Destroy; override;
    /// <summary>Parses a JSON document with System.JSON and returns a caller-owned compatibility view.</summary>
    class function Parse(const AJSON: string; const AGetJSONValue: Boolean = False): TJSON; static;
    /// <summary>Enumerates array child nodes.</summary>
    function GetEnumerator: TList<TJSON>.TEnumerator;
    /// <summary>Gets the parent node.</summary>
    property Parent: TJSON read FParent;
    /// <summary>Indicates whether this node represents an array.</summary>
    property IsList: Boolean read FIsList;
    /// <summary>Gets named object children.</summary>
    property Items: TJSONItems read FItems;
    /// <summary>Gets indexed array children.</summary>
    property ListItems: TJSONListItems read FListItems;
    /// <summary>Gets the scalar Variant value.</summary>
    property Value: Variant read FValue;
    /// <summary>Gets the scalar value as a string.</summary>
    property AsString: string read GetString;
    /// <summary>Gets the scalar value as an Integer.</summary>
    property AsInteger: Integer read GetInteger;
    /// <summary>Gets the scalar value as a Boolean.</summary>
    property AsBoolean: Boolean read GetBoolean;
    /// <summary>Gets the scalar value as an Int64.</summary>
    property AsInt64: Int64 read GetInt64;
    /// <summary>Gets an object member by name or array member by index.</summary>
    property JSONByNameOrIndex[const AData: Variant]: TJSON read GetJSONByNameOrIndex; default;
    /// <summary>Provides the legacy shorthand for name/index access.</summary>
    property _[const AData: Variant]: TJSON read GetJSONByNameOrIndex;
  end;

  /// <summary>Reports an unknown compatibility-node field or index.</summary>
  EJSONUnknownFieldOrIndex = class(Exception);

  /// <summary>Compatibility alias for malformed JSON errors.</summary>
  EJSONParseError = class(EHueAPIError);

  /// <summary>Safe, ownership-neutral helpers for System.JSON Hue documents.</summary>
  THueJSON = class sealed
  public
    /// <summary>Parses JSON and raises EHueAPIError when it is malformed.</summary>
    class function Parse(const AText: string): TJSONValue; static;
    /// <summary>Reads an optional string member without unchecked casts.</summary>
    class function StringValue(const AObject: TJSONObject; const AName: string;
      const ADefault: string = ''): string; static;
    /// <summary>Reads an optional Boolean member without unchecked casts.</summary>
    class function BooleanValue(const AObject: TJSONObject; const AName: string;
      const ADefault: Boolean = False): Boolean; static;
    /// <summary>Reads an optional numeric member without unchecked casts.</summary>
    class function NumberValue(const AObject: TJSONObject; const AName: string;
      const ADefault: Double = 0): Double; static;
    /// <summary>Returns an optional object member, owned by the input object.</summary>
    class function ObjectValue(const AObject: TJSONObject; const AName: string): TJSONObject; static;
    /// <summary>Returns an optional array member, owned by the input object.</summary>
    class function ArrayValue(const AObject: TJSONObject; const AName: string): TJSONArray; static;
    /// <summary>Escapes a string by using the platform JSON writer.</summary>
    class function Quote(const AValue: string): string; static;
    /// <summary>Raises EHueAPIError when a v1 or v2 response contains Hue errors.</summary>
    class procedure RaiseIfHueError(const AText: string); static;
  end;

/// <summary>Escapes a string for insertion between existing JSON quotation marks.</summary>
function JSONEscapeValue(const AValue: string): string;

implementation

constructor TJSON.Create(AParent: TJSON);
begin
  inherited Create;
  FParent := AParent;
  FItems := TJSONItems.Create([doOwnsValues]);
  FListItems := TJSONListItems.Create(True);
end;

constructor TJSON.CreateFromValue(const AValue: TJSONValue; const AParent: TJSON);
var
  Pair: TJSONPair;
  ChildValue: TJSONValue;
  IntegerValue: Int64;
begin
  Create(AParent);
  FJSONValue := AValue.ToJSON;
  if AValue is TJSONObject then
  begin
    FIsObject := True;
    for Pair in TJSONObject(AValue) do
      FItems.Add(Pair.JsonString.Value, CreateFromValue(Pair.JsonValue, Self));
  end
  else if AValue is TJSONArray then
  begin
    FIsList := True;
    for ChildValue in TJSONArray(AValue) do
      FListItems.Add(CreateFromValue(ChildValue, Self));
  end
  else if AValue is TJSONTrue then
    FValue := True
  else if AValue is TJSONFalse then
    FValue := False
  else if AValue is TJSONNull then
    FValue := Null
  else if AValue is TJSONNumber then
  begin
    if TryStrToInt64(AValue.Value, IntegerValue) then
      FValue := IntegerValue
    else
      FValue := TJSONNumber(AValue).AsDouble;
  end
  else
    FValue := AValue.Value;
end;

destructor TJSON.Destroy;
begin
  FListItems.Free;
  FItems.Free;
  inherited;
end;

class function TJSON.Parse(const AJSON: string;
  const AGetJSONValue: Boolean): TJSON;
var
  Parsed: TJSONValue;
begin
  Parsed := nil;
  try
    try
      Parsed := THueJSON.Parse(AJSON);
      Result := CreateFromValue(Parsed, nil);
    finally
      Parsed.Free;
    end;
  except
    on E: EHueAPIError do
      raise EJSONParseError.Create(E.Message);
  end;
end;

function TJSON.GetEnumerator: TList<TJSON>.TEnumerator;
begin
  Result := FListItems.GetEnumerator;
end;

function TJSON.GetJSONByNameOrIndex(const AData: Variant): TJSON;
var
  Index: Integer;
  Name: string;
begin
  if VarIsNumeric(AData) then
  begin
    Index := AData;
    if (Index >= 0) and (Index < FListItems.Count) then
      Exit(FListItems[Index]);
    raise EJSONUnknownFieldOrIndex.CreateFmt('Unknown index: %d', [Index]);
  end;
  Name := VarToStr(AData);
  if FItems.TryGetValue(Name, Result) then
    Exit;
  raise EJSONUnknownFieldOrIndex.CreateFmt('Unknown field: %s', [Name]);
end;

function TJSON.GetString: string;
begin
  if VarIsEmpty(FValue) and (FIsObject or FIsList) then
    Result := FJSONValue
  else if VarIsNull(FValue) or VarIsEmpty(FValue) then
    Result := ''
  else
    Result := VarToStr(FValue);
end;

function TJSON.GetInteger: Integer;
begin
  Result := VarAsType(FValue, varInteger);
end;

function TJSON.GetBoolean: Boolean;
begin
  Result := VarAsType(FValue, varBoolean);
end;

function TJSON.GetInt64: Int64;
begin
  Result := VarAsType(FValue, varInt64);
end;

class function THueJSON.Parse(const AText: string): TJSONValue;
begin
  try
    Result := TJSONObject.ParseJSONValue(AText, False, True);
  except
    on E: Exception do
      raise EHueAPIError.CreateFmt('The bridge returned malformed JSON: %s',
        [E.Message]);
  end;
  if not Assigned(Result) then
    raise EHueAPIError.Create('The bridge returned malformed JSON');
end;

class function THueJSON.StringValue(const AObject: TJSONObject;
  const AName, ADefault: string): string;
var V: TJSONValue;
begin
  Result := ADefault;
  if Assigned(AObject) and AObject.TryGetValue<TJSONValue>(AName, V) and
     not (V is TJSONNull) then Result := V.Value;
end;

class function THueJSON.BooleanValue(const AObject: TJSONObject;
  const AName: string; const ADefault: Boolean): Boolean;
var V: TJSONValue;
begin
  Result := ADefault;
  if Assigned(AObject) and AObject.TryGetValue<TJSONValue>(AName, V) then
    if V is TJSONTrue then Result := True else if V is TJSONFalse then Result := False;
end;

class function THueJSON.NumberValue(const AObject: TJSONObject;
  const AName: string; const ADefault: Double): Double;
var N: TJSONNumber;
begin
  Result := ADefault;
  if Assigned(AObject) and AObject.TryGetValue<TJSONNumber>(AName, N) then Result := N.AsDouble;
end;

class function THueJSON.ObjectValue(const AObject: TJSONObject;
  const AName: string): TJSONObject;
begin
  Result := nil;
  if Assigned(AObject) then AObject.TryGetValue<TJSONObject>(AName, Result);
end;

class function THueJSON.ArrayValue(const AObject: TJSONObject;
  const AName: string): TJSONArray;
begin
  Result := nil;
  if Assigned(AObject) then AObject.TryGetValue<TJSONArray>(AName, Result);
end;

class function THueJSON.Quote(const AValue: string): string;
var S: TJSONString;
begin
  S := TJSONString.Create(AValue);
  try Result := S.ToJSON; finally S.Free; end;
end;

function JSONEscapeValue(const AValue: string): string;
var
  Quoted: string;
begin
  Quoted := THueJSON.Quote(AValue);
  Result := Copy(Quoted, 2, Length(Quoted) - 2);
end;

class procedure THueJSON.RaiseIfHueError(const AText: string);
var
  V: TJSONValue;
  A: TJSONArray;
  E: TJSONObject;
  Description: string;
begin
  V := Parse(AText);
  try
    E := nil;
    if V is TJSONObject then
    begin
      A := ArrayValue(TJSONObject(V), 'errors');
      if Assigned(A) and (A.Count > 0) and (A.Items[0] is TJSONObject) then
        E := TJSONObject(A.Items[0]);
    end
    else if (V is TJSONArray) and (TJSONArray(V).Count > 0) and
      (TJSONArray(V).Items[0] is TJSONObject) then
      E := ObjectValue(TJSONObject(TJSONArray(V).Items[0]), 'error');
    if Assigned(E) then
    begin
      Description := StringValue(E, 'description', StringValue(E, 'type', 'Hue API error'));
      raise EHueAPIError.Create(Description);
    end;
  finally
    V.Free;
  end;
end;

end.
