program ObjectXmlToBinaryCon;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  uXmlLite.WinApi in 'src\uXmlLite.WinApi.pas',
  uObjectXmlConverter in 'src\uObjectXmlConverter.pas',
  uSettings in 'src\uSettings.pas',
  System.Classes,
  uContext in 'src\uContext.pas';

procedure Test;

  function ObjectBinaryToText(const AInput: TStream): String;
  var
    LOutput: TStringStream;
  begin
    LOutput := TStringStream.Create;
    try
      System.Classes.ObjectBinaryToText(AInput, LOutput);
      Writeln(LOutput.DataString);
    finally
      LOutput.Free;
    end;
  end;

const
  xmlFile = 'E:\Projects\TFS\Main\IS-Builder\Tests\Data\PrepRoute3.xml';
  xml =
'<?xml version="1.0" encoding="windows-1251" standalone="yes"?>' + sLineBreak+
'<Settings>' + sLineBreak +
'  <InitScript>' + sLineBreak +
'    <![CDATA[]]>' + sLineBreak +
'  </InitScript>' + sLineBreak +
'  <StartedAskableParams/>' + sLineBreak +
'  <Params/>' + sLineBreak +
'  <Properties>' + sLineBreak +
'    <Property Name="TaskSubject" Type="2">' + sLineBreak +
'      <ValueParamNames/>' + sLineBreak +
'    </Property>' + sLineBreak +
'    <Property Name="Attachments" Type="28">' + sLineBreak +
'      <ValueParamNames/>' + sLineBreak +
'    </Property>' + sLineBreak +
//'    <Property Name="Importance" Type="3" Description="Важность" DescriptionLocalizeID="SYSRES_SBINTF.ROUTE_IMPORTANCE_PROP_DESCRIPTION" Visible="true" ParentProperty="" IsOut="false" ValueType="0" AllowedTypes="3" AllowedValueTypes="0;1;2">' + sLineBreak +
//'      <ValueParamNames/>' + sLineBreak +
//'      <PickValues>' + sLineBreak +
//'        <PickValue Code="0" Name="Низкая" NameLocalizeID="SYSRES_SBINTF.LOW_IMPORTANCE_NAME"/>' + sLineBreak +
//'        <PickValue Code="1" Name="Обычная" NameLocalizeID="SYSRES_SBINTF.NORMAL_IMPORTANCE_NAME"/>' + sLineBreak +
//'        <PickValue Code="2" Name="Высокая" NameLocalizeID="SYSRES_SBINTF.HIGH_IMPORTANCE_NAME"/>' + sLineBreak +
//'      </PickValues>' + sLineBreak +
//'      <Value Value="Обычная"/>' + sLineBreak +
//'    </Property>' + sLineBreak +
'  </Properties>' + sLineBreak +
'</Settings>' + sLineBreak +
'';
var
  LInput, LOutput: TStream;
  LRoot: TSettings;
begin
  LOutput := TMemoryStream.Create;
  try
//    LInput := TFileStream.Create(xmlFile, fmOpenRead);
    LInput := TStringStream.Create(xml, TEncoding.ANSI);
    try
//      ObjectXmlToBinary(LInput, LOutput, TClassContext.Create(TSettings));
      ObjectXmlToBinary(LInput, LOutput);
    finally
      LInput.Free;
    end;

//    RegisterClass(TSettings);
//    RegisterClass(TInitScript);
//    RegisterClass(TStartedAskableParams);
//    RegisterClass(TParams);
//    RegisterClass(TProperties);
//    RegisterClass(TValueParamNames);

    LOutput.Position := 0;
    Writeln(ObjectBinaryToText(LOutput));
//    with TReader.Create(LOutput, 4096) do
//    try
//      LRoot := ReadRootComponent(nil) as TSettings;
//    finally
//      Free;
//    end;
    Readln;
  finally
    LOutput.Free;
  end;
end;

begin
  try
    Test;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
