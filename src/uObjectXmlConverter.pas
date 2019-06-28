unit uObjectXmlConverter;

interface

uses
  System.Classes;

procedure ObjectXmlToBinary(const AInput: TStream; const AOutput: TStream);

implementation

uses
  Winapi.ActiveX,
  System.SysUtils,
  System.Win.ComObj,
  System.Rtti,
  uXmlLite.WinApi;

type
  TWriterHack = class(TWriter);

procedure ObjectXmlToBinary(const AInput: TStream; const AOutput: TStream);
type
  TNodePropType = (nptPrefix, nptLocalName, nptValue);
var
  LReader: IXMLReader;
  LInput: IXmlReaderInput;
  LWriter: TWriter;
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

  procedure ConvertValue;
  begin
    LWriter.WriteString(NodeProperty(nptValue));
  end;

  procedure ConvertProperty;
  begin
    LWriter.WriteUTF8Str(NodeProperty(nptLocalName));
    ConvertValue;
  end;

  procedure ConvertHeader(const AIsInherited, AIsInline: Boolean; const APosition: Integer = -1);
  var
    LClassName, LObjectName: string;
    LFlags: TFilerFlags;
  begin
    LObjectName := NodeProperty(nptLocalName);
    LClassName := 'T' + LObjectName;

    LFlags := [];
    if AIsInherited then
      Include(LFlags, ffInherited);
    if AIsInline then
      Include(LFlags, ffInline);
    if APosition >= 0 then
      Include(LFlags, ffChildPos);
    TWriterHack(LWriter).WritePrefix(LFlags, APosition);
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

      TWriterHack(LWriter).WriteValue(vaBinary);
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
          LWriter.WriteListEnd;
        XmlNodeType.XmlDeclaration: ;
      end;
    end;
  end;

begin
  OleCheck(CreateXmlReader(XMLReaderGuid, LReader, nil));
  OleCheck(CreateXmlReaderInputWithEncodingCodePage(TStreamAdapter.Create(AInput) as IStream, nil, TEncoding.ANSI.CodePage, True, nil, LInput));
  OleCheck(LReader.SetInput(LInput));

  LWriter := TWriter.Create(AOutput, 4096);
  try
    LWriter.WriteSignature;
    ConvertNode({[ffInherited]}[]);
  finally
    LWriter.Free;
  end;
end;

end.
