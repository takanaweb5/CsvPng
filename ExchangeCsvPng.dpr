program ExchangeCsvPng;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  CsvPng in 'CsvPng.pas';

//*****************************************************************************
//[概要] 引数エラーチェック後のメイン
//[引数] なし
//[戻値] なし
//*****************************************************************************
procedure Main();
var
  CP: TCsvPng;
begin

  CP := TCsvPng.Create;
  try
    if Pos('csv2',ParamStr(1)) > 0 then
    begin
      if UpperCase(ParamStr(2)) = '-C' then
        CP.LoadFromClipBordText
      else
        CP.LoadFromCsvFile(ParamStr(2));
    end
    else if Pos('img2',ParamStr(1)) > 0 then
    begin
      if UpperCase(ParamStr(2)) = '-C' then
        CP.LoadFromClipBordImage
      else
        CP.LoadFromImageFile(ParamStr(2));
    end;

    if Pos('2csv',ParamStr(1)) > 0 then
    begin
      if UpperCase(ParamStr(3)) = '-C' then
        CP.SetToClipBoardText
      else
        CP.SaveToCsvFile(ParamStr(3));
    end
    else if Pos('2img',ParamStr(1)) > 0 then
    begin
      if UpperCase(ParamStr(3)) = '-C' then
        CP.SetToClipBoardImage
      else
        CP.SaveToImageFile(ParamStr(3));
    end;
  finally
    CP.Free;
  end;
end;

//*****************************************************************************
//[概要] Mainモジュール
//[引数] なし
//[戻値] なし
//*****************************************************************************
begin
  try
    if ParamCount = 0 then
    begin
      Writeln('');
      Writeln('ExchangeCsvPng.exe [変換スイッチ] [変換前]  [変換後]');
      Writeln('例:ExchangeCsvPng.exe -csv2img -C "c:\tmp\sample.bmp"');
      Writeln('[変換スイッチ] -変換前format2変換後format"');
      Writeln('  [変換前format] csv or img');
      Writeln('  [変換後format] csv or img');
      Writeln('[変換前] ファイル名 or -C(クリップボード)');
      Writeln('[変換後] ファイル名 or -C(クリップボード)');
      Exit;
    end;

    if ParamCount <> 3 then
    begin
      raise Exception.Create('引数の数が正しくありません');
      Exit;
    end;
    if (Pos('csv2',ParamStr(1)) = 0) and
       (Pos('img2',ParamStr(1)) = 0) then
    begin
      raise Exception.Create('第１引数が正しくありません');
      Exit;
    end;
    if (Pos('2csv',ParamStr(1)) = 0) and
       (Pos('2img',ParamStr(1)) = 0) then
    begin
      raise Exception.Create('第１引数が正しくありません');
      Exit;
    end;

    Main();
  except
    on E: Exception do
      Writeln(E.Message);
  end;
end.
