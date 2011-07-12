uses dos,crt,jogos;

var
  r: registers;
  gd,gm: integer;

function player: integer;
var
  pl: integer;
begin
  r.ah:=$12;
  intr ($16,r);
  pl:=0;
  if bit (r.al,0)=1 then pl:=1;
  if bit (r.al,1)=1 then inc (pl,2);
  player:=pl;
end;

FUNCTION TIMERIZA: BOOLEAN;
VAR
  MAX,CONT: INTEGER;
BEGIN
  TIMERIZA:=TRUE;
  MAX:=1000+RANDOM (3000);
  CONT:=0;
  REPEAT
    DELAY (1);
    IF PLAYER<>0 THEN BEGIN
      GOTOXY (1,10);
      WRITE ('ESTOUROU !');
      TIMERIZA:=FALSE;
      EXIT;
    END;
    INC (CONT);
  UNTIL CONT>MAX;
  SOUND (500);
  GOTOXY (1,5);
  WRITE ('VAI !');
END;

PROCEDURE VAI;
VAR
  V: INTEGER;
BEGIN
  REPEAT
    V:=PLAYER;
  UNTIL V<>0;
  GOTOXY (1,10);
  NOSOUND;
  WRITE ('VENCEDOR: ');
  CASE V OF
    1: WRITE (' --->');
    2: WRITE (' <---');
    3: WRITE (' <-->');
  END;
END;

BEGIN
  REPEAT
    CLRSCR;
    WRITE ('REFLEXOS !':30);
    IF TIMERIZA THEN VAI;
  UNTIL READKEY=#27;
END.