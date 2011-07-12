{$M 32000,0,655360}

USES CRT,DOS,JOGOS;

CONST
  J1='JOGADOR 1 (X)';
  J2='JOGADOR 2 (O)';
  X1=15-LENGTH (J1) DIV 2;
  X2=65-LENGTH (J2) DIV 2;

TYPE
  TIMP= (INV,NOR,LIG);
  QUAD= (XX,OO,NADA,MARCA);
  OPERACAO= (MOSTRAR,CHECAR,PENSAR,Avaliar,Calcular);
  T1D= ARRAY [1..4] OF QUAD;
  T2D= ARRAY [1..4] OF T1D;
  T3D= ARRAY [1..4] OF T2D;
  T4D= ARRAY [1..4] OF T3D;
  pt4d= ^t4d;
  PLista= ^TLista;
  TLista= record
            Mat: array [1..4] of integer;
            Tipo: Quad;
            Prox: PLista;
          end;
  Sequencias= (Fica,Sobe,Desce);
  PJogo= ^TJogo;
  TJogo= record
            Mat: array [1..4] of Sequencias;
            Tipo: Quad;
            Prox: PLista;
          end;

VAR
  TAB: T4D;
  SX,SY,SZ,ST,LRX,LRY,PRX,PRY,PX,PY,PZ,PT: BYTE;
  VEZ: QUAD;
  AJX,AJO,GAMEOVER: BOOLEAN;
  Pont,Lista: PLista;
  RamTop: pointer;
  ValTab,Cont: integer;

PROCEDURE INITQUADRO;
VAR
  X,Y,Z,T: BYTE;
BEGIN
  FOR X:=1 TO 4 DO
    FOR Y:=1 TO 4 DO
      FOR Z:=1 TO 4 DO
        FOR T:=1 TO 4 DO
          TAB[X,Y,Z,T]:=NADA;
END;

PROCEDURE SETCOLOR (B: TIMP);
BEGIN
  CASE B OF
    INV: INVERSE (ON);
    NOR: INVERSE (OFF);
    LIG: LIGHT (ON);
  END;
END;

PROCEDURE IMPUM (X,Y,Z,T: BYTE; B: TIMP);
VAR
  S: BYTE;
BEGIN
  S:=TEXTATTR;
  SETCOLOR (B);
  GOTOXY (25+x+Z*5,Y+t*5-2);
  CASE TAB[X,Y,Z,T] OF
    XX: REALWRITE ('X');
    OO: REALWRITE ('O');
    NADA: REALWRITE (#250);
    MARCA: REALWRITE (#7);
  END;
  TEXTATTR:=S;
END;

PROCEDURE IMPTUDO;
VAR
  X,Y,Z,T: BYTE;
BEGIN
  FOR X:=1 TO 4 DO
    FOR Y:=1 TO 4 DO
      FOR Z:=1 TO 4 DO
        FOR T:=1 TO 4 DO
          IMPUM (X,Y,Z,T,NOR);
END;

PROCEDURE JOGADOR (N: BYTE; B: BOOLEAN);
BEGIN
  LIGHT (B);
  IF N=1 THEN BEGIN
    GOTOXY (X1,3);
    WRITE (J1);
  END ELSE BEGIN
    GOTOXY (X2,3);
    WRITE (J2);
  END;
END;

PROCEDURE IMPAJUDA (N: BYTE);
VAR
  AJ: STRING;
  B: BOOLEAN;
  X: BYTE;
BEGIN
  LIGHT (OFF);
  AJ:='AJUDA: ';
  IF N=1 THEN B:=AJX ELSE B:=AJO;
  IF B THEN AJ:=AJ+'SIM' ELSE AJ:=AJ+'NAO';
  IF N=1 THEN X:=15 ELSE X:=65;
  GOTOXY (X-LENGTH (AJ) DIV 2,22);
  WRITE (AJ);
END;

PROCEDURE INITVIDEO;
VAR
  S1,S2,S3: STRING;
  N: BYTE;

  PROCEDURE LINHA (Y: BYTE);
  VAR
    N: BYTE;
  BEGIN
    FOR N:=Y TO Y+3 DO BEGIN
      GOTOXY (30,N);
      WRITE (S2);
    END;
  END;

BEGIN
  INVERSE (OFF);
  CLRSCR;
  CURSOR (OFF);
  IMPSTATUS ('JOGO DA VELHA 4D - BY RICARDO BITTENCOURT',1);
  S1:=SEQ (ESP,4);
  S2:=SEQ (#179+S1,4)+#179;
  S3:=SEQ (#196,4);
  GOTOXY (30,3);
  WRITE (#218,SEQ (S3+#194,3),S3,#191);
  FOR N:=1 TO 3 DO BEGIN
    LINHA (N*5-1);
    GOTOXY (30,N*5+3);
    WRITE (#195,SEQ (S3+#197,3),S3,#180);
  END;
  LINHA (19);
  GOTOXY (30,23);
  WRITE (#192,SEQ (S3+#193,3),S3,#217);
  IMPTUDO;
  FOR N:=1 TO 2 DO BEGIN
    JOGADOR (N,OFF);
    IMPAJUDA (N);
  END;
END;

PROCEDURE INITVARS;
BEGIN
  PX:=1;
  PY:=1;
  PZ:=1;
  PT:=1;
  PRX:=0;
  PRY:=0;
  LRX:=255;
  LRY:=255;
  SX:=255;
  SY:=255;
  SZ:=255;
  ST:=255;
  VEZ:=XX;
  GAMEOVER:=FALSE;
  Lista:=nil;
  Pont:=nil;
  Mark (RamTop);
END;

FUNCTION AJUDA (V: QUAD; OP: OPERACAO; var Tab: t4d): QUAD;
VAR
  X,Y,Z,T: BYTE;

  PROCEDURE Conta (X1,Y1,Z1,T1,X2,Y2,Z2,T2,X3,Y3,Z3,T3,X4,Y4,Z4,T4: BYTE);
  var
    nx,no,nb,neu,nele: integer;
  begin
    nx:=0;
    no:=0;
    nb:=0;
    case Tab[x1,y1,z1,t1] of
      XX: Inc (nx);
      OO: Inc (no);
      else Inc (nb);
    end;
    case Tab[x2,y2,z2,t2] of
      XX: Inc (nx);
      OO: Inc (no);
      else Inc (nb);
    end;
    case Tab[x3,y3,z3,t3] of
      XX: Inc (nx);
      OO: Inc (no);
      else Inc (nb);
    end;
    case Tab[x4,y4,z4,t4] of
      XX: Inc (nx);
      OO: Inc (no);
      else Inc (nb);
    end;
    if nb=4 then Exit;
    if nx+nb=4 then begin
      case nx of
        1: Dec (ValTab,1);
        2: Dec (ValTab,10);
        3: Dec (ValTab,4000);
        else ValTab:=-20000;
      end;
      Exit;
    end;
    if no+nb=4 then begin
      case no of
        1: Inc (ValTab,1);
        2: Inc (ValTab,10);
        3: Inc (ValTab,1000);
        else ValTab:=20000;
      end;
    end;
  end;

  PROCEDURE Evaluate (X1,Y1,Z1,T1,X2,Y2,Z2,T2,X3,Y3,Z3,T3,X4,Y4,Z4,T4: BYTE);
  begin
    IF (TAB[X1,Y1,Z1,T1] IN [XX,OO]) AND
       (TAB[X1,Y1,Z1,T1]=TAB[X2,Y2,Z2,T2]) AND
       (TAB[X2,Y2,Z2,T2]=TAB[X3,Y3,Z3,T3]) AND
       (TAB[X3,Y3,Z3,T3]=TAB[X4,Y4,Z4,T4])
    THEN Ajuda:=Tab[x1,y1,z1,t1];
  end;

  PROCEDURE MOSTRA (X1,Y1,Z1,T1,X2,Y2,Z2,T2,X3,Y3,Z3,T3,X4,Y4,Z4,T4: BYTE);
  BEGIN
    IF (TAB[X1,Y1,Z1,T1] IN [XX,OO]) AND
       (TAB[X1,Y1,Z1,T1]=TAB[X2,Y2,Z2,T2]) AND
       (TAB[X2,Y2,Z2,T2]=TAB[X3,Y3,Z3,T3]) AND
       (TAB[X3,Y3,Z3,T3]=TAB[X4,Y4,Z4,T4])
    THEN BEGIN
      IMPUM (PX,PY,PZ,PT,NOR);
      IMPUM (X1,Y1,Z1,T1,LIG);
      IMPUM (X2,Y2,Z2,T2,LIG);
      IMPUM (X3,Y3,Z3,T3,LIG);
      IMPUM (X4,Y4,Z4,T4,LIG);
      GAMEOVER:=TRUE;
      AJUDA:=TAB[X1,Y1,Z1,T1];
    END;
  END;

  PROCEDURE CHECA (X1,Y1,Z1,T1,X2,Y2,Z2,T2,X3,Y3,Z3,T3,X4,Y4,Z4,T4: BYTE);
  VAR
    E,S: BYTE;
    B: BOOLEAN;
    Q: QUAD;
  BEGIN
    S:=0;
    E:=0;
    IF TAB[X1,Y1,Z1,T1]=V THEN INC (S);
    IF TAB[X2,Y2,Z2,T2]=V THEN INC (S,2);
    IF TAB[X3,Y3,Z3,T3]=V THEN INC (S,4);
    IF TAB[X4,Y4,Z4,T4]=V THEN INC (S,8);
    IF TAB[X1,Y1,Z1,T1] IN [NADA,MARCA] THEN INC (E);
    IF TAB[X2,Y2,Z2,T2] IN [NADA,MARCA] THEN INC (E,2);
    IF TAB[X3,Y3,Z3,T3] IN [NADA,MARCA] THEN INC (E,4);
    IF TAB[X4,Y4,Z4,T4] IN [NADA,MARCA] THEN INC (E,8);
    IF V=XX THEN B:=AJX ELSE B:=AJO;
    IF B THEN Q:=MARCA ELSE Q:=NADA;
    IF (S+E<>15) OR (E=15) THEN EXIT;
    IF NOT (E IN [1,2,4,8]) THEN EXIT;
    IMPUM (PX,PY,PZ,PT,NOR);
    CASE E OF
      1: TAB[X1,Y1,Z1,T1]:=Q;
      2: TAB[X2,Y2,Z2,T2]:=Q;
      4: TAB[X3,Y3,Z3,T3]:=Q;
      8: TAB[X4,Y4,Z4,T4]:=Q;
    END;
    IF OP=CHECAR THEN BEGIN
      IMPUM (X1,Y1,Z1,T1,NOR);
      IMPUM (X2,Y2,Z2,T2,NOR);
      IMPUM (X3,Y3,Z3,T3,NOR);
      IMPUM (X4,Y4,Z4,T4,NOR);
    END;
    AJUDA:=OO;
  END;

  PROCEDURE VERIFICA (X1,Y1,Z1,T1,X2,Y2,Z2,T2,X3,Y3,Z3,T3,X4,Y4,Z4,T4: BYTE);
  BEGIN
    CASE OP OF
      Calcular: Conta (X1,Y1,Z1,T1,X2,Y2,Z2,T2,X3,Y3,Z3,T3,X4,Y4,Z4,T4);
      MOSTRAR:  MOSTRA (X1,Y1,Z1,T1,X2,Y2,Z2,T2,X3,Y3,Z3,T3,X4,Y4,Z4,T4);
      else      CHECA (X1,Y1,Z1,T1,X2,Y2,Z2,T2,X3,Y3,Z3,T3,X4,Y4,Z4,T4);
    END;
  END;

BEGIN
  AJUDA:=NADA;
  ValTab:=0;
  FOR T:=1 TO 4 DO
    FOR Z:=1 TO 4 DO
      FOR X:=1 TO 4 DO
           VERIFICA (X,1,Z,T,X,2,Z,T,X,3,Z,T,X,4,Z,T);
  FOR T:=1 TO 4 DO
    FOR Z:=1 TO 4 DO
      FOR Y:=1 TO 4 DO
           VERIFICA (1,Y,Z,T,2,Y,Z,T,3,Y,Z,T,4,Y,Z,T);
  FOR X:=1 TO 4 DO
    FOR Z:=1 TO 4 DO
      FOR Y:=1 TO 4 DO
           VERIFICA (X,Y,Z,1,X,Y,Z,2,X,Y,Z,3,X,Y,Z,4);
  FOR T:=1 TO 4 DO
    FOR X:=1 TO 4 DO
      FOR Y:=1 TO 4 DO
           VERIFICA (X,Y,1,T,X,Y,2,T,X,Y,3,T,X,Y,4,T);
  FOR T:=1 TO 4 DO
    FOR Z:=1 TO 4 DO BEGIN
      VERIFICA (1,1,Z,T,2,2,Z,T,3,3,Z,T,4,4,Z,T);
      VERIFICA (4,1,Z,T,3,2,Z,T,2,3,Z,T,1,4,Z,T);
    END;
  FOR T:=1 TO 4 DO
    FOR Y:=1 TO 4 DO BEGIN
      VERIFICA (1,Y,1,T,2,Y,2,T,3,Y,3,T,4,Y,4,T);
      VERIFICA (4,Y,1,T,3,Y,2,T,2,Y,3,T,1,Y,4,T);
    END;
  FOR X:=1 TO 4 DO
    FOR Z:=1 TO 4 DO BEGIN
      VERIFICA (X,1,Z,1,X,2,Z,2,X,3,Z,3,X,4,Z,4);
      VERIFICA (X,4,Z,1,X,3,Z,2,X,2,Z,3,X,1,Z,4);
    END;
  FOR Z:=1 TO 4 DO
    FOR Y:=1 TO 4 DO BEGIN
      VERIFICA (1,Y,Z,1,2,Y,Z,2,3,Y,Z,3,4,Y,Z,4);
      VERIFICA (1,Y,Z,4,2,Y,Z,3,3,Y,Z,2,4,Y,Z,1);
    END;
  FOR X:=1 TO 4 DO
    FOR Y:=1 TO 4 DO BEGIN
      VERIFICA (X,Y,1,1,X,Y,2,2,X,Y,3,3,X,Y,4,4);
      VERIFICA (X,Y,1,4,X,Y,2,3,X,Y,3,2,X,Y,4,1);
    END;
  FOR X:=1 TO 4 DO
    FOR T:=1 TO 4 DO BEGIN
      VERIFICA (X,1,1,T,X,2,2,T,X,3,3,T,X,4,4,T);
      VERIFICA (X,4,1,T,X,3,2,T,X,2,3,T,X,1,4,T);
    END;
  FOR X:=1 TO 4 DO BEGIN
    VERIFICA (X,1,1,1,X,2,2,2,X,3,3,3,X,4,4,4);
    VERIFICA (X,4,1,4,X,3,2,3,X,2,3,2,X,1,4,1);
    VERIFICA (X,1,1,4,X,2,2,3,X,3,3,2,X,4,4,1);
    VERIFICA (X,4,1,1,X,3,2,2,X,2,3,3,X,1,4,4);
  END;
  FOR Y:=1 TO 4 DO BEGIN
    VERIFICA (1,Y,1,1,2,Y,2,2,3,Y,3,3,4,Y,4,4);
    VERIFICA (4,Y,4,1,3,Y,3,2,2,Y,2,3,1,Y,1,4);
    VERIFICA (4,Y,1,1,3,Y,2,2,2,Y,3,3,1,Y,4,4);
    VERIFICA (1,Y,4,1,2,Y,3,2,3,Y,2,3,4,Y,1,4);
  END;
  FOR Z:=1 TO 4 DO BEGIN
    VERIFICA (1,1,Z,1,2,2,Z,2,3,3,Z,3,4,4,Z,4);
    VERIFICA (1,4,Z,4,2,3,Z,3,3,2,Z,2,4,1,Z,1);
    VERIFICA (1,4,Z,1,2,3,Z,2,3,2,Z,3,4,1,Z,4);
    VERIFICA (1,1,Z,4,2,2,Z,3,3,3,Z,2,4,4,Z,1);
  END;
  FOR T:=1 TO 4 DO BEGIN
    VERIFICA (1,1,1,T,2,2,2,T,3,3,3,T,4,4,4,T);
    VERIFICA (1,4,1,T,2,3,2,T,3,2,3,T,4,1,4,T);
    VERIFICA (4,4,1,T,3,3,2,T,2,2,3,T,1,1,4,T);
    VERIFICA (4,1,1,T,3,2,2,T,2,3,3,T,1,4,4,T);
  END;
  VERIFICA (1,4,1,4,2,3,2,3,3,2,3,2,4,1,4,1);
  VERIFICA (1,4,4,1,2,3,3,2,3,2,2,3,4,1,1,4);
  VERIFICA (1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4);
  VERIFICA (4,4,1,1,3,3,2,2,2,2,3,3,1,1,4,4);
  VERIFICA (1,1,1,4,2,2,2,3,3,3,3,2,4,4,4,1);
  VERIFICA (4,4,1,4,3,3,2,3,2,2,3,2,1,1,4,1);
  VERIFICA (4,1,1,1,3,2,2,2,2,3,3,3,1,4,4,4);
  VERIFICA (1,4,1,1,2,3,2,2,3,2,3,3,4,1,4,4);
END;

PROCEDURE GANHOU;
CONST
  V='VENCEDOR';
  X1=15-LENGTH (V) DIV 2;
  X2=65-LENGTH (V) DIV 2;
BEGIN
  IF VEZ=XX THEN GOTOXY (X2,8) ELSE GOTOXY (X1,8);
  PISCA (ON);
  WRITE (V);
END;

PROCEDURE LASTKEY;
VAR
  X,Y,Z,T: BYTE;
BEGIN
  IF SX=255 THEN EXIT;
  IMPUM (SX,SY,SZ,ST,LIG);
  WAITFORKEY;
  IMPUM (SX,SY,SZ,ST,NOR);
END;

PROCEDURE DESISTIU;
CONST
  DES='DESISTIU';
VAR
  X: BYTE;
BEGIN
  IF VEZ=XX THEN X:=15 ELSE X:=65;
  LIGHT (OFF);
  PISCA (ON);
  GOTOXY (X-LENGTH (DES) DIV 2,8);
  WRITE (DES);
END;

{true=max; false=min}
procedure Pensa;
const
  NivelRec=2;
var
  jx,jy,jz,jt,Val: integer;
  Temp: Quad;

  function MiniMax (Tab: t4d; Inte: boolean; Recursao: integer): integer;
  var
    Primeiro: boolean;
    x,y,z,t,at,s: integer;
  begin
{    Inc (Cont);
    GotoXY (1,5);
    WriteLn (Cont);}
    Primeiro:=true;
    if Recursao=NivelRec then begin
      Temp:=Ajuda (XX,Calcular,Tab);
      MiniMax:=ValTab;
{      GotoXy (1,6);
      WriteLn (ValTab,'  ');}
      Exit;
    end;
    for x:=1 to 4 do
      for y:=1 to 4 do
        for z:=1 to 4 do
          for t:=1 to 4 do
            if Tab[x,y,z,t]=Nada then begin
              if Inte
                then Tab[x,y,z,t]:=OO
                else Tab[x,y,z,t]:=XX;
              s:=MiniMax (Tab,not Inte,Recursao+1);
              if Primeiro then begin
                at:=s;
                jx:=x;
                jy:=y;
                jz:=z;
                jt:=t;
                Primeiro:=false;
              end else begin
                if Inte and (s>at) then begin
                  at:=s;
                  jx:=x;
                  jy:=y;
                  jz:=z;
                  jt:=t;
                end;
                if not Inte and (s<at) then begin
                  at:=s;
                  jx:=x;
                  jy:=y;
                  jz:=z;
                  jt:=t;
                end;
              end;
              Tab[x,y,z,t]:=Nada;
            end;
{    GotoXY (1,6);
    Write (at,'  ');}
    MiniMax:=at;
  end;

begin
  Cont:=0;
  ImpUm (px,py,pz,pt,Nor);
  GotoXY (60,10);
  Light (Off);
  Write ('Pensando...');
  for jx:=1 to 4 do
    for jy:=1 to 4 do
      for jz:=1 to 4 do
        for jt:=1 to 4 do
          if Tab[jx,jy,jz,jt]=Marca then Tab[jx,jy,jz,jt]:=Nada;
  Val:=MiniMax (Tab,true,1);
  px:=jx;
  py:=jy;
  pz:=jz;
  pt:=jt;
  prx:=(px-1)+(pz-1)*4;
  pry:=(py-1)+(pt-1)*4;
  GotoXy (60,10);
  Write ('              ');
{  GotoXY (1,10);
  WriteLn ('Valor alcancado: ',Val,'   ');
  WriteLn ('Posicao escolhida: [',px,',',py,',',pz,',',pt,']');}
end;

procedure MostraJogadas;
var
  SaveTela: ScreenType;
  p: PLista;
begin
  SaveTela:=AbScr;
  ClrScr;
  p:=Lista;
  while p<>nil do begin
    Write ('Posicao [',p^.Mat[1],',',p^.Mat[2],',',
           p^.Mat[3],',',p^.Mat[4],']:=');
    if p^.Tipo=XX
      then WriteLn ('XX')
      else WriteLn ('OO');
    p:=p^.Prox;
  end;
  WaitForKey;
  AbScr:=SaveTela;
end;

PROCEDURE JOGA;
VAR
  T: CHAR;
  Q: QUAD;
BEGIN
  REPEAT
    IF VEZ=XX THEN JOGADOR (1,ON) ELSE JOGADOR (2,ON);
    IF VEZ=OO THEN PENSA;
    IMPUM (PX,PY,PZ,PT,INV);
    IF VEZ=XX THEN T:=READKEY ELSE T:=CR;
    IF T=#0 THEN CASE READKEY OF
      UP: DEC (PRY);
      DOWN: INC (PRY);
      LEFT: DEC (PRX);
      RIGHT: INC (PRX);
      F1: LASTKEY;
      F2: BEGIN
            IF AJX THEN AJX:=FALSE ELSE AJX:=TRUE;
            IMPAJUDA (1);
            Q:=AJUDA (XX,CHECAR,Tab);
          END;
      F3: BEGIN
            IF AJO THEN AJO:=FALSE ELSE AJO:=TRUE;
            IMPAJUDA (2);
            Q:=AJUDA (OO,CHECAR,Tab);
          END;
      F4: MostraJogadas;
    END;
    IF (LRY<>PRY) OR (LRX<>PRX) THEN BEGIN
      IF PRY=255 THEN PRY:=15;
      IF PRY=16 THEN PRY:=0;
      IF PRX=255 THEN PRX:=15;
      IF PRX=16 THEN PRX:=0;
      IMPUM (PX,PY,PZ,PT,NOR);
      PX:=PRX MOD 4+1;
      PZ:=PRX DIV 4+1;
      PY:=PRY MOD 4+1;
      PT:=PRY DIV 4+1;
    END;
    IF (T IN [CR,ESP]) AND (TAB [PX,PY,PZ,PT] IN [NADA,MARCA]) THEN BEGIN
      TAB [PX,PY,PZ,PT]:=VEZ;
      if Lista=nil then begin
        New (Lista);
        Pont:=Lista;
      end else begin
        New (Pont^.Prox);
        Pont:=Pont^.Prox;
      end;
      Pont^.Mat[1]:=px;
      Pont^.Mat[2]:=py;
      Pont^.Mat[3]:=pz;
      Pont^.Mat[4]:=pt;
      Pont^.Tipo:=Vez;
      Pont^.Prox:=nil;
      SX:=PX;
      SY:=PY;
      SZ:=PZ;
      ST:=PT;
      IF AJX THEN Q:=AJUDA (XX,CHECAR,Tab);
      IF AJO THEN Q:=AJUDA (OO,CHECAR,Tab);
      IF VEZ=XX THEN BEGIN
        VEZ:=OO;
        JOGADOR (1,OFF);
      END ELSE BEGIN
        VEZ:=XX;
        JOGADOR (2,OFF);
      END;
      IF AJUDA (NADA,MOSTRAR,Tab)<>NADA THEN GANHOU;
    END;
    LRX:=PRX;
    LRY:=PRY;
  UNTIL (T=ESC) OR GAMEOVER;
  IF T=ESC THEN DESISTIU;
END;

PROCEDURE FINAL;
BEGIN
  INVERSE (OFF);
  CURSOR (ON);
  CLRSCR;
END;

PROCEDURE REALINIT;
BEGIN
  AJX:=OFF;
  AJO:=OFF;
END;

BEGIN
  REALINIT;
  REPEAT
    INITQUADRO;
    INITVARS;
    INITVIDEO;
    JOGA;
    IMPSTATUS ('[RETURN] NOVAMENTE / [ESC] SAI',24);
    Release (RamTop);
  UNTIL READKEY=ESC;
  FINAL;
END.
