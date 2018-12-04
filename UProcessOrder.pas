unit UProcessOrder;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ShellApi, StdCtrls;

type
  TProcessOrder = class

  private
  procedure MergeCodeList(aList: TList);
  procedure DisassembleRubberMix;
  procedure DisassembleSemifinished;

  public
  procedure RunOrderProcessing(aOrdNum:integer);
  procedure SaveToFile(str: string);

  end;

  TProductComponent = class
    private
    // ѕол€ данных этого нового класса
    ComponentKm: String;
    ComponentAmt: Double;
    ComponentEd: String;
    ComponentNameEd: String;
    ComponentKc: String;
    ComponentCenm: Currency;
    ComponentSumma: Currency;
    ComponentCenmNew: Currency;
    ComponentNameM: String;

    public
      // —войства дл€ чтени€ значений этих данных
      property Km : String read ComponentKm;
      property Amt : Double read ComponentAmt;
      property Ed : String read ComponentEd;
      property NameEd : String read ComponentNameEd;
      property Kc : String read ComponentKc;
      property Cenm : Currency read ComponentCenm;
      property Summa : Currency read ComponentSumma;
      property CenmNew : Currency read ComponentCenmNew;
      property NameM : String read ComponentNameM;

      //  оструктрор
      constructor Create(const ComponentKm   : String;
                         const ComponentAmt : Double;
                         const ComponentEd : String;
                         const ComponentNameEd   : String;
                         const ComponentKc   : String;
                         const ComponentCenm   : Currency;
                         const ComponentSumma   : Currency;
                         const ComponentCenmNew   : Currency;
                         const ComponentNameM   : String);

  end;

var
  ProcessOrder: TProcessOrder;
  RawMaterialList: TList;
  RubberMixList: TList;
  SemifinishedList: TList;
  RawMaterial: TProductComponent;
  RubberMix: TProductComponent;
  Semifinished: TProductComponent;

implementation

uses UDM, UMainRent, DB, Math;


procedure TProcessOrder.DisassembleRubberMix;
var s:string;
    cenm, cenmNew: Currency;
    aDateDisassembleBeg, aDateDisassembleEnd: String;
begin
  while RubberMixList.Count>0 do
  begin
  if frmMainRent.DateDisassembleOrdBeg.Text>'01.01.1990' then
  aDateDisassembleBeg:=frmMainRent.DateDisassembleOrdBeg.Text;
  if frmMainRent.DateDisassembleOrdEnd.Text>'01.01.1990' then
  aDateDisassembleEnd:=frmMainRent.DateDisassembleOrdEnd.Text;

  dm.quWork.Close;
  dm.quWork.SQL.Text:='select r.*,h.*,e.name edname  '
  +' from r_normrs r '
  +' left join r_nxh22 h on h.kod='
  +TProductComponent(RubberMixList[RubberMixList.Count-1]).Ed+'||r.ednor '
  +' left join s_edin e on e.codestr=r.edn '
  +' where r.krsm = '''
  +TProductComponent(RubberMixList[RubberMixList.Count-1]).Km+''''+' and r.kc='''
  +TProductComponent(RubberMixList[RubberMixList.Count-1]).Kc+''''
  +' and r.tnpr=1';
  dm.quWork.Open;

    if DM.quWork.RecordCount=0 then
    begin
    dm.quWork.Close;
    dm.quWork.SQL.Text:='select r.*,h.*,e.name edname  '
    +' from r_normrs r '
    +' left join r_nxh22 h on h.kod='
    +TProductComponent(RubberMixList[RubberMixList.Count-1]).Ed+'||r.ednor '
    +' left join s_edin e on e.codestr=r.edn '
    +' where r.krsm = '''
    +TProductComponent(RubberMixList[RubberMixList.Count-1]).Km+''''
    +' and r.tnpr=1';
    dm.quWork.Open;
    end;

    if not dm.quWork.IsEmpty then
    begin
      dm.quWork.First;
      while not dm.quWork.Eof do
      begin
        case dm.quWork.FieldByName('tpr').AsInteger of
          3:  begin
              Semifinished:= TProductComponent.Create(
                dm.quWork.FieldByName('km').AsString,
                RoundTo(TProductComponent(RubberMixList[RubberMixList.Count-1]).Amt
                *dm.quWork.FieldByName('normr').AsFloat
                *StrToFloat(dm.quWork.FieldByName('text').AsString),-6),
                dm.quWork.FieldByName('edn').AsString,
                dm.quWork.FieldByName('edname').AsString,
                '', 0, 0, 0, '');
              SemifinishedList.Add(Semifinished);
              end;

          4:  begin
              cenm:=0;
              ShortDateFormat:='dd.mm.yyyy';
              s:='select first 1 cenm, eizm, dtndc  from r_cenmo where ';
              s:=s+' cenm<>0 and km='''+dm.quWork.FieldByName('km').AsString+'''';
              s:=s+' and date(nvl(dtndc,0)) <='''+aDateDisassembleBeg+'''';
              s:=s+' order by dtndc desc';
              dm.quWork2.Close;
              dm.quWork2.SQL.Text:=s;
              dm.quWork2.Open;

              cenm:=dm.quWork2.FieldByName('cenm').AsFloat;

              cenmNew:=0;
              s:='select first 1 cenm, eizm, dtndc  from r_cenmo where ';
              s:=s+' cenm<>0 and km='''+dm.quWork.FieldByName('km').AsString+'''';
              s:=s+' and date(nvl(dtndc,0)) <='''+aDateDisassembleEnd+'''';
              s:=s+' order by dtndc desc';
              dm.quWork2.Close;
              dm.quWork2.SQL.Text:=s;
              dm.quWork2.Open;
              cenmNew:=dm.quWork2.FieldByName('cenm').AsFloat;

              RawMaterial:= TProductComponent.Create(
                dm.quWork.FieldByName('km').AsString,
                RoundTo(TProductComponent(RubberMixList[RubberMixList.Count-1]).Amt
                *dm.quWork.FieldByName('normr').AsFloat
                *StrToFloat(dm.quWork.FieldByName('text').AsString),-6),
                dm.quWork.FieldByName('edn').AsString,
                dm.quWork.FieldByName('edname').AsString,
                '', cenm,
                RoundTo(TProductComponent(RubberMixList[RubberMixList.Count-1]).Amt
                *dm.quWork.FieldByName('normr').AsFloat*cenm
                *StrToFloat(dm.quWork.FieldByName('text').AsString),-6), cenmNew, '');
              RawMaterialList.Add(RawMaterial);
              end;

          else {--} ;
        end;

        dm.quWork.Next;
      end;
    end;

  RubberMixList.Remove(RubberMixList[RubberMixList.Count-1]);
  end;
end;

procedure TProcessOrder.DisassembleSemifinished;
var s:string;
    cenm, cenmNew: Currency;
    aDateDisassembleBeg, aDateDisassembleEnd: String;
begin
  while SemifinishedList.Count>0 do
  begin
  if frmMainRent.DateDisassembleOrdBeg.Text>'01.01.1990' then
  aDateDisassembleBeg:=frmMainRent.DateDisassembleOrdBeg.Text;
  if frmMainRent.DateDisassembleOrdEnd.Text>'01.01.1990' then
  aDateDisassembleEnd:=frmMainRent.DateDisassembleOrdEnd.Text;

  dm.quWork.Close;
  dm.quWork.SQL.Text:='select n.vtpr, n.vkc, n.veiz, n.wtpr, n.wkc, '
  +'n.wkpr km, n.tnpr, n.weiz, s1.name nameed, n.wnorm, n.udvrs, n.koeffseb  '
  +' from r_nsinorm n '
  +' left join s_edin s1 on s1.codestr=n.weiz '
  +' where n.vkpr = '''
  +TProductComponent(SemifinishedList[SemifinishedList.Count-1]).Km+''''
  +' and n.vkc='''
  +TProductComponent(SemifinishedList[SemifinishedList.Count-1]).Kc+''''
  +' and n.tnpr=1';
  dm.quWork.Open;

    if not dm.quWork.IsEmpty then
    begin
      dm.quWork.First;
      while not dm.quWork.Eof do
      begin
        case dm.quWork.FieldByName('wtpr').AsInteger of
          2:  begin
              RubberMix:= TProductComponent.Create(
                dm.quWork.FieldByName('km').AsString,
                RoundTo(TProductComponent(SemifinishedList[
                  SemifinishedList.Count-1]).Amt
                  *dm.quWork.FieldByName('wnorm').AsFloat
                  *dm.quWork.FieldByName('koeffseb').AsFloat,-6),
                dm.quWork.FieldByName('weiz').AsString,
                dm.quWork.FieldByName('nameed').AsString,
                dm.quWork.FieldByName('wkc').AsString, 0, 0, 0, '');
              RubberMixList.Add(RubberMix);
              end;

          4:  begin
              cenm:=0;
              ShortDateFormat:='dd.mm.yyyy';

              s:='select first 1 cenm, eizm, dtndc  from r_cenmo where ';
              s:=s+' cenm<>0 and km='''+dm.quWork.FieldByName('km').AsString+'''';
              s:=s+' and date(nvl(dtndc,0)) <='''+aDateDisassembleBeg+'''';
              s:=s+' order by dtndc desc';
              dm.quWork2.Close;
              dm.quWork2.SQL.Text:=s;
              dm.quWork2.Open;

              cenm:=dm.quWork2.FieldByName('cenm').AsFloat;

              cenmNew:=0;
              s:='select first 1 cenm, eizm, dtndc  from r_cenmo where ';
              s:=s+' cenm<>0 and km='''+dm.quWork.FieldByName('km').AsString+'''';
              s:=s+' and date(nvl(dtndc,0)) <='''+aDateDisassembleEnd+'''';
              s:=s+' order by dtndc desc';
              dm.quWork2.Close;
              dm.quWork2.SQL.Text:=s;
              dm.quWork2.Open;
              cenmNew:=dm.quWork2.FieldByName('cenm').AsFloat;

              RawMaterial:= TProductComponent.Create(
                dm.quWork.FieldByName('km').AsString,
                RoundTo(TProductComponent(SemifinishedList[SemifinishedList.Count-1]).Amt
                  *dm.quWork.FieldByName('wnorm').AsFloat
                  *dm.quWork.FieldByName('koeffseb').AsFloat,-6),
                dm.quWork.FieldByName('weiz').AsString,
                dm.quWork.FieldByName('nameed').AsString,
                dm.quWork.FieldByName('wkc').AsString, cenm,
                RoundTo(TProductComponent(SemifinishedList[SemifinishedList.Count-1]).Amt
                  *dm.quWork.FieldByName('wnorm').AsFloat*cenm
                  *dm.quWork.FieldByName('koeffseb').AsFloat,-6), cenmNew, '');
              RawMaterialList.Add(RawMaterial);
              end;

          else {--} ;
        end;

        dm.quWork.Next;
      end;
    end;

  SemifinishedList.Remove(SemifinishedList[SemifinishedList.Count-1]);
  end;

end;

procedure TProcessOrder.MergeCodeList(aList: TList);
var i,j: integer;
begin
if aList.Count>0 then
  begin
  for i :=0  to aList.Count-1 do
    begin
    for j := aList.Count-1  downto i+1 do
      begin
      if (TProductComponent(aList[i]).Km = TProductComponent(aList[j]).Km)
        and (TProductComponent(aList[i]).Ed = TProductComponent(aList[j]).Ed)
      then
        begin
        TProductComponent(aList[i]).ComponentAmt:= TProductComponent(aList[i]).ComponentAmt +
          TProductComponent(aList[j]).ComponentAmt;
        aList.Remove(aList[j]);
        end;
      end;
    end;
  end;
end;

procedure TProcessOrder.RunOrderProcessing(aOrdNum:integer);
var s:string;
begin
  if RawMaterialList = nil then
  RawMaterialList:= TList.Create;
  RawMaterialList.Clear;

  if RubberMixList = nil then
  RubberMixList:= TList.Create;
  RubberMixList.Clear;

  if SemifinishedList = nil then
  SemifinishedList:= TList.Create;
  SemifinishedList.Clear;

  dm.quWork.Close;
  dm.quWork.SQL.Text:='select o.codetmc,o.ki,o.vi,o.kvc, t.sedin, o.amount, '
  +' o.price, o.price_kvart, o.kc, n.vtpr, n.vkc, n.veiz, n.wtpr, n.wkc, '
  +'n.wkpr, n.tnpr, n.weiz, s1.name nameed, n.wnorm, n.udvrs, n.koeffseb '
  +'from acyp_rent_om o '
  +'left join k_tmc t  on t.codetmc=o.codetmc '
  +'left join r_nsinorm n on o.ki=n.vkpr and o.vi=n.vvi and o.kvc=n.vc '
  +'left join s_edin s1 on s1.codestr=n.weiz '
  +'where n.tnpr=''1'' '
  +'and o.kc[1,4]=n.vkc '
  +'and o.ord_num='+IntToStr(aOrdNum);
  dm.quWork.Open;

  //–азбираем изделие по таблице с нормами (r_nsinorm) на рез.см., п/ф и сырье
  if not dm.quWork.IsEmpty then
  begin
    dm.quWork.First;
    while not dm.quWork.Eof do
    begin
      case dm.quWork.FieldByName('wtpr').AsInteger of
        //рез.см.
        2:  begin
            RubberMix:= TProductComponent.Create(
              dm.quWork.FieldByName('wkpr').AsString,
              RoundTo(dm.quWork.FieldByName('amount').AsFloat
                *dm.quWork.FieldByName('wnorm').AsFloat
                *dm.quWork.FieldByName('koeffseb').AsFloat,-6),
              dm.quWork.FieldByName('weiz').AsString,
              dm.quWork.FieldByName('nameed').AsString,
              dm.quWork.FieldByName('wkc').AsString, 0, 0, 0, '');
            RubberMixList.Add(RubberMix);
            end;
        //п/ф
        3:  begin
            Semifinished:= TProductComponent.Create(
              dm.quWork.FieldByName('wkpr').AsString,
              RoundTo(dm.quWork.FieldByName('amount').AsFloat
                *dm.quWork.FieldByName('wnorm').AsFloat
                *dm.quWork.FieldByName('koeffseb').AsFloat,-6),
              dm.quWork.FieldByName('weiz').AsString,
              dm.quWork.FieldByName('nameed').AsString,
              dm.quWork.FieldByName('wkc').AsString, 0, 0, 0, '');
            SemifinishedList.Add(Semifinished);
            end;
        //сырье
        4:  begin
            RawMaterial:= TProductComponent.Create(
              dm.quWork.FieldByName('wkpr').AsString,
              RoundTo(dm.quWork.FieldByName('amount').AsFloat
                *dm.quWork.FieldByName('wnorm').AsFloat
                *dm.quWork.FieldByName('koeffseb').AsFloat,-6),
              dm.quWork.FieldByName('weiz').AsString,
              dm.quWork.FieldByName('nameed').AsString,
              dm.quWork.FieldByName('wkc').AsString, 0, 0, 0, '');
            RawMaterialList.Add(RawMaterial);
            end;

        else {--} ;
      end;

      dm.quWork.Next;
    end;
  end;

  //–азбираем список рез.см. по таблице с нормами (r_normrs) на п/ф и сырье
  DisassembleRubberMix;

  //–азбираем список п/ф по таблице с нормами (r_nsinorm) на рез.см. и сырье
  DisassembleSemifinished;

  //–азбираем список рез.см. по таблице с нормами (r_normrs) на п/ф и сырье
  DisassembleRubberMix;

MergeCodeList(RawMaterialList);
MergeCodeList(RubberMixList);
MergeCodeList(SemifinishedList);

end;

{ TProductComponent }

constructor TProductComponent.Create(const ComponentKm: String;
  const ComponentAmt: Double; const ComponentEd: String; const ComponentNameEd:
  String; const ComponentKc: String;  const ComponentCenm: Currency; const
  ComponentSumma: Currency; const ComponentCenmNew: Currency;
  const ComponentNameM: String);
begin
  // —охранение переданных параметров
  self.ComponentKm   := ComponentKm;
  self.ComponentAmt   := ComponentAmt;
  self.ComponentEd   := ComponentEd;
  self.ComponentNameEd   := ComponentNameEd;
  self.ComponentKc   := ComponentKc;
  self.ComponentCenm   := ComponentCenm;
  self.ComponentSumma   := ComponentSumma;
  self.ComponentCenmNew   := ComponentCenmNew;
  self.ComponentNameM   := ComponentNameM;
end;

procedure TProcessOrder.SaveToFile(str: string);
var
 f:TextFile;
 FileDir:String;
begin
FileDir:=ExtractFilePath(Application.ExeName)+'TestProcessOrder.txt';
AssignFile(f,FileDir);
if not FileExists(FileDir) then
  begin
  Rewrite(f);
  CloseFile(f);
  end;
Append(f);
Writeln(f,str);
Flush(f);
CloseFile(f);
end;

end.
