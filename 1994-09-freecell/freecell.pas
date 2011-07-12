{FreeCell}
{Versao 1.0 - 23/7/94}
{Versao 1.1 - 24/7/94}
{- bug corrigido: cursor de mouse parado na tela inicial}
{- bug corrigido: nao atualiza o recorde na saida}
{- bug corrigido: nao aceita minusculas no recorde}
{- bug corrigido: entrada do recorde um espaco para a esquerda}
{Versao 1.1a - 27/7/94}
{- bug corrigido: cursor do mouse preso na tela}
{- bug corrigido: caracteres estranhos apos o relogio}
{- implementado: rotina de game over completa}
{- implementado: botao direito}
{Versao 1.1b - 28/7/94}
{- implementado: recorde grava o numero do jogo}
{- implementado: arrastar uma coluna inteira}
{Versao 1.1c - 31/7/94}
{- modificacao: melhor visualizacao em monitores monocromaticos}
{Versao 1.2 - 1/8/94}
{- bug corrigido: opcao procura destroi as cores das cartas}
{Versao 1.3 - 5/8/94}
{- modificacao: cartas ficam na parte superior da tela}
{Versao 1.3a - 6/8/94}
{- implementado: estatisticas}
{- implementado: shift como alternativa para o botao do meio}
{Versao 1.3b - 7/8/94}
{- bug corrigido: rotina YouLose acabava o jogo antes do tempo (122753293)}
{- implementado: switch /r - reset estatisticas}
{Versao 1.4 - 1/9/94}
{- implementado: botao direito+esquerdo=central para mouse de dois botoes}
{Versao 1.4a - 6/9/94}
{- bug corrigido: cartas se teleportam}

uses Crt,Dos,Mouse,Jogos;

{ Ouros=0; Espadas=1; Copas=2; Paus=3;
  Carta= (A=1),2,3,4,5,6,7,8,9,10,(J=11),(Q=12),(K=13)
  Formula= Naipe*13+(Carta-1)}

const
  Versao='1.4a';
  Data='6/9/94';
  Vazio=-1;
  Lim=6;
  mx=7;
  my=3;

type
  Coluna= record
            Elem: array [1..15] of integer;
            Tam: integer;
          end;
  Card= record
          x,y: integer;
          Save: array [0..mx,0..my] of Character;
        end;
  Ponto= record
           x,y: integer;
         end;
  DuasLetras= string[2];
  Recorde= record
             Nome: string;
             m,s: integer;
             Total,Vencidas,
             Jogo: longint;
           end;

var
  OldInt: pointer;                      {Antiga interrupcao}
  Rec: Recorde;                         {Recorde atual}
  Jogo: longint;                        {Numero do jogo}
  LastSeg,                              {Ultimo segundo}
  Min,Seg,                              {Minuto/Segundo do relogio}
  Menor: integer;                       {Menor valor da pilha}
  Tab: array [1..8] of Coluna;          {Cartas nas colunas}
  Cell: array [1..4] of integer;        {Espacos de troca}
  Stack: array [1..4] of integer;       {Pilha permanente de cartas}
  Deck: array [0..51] of Card;          {Tela embaixo das cartas}

function Numero (c: integer): DuasLetras;
begin
  c:=c mod 13+1;
  Numero[0]:=Chr (1);
  case c of
    2..9: Numero[1]:=Chr (c+48);
    1:    Numero[1]:='A';
    10:   Numero:='10';
    11:   Numero[1]:='J';
    12:   Numero[1]:='Q';
    13:   Numero[1]:='K';
  end;
end;

function Cor (c: integer): integer;
begin
  Cor:=(c div 13) mod 2;
end;

function Ultima (c: integer): integer;
begin
  Ultima:=Tab[c].Elem[Tab[c].Tam];
end;

function TimeToStr (m,s: integer): string;
var
  st1,st2: string;
begin
  Str (m:2,st1);
  Str (s:2,st2);
  if st2[1]=' ' then st2[1]:='0';
  TimeToStr:=st1+':'+st2;
end;

procedure Relogio; interrupt;
var
  sx,sy,sa: integer;
  h,m,s,d: word;
  st: string;
begin
  GetTime (h,m,s,d);
  if s<>LastSeg then begin
    LastSeg:=s;
    Inc (Seg);
    if Seg=60 then begin
      Seg:=0;
      Inc (Min);
    end;
    sx:=WhereX;
    sy:=WhereY;
    sa:=TextAttr;
    TextColor (Black);
    TextBackGround (LightGray);
    GotoXY (8,24);
    Str (Min:2,st);
    Write (st,':');
    Str (Seg:2,st);
    if st[1]=' ' then st[1]:='0';
    Write (st,'            ');
    GotoXY (sx,sy);
    TextAttr:=sa;
  end;
end;

procedure LigaInt;
begin
  SetIntVec ($1C,@Relogio);
end;

procedure DesligaInt;
begin
  SetIntVec ($1C,OldInt);
end;

function AnyShift: boolean;
var
  r: Registers;
begin
  r.ah:=$12;
  Intr ($16,r);
  AnyShift:=r.ax mod 4>0;
end;

procedure SaveCard (x,y,Carta: integer);
var
  i,j: integer;
begin
  for i:=0 to mx do
    for j:=0 to my do
      Deck[Carta].Save[i][j]:=AbScr[y+j][x+i];
  Deck[Carta].x:=x;
  Deck[Carta].y:=y;
end;

procedure LoadCard (Carta: integer);
var
  i,j: integer;
begin
  for i:=0 to mx do
    for j:=0 to my do
      AbScr[j+Deck[Carta].y][i+Deck[Carta].x]:=Deck[Carta].Save[i][j];
end;

procedure DrawCard (x,y,Carta: integer);
begin
  Janela (x,y,x+mx,y+my,LightGray,Black);
  if (Carta div 13) mod 2=0
    then TextColor (White)
    else TextColor (Brown);
  GotoXY (x+1,y);
  Write (Numero (Carta));
  GotoXY (x+4,y);
  case Carta div 13 of
    0: RealWrite (#4);
    1: RealWrite (#6);
    2: RealWrite (#3);
    3: RealWrite (#5);
  end;
  TextColor (LightGray);
end;

{Atencao: chamadas a MoveCard devem ser feitas com
          o cursor do mouse desligado.}
procedure MoveCard (cx,cy,Carta: integer);
begin
  LoadCard (Carta);
  SaveCard (cx,cy,Carta);
  DrawCard (cx,cy,Carta);
end;

procedure LongMoveCard (cx,cy,Carta: integer);
var
  p,dx,dy: real;
  ax,ay,sx,sy,i: integer;
begin
  sx:=Deck[Carta].x;
  sy:=Deck[Carta].y;
  dx:=cx-sx;
  dy:=cy-sy;
  p:=Sqrt (Sqr (dx)+Sqr (dy));
  if p=0 then p:=1;
  dx:=dx/p;
  dy:=dy/p;
  for i:=1 to Trunc (p) do begin
    ax:=Trunc (sx+i*dx);
    ay:=Trunc (sy+i*dy);
    if ax<1 then ax:=1;
    if ay<1 then ay:=1;
    MoveCard (ax,ay,Carta);
    Delay (10);
  end;
  MoveCard (cx,cy,Carta);
end;

procedure SetMouseWindow (Switch: boolean);
begin
  if Switch then begin
    MouseWindow (0,0,639,199);
    ShowCursor;
  end else begin
    MouseWindow (0,0,631-mx*8,182-my*8);
    HideCursor;
  end;
end;

procedure RealInit;
var
  OpcaoR,IsMouse: boolean;
  i,j,But: integer;
  f: file of Recorde;
  s: string;
begin
  OpcaoR:=false;
  if ParamCount>0 then
    for i:=1 to ParamCount do begin
      s:=ParamStr (i);
      for j:=1 to Length (s) do
        s[j]:=UpCase (s[j]);
      if Pos ('/R',s)>0 then OpcaoR:=true;
    end;
  Randomize;
  Jogo:=RandSeed;
  InitMouse (IsMouse,But);
  if not IsMouse then begin
    WriteLn ('Nao achei o mouse.');
    Halt (1);
  end;
  if ExisteArq ('FREECELL.HIG') then begin
    Assign (f,'FREECELL.HIG');
    Reset (f);
    Read (f,Rec);
    Close (f);
  end else begin
    Rec.Nome:='Anonimo';
    Rec.m:=99;
    Rec.s:=0;
    Rec.Jogo:=Jogo;
    Rec.Vencidas:=0;
    Rec.Total:=0;
  end;
  if OpcaoR then begin
    Rec.Total:=0;
    Rec.Vencidas:=0;
  end;
  Minusc:=true;
  GetIntVec ($1C,OldInt);
  Cursor (Off);
  SetMouseWindow (On);
end;

procedure WriteRecordes;
begin
  Inverse (On);
  GotoXY (1,25);
  Write ('Recorde: ',TimeToStr (Rec.m,Rec.s),' <- ',Rec.Nome);
  GotoXY (65,25);
  Write ('(',Rec.Jogo,')');
  Inverse (Off);
end;

procedure InitTab;
var
  i,j,c: integer;
  a: array [0..51] of boolean;
begin
  ClrScr;
  HideCursor;
  Inverse (On);
  for i:=1 to 80 do begin
    AbScr[25][i].a:=TextAttr;
    AbScr[24][i].a:=TextAttr;
  end;
  GotoXY (1,24);
  WriteLn ('Tempo: ');
  WriteRecordes;
  Menor:=-1;
  for i:=1 to 4 do begin
    Stack[i]:=Vazio;
    Cell[i]:=Vazio;
  end;
  for i:=0 to 51 do
    a[i]:=false;
  for i:=1 to 8 do begin
    Janela (i*10-9,1,i*10+mx-9,1+my,LightGray,Black);
    if i<5 then Janela (i*10-8,2,i*10+mx-10,my,LightGray,Black);
    Tab[i].Tam:=6+(i-1) div 4;
    for j:=1 to 15 do
      Tab[i].Elem[j]:=Vazio;
    for j:=1 to Tab[i].Tam do begin
      c:=Random (52);
      while a[c] do c:=(c+1) mod 52;
      a[c]:=true;
      Tab[i].Elem[j]:=c;
      SaveCard (i*10-9,Lim+j,c);
      DrawCard (i*10-9,Lim+j,c);
    end;
  end;
  Min:=0;
  Seg:=0;
  LigaInt;
end;

procedure Busca;
var
  c,i: integer;
  Existe: boolean;
begin
  repeat
    Existe:=false;
    for i:=1 to 8 do
      if Tab[i].Tam>0 then begin
        c:=Ultima (i);
        if c mod 13=Menor+1 then begin
          LongMoveCard (41+(c div 13)*10,1,c);
          Existe:=true;
          Stack[c div 13+1]:=c mod 13+1;
          Tab[i].Elem[Tab[i].Tam]:=Vazio;
          Dec (Tab[i].Tam);
        end;
      end;
    for i:=1 to 4 do
      if Cell[i] mod 13=Menor+1 then begin
        LongMoveCard (41+(Cell[i] div 13)*10,1,Cell[i]);
        Existe:=true;
        Stack[Cell[i] div 13+1]:=Cell[i] mod 13+1;
        Cell[i]:=Vazio;
      end;
    Menor:=13;
    for i:=1 to 4 do
      if Stack[i]<Menor then Menor:=Stack[i];
    if Menor>-1 then Dec (Menor);
  until not Existe;
end;

function GameOver: boolean;
begin
  if Stack[1]+Stack[2]+Stack[3]+Stack[4]=4*13
    then GameOver:=true
    else GameOver:=false;
end;

function Existe (Col,Carta: integer): boolean;
var
  i: integer;
begin
  for i:=1 to 8 do
    if (i<>Col) and
       (Cor (Carta)<>Cor (Tab[i].Elem[Tab[i].Tam])) and
       (Carta mod 13=Tab[i].Elem[Tab[i].Tam] mod 13-1) then
    begin
      Existe:=true;
      Exit;
    end;
  Existe:=false;
end;

function YouLose: boolean;
var
  i,j: integer;
begin
  {Verifica se algum cell esta vazio}
  for i:=1 to 4 do
    if Cell[i]=Vazio then begin
      YouLose:=false;
      Exit;
    end;
  {Verifica se alguma coluna esta vazia}
  for i:=1 to 8 do
    if Tab[i].Tam=0 then begin
      YouLose:=false;
      Exit;
    end;
  {Verifica se alguma coluna pode ir para o Stack}
  for i:=1 to 8 do
    if Ultima (i) mod 13=Stack[Ultima (i) div 13+1] then begin
      YouLose:=false;
      Exit;
    end;
  {Verifica se algum Cell pode ir para o Stack}
  for i:=1 to 4 do
    if Cell[i] mod 13=Stack[Cell[i] div 13+1] then begin
      YouLose:=false;
      Exit;
    end;
  {Verifica se algum Cell pode ir para uma coluna}
  for i:=1 to 4 do
    for j:=1 to 8 do
      if (Cell[i] mod 13=Ultima (j) mod 13-1) and
         (Cor (Cell[i])<>Cor (Ultima (j))) then
      begin
        YouLose:=false;
        Exit;
      end;
  {Verifica se alguma coluna pode ir para outra coluna}
  for i:=1 to 8 do
    for j:=1 to 8 do
      if (i<>j) and
         (Ultima (i) mod 13=Ultima (j) mod 13-1) and
         (Cor (Ultima (i))<>Cor (Ultima (j))) and
        {Verifica se existe loop}
         not ((Tab[i].Tam>1) and
           (Ultima (i) mod 13=Tab[i].Elem[Tab[i].Tam-1] mod 13-1) and
           (Cor (Ultima (i))<>Cor (Tab[i].Elem[Tab[i].Tam-1])) and
           (Tab[i].Elem[Tab[i].Tam-1] mod 13<>
            Stack[Tab[i].Elem[Tab[i].Tam-1] div 13+1]) and
            not Existe (i,Tab[i].Elem[Tab[i].Tam-1])) then
      begin
        YouLose:=false;
        Exit;
      end;
  YouLose:=true;
end;

procedure Limpa (col: integer);
begin
  if col<10 then begin
    Tab[col].Elem[Tab[col].Tam]:=Vazio;
    Dec (Tab[col].Tam);
  end else Cell[col-10]:=Vazio;
end;

procedure Procura;
var
  Waiting: boolean;
  t,c,i,j,cx,cy: integer;
  l: DuasLetras;
  a: array [1..4] of Ponto;
begin
  GetMouseXY (cx,cy);
  cx:=cx div 8+1;
  cy:=cy div 8+1;
  t:=0;
  c:=Vazio;
  for i:=1 to 8 do
    if (cy>Lim) and (cy<=Lim+Tab[i].Tam) and
       (cx>=i*10-9) and (cx<=i*10-10+mx) then c:=Tab[i].Elem[cy-Lim];
  if cy=1 then
    for i:=1 to 8 do
      if (cx>=i*10-9) and (cx<=i*10-10+mx) then
        if i<5
          then c:=Cell[i]
          else c:=Stack[i-4]-1;
  HideCursor;
  if c<>Vazio then begin
    t:=1;
    l:=Numero (c);
    for i:=1 to 80 do
      for j:=1 to 23 do
        if l[1]=AbScr[j][i].c then begin
          a[t].x:=i;
          a[t].y:=j;
          Inc (t);
          AbScr[j][i].a:=AbScr[j][i].a+Blink;
          if c mod 13+1=10 then AbScr[j][i+1].a:=AbScr[j][i+1].a+Blink;
        end;
  end;
  ShowCursor;
  Waiting:=true;
  while Waiting do
    Waiting:=CentralButton or AnyShift or LeftButton or RightButton;
  HideCursor;
  if t>0 then
    for i:=1 to t do begin
      AbScr[a[i].y][a[i].x].a:=AbScr[a[i].y][a[i].x].a-Blink;
      if c mod 13+1=10
        then AbScr[a[i].y][a[i].x+1].a:=AbScr[a[i].y][a[i].x+1].a-Blink;
    end;
  ShowCursor;
end;

function Arrasta (a,b: integer): boolean;
var
  c,i,Livres,Conta: integer;
  t,UpSpace: boolean;
begin
  Livres:=0;
  UpSpace:=false;
  for i:=1 to 4 do
    if Cell[i]=Vazio then begin
      Inc (Livres);
      UpSpace:=true;
    end;
  for i:=1 to 8 do
    if (Tab[i].Tam=0) and (i<>b) then Inc (Livres);
  Conta:=1;
  i:=Tab[a].Tam;
  while (i>0) and
        (Tab[a].Elem[i] mod 13=Tab[a].Elem[i-1] mod 13-1) and
        (Cor (Tab[a].Elem[i])<>Cor (Tab[a].Elem[i-1])) and not
        ((Tab[b].Tam>0) and
        (Tab[a].Elem[i] mod 13=Ultima (b) mod 13-1) and
        (Cor (Tab[a].Elem[i])<>Cor (Ultima (b)))) do
  begin
    Inc (Conta);
    Dec (i);
  end;
  if ((Conta>Livres+1) and (Tab[b].Tam>0)) or
     ((Tab[b].Tam>0) and not
     ((Tab[a].Elem[i] mod 13=Ultima (b) mod 13-1) and
     (Cor (Tab[a].Elem[i])<>Cor (Ultima (b))))) then
  begin
    Arrasta:=false;
    Exit;
  end;
  if Conta>Livres+1 then Conta:=1;
  c:=Ultima (a);
  if Conta=1 then begin
    Limpa (a);
    Inc (Tab[b].Tam);
    Tab[b].Elem[Tab[b].Tam]:=c;
    LongMoveCard (b*10-9,Lim+Tab[b].Tam,c);
  end else begin
    if UpSpace then begin
      i:=1;
      while Cell[i]<>Vazio do Inc (i);
      Limpa (a);
      Cell[i]:=c;
      LongMoveCard (i*10-9,1,c);
    end else begin
      i:=1;
      while (i=b) or (Tab[i].Tam>0) do Inc (i);
      Limpa (a);
      Inc (Tab[i].Tam);
      Tab[i].Elem[Tab[i].Tam]:=c;
      LongMoveCard (i*10-9,Lim+Tab[i].Tam,c);
    end;
    t:=Arrasta (a,b);
    if UpSpace then begin
      Cell[i]:=Vazio;
      Inc (Tab[b].Tam);
      Tab[b].Elem[Tab[b].Tam]:=c;
      LongMoveCard (b*10-9,Lim+Tab[b].Tam,c);
    end else begin
      Limpa (i);
      Inc (Tab[b].Tam);
      Tab[b].Elem[Tab[b].Tam]:=c;
      LongMoveCard (b*10-9,Lim+Tab[b].Tam,c);
    end;
  end;
  Arrasta:=true;
end;

procedure Main;
var
  cx,cy,p,col,lx,ly,sx,sy,i,c: integer;
  Temp,Manda,Mudei,Action,Peguei: boolean;
begin
  Busca;
  ShowCursor;
  repeat
    {Espera que apertem o botao do mouse}
    repeat
      Action:=LeftButton;
      if CentralButton or AnyShift then Procura;
      Manda:=RightButton;
      Temp:=Manda;
      while Temp do begin
        if LeftButton then Procura;
        Temp:=RightButton;
        Action:=false;
      end;
      GetMouseXY (cx,cy);
      cx:=cx div 8+1;
      cy:=cy div 8+1;
    until Action or Manda or KeyPressed;
    Peguei:=false;
    {Checa se pegou carta na coluna}
    for i:=1 to 8 do
      if Tab[i].Tam>0 then
        if ((cx>=i*10-9) and (cx<=i*10-10+mx) and
            (cy>=Lim+Tab[i].Tam) and (cy<=Lim+Tab[i].Tam+my)) then
        begin
          col:=i;
          c:=Ultima (i);
          sx:=Deck[c].x;
          sy:=Deck[c].y;
          lx:=sx;
          ly:=sy;
          Peguei:=true;
          SetMouseWindow (Off);
        end;
    {Checa se pegou carta do Cell}
    for i:=1 to 4 do
      if (Cell[i]<>Vazio) and (cx>=i*10-9) and
         (cx<=i*10-10+mx) and (cy<my+2) then
      begin
        col:=10+i;
        c:=Cell[i];
        sx:=Deck[c].x;
        sy:=Deck[c].y;
        lx:=sx;
        ly:=sy;
        Peguei:=true;
        SetMouseWindow (off);
      end;
    {Espera soltar o botao do mouse}
    Temp:=false;
    while Action and not Temp do begin
      Temp:=RightButton;
      if Temp then begin
        if Peguei then LongMoveCard (sx,sy,c);
        Procura;
      end;
      Action:=LeftButton;
      GetMouseXY (cx,cy);
      cx:=cx div 8+1;
      cy:=cy div 8+1;
      if (not Temp) and Peguei and ((lx<>cx) or (ly<>cy)) then begin
        MoveCard (cx,cy,c);
        lx:=cx;
        ly:=cy;
      end;
    end;
    {Caso tenha pego uma carta...}
    if Peguei and not Temp then begin
      Mudei:=false;
      p:=(cx+12) div 10;
      {Checa se foi colocada em uma coluna}
      if (cy>Lim-my) then
        if ((Tab[p].Tam>0) and
           (Ultima (p) mod 13=c mod 13+1) and
           (Cor (Ultima (p))<>Cor (c))) or
           ((Tab[p].Tam=0) and (col>=10))
        then begin
          Limpa (col);
          Inc (Tab[p].Tam);
          Tab[p].Elem[Tab[p].Tam]:=c;
          MoveCard (p*10-9,Lim+Tab[p].Tam,c);
          Mudei:=true;
        end else
          if (col<10) and (col<>p) and Arrasta (col,p) then
            Mudei:=true;
      {Checa se foi colocada em um Cell}
      if (cy<my+2) and (cx<=30+mx) and (Cell[p]=Vazio) then begin
        Limpa (col);
        Cell[p]:=c;
        MoveCard (p*10-9,1,c);
        Mudei:=true;
      end;
      {Checa se foi colocada no Stack}
      if (((cy<my+2) and (cx>30+mx)) or Manda) and
         (Stack[c div 13+1]=c mod 13)
      then begin
        Limpa (col);
        Stack[c div 13+1]:=c mod 13+1;
        LongMoveCard ((c div 13+5)*10-9,1,c);
        Mudei:=true;
      end;
      if not Mudei then LongMoveCard (sx,sy,c);
    end;
    {Verifica se alguma carta deve ir para o Stack automaticamente}
    Busca;
    SetMouseWindow (On);
  until KeyPressed or GameOver or YouLose;
end;

procedure Done;
var
  c: char;
  f: file of Recorde;
begin
  DesligaInt;
  HideCursor;
  GotoXY (30,24);
  Inverse (On);
  Inc (Rec.Total);
  if GameOver
    then begin
      Write ('Voce venceu ');
      Inc (Rec.Vencidas);
      if (Min<Rec.m) or ((Min=Rec.m) and (Seg<Rec.s)) then begin
        Write ('e bateu o recorde !');
        Rec.m:=Min;
        Rec.s:=Seg;
        Rec.Jogo:=Jogo;
        WriteRecordes;
        Recebe (19,25,40,White,LightGray,Black,LightGray,Rec.Nome);
      end else Write ('!');
    end else if YouLose
      then Write ('Voce perdeu !')
      else Write ('Voce desistiu !');
  Inverse (Off);
  while KeyPressed do c:=ReadKey;
  WaitForKey;
  Cursor (On);
  Assign (f,'FREECELL.HIG');
  ReWrite (f);
  Write (f,Rec);
  Close (f);
  ClrScr;
  WriteLn ('FreeCell - by Ricardo Bittencourt Vidigal Leitao');
  WriteLn ('Versao: ',Versao);
  WriteLn ('Data: ',Data);
  WriteLn ('Numero do jogo: ',Jogo);
  WriteLn ('Total de partidas jogadas: ',Rec.Total);
  WriteLn ('Total de partidas vencidas: ',Rec.Vencidas);
  WriteLn ('Porcentagem de vitorias: ',Rec.Vencidas/Rec.Total*100:0:2,'%');
end;

begin
  RealInit;
  InitTab;
  Main;
  Done;
end.

