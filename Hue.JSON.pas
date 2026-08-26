unit Hue.JSON;

interface

uses
  System.JSON;

type
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

implementation

uses
  System.SysUtils, Hue.Errors;

class function THueJSON.Parse(const AText: string): TJSONValue;
begin
  Result := TJSONObject.ParseJSONValue(AText, False, True);
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

class procedure THueJSON.RaiseIfHueError(const AText: string);
var
  V: TJSONValue;
  A: TJSONArray;
  O, E: TJSONObject;
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
