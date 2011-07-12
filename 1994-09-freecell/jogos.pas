UNIT JOGOS;

INTERFACE

  USES CRT,DOS,PRINTER;

  CONST
    ON=TRUE;
    OFF=FALSE;
    ESP=#32;
    CR=#13;
    ESC=#27;
    BS=#8;
    UP=#72;
    DOWN=#80;
    LEFT=#75;
    RIGHT=#77;
    F1=#59;
    F2=#60;
    F3=#61;
    F4=#62;
    INTREL=$1C;
    NUL=#0#0#0#27;
    NULN=$FFFFF;

  TYPE
    OPCAO= STRING[40];
    MENUL= ^MENUOP;
    MENUOP= RECORD
              S: OPCAO;
              PROX: MENUL;
            END;
    WEEKDAY= (DOM,SEG,TER,QUA,QUI,SEX,SAB);
    CHARACTER= RECORD
                 C: CHAR;
                 A: BYTE;
               END;
    LINHATYPE= ARRAY [1..80] OF CHARACTER;
    SCREENTYPE= ARRAY [1..25] OF LINHATYPE;

  VAR
    MENUSN: MENUL;
    ABSCR: SCREENTYPE ABSOLUTE $B800:0;
    MINUSC: BOOLEAN;

  PROCEDURE INVERSE (X: BOOLEAN);

  PROCEDURE LIGHT (X: BOOLEAN);

  PROCEDURE PISCA (X: BOOLEAN);

  PROCEDURE IMPSTATUS (S: STRING; Y: BYTE);

  PROCEDURE WAITFORKEY;

  PROCEDURE CURSOR (B: BOOLEAN);

  PROCEDURE JANELA (X1,Y1,X2,Y2,I,P: BYTE);

  PROCEDURE CLOCK (X,Y,M,S: BYTE);

  PROCEDURE INCREL (VAR M,S: BYTE);

  PROCEDURE SETATTR (X,Y,I,P: BYTE);

  PROCEDURE SETATTRW (X1,Y1,X2,Y2,I,P: BYTE);

  PROCEDURE REALWRITE (C: CHAR);

  PROCEDURE INSMENUOP (N: OPCAO; VAR M: MENUL);

  PROCEDURE MENSAGEM (S: STRING; X,Y,I,P: BYTE);

  PROCEDURE RECEBE (X,Y,T,I1,P1,I2,P2: BYTE; VAR S: STRING);

  PROCEDURE RECEBEN (X,Y,T,I1,P1,I2,P2: BYTE; VAR N: LONGINT);

  PROCEDURE CLEARWINDOW (X1,Y1,X2,Y2: BYTE);

  FUNCTION CHECKPRINTER: BOOLEAN;

  FUNCTION INTPOWER (N,P: INTEGER): INTEGER;

  FUNCTION BIT (A,N: BYTE): BYTE;

  FUNCTION MENU (M: MENUL; TIT: OPCAO; X,Y,IC,PC,IB,PB: BYTE): WORD;

  FUNCTION GETATTR (X,Y: BYTE): BYTE;

  FUNCTION CENT (S: STRING): BYTE;

  FUNCTION SEQ (C: STRING; N: BYTE): STRING;

  FUNCTION EXISTEARQ (S: STRING): BOOLEAN;

  FUNCTION ASTR (N: LONGINT): STRING;

  FUNCTION WEEK (D,M,A: WORD): WEEKDAY;

  FUNCTION MAXDAYS (M,A: WORD): BYTE;

  FUNCTION HEXA (A: BYTE): STRING;

IMPLEMENTATION

  VAR
    CURSAT: BOOLEAN;

  PROCEDURE INVERSE;
  BEGIN
    IF X THEN BEGIN
      TEXTCOLOR (BLACK);
      TEXTBACKGROUND (LIGHTGRAY);
    END ELSE BEGIN
      TEXTCOLOR (LIGHTGRAY);
      TEXTBACKGROUND (BLACK);
    END;
  END;

  PROCEDURE LIGHT;
  BEGIN
    IF X THEN BEGIN
      TEXTCOLOR (WHITE);
      TEXTBACKGROUND (BLACK);
    END ELSE BEGIN
      TEXTCOLOR (LIGHTGRAY);
      TEXTBACKGROUND (BLACK);
    END;
  END;

  PROCEDURE PISCA;
  BEGIN
    IF X THEN TEXTATTR:=TEXTATTR OR BLINK
         ELSE TEXTATTR:=TEXTATTR AND (NOT (BLINK));
  END;

  FUNCTION CENT;
  BEGIN
    CENT:=40-LENGTH (S) DIV 2;
  END;

  PROCEDURE CLOCK;
  VAR
    ST: STRING[3];
  BEGIN
    STR (M:2,ST);
    GOTOXY (X,Y);
    WRITE (ST,':');
    STR (S:2,ST);
    IF S<10 THEN ST:='0'+COPY (ST,2,1);
    WRITE (ST);
  END;

  PROCEDURE INCREL;
  BEGIN
    INC (S);
    IF S=60 THEN BEGIN
      S:=0;
      INC (M);
    END;
  END;

  PROCEDURE SETATTR;
  BEGIN
    ABSCR [Y][X].A:=I+P*16;
  END;

  PROCEDURE SETATTRW;
  VAR
    X,Y: BYTE;
  BEGIN
    FOR Y:=Y1 TO Y2 DO
      FOR X:=X1 TO X2 DO
        SETATTR (X,Y,I,P);
  END;

  PROCEDURE REALWRITE;
  BEGIN
    ABSCR [WHEREY][WHEREX].C:=C;
    ABSCR [WHEREY][WHEREX].A:=TEXTATTR;
  END;

  FUNCTION GETATTR;
  BEGIN
    GETATTR:=ABSCR [Y][X].A;
  END;

  FUNCTION SEQ;
  VAR
    T: STRING;
    X: BYTE;
  BEGIN
    T:='';
    IF N>0 THEN FOR X:=1 TO N DO T:=T+C;
    SEQ:=T;
  END;

  PROCEDURE IMPSTATUS;
  VAR
    SF: BYTE;
  BEGIN
    SF:=TEXTATTR;
    INVERSE (ON);
    GOTOXY (1,Y);
    WRITE (SEQ (ESP, 80));
    GOTOXY (CENT (S),Y);
    WRITE (S);
    TEXTATTR:=SF;
  END;

  PROCEDURE CURSOR;
  VAR
    R: REGISTERS;
    A: BYTE;
  BEGIN
{    R.AX:=$100;
    R.CL:=10;
    IF B THEN R.CH:=6 ELSE R.CH:=15;
    INTR ($10,R);}
    PORT [$3D4]:=$A;
    A:=PORT [$3D5];
    IF B THEN BEGIN
      PORT [$3D4]:=$A;
      PORT [$3D5]:=A AND 223;
    END ELSE BEGIN
      PORT [$3D4]:=$A;
      PORT [$3D5]:=A OR 32;
    END;
    CURSAT:=B;
  END;

  PROCEDURE WAITFORKEY;
  VAR
    T: CHAR;
    B: BOOLEAN;
  BEGIN
    B:=CURSAT;
    CURSOR (OFF);
    T:=READKEY;
    IF T=#0 THEN T:=READKEY;
    CURSOR (B);
  END;

  PROCEDURE JANELA;
  VAR
    SF,Y: BYTE;
    T: STRING;
  BEGIN
    SF:=TEXTATTR;
    TEXTCOLOR (I);
    TEXTBACKGROUND (P);
    GOTOXY (X1,Y1);
    T:=SEQ (ESP,X2-X1-2);
    WRITE (#218,SEQ (#196,X2-X1-2),#191);
    FOR Y:=Y1+1 TO Y2-1 DO BEGIN
      GOTOXY (X1,Y);
      WRITE (#179,T,#179);
    END;
    GOTOXY (X1,Y2);
    WRITE (#192,SEQ (#196,X2-X1-2),#217);
    TEXTATTR:=SF;
  END;

  PROCEDURE CLEARWINDOW;
  VAR
    S: STRING;
    Y: BYTE;
  BEGIN
    S:=SEQ (ESP,X2-X1);
    FOR Y:=Y1 TO Y2 DO BEGIN
      GOTOXY (X1,Y);
      WRITE (S);
    END;
  END;

  PROCEDURE INSMENUOP;
  VAR
    P: MENUL;
  BEGIN
    IF M=NIL THEN BEGIN
      NEW (M);
      M^.S:=N;
      M^.PROX:=NIL;
    END ELSE BEGIN
      P:=M;
      WHILE P^.PROX<>NIL DO P:=P^.PROX;
      NEW (P^.PROX);
      P^.PROX^.S:=N;
      P^.PROX^.PROX:=NIL;
    END;
  END;

  FUNCTION MENU;
  VAR
    SC,FL,L: BYTE;
    PP,NR,LAT,T,N,AT: WORD;
    P: MENUL;
    TC: CHAR;
    R,B: BOOLEAN;

    PROCEDURE AJUSTA;
    VAR
      N: WORD;
    BEGIN
      P:=M;
      N:=1;
      WHILE N<>PP DO BEGIN
        P:=P^.PROX;
        INC (N);
      END;
      N:=1;
      WHILE Y+N+FL<25 DO BEGIN
        GOTOXY (X+2,Y+N+FL);
        WRITE (SEQ (ESP,L));
        GOTOXY (X+(L+4-LENGTH (P^.S)) DIV 2,Y+N+FL);
        WRITE (P^.S);
        P:=P^.PROX;
        INC (N);
      END;
    END;

  BEGIN
    B:=CURSAT;
    SC:=TEXTATTR;
    CURSOR (OFF);
    L:=LENGTH (TIT);
    P:=M;
    N:=0;
    WHILE P<>NIL DO BEGIN
      IF L<LENGTH (P^.S) THEN L:=LENGTH (P^.S);
      P:=P^.PROX;
      INC (N);
    END;
    INC (L,4);
    IF X=0 THEN X:=40-L DIV 2;
    R:=FALSE;
    IF TIT='' THEN FL:=0 ELSE FL:=1;
    NR:=N;
    IF N+Y+1+FL>24 THEN BEGIN
      N:=24-Y-FL;
      R:=TRUE;
    END;
    JANELA (X,Y,X+L,Y+N+1+FL,IC,PC);
    TEXTCOLOR (IC);
    TEXTBACKGROUND (PC);
    P:=M;
    GOTOXY (X+(L-LENGTH (TIT)) DIV 2,Y);
    WRITE (TIT);
    N:=1;
    WHILE P<>NIL DO BEGIN
      T:=LENGTH (P^.S);
      GOTOXY (X+(L-T) DIV 2,Y+N+FL);
      WRITE (P^.S);
      P:=P^.PROX;
      INC (N);
      IF Y+N+FL=25 THEN BEGIN
        P:=NIL;
        DEC (N);
      END;
    END;
    DEC (L,4);
    AT:=1;
    LAT:=1;
    PP:=1;
    REPEAT
      SETATTRW (X+1,Y+1+AT-PP+FL,X+L+2,Y+1+AT-PP+FL,IB,PB);
      TC:=READKEY;
      IF TC=#0 THEN CASE READKEY OF
        UP: DEC (AT);
        DOWN: INC (AT);
      END;
      IF LAT<>AT THEN BEGIN
        SETATTRW (X+1,Y+1+LAT-PP+FL,X+L+2,Y+1+LAT-PP+FL,IC,PC);
        IF R THEN BEGIN
          IF AT-PP+1<1 THEN
            IF AT>=1 THEN BEGIN
              DEC (PP);
              AJUSTA;
            END ELSE BEGIN
              PP:=NR-22+Y;
              AT:=NR;
              AJUSTA;
            END;
          IF Y+AT-PP+2>24 THEN
            IF AT<=NR THEN BEGIN
              INC (PP);
              AJUSTA;
            END ELSE BEGIN
              PP:=1;
              AT:=1;
              AJUSTA;
            END;
        END ELSE BEGIN
          IF AT<1 THEN AT:=N-1;
          IF AT=N THEN AT:=1;
        END;
        LAT:=AT;
      END;
    UNTIL TC IN [ESC,CR];
    IF TC=ESC THEN MENU:=0 ELSE MENU:=AT;
    CURSOR (B);
    TEXTATTR:=SC;
  END;

  PROCEDURE MENSAGEM;
  VAR
    SC,N: BYTE;
  BEGIN
    SC:=TEXTATTR;
    N:=LENGTH (S);
    IF X=0 THEN X:=38-(LENGTH (S)) DIV 2;
    JANELA (X,Y,X+N+4,Y+2,I,P);
    GOTOXY (X+2,Y+1);
    TEXTCOLOR (I);
    TEXTBACKGROUND (P);
    WRITE (S);
    TEXTATTR:=SC;
  END;

  PROCEDURE RECEBE;
  VAR
    SC,N: BYTE;
    B: BOOLEAN;
    TC: CHAR;
  BEGIN
    SC:=TEXTATTR;
    B:=CURSAT;
    TEXTCOLOR (I1);
    TEXTBACKGROUND (P1);
    GOTOXY (X,Y);
    WRITE (SEQ (ESP,T+1));
    GOTOXY (X,Y);
    WRITE (S);
    N:=LENGTH (S);
    CURSOR (ON);
    REPEAT
      GOTOXY (X+N,Y);
      IF MINUSC THEN TC:=READKEY ELSE TC:=UPCASE (READKEY);
      IF TC=#0 THEN BEGIN
        TC:=READKEY;
        IF TC=#6 THEN BEGIN
          S:='';
          GOTOXY (X,Y);
          WRITE (SEQ (ESP,T+1));
          N:=0;
        END;
        TC:=#0;
      END;
      IF (N<T) AND (ORD (TC)>31) THEN BEGIN
        WRITE (TC);
        S:=S+TC;
        INC (N);
      END;
      IF (TC=BS) AND (N>0) THEN BEGIN
        GOTOXY (X+N-1,Y);
        WRITE (ESP);
        DEC (N);
        S:=COPY (S,1,LENGTH (S)-1);
      END;
    UNTIL TC IN [CR,ESC];
    TEXTCOLOR (I2);
    TEXTBACKGROUND (P2);
    GOTOXY (X,Y);
    WRITE (S, SEQ (ESP,T+1-LENGTH (S)));
    IF TC=ESC THEN S:=NUL;
    CURSOR (B);
    TEXTATTR:=SC;
  END;

  PROCEDURE RECEBEN;
  VAR
    S: STRING;
    C: INTEGER;
  BEGIN
    IF N<>0 THEN STR (N,S) ELSE S:='';
    REPEAT
      RECEBE (X,Y,T,I1,P1,I2,P2,S);
      VAL (S,N,C);
    UNTIL (S=NUL) OR (C=0);
    IF S=NUL THEN N:=NULN;
  END;

  FUNCTION EXISTEARQ;
  VAR
    SR: SEARCHREC;
  BEGIN
    FINDFIRST (S,ARCHIVE,SR);
    IF DOSERROR=18 THEN EXISTEARQ:=FALSE ELSE EXISTEARQ:=TRUE;
  END;

  FUNCTION ASTR;
  VAR
    S1: STRING;
  BEGIN
    STR (N,S1);
    ASTR:=S1;
  END;

  FUNCTION WEEK;
  VAR
    N1,N2,N3: BYTE;
  BEGIN
    CASE M OF
      1,10:   N1:=0;
      5:      N1:=1;
      8:      N1:=2;
      2,3,11: N1:=3;
      6:      N1:=4;
      9,12:   N1:=5;
      4,7:    N1:=6;
    END;
    N1:=(N1+(D-1) MOD 7) MOD 7+1;
    CASE A MOD 100 OF
      0,6,17,23,28,34,45,51,56,62,73,79,84,90:    N2:=0;
      1,7,12,18,29,35,40,46,57,63,68,74,85,91,96: N2:=1;
      2,13,19,24,30,41,47,52,58,69,75,80,86,97:   N2:=2;
      3,8,14,25,31,36,42,53,59,64,70,81,87,92,98: N2:=3;
      9,15,20,26,37,43,48,54,65,71,76,82,93,99:   N2:=4;
      4,10,21,27,32,38,49,55,60,66,77,83,88,94:   N2:=5;
      5,11,16,22,33,39,44,50,61,67,72,78,89,95:   N2:=6;
    END;
    CASE A DIV 100 OF
      6,13:             N3:=1;
      5,12,16,20,24,28: N3:=2;
      4,11,15,19,23,27: N3:=3;
      3,10:             N3:=4;
      2,9,18,22,26:     N3:=5;
      1,8:              N3:=6;
      0,7,14,17,21,25:  N3:=7;
    END;
    N2:=(N2+N3-1) MOD 7+1;
    IF (A MOD 4=0) AND (M<3) THEN N3:=6 ELSE N3:=0;
    N3:=((N1+4) MOD 7+N2+N3) MOD 7;
    WEEK:=WEEKDAY (N3);
  END;

  FUNCTION MAXDAYS;
  CONST
    DM='312831303130313130313031';
  VAR
    D: STRING;
    X,C: INTEGER;
  BEGIN
    D:=COPY (DM,M*2-1,2);
    VAL (D,X,C);
    IF (A MOD 4=0) AND (M=2) THEN X:=29;
    MAXDAYS:=X;
  END;

  FUNCTION CHECKPRINTER;
  VAR
    R: REGISTERS;
  BEGIN
    R.AH:=2;
    R.DX:=0;
    INTR ($17,R);
    IF R.AH=144 THEN CHECKPRINTER:=TRUE ELSE CHECKPRINTER:=FALSE;
  END;

  FUNCTION INTPOWER;
  VAR
    A,X: INTEGER;
  BEGIN
    A:=1;
    FOR X:=1 TO P DO A:=A*N;
    INTPOWER:=A;
  END;

  FUNCTION BIT;
  VAR
    B: BYTE;
  BEGIN
    B:=(A AND INTPOWER (2,N));
    IF B>0 THEN BIT:=1 ELSE BIT:=0;
  END;

  FUNCTION HEXA;

    FUNCTION HALF (A: BYTE): CHAR;
    BEGIN
      IF A>9 THEN HALF:=CHR ($40+A-9) ELSE HALF:=CHR ($30+A);
    END;

  BEGIN
    HEXA:=HALF (A DIV 16)+HALF (A MOD 16);
  END;

BEGIN
  INVERSE (OFF);
  CLRSCR;
  CURSOR (ON);
  MENUSN:=NIL;
  MINUSC:=FALSE;
  INSMENUOP ('Sim',MENUSN);
  INSMENUOP ('Nao',MENUSN);
END.