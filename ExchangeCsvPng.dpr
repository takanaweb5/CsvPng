program ExchangeCsvPng;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  CsvPng in 'CsvPng.pas';

//*****************************************************************************
//[�T�v] �����G���[�`�F�b�N��̃��C��
//[����] �Ȃ�
//[�ߒl] �Ȃ�
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
//[�T�v] Main���W���[��
//[����] �Ȃ�
//[�ߒl] �Ȃ�
//*****************************************************************************
begin
  try
    if ParamCount = 0 then
    begin
      Writeln('');
      Writeln('ExchangeCsvPng.exe [�ϊ��X�C�b�`] [�ϊ��O]  [�ϊ���]');
      Writeln('��:ExchangeCsvPng.exe -csv2img -C "c:\tmp\sample.bmp"');
      Writeln('[�ϊ��X�C�b�`] -�ϊ��Oformat2�ϊ���format"');
      Writeln('  [�ϊ��Oformat] csv or img');
      Writeln('  [�ϊ���format] csv or img');
      Writeln('[�ϊ��O] �t�@�C���� or -C(�N���b�v�{�[�h)');
      Writeln('[�ϊ���] �t�@�C���� or -C(�N���b�v�{�[�h)');
      Exit;
    end;

    if ParamCount <> 3 then
    begin
      raise Exception.Create('�����̐�������������܂���');
      Exit;
    end;
    if (Pos('csv2',ParamStr(1)) = 0) and
       (Pos('img2',ParamStr(1)) = 0) then
    begin
      raise Exception.Create('��P����������������܂���');
      Exit;
    end;
    if (Pos('2csv',ParamStr(1)) = 0) and
       (Pos('2img',ParamStr(1)) = 0) then
    begin
      raise Exception.Create('��P����������������܂���');
      Exit;
    end;

    Main();
  except
    on E: Exception do
      Writeln(E.Message);
  end;
end.
