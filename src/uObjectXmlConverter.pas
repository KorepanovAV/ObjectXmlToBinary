unit uObjectXmlConverter;

interface

uses
  System.Classes,
  uXmlLite.WinApi;

type
  TPropertyType = (ptUnknown, ptSymbol, ptString, ptInteger, ptFloatS, ptFloatC, ptFloatD, ptFloat,
    ptSet, ptList, ptBinary, ptCollection);

  TWriteBinaryMethod = procedure(WriteData: TStreamProc) of object;
  TWriteListItemProc = procedure(const AType: TPropertyType; const AValue: String);

  IContext = interface
  ['{D55C36A5-D57A-4551-BDDF-BE5568808733}']
    procedure Push(const AElement: String);
    procedure Pop;

    function GetClassName(const AReader: IXMLReader): String;
    function GetPropertyType(const APropertyName: String): TPropertyType;

    procedure WriteListItems(const AWriter: TWriteListItemProc; const AReader: IXMLReader);
    procedure WriteBinary(const ABinaryWriter: TWriteBinaryMethod);
//    procedure WritePropertyValue(const AWriter: TWriter);
  end;

procedure ObjectXmlToBinary(const AInput: TStream; const AOutput: TStream; AContext: IContext); overload;
procedure ObjectXmlToBinary(const AInput: TStream; const AOutput: TStream); overload;

implementation

uses
  Winapi.ActiveX,
  System.SysUtils,
  System.Win.ComObj,
  System.Rtti, Winapi.Windows;

type
  TWriterHack = class(TWriter);
  TWriter = TWriterHack;

procedure ObjectXmlToBinary(const AInput: TStream; const AOutput: TStream); overload;
{$INLINE OFF}
type
  TNodePropType = (nptPrefix, nptLocalName, nptValue);
  TXmlNodeTypeSet = set of XmlNodeType;

const
  ALL_NODE_SET = [XmlNodeType.None..XmlNodeType.XmlDeclaration];
  PROPERTY_NODE_SET = [XmlNodeType.CDATA];
  OBJECT_NODE_SET = [XmlNodeType.Element, XmlNodeType.EndElement];

  procedure OleCheck(Result: HResult); inline;
  begin
    if not Succeeded(Result) then OleError(Result);
  end;

  function NodeProperty(const AProp: TNodePropType; const AReader: IXMLReader): String; inline;
  var
    LValue: PWideChar;
    LLength: Cardinal;
  begin
    case AProp of
      nptPrefix:
        OleCheck(AReader.GetPrefix(LValue, LLength));
      nptLocalName:
        OleCheck(AReader.GetLocalName(LValue, LLength));
      nptValue:
        OleCheck(AReader.GetValue(LValue, LLength));
    end;
    Result := Copy(LValue, 0, LLength); //WideCharLenToString(LValue, LLength);
  end;

  procedure ConvertProperty(const AWriter: TWriter; const AReader: IXMLReader); inline;
  begin

  end;

  procedure WriteObjectHeader(const AWriter: TWriter; const AObjectName, AClassName: String); inline;
  begin
    AWriter.WritePrefix([], -1);
    AWriter.WriteUTF8Str(AClassName);
    AWriter.WriteUTF8Str(AObjectName);
  end;

  procedure ReadNode(const ANodeTypeSet: TXmlNodeTypeSet; const AWriter: TWriter; const AReader: IXMLReader; out AIsScopeEnd: Boolean); inline; forward;

  procedure ConvertObject(const AWriter: TWriter; const AReader: IXMLReader); inline;
  var
    LIsEmpty: Boolean;
    LObjectName: String;
    LClassName: String;
    LIsScopeEnd: Boolean;
  begin
    LIsEmpty := AReader.IsEmptyElement;
    LObjectName := NodeProperty(nptLocalName, AReader);
    LClassName := 'T' + LObjectName;

    WriteObjectHeader(AWriter, LObjectName, LClassName);
    if AReader.MoveToFirstAttribute = S_OK then
    repeat
      ConvertProperty(AWriter, AReader);
    until AReader.MoveToNextAttribute <> S_OK;

//    ReadNode(PROPERTY_NODE_SET, AWriter, AReader, LIsEmpty);
    AWriter.WriteListEnd;

    LIsScopeEnd := False;
    if not LIsEmpty then
    repeat
      ReadNode(OBJECT_NODE_SET, AWriter, AReader, LIsScopeEnd);
    until LIsScopeEnd;
    AWriter.WriteListEnd;
  end;

  procedure ReadNode(const ANodeTypeSet: TXmlNodeTypeSet; const AWriter: TWriter; const AReader: IXMLReader; out AIsScopeEnd: Boolean); inline;
  var
    LNodeType: XmlNodeType;
  begin
    OleCheck(AReader.Read(LNodeType));
    if LNodeType in ANodeTypeSet then
    case LNodeType of
      XmlNodeType.None: ;
      XmlNodeType.Element:
        ConvertObject(AWriter, AReader);
      XmlNodeType.Attribute: ;
      XmlNodeType.Text: ;
      XmlNodeType.CDATA:
      begin
      end;
      XmlNodeType.ProcessingInstruction: ;
      XmlNodeType.Comment: ;
      XmlNodeType.DocumentType: ;
      XmlNodeType.Whitespace: ;
      XmlNodeType.EndElement:
      begin
        AIsScopeEnd := True;
      end;
      XmlNodeType.XmlDeclaration: ;
    else
      raise Exception.Create(TRttiEnumerationType.GetName(LNodeType));
    end;
  end;

  procedure ReadNodes(const AWriter: TWriter; const AReader: IXMLReader); inline;
  var
    LIsScopeEnd: Boolean;
  begin
    while not AReader.IsEOF do
      ReadNode(ALL_NODE_SET, AWriter, AReader, LIsScopeEnd);
  end;

var
  LReader: IXMLReader;
  LInput: IXmlReaderInput;
  LWriter: TWriterHack;
begin
  OleCheck(CreateXmlReader(XMLReaderGuid, LReader, nil));
  OleCheck(CreateXmlReaderInputWithEncodingCodePage(TStreamAdapter.Create(AInput) as IStream, nil, TEncoding.ANSI.CodePage, True, nil, LInput));
  OleCheck(LReader.SetInput(LInput));

  LWriter := TWriterHack(TWriter.Create(AOutput, 4096));
  try
    LWriter.WriteSignature;
    ReadNodes(LWriter, LReader);
  finally
    LWriter.Free;
  end;
end;

procedure ObjectXmlToBinary(const AInput: TStream; const AOutput: TStream; AContext: IContext);
type
  TNodePropType = (nptPrefix, nptLocalName, nptValue);
var
  LReader: IXMLReader;
  LInput: IXmlReaderInput;
  LWriter: TWriterHack;
  LNodeType: XmlNodeType;

  function NodeProperty(const AProp: TNodePropType): String;
  var
    LValue: PWideChar;
    LLength: Cardinal;
  begin
    case AProp of
      nptPrefix:
        OleCheck(LReader.GetPrefix(LValue, LLength));
      nptLocalName:
        OleCheck(LReader.GetLocalName(LValue, LLength));
      nptValue:
        OleCheck(LReader.GetValue(LValue, LLength));
    end;
    Result := Copy(LValue, 0, LLength); //WideCharLenToString(LValue, LLength);
  end;


  procedure ConvertProperty; forward;

  procedure ConvertValue(const APropertyType: TPropertyType; const AValue: String);
  var
    LItem: String;
  begin
//    LWriter.WriteString(NodeProperty(nptValue));

    if APropertyType in [ptString] then
      LWriter.WriteString(AValue)
    else
    begin
      case APropertyType of
//        ptUnknown: ;
        ptSymbol:
          LWriter.WriteIdent(AValue);
//        ptString: ;
        ptInteger:
          LWriter.WriteInteger(AValue.ToInt64());
        ptFloatS:
          LWriter.WriteSingle(AValue.ToExtended());
        ptFloatC:
          LWriter.WriteCurrency(AValue.ToExtended() / 10000);
        ptFloatD:
          LWriter.WriteDate(AValue.ToExtended());
        ptFloat:
          LWriter.WriteFloat(AValue.ToExtended());
        ptSet:
        begin
          LWriter.WriteValue(vaSet);
          for LItem in AValue.Split([',']) do
            LWriter.WriteUTF8Str(LItem.Trim);
          LWriter.WriteUTF8Str('');
        end;
        ptList:
        begin
          LWriter.WriteListBegin;
          AContext.WriteListItems(@ConvertValue, LReader);
          LWriter.WriteListEnd;
        end;
        ptBinary:
          AContext.WriteBinary(LWriter.WriteBinary);
        ptCollection:
        begin

        end;
      end;

    end;
  end;

  procedure ConvertProperty;
  var
    LPropertyName: String;
  begin
    LPropertyName := NodeProperty(nptLocalName);
    LWriter.WriteUTF8Str(LPropertyName);
    ConvertValue(AContext.GetPropertyType(LPropertyName), NodeProperty(nptValue));
  end;

  procedure ConvertHeader(const AIsInherited, AIsInline: Boolean; const APosition: Integer = -1);
  var
    LClassName, LObjectName: string;
    LFlags: TFilerFlags;
  begin
    LObjectName := NodeProperty(nptLocalName);
    AContext.Push(LObjectName);
    LClassName := AContext.GetClassName(LReader);
    OleCheck(LReader.MoveToElement);
//    LClassName := 'T' + LObjectName;

    LFlags := [];
    if AIsInherited then
      Include(LFlags, ffInherited);
    if AIsInline then
      Include(LFlags, ffInline);
    if APosition >= 0 then
      Include(LFlags, ffChildPos);
    LWriter.WritePrefix(LFlags, APosition);
    LWriter.WriteUTF8Str(LClassName);
    LWriter.WriteUTF8Str(LObjectName);
  end;

  procedure ConvertNode(const AFlags: TFilerFlags); forward;

var
  LPropertiesPosition: Integer;

  procedure ConvertObject(const AFlags: TFilerFlags);
  var
    LIsEmptyElement: Boolean;
  begin
    LIsEmptyElement := LReader.IsEmptyElement;

    ConvertHeader(ffInherited in AFlags, ffInline in AFlags);
    if LReader.MoveToFirstAttribute = S_OK then
    repeat
      ConvertProperty;
    until LReader.MoveToNextAttribute <> S_OK;

    LPropertiesPosition := LWriter.Position;
    LWriter.WriteListEnd;

    if not LIsEmptyElement then
      ConvertNode([]);

    LWriter.WriteListEnd;
    if LIsEmptyElement then
      AContext.Pop;
  end;

  procedure WriteBinaryProperty(const APropertyName: String);
  var
    LStream: TMemoryStream;
    LCount: Longint;
    LBuffer: PWideChar;
    LBufferLength: Cardinal;
  begin
    LWriter.WriteUTF8Str(APropertyName);
    LStream := TMemoryStream.Create;
    try
      OleCheck(LReader.GetValue(LBuffer, LBufferLength));
      LStream.WriteData(LBuffer, LBufferLength);

      LWriter.WriteValue(vaBinary);
      LCount := LStream.Size;
      LWriter.Write(LCount, SizeOf(LCount));
      LWriter.Write(LStream.Memory^, LCount);
    finally
      LStream.Free;
    end;
  end;

  procedure ConvertNode(const AFlags: TFilerFlags);
  begin
    while not LReader.IsEOF do
    begin
      OleCheck(LReader.Read(LNodeType));
      case LNodeType of
        XmlNodeType.None: ;
        XmlNodeType.Element:
          ConvertObject(AFlags);
        XmlNodeType.Attribute: ;
        XmlNodeType.Text: ;
        XmlNodeType.CDATA:
        begin
          LWriter.Position := LPropertiesPosition;
          WriteBinaryProperty('CData');
          LPropertiesPosition := LWriter.Position;
          LWriter.WriteListEnd;
        end;
        XmlNodeType.ProcessingInstruction: ;
        XmlNodeType.Comment: ;
        XmlNodeType.DocumentType: ;
        XmlNodeType.Whitespace: ;
        XmlNodeType.EndElement:
        begin
          LWriter.WriteListEnd;
          AContext.Pop;
        end;
        XmlNodeType.XmlDeclaration: ;
      end;
    end;
  end;

begin
  OleCheck(CreateXmlReader(XMLReaderGuid, LReader, nil));
  OleCheck(CreateXmlReaderInputWithEncodingCodePage(TStreamAdapter.Create(AInput) as IStream, nil, TEncoding.ANSI.CodePage, True, nil, LInput));
  OleCheck(LReader.SetInput(LInput));

  LWriter := TWriterHack(TWriter.Create(AOutput, 4096));
  try
    LWriter.WriteSignature;
    ConvertNode({[ffInherited]}[]);
  finally
    LWriter.Free;
  end;
end;

end.
