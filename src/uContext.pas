unit uContext;

interface

uses
  uObjectXmlConverter,
  uXmlLite.WinApi,
  System.Generics.Collections,
  System.Classes, System.Rtti;

type
  TClassContext = class(TInterfacedObject, IContext)
  private type
    TStack = TStack<TRttiInstanceType>;
  private
    FStack: TStack;
    FRttiContext: TRttiContext;
    FMetaclass: TClass;
  protected
    { IContext }
    function GetClassName(const AReader: IXMLReader): string;
    procedure Pop;
    procedure Push(const AElement: string);
//    procedure WritePropertyValue(const AWriter: TWriter);
    function GetPropertyType(const APropertyName: String): TPropertyType;
    procedure WriteBinary(const ABinaryWriter: TWriteBinaryMethod);
    procedure WriteListItems(const AWriter: TWriteListItemProc; const AReader: IXMLReader);

  public
    constructor Create(const AMetaclass: TClass);
    destructor Destroy; override;
  end;

implementation

uses
  System.TypInfo;

{ TClassContext }

constructor TClassContext.Create(const AMetaclass: TClass);
begin
  inherited Create;
  FRttiContext := TRttiContext.Create;
  FStack := TStack.Create;
  FMetaclass := AMetaclass;
end;

destructor TClassContext.Destroy;
begin
  FStack.Free;
  FRttiContext.Free;
  inherited;
end;

function TClassContext.GetClassName(const AReader: IXMLReader): string;
begin
  Result := FStack.Peek.Name;
end;

function TClassContext.GetPropertyType(const APropertyName: String): TPropertyType;
var
  LProperty: TRttiProperty;
begin
  LProperty := FStack.Peek.GetProperty(APropertyName);
  case LProperty.PropertyType.TypeKind of
//    tkUnknown: ;
    tkInteger:
      Result := ptInteger;
    tkChar:
      Result := ptString;
    tkEnumeration:
      Result := ptSymbol;
    tkFloat:
      case LProperty.PropertyType.Handle^.TypeData^.FloatType of
//  TFloatType = (ftSingle, ftDouble, ftExtended, ftComp, ftCurr);
        ftSingle:
          Result := ptFloatS;
        ftCurr:
          Result := ptFloatC;
        ftDouble:
        begin
          with LProperty.PropertyType do
            if (Handle = TypeInfo(TDate)) or (Handle = TypeInfo(TTime)) or (Handle = TypeInfo(TDateTime)) then
              Result := ptFloatD
            else
              Result := ptFloat;
        end;
      else
        Result := ptFloat;
      end;
    tkString:
      Result := ptString;
    tkSet:
      Result := ptSet;
    tkClass:
      Result := ptUnknown;
    tkMethod:
      Result := ptUnknown;
    tkWChar:
      Result := ptString;
    tkLString:
      Result := ptString;
    tkWString:
      Result := ptString;
    tkVariant:
      Result := ptUnknown;
    tkArray:
      Result := ptUnknown;
    tkRecord:
      Result := ptUnknown;
    tkInterface:
      Result := ptUnknown;
    tkInt64:
      Result := ptInteger;
    tkDynArray:
      Result := ptUnknown;
    tkUString:
      Result := ptString;
    tkClassRef:
      Result := ptUnknown;
    tkPointer:
      Result := ptUnknown;
    tkProcedure:
      Result := ptUnknown;
    tkMRecord:
      Result := ptUnknown;
  end;
end;

procedure TClassContext.Pop;
begin
  FStack.Pop;
end;

procedure TClassContext.Push(const AElement: string);
var
  LType: TRttiType;
begin
  if FStack.Count = 0 then
    LType := FRttiContext.GetType(FMetaclass)
  else
    LType := FStack.Peek.GetField(AElement).FieldType;

  FStack.Push(LType.AsInstance);
end;

procedure TClassContext.WriteBinary(const ABinaryWriter: TWriteBinaryMethod);
begin

end;

procedure TClassContext.WriteListItems(const AWriter: TWriteListItemProc; const AReader: IXMLReader);
begin

end;

//procedure TClassContext.WritePropertyValue(const AWriter: TWriter);
//begin
//
//end;

end.
