unit uSettings;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Generics.Collections;

type
  TCustomObject = class abstract(TComponent)
  protected
    function GetChildOwner: TComponent; override;
    function GetChildParent: TComponent; override;
    procedure ReadState(Reader: TReader); override;
  public
    function HasParent: Boolean; override;
    function GetParentComponent: TComponent; override;
  end;

  TScript = class abstract(TCustomObject)
  private
    FData: TBytes;
    procedure ReadData(AReader: TStream);
    procedure WriteData(AWriter: TStream);
  protected
    procedure DefineProperties(Filer: TFiler); override;
  public
    property Data: TBytes read FData write FData;
  end;

  TInitScript = class(TScript)
  end;

  TStartedAskableParams = class(TCustomObject)
  end;

  TParams = class(TCustomObject)
  end;

  TValueParamNames = class(TCustomObject)
  end;

  TProperty = class(TCustomObject)
    ValueParamNames: TValueParamNames;
  private
    FType: String;
    FName: String;
  published
    property &Type: String read FType write FType;
    property Name: String read FName write FName;
  end;

  TProperties = class(TCustomObject)
  private
    FItems: TObjectList<TProperty>;
  protected
    procedure ReadState(Reader: TReader); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TSettings = class(TCustomObject)
    InitScript: TInitScript;
    StartedAskableParams: TStartedAskableParams;
    Properties: TProperties;
    Params: TParams;
  end;


implementation

{ TScript }

procedure TScript.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineBinaryProperty('CData', ReadData, WriteData, True);
end;

procedure TScript.ReadData(AReader: TStream);
begin
  SetLength(FData, AReader.Size);
  AReader.Read(FData, AReader.Size);
end;

procedure TScript.WriteData(AWriter: TStream);
begin

end;

{ TProperties }

constructor TProperties.Create(AOwner: TComponent);
begin
  inherited;
  FItems := TObjectList<TProperty>.Create;
end;

destructor TProperties.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TProperties.ReadState(Reader: TReader);
begin
//  inherited ReadState(Reader);
  // ѕропускаем свойства у TProperties, т.к. их пока нет и так проще.
  while not Reader.EndOfList do
  begin
    Reader.ReadStr;
    Reader.SkipValue;
  end;
  Reader.ReadListEnd;

    while not Reader.EndOfList do
      FItems.Add(Reader.ReadComponent(TProperty.Create(nil)) as TProperty);
  Reader.ReadListEnd;
end;

{ TCustomObject }

function TCustomObject.GetChildOwner: TComponent;
begin
  Result := Self;
end;

function TCustomObject.GetChildParent: TComponent;
begin
  Result := inherited GetChildParent;
end;

function TCustomObject.GetParentComponent: TComponent;
begin
  Result := Owner;
end;

function TCustomObject.HasParent: Boolean;
begin
  Result := Assigned(Owner);
end;

procedure TCustomObject.ReadState(Reader: TReader);
var
  LRoot: TComponent;
begin
  LRoot := Reader.Root;
  Reader.Root := Self;
  try
    inherited;
  finally
    Reader.Root := LRoot;
  end;
end;

end.
