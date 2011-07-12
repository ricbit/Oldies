// Ricardo Vision
// Ricardo Bittencourt

#include <dos.h>
#include <conio.h>
#include <process.h>
#include "Mouse.h"
#include "StrClass.h"

class Window {
private:
  int x,y;              // Posicao inicial da janela
  int dx,dy;            // Tamanho da janela
  int flags;            // Flags de controle da janela
  int backcolor;        // Cor de fundo
  int bordercolor;      // Cor da borda
  int titlecolor;       // Cor do titulo
  int opened;           // A janela esta aberta
  string title;         // Titulo
  char *below;          // Tela embaixo da janela

public:
  enum window_types {
    wNormal= 0x0000,
    wBorder= 0x0001,
    wTitle=  0x0002,
    wClose=  0x0004,
    wShadow= 0x0008
  };

  // Constructor
  Window (int type);
  // Destructor
  ~Window (void);
  // Muda o titulo
  void SetTitle (string Title);
  // Move a janela
  void Move (int X, int Y);
  // Desenha a janela
  void Draw (void);
  // Apaga a janela;
  void UnDraw (void);
  // Abre a janela
};

Window::Window (int type) {
  if (type & wClose)
    type|=wBorder;
  flags=type;
  x=10;
  y=10;
  dx=40;
  dy=10;
  backcolor=BLUE;
  bordercolor=LIGHTBLUE;
  titlecolor=RED;
  opened=0;
  below=new char[(dx+1)*(dy+1)*2];
}

Window::~Window (void) {
  delete below;
}

void Window::SetTitle (string Title) {
  flags|=wTitle;
  title=Title;
}

void Window::Move (int X, int Y) {
  int i,j;

  if (!opened) {
    x=X;
    y=Y;
  }
  else {
    HideMouseCursor ();
    UnDraw ();
    x=X;
    y=Y;
    Draw ();
    ShowMouseCursor ();
  }
}

void Window::Draw (void) {
  string Blank(32,flags & wBorder ? dx-2:dx), Line(196,dx-2);
  int j,i,k=0;

  opened=1;
  HideMouseCursor ();
  for (j=(y-1); j<(y)+dy; j++)
    for (i=(x-1)*2; i<(x)*2+dx*2; i++)
      below[k++]=peekb (0xB800,j*160+i);
  textbackground (backcolor);
  textcolor (bordercolor);
  if (!(flags & wBorder)) {
    for (j=y; j<y+dy; j++) {
      gotoxy (x,j);
      cprintf ("%s",Blank.c());
    }
  }
  else {
    gotoxy (x,y);
    cprintf ("%c%s%c",218,Line.c(),191);
    for (j=y+1; j<y+dy-1; j++) {
      gotoxy (x,j);
      cprintf ("%c%s%c",179,Blank.c(),179);
    }
    gotoxy (x,y+dy-1);
    cprintf ("%c%s%c",192,Line.c(),217);
    if (flags & wClose) {
      gotoxy (x+2,y);
      cprintf ("[ ]");
      textcolor (titlecolor);
      gotoxy (x+3,y);
      cprintf ("*");
    }
    if (flags & wTitle) {
      textcolor (titlecolor);
      gotoxy (x+(dx-title.Len())/2-1,y);
      cprintf (" %s ",title.c());
    }
    if (flags & wShadow) {
      for (i=x; i<=x+dx-1; i++)
        pokeb (0xB800,(y+dy-1)*160+i*2+1,DARKGRAY);
      for (j=y; j<=y+dy-1; j++)
        pokeb (0xB800,j*160+(x+dx-1)*2+1,DARKGRAY);
    }
  }
  ShowMouseCursor ();
}

void Window::UnDraw (void) {
  int i,j,k=0;

  opened=0;
  HideMouseCursor ();
  for (j=(y-1); j<(y)+dy; j++)
    for (i=(x-1)*2; i<(x)*2+dx*2; i++)
      pokeb (0xB800,j*160+i,below[k++]);
  ShowMouseCursor ();
}

void main (void) {
  int But,x,y,lx,ly;

  clrscr ();
  textcolor (BLACK);
  textbackground (LIGHTGRAY);
  for (x=0; x<250; x++) cprintf ("Ricardo ");
  textbackground (GREEN);
  gotoxy (1,1);
  if (!InitMouse (&But)) {
    cprintf ("Nao ha mouse instalado\n\r");
    exit (1);
  }
  else {
    cprintf ("Existe um mouse com %d botoes\n\r",But);
  }
  Window W (Window::wBorder | Window::wClose | Window::wShadow);
  W.SetTitle ("Titulo");
  ShowMouseCursor ();
  _setcursortype (_NOCURSOR);
  while (!kbhit()) {
    gotoxy (1,3);
    GetMouseXY (&x,&y);
    cprintf ("X:%3d, Y:%3d ",x,y);
    if (LeftButton ()) {
      W.Move (x/8,y/8);
      W.Draw ();
      lx=x;
      ly=y;
      while (LeftButton ()) {
        GetMouseXY (&x,&y);
        if (ly!=y || lx!=x) {
          W.Move (x/8,y/8);
          lx=x;
          ly=y;
        }
      }
      W.UnDraw ();
    }
  }
  HideMouseCursor ();
  _setcursortype (_NORMALCURSOR);
}