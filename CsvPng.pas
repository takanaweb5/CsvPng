unit CsvPng;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, PNGImage, GIFImg, Clipbrd;

type
  TCsvPng = class(TObject)
  private
    FPixels: array of array of TColor;
    FAlpha:  array of array of Byte;
    FWidth, FHeight: Integer;
    FTransparent: Boolean; //透明色を持つかどうか
    FTransparentColor: TColor; //透明色
    procedure CsvToPng(out PNG: TPngImage);
    procedure CsvToBmp(out BMP: TBitmap);
    procedure CsvToIco(out ICO: TIcon);
    procedure PngToCsv(const PNG: TPngImage);
    procedure BmpToCsv(const BMP: TBitmap);
    procedure IcoToCsv(const ICO: TIcon);
    function ToCsvText(): string;
    procedure FromCsvText(CsvText: string);
  public
    procedure LoadFromCsvFile(FileName: TFileName);
    procedure LoadFromImageFile(FileName: TFileName);
    procedure LoadFromClipBordText();
    procedure LoadFromClipBordImage();
    procedure SaveToCsvFile(FileName: TFileName);
    procedure SaveToImageFile(FileName: TFileName);
    procedure SetToClipBoardText();
    procedure SetToClipBoardImage();
  end;

implementation

{ TCsvPng }
//*****************************************************************************
//[概要] FPixelsの中身からTPngImageを作成する
//[引数] 作成されたTngImage
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.CsvToPng(out PNG: TPngImage);
var
  x,y: Integer;
  SL: PByteArray;
begin
  //アルファチャンネル付きのTPngImageオブジェクトを作成
  PNG := TPngImage.CreateBlank(COLOR_RGBALPHA, 8, FWidth, FHeight);
  for y := 0 to PNG.Height - 1 do
  begin
    SL := PNG.ScanLine[y];
    for x := 0 to PNG.Width - 1 do
    begin
      SL[x*3 +0] := GetBValue(FPixels[y,x]);
      SL[x*3 +1] := GetGValue(FPixels[y,x]);
      SL[x*3 +2] := GetRValue(FPixels[y,x]);
      if FTransparent then
      begin
        if FPixels[y,x] = FTransparentColor then
          //透明色の時
          PNG.AlphaScanline[y]^[x] := 0
        else
          //透過なし
          PNG.AlphaScanline[y]^[x] := 255;
      end
      else
      begin
        //透明色の設定のない時は、アルファチャンネルを設定
        PNG.AlphaScanline[y]^[x] := FAlpha[y,x];
      end;
    end;
  end;
end;

//*****************************************************************************
//[概要] FPixelsの中身からTBitmapを作成する
//[引数] 作成されたTBitmap
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.CsvToBmp(out BMP: TBitmap);
var
  x,y: Integer;
  SL: PByteArray;
  Color: Integer;
begin
  BMP := TBitmap.Create();
  BMP.HandleType  := bmDIB;

  //透明色ありの時
  if FTransparent then
  begin
    BMP.PixelFormat := pf24bit;   //上位24bitがRGB
    BMP.TransparentMode := tmFixed;
    BMP.TransparentColor := FTransparentColor;
  end
  else
  begin
    BMP.PixelFormat := pf32bit;   //上位24bitがRGB、下位8bitがアルファ(透過)値
    BMP.AlphaFormat := afDefined; //アルファチャンネルあり
  end;

  BMP.SetSize(FWidth, FHeight);
  for y := 0 to BMP.Height - 1 do
  begin
    SL := BMP.ScanLine[y];
    for x := 0 to BMP.Width - 1 do
    begin
      Color := FPixels[y,x];
      //透明色ありの時
      if FTransparent then
      begin
        SL[x*3 +0] := GetBValue(Color);//blue
        SL[x*3 +1] := GetGValue(Color);//green
        SL[x*3 +2] := GetRValue(Color);//red
      end
      else
      begin
        SL[x*4 +0] := GetBValue(Color);//blue
        SL[x*4 +1] := GetGValue(Color);//green
        SL[x*4 +2] := GetRValue(Color);//red
        //透明色の設定のない時は、アルファチャンネルを設定
        SL[x*4 +3] := FAlpha[y,x];
      end;
    end
  end
end;

//*****************************************************************************
//[概要] FPixelsの中身からTIconを作成する
//[引数] 作成されたTIcon
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.CsvToIco(out ICO: TIcon);
var
  x,y: Integer;
  BMP, MASK: TBitmap;
  IconInfo: TIconInfo;
begin
  ICO := TIcon.Create();
  MASK := TBitmap.Create();
  CsvToBmp(BMP);
  try
    MASK.Assign(BMP);
    //透明色ありの時
    if FTransparent then
    begin
      MASK.Mask(FTransparentColor);
    end
    else
    begin
      MASK.PixelFormat := pf24bit;   //上位24bitがRGB
      for y := 0 to MASK.Height - 1 do
      begin
        for x := 0 to MASK.Width - 1 do
        begin
          if FAlpha[y,x] = 0 then
            MASK.Canvas.Pixels[x,y] := $FFFFFF //透明
          else
            MASK.Canvas.Pixels[x,y] := $000000;//非透明
        end
      end
    end;

    //TIconInfoレコード型の値をセット
    IconInfo.fIcon    := True;
    IconInfo.xHotspot := 0;
    IconInfo.yHotspot := 0;
    IconInfo.hbmColor := BMP.Handle;
    IconInfo.hbmMask  := MASK.Handle;
    //TBitmap画像からTIcon画像を作成
    ICO.Handle := CreateIconIndirect(IconInfo);
  finally
    BMP.Free;
    MASK.Free;
  end;
end;

//*****************************************************************************
//[概要] TPngImageオブジェクトからFPixelsを作成する
//[引数] TPngImageオブジェクト
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.PngToCsv(const PNG: TPngImage);
var
  x,y: Integer;
begin
  FWidth  := PNG.Width;
  FHeight := PNG.Height;
  SetLength(FPixels, FHeight, FWidth);
  SetLength(FAlpha, FHeight, FWidth);

  for y := 0 to FHeight - 1 do
  begin
    for x := 0 to FWidth - 1 do
    begin
      FPixels[y,x] := PNG.Pixels[x,y];
      if (PNG.TransparencyMode = ptmPartial) and
          PNG.SupportsPartialTransparency then
        //アルファチャネルの設定あり
        FAlpha[y,x] := PNG.AlphaScanline[y]^[x]
      else
        //透過なし
        FAlpha[y,x] := 255;
    end;
  end;

  //透明色設定モードの時
  if PNG.TransparencyMode = ptmBit then
  begin
    FTransparent := True;
    FTransparentColor := PNG.TransparentColor;
  end;
end;

//*****************************************************************************
//[概要] TBitmapオブジェクトからFPixelsを作成する
//[引数] TBitmapオブジェクト
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.BmpToCsv(const BMP: TBitmap);
  procedure SetAlpha(const BMP: TBitmap);
  var
    x,y: Integer;
    SL: PByteArray;
    alpha: Integer; //アルファチャネルが１つでも設定されているかどうか
  begin
    alpha := 0;
    for y := 0 to FHeight - 1 do
    begin
      SL := BMP.ScanLine[y];
      for x := 0 to FWidth - 1 do
      begin
        FAlpha[y,x] := SL[x*4 +3];
        alpha := alpha + SL[x*4 +3];
      end;
    end;

    //アルファチャネル設定なし
    if alpha = 0 then
      for y := 0 to FHeight - 1 do
        for x := 0 to FWidth - 1 do
          FAlpha[y,x] := 255; //不透明
  end;
var
  x,y: Integer;
begin
  FWidth  := BMP.Width;
  FHeight := BMP.Height;
  SetLength(FPixels, FHeight, FWidth);
  SetLength(FAlpha, FHeight, FWidth);

  for y := 0 to FHeight - 1 do
  begin
    for x := 0 to FWidth - 1 do
    begin
      FPixels[y,x] := BMP.Canvas.Pixels[x,y];
      //透過なし(初期設定)
      FAlpha[y,x] := 255;
    end;
  end;

  //透明色設定モードの時
  if BMP.TransparentMode = tmFixed then
  begin
    FTransparent := True;
    FTransparentColor := BMP.TransparentColor;
    Exit;
  end;

  //アルファチャネルを設定
  if BMP.PixelFormat = pfDevice then
  begin
    BMP.HandleType := bmDIB;
    BMP.PixelFormat := pf32bit;
    BMP.AlphaFormat := afDefined;
  end;

  if BMP.PixelFormat = pf32bit then
  begin
    SetAlpha(BMP);
  end
end;

//*****************************************************************************
//[概要] TIconオブジェクトからFPixelsを作成する
//[引数] TIconオブジェクト
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.IcoToCsv(const ICO: TIcon);
var
  x,y: Integer;
  IconInfo: TIconInfo;
  BMP1,BMP2,BMP3: TBitmap;
begin
  GetIconInfo(Ico.Handle, IconInfo);
  FWidth  := ICO.Width;
  FHeight := ICO.Height;
  SetLength(FPixels, FHeight, FWidth);
  SetLength(FAlpha, FHeight, FWidth);

  BMP1 := TBitmap.Create;
  BMP2 := TBitmap.Create;
  BMP3 := TBitmap.Create;
  try
    BMP1.Handle := IconInfo.hbmColor;
    BMP2.PixelFormat := pf24bit;   //上位24bitがRGB
    BMP2.SetSize(BMP1.Width,BMP1.Height);
    BMP2.Canvas.Draw(0,0,BMP1);

    for y := 0 to FHeight - 1 do
      for x := 0 to FWidth - 1 do
        FPixels[y,x] := BMP2.Canvas.Pixels[x,y];


    //マスクの取り出し
    if IconInfo.hbmMask <> 0 then
    begin
      BMP3.Handle := IconInfo.hbmMask;
      for y := 0 to FHeight - 1 do
        for x := 0 to FWidth - 1 do
          if BMP3.Canvas.Pixels[x,y] = 0 then
            FAlpha[y,x] := 255 //非透明
          else
            FAlpha[y,x] := 0;  //透明
    end;

  finally
    BMP1.Free;
    BMP2.Free;
    BMP3.Free;
  end;
end;

//*****************************************************************************
//[概要] FPixelsの中身をCSV形式のテキストに変換
//[引数] なし
//[戻値] なし
//*****************************************************************************
function TCsvPng.ToCsvText(): string;
  function GetColorText(Color: TColor; Alpha: Byte): string;
  begin
    //透明色モード
    if FTransparent then
      if Color = FTransparentColor then
        Result := '       '
      else
        Result := '$' + IntToHex(Integer(Color),6)
    else
      if Alpha = 0 then
        Result := '       '
      else
        Result := '$' + IntToHex(Integer(Color),6)
  end;
var
  x,y: Integer;
  SL: TStringList;
  StrCol: string;
begin
  SL := TStringList.Create;
  try
    for y := 0 to FHeight -1 do
    begin
      StrCol := GetColorText(FPixels[y,0], FAlpha[y,0]);
      for x := 1 to FWidth -1 do
        StrCol := StrCol + ',' + GetColorText(FPixels[y,x], FAlpha[y,x]);
      SL.Add(StrCol);
    end;
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

//*****************************************************************************
//[概要] CSVファイルからFTableに内容を読込む
//[引数] CSVファイル名
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.FromCsvText(CsvText: string);
var
  x,y: Integer;
  Rows,Cols: TStringList;
  Color: Integer;
begin
  Rows := TStringList.Create;
  Cols := TStringList.Create;
  try
    Rows.Text := CsvText;

    //２次元配列のサイズを設定
    Cols.Delimiter := ',';
    Cols.StrictDelimiter := True;
    Cols.DelimitedText := Rows[0];
    FHeight := Rows.Count;
    FWidth  := Cols.Count;
    SetLength(FPixels, FHeight, FWidth);
    SetLength(FAlpha, FHeight, FWidth);

    //行数LOOP
    for y := 0 to FHeight-1 do
    begin
      //カンマで分割
      Cols.DelimitedText := Rows[y];
      //列数LOOP
      for x := 0 to FWidth-1 do
      begin
        if TryStrToInt(Trim(Cols[x]), Color) then
        begin
          FPixels[y,x] := Color;
          FAlpha[y,x] := 255
        end
        else
        begin
          //透明
          FPixels[y,x] := 0;
          FAlpha[y,x] := 0;
        end
      end;
    end;
  finally
    Rows.Free;
    Cols.Free;
  end;
end;

//*****************************************************************************
//[概要] クリップボードのCSV形式のテキストをFTableに読込む
//[引数] CSVファイル名
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.LoadFromClipBordText();
var
  CsvText: string;
begin
  CsvText := Clipboard.AsText;
  if CsvText <> '' then
    FromCsvText(CsvText);
end;

//*****************************************************************************
//[概要] クリップボードの画像をFTableに読込む
//[引数] CSVファイル名
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.LoadFromClipBordImage();
var
  BMP: TBitmap;
begin
  BMP := TBitmap.Create;
  try
    BMP.Assign(Clipboard);
    BmpToCsv(BMP);
  finally
    BMP.Free;
  end;
end;

//*****************************************************************************
//[概要] CSVファイルの内容をFTableに読込む
//[引数] CSVファイル名
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.LoadFromCsvFile(FileName: TFileName);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.LoadFromFile(FileName);
    FromCsvText(SL.Text);
  finally
    SL.Free;
  end;
end;

//*****************************************************************************
//[概要] 画像ファイルからFTableに内容を読込む
//[引数] 画像ファイル名
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.LoadFromImageFile(FileName: TFileName);
var
  PIC: TPicture;
  BMP: TBitmap;
begin
  PIC := TPicture.Create;
  BMP := TBitmap.Create;
  try
    PIC.LoadFromFile(FileName);
    if PIC.Graphic is TPngImage then
      PngToCsv(TPngImage(PIC.Graphic))
    else if PIC.Graphic is TBitmap then
      BmpToCsv(TBitmap(PIC.Graphic))
    else if PIC.Graphic is TIcon then
      IcoToCsv(TIcon(PIC.Graphic))
    else
    begin
      BMP.HandleType := bmDIB;
      BMP.PixelFormat := pf24bit;
//      BMP.AlphaFormat := afDefined;
      BMP.Width := PIC.Width;
      BMP.Height := PIC.Height;
      BMP.Canvas.Draw(0, 0, PIC.Graphic);
      BmpToCsv(BMP);
    end;
  finally
    PIC.Free;
    BMP.Free;
  end;
end;

//*****************************************************************************
//[概要] FTableの中身をファイルに保存する
//[引数] CSVファイル名
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.SaveToCsvFile(FileName: TFileName);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := ToCsvText();
    SL.SaveToFile(FileName);
  finally
    SL.Free;
  end;
end;

//*****************************************************************************
//[概要] FTableの中身から画像を作成しファイルに保存する
//[引数] 画像ファイル名(png or bmp)
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.SaveToImageFile(FileName: TFileName);
var
  Ext: string;
  PNG: TPngImage;
  BMP: TBitmap;
  ICO: TIcon;
begin
  PNG := nil;
  BMP := nil;
  ICO := nil;
  Ext := ExtractFileExt(Filename).Remove(0, 1).ToUpper;
  if Ext = 'PNG' then
  begin
    CsvToPng(PNG);
    try
      PNG.SaveToFile(FileName);
    finally
      PNG.Free;
    end;
  end
  else if Ext= 'BMP' then
  begin
    CsvToBmp(BMP);
    try
      BMP.SaveToFile(FileName);
    finally
      BMP.Free;
    end;
  end
  else if Ext= 'ICO' then
  begin
    CsvToIco(ICO);
    try
      ICO.SaveToFile(FileName);
    finally
      ICO.Free;
    end;
  end
end;

//*****************************************************************************
//[概要] FTableの中身をCSV形式でテキストとしてクリップボードに貼り付ける
//[引数] なし
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.SetToClipBoardText();
begin
  Clipboard.AsText := ToCsvText();
end;

//*****************************************************************************
//[概要] FTableの中身をpng形式とbmp形式でクリップボードに貼り付ける
//[引数] なし
//[戻値] なし
//*****************************************************************************
procedure TCsvPng.SetToClipBoardImage();
var
  MS:  TMemoryStream;
  PNG: TPngImage;
  BMP: TBitmap;
  LhGlobal: HGLOBAL;
  Format: Word;
  CF_PNG    : UINT;
  pBuffer  : Pointer;
  Data: THandle;
  Palette: HPALETTE;
begin
  PNG := nil;
  BMP := nil;
  MS := TMemoryStream.Create;
  CsvToPng(PNG);
  CsvToBmp(BMP);
  Clipboard.Clear;
  Clipboard.Open;
  try
    //BMPイメージの保存
    BMP.SaveToClipboardFormat(Format, Data, Palette);
    Clipboard.SetAsHandle(Format, Data);

    //PNGイメージの保存
    PNG.SaveToStream(MS);
    CF_PNG := RegisterClipboardFormat('PNG');
    MS.Position := 0;
    LhGlobal := GlobalAlloc(GMEM_MOVEABLE, MS.Size);
    pBuffer := GlobalLock(LhGlobal);
    try
      MS.Read(pBuffer^, MS.Size);
    finally
      GlobalUnlock(LhGlobal);
    end;
    // クリップボードにデータをセット
    SetClipboardData(CF_PNG, LhGlobal);
  finally
    Clipboard.Close;
    MS.Free;
    PNG.Free;
    BMP.Free;
  end;
end;

end.

