uses dos,crt,jogos;

type
  mov= (cim,bai,esq,dir,parado);
  pecas= (tijolo,vazio,pacman,bicho,pilula,ponto,pacf,bichomido);
  posxy= record
           xl,yl,
           x,y: byte;
         end;
  bichao= array [1..4] of posxy;
  labirinto= array [0..21,0..21] of pecas;
  typerec= record
             nome: string[10];
             fase,pontos: longint;
           end;
  recs= array [1..10] of typerec;

var
  lab: labirinto;                      {matriz do labirinto}
  pontos,                              {pontos}
  fase: longint;                       {fase atual}
  powermax,                            {maximo tempo p/poder}
  powerat,                             {poder atual}
  maxbi,                               {vel.max dos bichos}
  contbi,                              {velocid. bichos}
  velat,                               {velocidade atual}
  contint,                             {contador de interrupcoes}
  xl,yl,                               {ultima posicao do pac}
  xp,yp: byte;                         {posicao do pac}
  movat: mov;                          {sentido de mov. do pac}
  check,                               {indica fim das pecas da fase}
  gameover: boolean;                   {indica fim de jogo}
  tecla: char;                         {var. para tecla do jogador}
  bi: bichao;                          {posicao dos bichos}
  saveint: pointer;                    {var. salva a interrupcao}
  comido: array [1..4] of byte;        {bicho comido}
  recorde: recs;                       {recordes}
  fr: file of recs;                    {arquivo}

  function boo: boolean;
  begin
    boo:=false;
    if random (10)>3 then boo:=true;
  end;

  procedure showpos (x,y: byte; peca: pecas);
  var
    c: char;
  begin
    gotoxy (x+30,y+2);
    case peca of
      vazio: c:=#32;
      tijolo: c:=#177;
      pacman: c:=#1;
      pacf: c:=#2;
      bicho: c:=#234;
      pilula: c:=#9;
      ponto: c:=#249;
      bichomido: c:=#236;
    end;
    realwrite (c);
  end;

  procedure showlab (lab: labirinto);
  var
    x,y: byte;
  begin
    clrscr;
    janela (30,2,52,23,lightgray,black);
    for x:=1 to 20 do
      for y:=1 to 20 do begin
        showpos (x,y,lab[x][y]);
      end;
    gotoxy (65,5);
    write ('PONTOS');
  end;

  procedure dist (xo,yo: byte; var x,y: byte);
  var
    xv,yv: byte;
    dat,dt: real;
  begin
    dat:=40;
    for xv:=1 to 20 do
      for yv:=1 to 20 do begin
        dt:=sqrt (sqr (xv-xo)+sqr (yv-yo));
        if (dt<dat) and (lab[xv][yv]=vazio) then begin
          dat:=dt;
          x:=xv;
          y:=yv;
        end;
      end;
  end;

  procedure preenchelab2 (var lab: labirinto);
  var
    x,y,e: byte;
    f: boolean;
    temp: labirinto;
    ar: array [1..20,1..20] of integer;

    procedure pre (x,y: byte);
    var
      c,d: byte;
    begin
      if (lab[x-1][y]=vazio) and (lab[x][y-1]=vazio) and (lab[x-1][y-1]=vazio) then exit;
      if (lab[x+1][y]=vazio) and (lab[x][y-1]=vazio) and (lab[x+1][y-1]=vazio) then exit;
      if (lab[x-1][y]=vazio) and (lab[x][y+1]=vazio) and (lab[x-1][y+1]=vazio) then exit;
      if (lab[x+1][y]=vazio) and (lab[x][y+1]=vazio) and (lab[x+1][y+1]=vazio) then exit;
      lab[x][y]:=vazio;
      inc (ar[x][y]);
      if ar[x][y]=5 then temp[x][y]:=vazio;
      c:=random (4);
      case c of
        0: if (x>1) and (temp[x-1][y]=tijolo) then pre (x-1,y);
        1: if (x<20) and (temp[x+1][y]=tijolo) then pre (x+1,y);
        2: if (y<20) and (temp[x][y+1]=tijolo) then pre (x,y+1);
        3: if (y>1) and (temp[x][y-1]=tijolo) then pre (x,y-1);
      end;
      repeat d:=random (4) until d<>c;
      case d of
        0: if (x>1) and (temp[x-1][y]=tijolo) then pre (x-1,y);
        1: if (x<20) and (temp[x+1][y]=tijolo) then pre (x+1,y);
        2: if (y<20) and (temp[x][y+1]=tijolo) then pre (x,y+1);
        3: if (y>1) and (temp[x][y-1]=tijolo) then pre (x,y-1);
      end;
    end;

  begin
    for x:=1 to 20 do
      for y:=1 to 20 do begin
        lab[x][y]:=tijolo;
        temp[x][y]:=tijolo;
        ar[x][y]:=0;
      end;
    pre (10,10);
    repeat
      f:=true;
      for x:=1 to 20 do
        for y:=1 to 20 do begin
          e:=0;
          if (x>1) and (lab[x-1][y]=vazio) then inc (e);
          if (x<20) and (lab[x+1][y]=vazio) then inc (e);
          if (y>1) and (lab[x][y-1]=vazio) then inc (e);
          if (y<20) and (lab[x][y+1]=vazio) then inc (e);
          if (e=1) and (lab[x][y]=vazio) then begin
            lab[x][y]:=tijolo;
            f:=false;
          end;
        end;
    until f;
    for x:=0 to 21 do begin
      lab[x][0]:=tijolo;
      lab[x][21]:=tijolo;
    end;
    for y:=0 to 21 do begin
      lab[0][y]:=tijolo;
      lab[21][y]:=tijolo;
    end;
    dist (10,10,xp,yp);
    lab[xp][yp]:=pacman;
    xl:=xp;
    yl:=yp;
    dist (1,20,x,y);
    lab[x][y]:=pilula;
    dist (1,1,x,y);
    lab[x][y]:=pilula;
    dist (20,20,x,y);
    lab[x][y]:=pilula;
    dist (20,1,x,y);
    lab[x][y]:=pilula;
    dist (10,20,bi[1].x,bi[1].y);
    bi[1].xl:=bi[1].x;
    bi[1].yl:=bi[1].y;
    dist (10,1,bi[2].x,bi[2].y);
    bi[2].xl:=bi[2].x;
    bi[2].yl:=bi[2].y;
    for x:=1 to 20 do
      for y:=1 to 20 do
        if lab[x][y]=vazio then lab[x][y]:=ponto;
  end;

  procedure showpac;
  var
    n: byte;
  begin
    for n:=1 to 2 do
      if (xp=bi[n].x) and (yp=bi[n].y) then
        if powerat>0 then if comido[n]=0 then begin
                                                comido[n]:=15;
                                                inc (pontos,100);
                                              end
                                         else comido[n]:=15
                     else if comido[n]=0 then gameover:=true;
    if lab[xp][yp]=pilula then begin
      powerat:=powermax;
      inc (pontos,10);
    end;
    if lab[xp][yp]=ponto then inc (pontos,1);
    lab[xl][yl]:=vazio;
    lab[xp][yp]:=pacman;
    showpos (xl,yl,vazio);
    if powerat=0 then showpos (xp,yp,lab[xp][yp])
                 else showpos (xp,yp,pacf);
    xl:=xp;
    yl:=yp;
    for n:=1 to 2 do if comido[n]>0 then showpos (bi[n].x,bi[n].y,bichomido)
                                    else showpos (bi[n].x,bi[n].y,bicho);
    gotoxy (65,6);
    write (pontos:6);
  end;

  procedure evalbicho (n: byte);
  var
    t: real;
    m: array [1..3] of mov;
    c: byte;
  begin
    if xp-bi[n].x=0 then
      if yp>=bi[n].y then t:=pi/2
                     else t:=3*pi/2
                    else t:=arctan ((yp-bi[n].y)/(xp-bi[n].x));
    if xp<bi[n].x then t:=t+pi;
    t:=-t;
    repeat
      if t>2*pi then t:=t-2*pi;
      if t<0 then t:=t+2*pi;
    until (0<=t) and (t<=2*pi);
    if (t>=0) and (t<pi/4) then begin
      m[1]:=dir;
      m[2]:=cim;
      m[3]:=bai;
    end;
    if (t>=pi/4) and (t<pi/2) then begin
      m[1]:=cim;
      m[2]:=dir;
      m[3]:=esq;
    end;
    if (t>=pi/2) and (t<3*pi/4) then begin
      m[1]:=cim;
      m[2]:=esq;
      m[3]:=dir;
    end;
    if (t>=3*pi/4) and (t<pi) then begin
      m[1]:=esq;
      m[2]:=cim;
      m[3]:=bai;
    end;
    if (t>=pi) and (t<5*pi/4) then begin
      m[1]:=esq;
      m[2]:=bai;
      m[3]:=cim;
    end;
    if (t>=5*pi/4) and (t<3*pi/2) then begin
      m[1]:=bai;
      m[2]:=esq;
      m[3]:=dir;
    end;
    if (t>=3*pi/2) and (t<7*pi/4) then begin
      m[1]:=bai;
      m[2]:=dir;
      m[3]:=esq;
    end;
    if (t>=7*pi/4) and (t<=2*pi) then begin
      m[1]:=dir;
      m[2]:=bai;
      m[3]:=cim;
    end;
    if (powerat>0) or (comido[n]>0) then
      for c:=1 to 3 do
        case m[c] of
          esq: m[c]:=dir;
          dir: m[c]:=esq;
          cim: m[c]:=bai;
          bai: m[c]:=cim;
        end;
    c:=1;
    repeat
      case m[c] of
        esq: if lab[bi[n].x-1][bi[n].y]<>tijolo then dec (bi[n].x);
        dir: if lab[bi[n].x+1][bi[n].y]<>tijolo then inc (bi[n].x);
        cim: if lab[bi[n].x][bi[n].y-1]<>tijolo then dec (bi[n].y);
        bai: if lab[bi[n].x][bi[n].y+1]<>tijolo then inc (bi[n].y);
      end;
      inc (c);
    until (c=4) or (bi[n].x<>bi[n].xl) or (bi[n].y<>bi[n].yl);
    showpos (bi[n].xl,bi[n].yl,lab[bi[n].xl][bi[n].yl]);
    if comido[n]>0 then showpos (bi[n].x,bi[n].y,bichomido)
                   else showpos (bi[n].x,bi[n].y,bicho);
    bi[n].xl:=bi[n].x;
    bi[n].yl:=bi[n].y;
    if (lab[bi[n].x][bi[n].y]=pacman) and (comido[n]=0) then gameover:=true;
    if comido[n]>0 then dec (comido[n]);
  end;

  procedure intprinc; interrupt;
  var
    x,y: byte;
  begin
    inc (contint);
    if contint>velat then begin
      contint:=0;
      if powerat>0 then dec (powerat);
      case movat of
        cim: if lab[xp][yp-1]<>tijolo then dec (yp);
        bai: if lab[xp][yp+1]<>tijolo then inc (yp);
        esq: if lab[xp-1][yp]<>tijolo then dec (xp);
        dir: if lab[xp+1][yp]<>tijolo then inc (xp);
      end;
      if movat<>parado then showpac;
      inc (contbi);
      if contbi=maxbi then begin
        evalbicho (1);
        evalbicho (2);
        contbi:=0;
      end;
      check:=true;
      for x:=1 to 20 do
        for y:=1 to 20 do
          if lab[x][y] in [pilula,ponto] then check:=false;
    end;
  end;

  procedure init;
  begin
    getintvec (intrel,saveint);
    cursor (off);
    fase:=0;
    gameover:=false;
    movat:=parado;
    velat:=4;
    contint:=0;
    powermax:=25;
    powerat:=0;
    contbi:=0;
    for maxbi:=1 to 2 do comido[maxbi]:=0;
    assign (fr,'PACMAN.HIG');
    if existearq ('PACMAN.HIG') then begin
      reset (fr);
      read (fr,recorde);
      close (fr);
    end else for maxbi:=1 to 10 do begin
      recorde[maxbi].pontos:=0;
      recorde[maxbi].fase:=0;
      recorde[maxbi].nome:='';
    end;
    maxbi:=2;
  end;

  procedure done;
  begin
    cursor (on);
    setintvec (intrel,saveint);
    rewrite (fr);
    write (fr,recorde);
    close (fr);
    clrscr;
  end;

  procedure telaini;
  begin
    clrscr;
    writeln ('PACMAN');
    write ('Hit Start');
  end;

  procedure enterrec;
  var
    n: integer;
  begin
    clrscr;
    if recorde[10].pontos>=pontos then begin
      for n:=1 to 10 do begin
        gotoxy (20,n);
        write (recorde[10].pontos);
        gotoxy (30,n);
        write (recorde[10].nome);
        gotoxy (45,n);
        write (recorde[10].fase);
      end;
    end else begin
      n:=9;
      repeat
        recorde[n+1]:=recorde[n];
        if (recorde[n+1].pontos>pontos) or (n=1) then begin
          recorde[n+1].pontos:=pontos;
          recorde[n+1].fase:=fase;
          write ('Entre nome: ');
          readln (recorde[n+1].nome);
        end;
        dec (n);
      until (recorde[n+1].pontos>pontos) or (n=0);
      for n:=1 to 10 do begin
        gotoxy (20,n);
        write (recorde[10].pontos);
        gotoxy (30,n);
        write (recorde[10].nome);
        gotoxy (45,n);
        write (recorde[10].fase);
      end;
    end;
    waitforkey;
  end;

begin
  init;
  telaini;
  waitforkey;
  repeat
    pontos:=0;
    repeat
      inc (fase);
      randseed:=fase;
      preenchelab2 (lab);
      showlab (lab);
      setintvec (intrel,addr (intprinc));
      repeat
        tecla:=readkey;
        case tecla of
          #0: case readkey of
                up: movat:=cim;
                down: movat:=bai;
                left: movat:=esq;
                right: movat:=dir;
              end;
          esc: gameover:=true;
        end;
      until gameover or check;
      setintvec (intrel,saveint);
      check:=false;
      if not gameover then begin
        if powermax>5 then dec (powermax);
        if (fase mod 3=0) and (maxbi>0) then dec (maxbi);
      end;
    until gameover;
    enterrec;
    telaini;
    gameover:=false;
  until readkey=esc;
  done;
end.