/* Arkanoid 1.0 */
/* Ricardo Bittencourt */
/* ricardo@lsi.usp.br */

#include <conio.h>
#include <stdlib.h>
#include <dos.h>
#include <math.h>

#define pi 3.1415926535897
/* Tamanho do tabuleiro */
#define maxx 80
#define maxy 20
/* Tamanho da peca */
#define tam 4
/* Tamanho da raquete */
#define rtam 8
/* Numero maximo de bolinhas */
#define maxbol 10
/* Constantes de tempo */
#define raqtime 3000
#define boltime 20000
/* Variacao da normal na raquete, centrada em pi/2 */
#define raqnorm pi/8

typedef struct {
  int x,y,lx,ly;
  int ax,ay,d,sx,sy;
  int player;
  struct time t;
} BolinhaType;

int lostone;                            /* Perdeu uma vida */
int rk1,lk1,lk2,rk2,ek;                 /* Teclas */
void interrupt (*old9handler) ();       /* Antiga interrupcao do teclado */
int p1x,p2x;                            /* Posicao das raquetes */
BolinhaType bol[maxbol];                /* Lista de bolinhas */
struct time raq;                        /* Tempo de atualizacao raquetes */
int Tab[maxx][maxy];                    /* Tabuleiro 0=vazio 1000+n=peca */
                                        /* 100+n=player1 200+n=player2 */

void interrupt new9handler () {
  int v;
  v=inp (0x60);
  switch (v) {
    case 1:      ek=1;  break;
    case 75:     lk1=1; break;
    case 77:     rk1=1; break;
    case 29:     lk2=1; break;
    case 56:     rk2=1; break;
    case 1+128:  ek=0;  break;
    case 75+128: lk1=0; break;
    case 77+128: rk1=0; break;
    case 29+128: lk2=0; break;
    case 56+128: rk2=0; break;
  }
  old9handler ();
  if (kbhit ()) getch ();
}

int sgn (int x) {
  if (x>0) return 1;
  if (x<0) return -1;
  return 0;
}

void Reflexo (double nx, double ny, double vx,
              double vy, double *rx, double *ry) {
  double esc,mod,nmod;
  mod=sqrt (vx*vx+vy*vy);
  nmod=sqrt (nx*nx+ny*ny);
  nx/=nmod;
  ny/=nmod;
  vx/=mod;
  vy/=mod;
  esc=vx*nx+vy*ny;
  (*rx)=vx-2*esc*nx;
  (*ry)=vy-2*esc*ny;
}

void InitBres (BolinhaType *b, double rx, double ry) {
  int c,s;
  c=(int) (rx*100);
  s=(int) (ry*100);
  b->ax=abs (c);
  b->ay=abs (s);
  b->sx=sgn (c);
  b->sy=sgn (s);
  if (b->ax>b->ay)
    b->d=b->ay-(b->ax/2);
  else
    b->d=b->ax-(b->ay/2);
}

void Mata (int x, int y) {
  int v,i;
  v=Tab[x][y];
  for (i=x-tam; i<x+tam+1; i++)
    if (i>=0 && i<maxx)
      if (Tab[i][y]==v) {
        Tab[i][y]=0;
        gotoxy (i+1,y+1);
        cprintf (" ");
      }
}

void IteracaoBres (BolinhaType *b) {
  double nx,ny;
  double rx,ry;
  double ang;
  int reat=0,posx;
  /* Calcula a proxima coordenada por Bresenham */
  if (b->ax>b->ay) {
    if (b->d>=0) {
      (b->y)+=b->sy;
      (b->d)-=b->ax;
    }
    (b->x)+=b->sx;
    (b->d)+=b->ay;
  } else {
    if (b->d>=0) {
      (b->x)+=b->sx;
      (b->d)-=b->ay;
    }
    (b->y)+=b->sy;
    (b->d)+=b->ax;
  }
  /* Checa colisao com a borda da tela */
  nx=ny=0;
  if (b->y>=maxy) {
    ny=-1;
    reat=1;
  }
  if (b->y<0) {
    ny=1;
    reat=1;
  }
  if (b->x<0) {
    nx=1;
    reat=1;
  }
  if (b->x>=maxx) {
    nx=-1;
    reat=1;
  }
  /* Checa colisao com a raquete */
  if (!reat && Tab[b->x][b->y]>100 && Tab[b->x][b->y]<300) {
    b->player=Tab[b->x][b->y]/100;
    posx=Tab[b->x][b->y]%100;
    ang=(double)(rtam-1-posx)/(rtam-1)*2*raqnorm+pi/2-raqnorm;
    nx=cos (ang);
    ny=sin (ang);
    if (b->player==1) ny=-ny;
    reat=1;
  }
  /* Checa colisao com alguma peca */
  if (!reat && Tab[b->x][b->y]>999) {
    nx=b->lx-b->x;
    ny=b->ly-b->y;
    reat=1;
    Mata (b->x,b->y);
  }
  /* Recalcula posicao em caso de colisao */
  if (reat) {
    b->x=b->lx;
    b->y=b->ly;
    Reflexo (nx,ny,(double) b->ax*b->sx,(double) b->ay*b->sy,&rx,&ry);
/*
    gotoxy (1,23);
    cprintf ("nx %lf ny %lf ax*sx %d ay*sy %d rx %lf ry %lf ",
              nx,ny,b->ax*b->sx,b->ay*b->sy,rx,ry);
*/
    InitBres (b,rx,ry);
    IteracaoBres (b);
  } else {
    gotoxy (b->lx+1,b->ly+1);
    cprintf (" ");
    gotoxy (b->x+1,b->y+1);
    switch (b->player) {
      case 1: textcolor (LIGHTRED);  break;
      case 2: textcolor (LIGHTBLUE); break;
    }
    cprintf ("o");
    b->lx=b->x;
    b->ly=b->y;
  }
}

void DrawRaq (int x, int y, int c) {
  int i;
  gotoxy (x+1,y+1);
  switch (c) {
    case 1: textcolor (LIGHTRED);  break;
    case 2: textcolor (LIGHTBLUE); break;
  }
  cprintf ("--------");
  for (i=0; i<rtam; i++)
    Tab[i+x][y]=c*100+i;
}

void UnDrawRaq (int x, int y) {
  int i;
  gotoxy (x+1,y+1);
  cprintf ("        ");
  for (i=0; i<rtam; i++)
    Tab[i+x][y]=0;
}

void Init (void) {
  int i,j,k,n;
  double angulo;
  n=0;

  for (j=0; j<maxy; j++)
    for (i=0; i<maxx; i++)
      Tab[i][j]=0;
  for (j=maxy/3; j<2*maxy/3; j++)
    for (i=0; i<maxx/tam; i++) {
      for (k=0; k<tam; k++)
        Tab[i*tam+k][j]=1000+n;
      n++;
    }
  for (i=0; i<maxbol; i++)
    bol[i].player=0;
  bol[0].lx=bol[0].x=maxx/2;
  bol[0].ly=bol[0].y=maxy-2;
  bol[0].player=1;
  bol[1].lx=bol[1].x=maxx/2;
  bol[1].ly=bol[1].y=1;
  bol[1].player=2;
  angulo=pi/2;
/* (double) random (1000)/999.0*pi; */
  InitBres (&bol[0],cos (angulo),-sin (angulo));
  angulo=3*pi/4;
  InitBres (&bol[1],cos (angulo),sin (angulo));
  _setcursortype (_NOCURSOR);
  rk1=lk1=rk2=lk2=ek=0;
  p1x=(maxx-rtam)/2;
  lostone=0;
  old9handler=getvect (9);
  setvect (9,new9handler);
}

void Show (void) {
  int i,j,l;
  clrscr ();
  l=0;
  for (j=0; j<maxy; j++)
    for (i=0; i<maxx; i++) {
      if (Tab[i][j]!=l) {
        l=Tab[i][j];
        textcolor (random (15)+1);
      }
      if (Tab[i][j]>=1000) {
        gotoxy (i+1,j+1);
        cprintf ("@");
      }
    }
  DrawRaq (p1x,maxy-1,1);
  DrawRaq (p2x,0,2);
}

void Play (void) {
  int l2x=0,l1x=0,c=0,raqc=0;
  while (!ek && !lostone) {
    if (l1x!=p1x) {
      UnDrawRaq (l1x,maxy-1);
      DrawRaq (p1x,maxy-1,1);
      l1x=p1x;
    }
    if (l2x!=p2x) {
      UnDrawRaq (l2x,0);
      DrawRaq (p2x,0,2);
      l2x=p2x;
    }
    c++;
    if (c>boltime) {
      IteracaoBres (&bol[0]);
      IteracaoBres (&bol[1]);
      c=0;
    }
    raqc++;
    if (raqc>raqtime) {
      if (lk1 && p1x>0) p1x--;
      if (rk1 && p1x<maxx-rtam) p1x++;
      if (lk2 && p2x>0) p2x--;
      if (rk2 && p2x<maxx-rtam) p2x++;
      raqc=0;
    }
  }
}

void Done (void) {
  _setcursortype (_NORMALCURSOR);
  setvect (9,old9handler);
}

void main (void) {
  Init ();
  Show ();
  Play ();
  Done ();
}