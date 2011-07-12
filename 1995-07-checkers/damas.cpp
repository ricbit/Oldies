// Damas.cpp
// Ricardo Bittencourt

// Includes
#include <conio.h>
#include <ctype.h>

// Defines
#define UP 72
#define DOWN 80
#define LEFT 75
#define RIGHT 77

// Typedefs
typedef unsigned char byte;

// Variaveis globais
int endgame=0;

// Definicoes de classes
class Tabuleiro {
public:
  byte tab[8][8];
  int comidas;
  int pos[12][2];
  // 0=vazio
  // 1=peca branca
  // 2=peca preta
  // 3=dama branca
  // 4=dama preta
  // obs: branco==1==x e preto==0==o (mod 2)

  Tabuleiro (void);
  void Draw (void);
  void ShowCursor (void);
  void HideCursor (void);
  void DrawOne (int x, int y, int peca);
  int End (void);
  int Checa (int sx, int sy, int px, int py, int lado);
  int Tpeca (int x, int y, int lado);
};

class Jogador {
public:
  virtual Tabuleiro Processa (Tabuleiro T, int lado) {lado=lado; return T;};
  //1= lado branco
  //0= lado preto
};

class Usuario: public Jogador {
public:
  int px,py;

  Usuario (void);
  virtual Tabuleiro Processa (Tabuleiro T, int lado);
};

// Classe Tabuleiro
Tabuleiro::Tabuleiro (void) {
  int i,j;

  for (i=0; i<8; i++)
    for (j=0; j<8; j++)
      if ((i+j)%2) {
        if (j<3)
          tab[i][j]=1;
        else
          if (j>4)
            tab [i][j]=2;
          else tab[i][j]=0;
      } else tab[i][j]=0;
}

void Tabuleiro::Draw (void) {
  int i,j;

  clrscr ();
  _setcursortype (_NOCURSOR);
  for (i=0; i<8; i++)
    for (j=0; j<8; j++)
      DrawOne (i,j,tab[i][j]);
}

void Tabuleiro::ShowCursor (void) {
  _setcursortype (_NORMALCURSOR);
};

void Tabuleiro::HideCursor (void) {
  _setcursortype (_NOCURSOR);
};

void Tabuleiro::DrawOne (int x, int y, int peca) {
  gotoxy (x*2+1,y+1);
  switch (peca) {
    case 1: cprintf ("x");
            break;
    case 2: cprintf ("o");
            break;
    case 3: cprintf ("X");
            break;
    case 4: cprintf ("O");
            break;
  }
};

int Tabuleiro::End (void) {
  int i,j,c1,c2;

  for (i=0; i<8; i++)
    for (j=0; j<8; j++) {
      if (!tab[i][j])
        if (tab[i][j]%2)
          c2++;
        else
          c1++;
    }
  if (!c1) return 2;
  if (!c2) return 1;
  return 0;
}

int Tabuleiro::Checa (int sx, int sy, int px, int py, int lado) {
  int s,s2;

  if (tab[sx][sy]%2!=lado) return 0;
  if (tab[px][py]!=0) return 0;
  if (lado)
    s=1;
  else
    s=-1;
  s2=2*s;
  comidas=0;
  //Anda uma posicao para a frente
  if (py==sy+s && (px==sx-1 || px==sx+1)) return 1;
  //Pode comer?
  if (py==sy+s2 &&
      ((px==sx-2 && Tpeca (sx-1,sy+s,!lado)) ||
       (px==sx+2 && Tpeca (sx+1,sy+s,!lado))))
  {
    comidas=1;
    pos[0][0]=sx+(px-sx)/2;
    pos[0][1]=sy+s;
    return 1;
  }
  return 0;
}

int Tabuleiro::Tpeca (int x, int y, int lado) {
  return (tab[x][y]!=0 && tab[x][y]%2==lado);
}

// Classe Usuario
Usuario::Usuario (void) {
  px=py=0;
}

Tabuleiro Usuario::Processa (Tabuleiro T, int lado) {
  int end=0,estado=1,sx,sy,i;

  T.ShowCursor ();
  do {
    gotoxy (40,1);
    cprintf ("Lado %d Estado=%d ",lado,estado);
    gotoxy (px*2+1,py+1);
    switch (getch ()) {
      case 0: switch (toupper (getch ())) {
                case UP:    py-=1;
                            break;
                case DOWN:  py+=1;
                            break;
                case RIGHT: px+=1;
                            break;
                case LEFT:  px-=1;
                            break;
              }
              if (px<0) px=7;
              if (py<0) py=7;
              if (px>7) px=0;
              if (py>7) py=0;
              T.DrawOne (px,py,T.tab[px][py]);
              break;
      case 27: endgame=1;
               end=1;
               break;
      case 'R': T.Draw ();
                break;
      case 13: if (estado) {
                 if (T.tab[px][py]%2==lado) {
                   textcolor (WHITE);
                   T.DrawOne (px,py,T.tab[px][py]);
                   textcolor (LIGHTGRAY);
                   estado=0;
                   sx=px;
                   sy=py;
                 }
               } else {
                 if (T.Checa (sx,sy,px,py,lado)) {
                   T.tab[px][py]=T.tab[sx][sy];
                   T.tab[sx][sy]=0;
                   end=1;
                   T.DrawOne (sx,sy,0);
                   textcolor (WHITE);
                   T.DrawOne (px,py,T.tab[px][py]);
                   textcolor (LIGHTGRAY);
                   if (T.comidas) {
                     for (i=0; i<T.comidas; i++) {
                       T.tab[T.pos[i][0]][T.pos[i][1]]=0;
                       T.DrawOne (T.pos[i][0],T.pos[i][1],0);
                     }
                   }
                 } else {
                   T.DrawOne (sx,sy,T.tab[sx][sy]);
                   estado=1;
                 }
               }
    }
  } while (!end);
  return T;
}

// Modulo principal

void main (void) {
  Tabuleiro T;
  Jogador *J1,*J2;
  Usuario U1,U2;
  int lado=1;

  J1=&U1;
  J2=&U2;
  do {
    T.Draw ();
    if (lado)
      T=J2->Processa (T,lado);
    else
      T=J1->Processa (T,lado);
    lado=!lado;
  } while (!(T.End () || endgame));
}