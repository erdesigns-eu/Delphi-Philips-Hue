unit Hue.Types;

interface

type
  /// <summary>Selects the generation of the Philips Hue local REST API.</summary>
  THueAPIVersion = (hav1, hav2);

  /// <summary>Identifies the HTTP operation issued to a Hue bridge.</summary>
  THueHTTPMethod = (hhmGet, hhmPost, hhmPut, hhmDelete);

  /// <summary>Describes a Hue resource without coercing v2 UUIDs into legacy integers.</summary>
  THueResourceReference = record
  private
    FLegacyID: Integer;
    FResourceID: string;
  public
    /// <summary>Creates an API-version-aware resource reference.</summary>
    class function Create(const ALegacyID: Integer; const AResourceID: string): THueResourceReference; static;
    /// <summary>Returns the v1 numeric identifier, or zero for a v2-only resource.</summary>
    property LegacyID: Integer read FLegacyID;
    /// <summary>Returns the v2 UUID identifier, or an empty string for a v1-only resource.</summary>
    property ResourceID: string read FResourceID;
  end;

implementation

class function THueResourceReference.Create(const ALegacyID: Integer;
  const AResourceID: string): THueResourceReference;
begin
  Result.FLegacyID := ALegacyID;
  Result.FResourceID := AResourceID;
end;

end.
