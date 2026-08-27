unit Hue.Errors;

interface

uses
  System.SysUtils, Hue.Types;

type
  /// <summary>Base exception for transport, protocol, and compatibility failures.</summary>
  EHueError = class(Exception);

  /// <summary>Reports an HTTP failure and retains its status and response body.</summary>
  EHueHTTPError = class(EHueError)
  private
    FStatusCode: Integer;
    FResponseBody: string;
  public
    /// <summary>Creates an HTTP error with diagnostic response details.</summary>
    constructor Create(const AStatusCode: Integer; const AResponseBody: string);
    /// <summary>Gets the HTTP response status.</summary>
    property StatusCode: Integer read FStatusCode;
    /// <summary>Gets the unmodified response body.</summary>
    property ResponseBody: string read FResponseBody;
  end;

  /// <summary>Reports a structured error returned by a Hue API.</summary>
  EHueAPIError = class(EHueError);

  /// <summary>Reports that a legacy operation has no valid equivalent in the selected API.</summary>
  EHueUnsupportedOperation = class(EHueError)
  private
    FAPIVersion: THueAPIVersion;
    FOperation: string;
  public
    /// <summary>Creates an explicit API capability error.</summary>
    constructor Create(const AOperation: string; const AVersion: THueAPIVersion);
    /// <summary>Gets the selected API version.</summary>
    property APIVersion: THueAPIVersion read FAPIVersion;
    /// <summary>Gets the unsupported operation name.</summary>
    property Operation: string read FOperation;
  end;

implementation

constructor EHueHTTPError.Create(const AStatusCode: Integer;
  const AResponseBody: string);
begin
  FStatusCode := AStatusCode;
  FResponseBody := AResponseBody;
  inherited CreateFmt('Hue HTTP request failed with status %d: %s',
    [AStatusCode, AResponseBody]);
end;

constructor EHueUnsupportedOperation.Create(const AOperation: string;
  const AVersion: THueAPIVersion);
const
  VersionNames: array[THueAPIVersion] of string = ('v1', 'v2');
begin
  FOperation := AOperation;
  FAPIVersion := AVersion;
  inherited CreateFmt('%s is not available through Hue API %s',
    [AOperation, VersionNames[AVersion]]);
end;

end.
