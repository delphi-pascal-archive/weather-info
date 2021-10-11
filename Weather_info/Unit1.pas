unit Unit1;

interface             

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdHTTP, StdCtrls, ExtCtrls, ComCtrls, Gauges;

type
  TWeat = (wPasmurno, wRain, wSun, wSnow, wPeremenno, wGroza);

  TForm1 = class(TForm)
    IdHTTP1: TIdHTTP;
    Label1: TLabel;
    ComboBox1: TComboBox;
    Temp: TGauge;
    Shape1: TShape;
    Label2: TLabel;
    Label3: TLabel;
    Image1: TImage;
    Label4: TLabel;
    Label5: TLabel;
    procedure Reload(CityID : Integer);
    procedure FillIDs;
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

const
  TempStr = '<td bgcolor="#FFFFE0">Днем, &deg;C</td>';

//99973
var
  Form1: TForm1;
  IDS  : array of array [0..1] of string;
  ID  : Integer;
  Weat : set of TWeat;
implementation

{$R *.dfm}

function GetPart(Str : String; DelChr : Char; Number : Integer) : string;
var b, b1, i : Integer;
    s1   : string;
begin
  Str := Str + DelChr;
  b := 0;
  for i := 0 to Length(Str) do begin
    if Str[i] = DelChr then inc(b);
    if b = (Number-1) then break;
  end;
  s1 := Copy(Str, i+1, maxint);
  b1 := Pos(DelChr, s1);
  Result := copy(s1, 0, b1-1);
end;

procedure TForm1.FillIDs;
var SL : TStringList;
    i  : Integer;
begin
  SL := TStringList.Create;
  sl.LoadFromFile('ids.txt');
  SetLength(IDS, SL.Count);
  ComboBox1.Clear;
  for i := 0 to SL.Count - 1 do begin
    IDS[i,0] := GetPart(sl[i], '|', 1);
    IDS[i,1] := GetPart(sl[i], '|', 2);
    ComboBox1.Items.Add(IDS[i, 0])
  end;
  ComboBox1.ItemIndex := 0;
end;

procedure TransLoad(FileName : String);
var w, h : Integer;
begin
  Form1.Image1.Picture.LoadFromFile(FileName);
  for w := 0 to Form1.Image1.Width - 1 do
    for h := 0 to Form1.Image1.Height - 1 do
      if Form1.Image1.Canvas.Pixels[w, h] = clWhite then
        Form1.Image1.Canvas.Pixels[w, h] :=
          Form1.Color;
end;

procedure TForm1.Reload(CityID: Integer);
var s,s1,s2 : string;
    c       : TColor;
begin
  s := IdHTTP1.Get('http://pda.gismeteo.ru/'+IntToStr(CityID)+'.htm');
  S := Copy(S, Pos('<td bgcolor="#E0FFE0">Облачность<br>и осадки</td>', S), MAXINT);
  s1 := Copy(S, Pos('alt="', S)+5, MAXINT);
  s1 := Copy(s1, 0, Pos('"', s1) - 1); //Облачность
  s2 := Copy(S, Pos(TempStr, S)+Length(TempStr), MaxInt);
  s2 := Copy(s2, Pos('r>', s2), MAXINT);
  s2 := Copy(S2, Pos('>', s2)+1, MAXINT);
  s2 := Copy(s2, 0, Pos('</td>', s2)-1);

  Label1.Caption := S1;
  Temp.Progress := StrToInt(s2);
  Label3.Caption := s2;
  if s2 = '0' then c := clGreen;
  if s2[1] = '+' then c := clRed;
  if s2[1] = '-' then c := clNavy;
  Temp.ForeColor := c;
  Shape1.Brush.Color := c;

  //Множество
  Weat := [];
  if Pos('ясно', s1) > 0 then Include(Weat, wSun);
  if Pos('облачно', s1) > 0 then Include(Weat, wPasmurno);
  if Pos('пасмурно', s1) > 0 then Include(Weat, wPasmurno);
  if Pos('переменная облачность', s1) > 0 then Include(Weat, wPeremenno);
  if Pos('дождь', s1) > 0 then Include(Weat, wRain);
  if Pos('снег', s1) > 0 then Include(Weat, wSnow);
  if Pos('гроза', s1) > 0 then Include(Weat, wGroza);
  //Проверка
  if (wRain in Weat) and (wGroza in Weat) then Exclude(Weat, wRain);
  if (wRain in Weat) and (wSnow in Weat) then Exclude(Weat, wRain);
  //Загрузка
  s := '';
  if (wSun in Weat) then s := 'sun.bmp';
  if (wPasmurno in Weat) then s := 'pasmurno.bmp';
  if (wPeremenno in Weat) then s := 'peremenno.bmp';
  if (wRain in Weat) then s := 'rain.bmp';
  if (wSnow in Weat) then s := 'snow.bmp';
  if (wGroza in Weat) then s := 'groza.bmp';

  TransLoad(s);

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FillIDs;
  ID := StrToInt(IDs[0,1]);
  Label4.Caption := IDs[0,0];
  Reload(ID);
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  ID  := StrToInt(IDS[ComboBox1.ItemIndex, 1]);
  Label4.Caption := IDs[ComboBox1.ItemIndex, 0];
  Reload(ID);
end;

end.
