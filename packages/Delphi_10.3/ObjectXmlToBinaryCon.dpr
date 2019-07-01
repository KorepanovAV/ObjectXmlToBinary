program ObjectXmlToBinaryCon;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  uXmlLite.WinApi in '..\..\src\uXmlLite.WinApi.pas',
  uObjectXmlConverter in '..\..\src\uObjectXmlConverter.pas',
  uSettings in '..\..\src\uSettings.pas',
  System.Classes,
  uMain in '..\..\src\uMain.pas';

begin
  try
    Test;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
