// Menu.cpp
// Ricardo Bittencourt

#include "Menu.h"

void Menu::InitPointers (void) {
  ErrorCode=MenuOk;
  Next=NULL;
  Prev=NULL;
  OpNumber=0;
  Title=0;
  backcolor=BLUE;
  txtcolor=LIGHTGRAY;
  choosecolor=WHITE;
  bordercolor=LIGHTBLUE;
  titlecolor=LIGHTRED;
}

Menu::Menu (void) {
  SpacesChar=1;
  MaxResX=79;
  InitPointers ();
}

Menu::~Menu (void) {
  Menu *M,*S;

  if (OpNumber) {
    M=this->Next;
    while (M!=NULL) {
      S=M;
      S->OpNumber=0;
      M=M->Next;
      delete S;
    }
  }
  if (Title) {
    delete titlestr;
    Title=0;
  }
}

void Menu::operator+= (string s) {
  Menu *M;

  if (!OpNumber) {
    item=s;
    OpNumber=1;
  }
  else {
    M=this;
    while (M->Next!=NULL)
      M=M->Next;
    M->Next=new Menu;
    M->Next->Prev=M;
    M->Next->item=s;
    M->Next->OpNumber=M->OpNumber+1;
    M->Next->Next=NULL;
  }
}

void Menu::SetPos (int x, int y) {
  gotoxy (x,y);
}

void Menu::Write (string s) {
  cprintf ("%s",s.c());
}

void Menu::SetColors (int fore, int back) {
  textcolor (fore);
  textbackground (back);
}

void Menu::Cursor (int a) {
  unsigned char b;

  outportb (0x3d4,10);
  b=inportb (0x3d5);
  outportb (0x3d4,10);
  if (a)
    outportb (0x3d5,b & 223);
  else
    outportb (0x3d5,b | 32);
}

void Menu::Colors (int BackC,int TextC,int ChooseC,int BorderC,int TitleC) {
  backcolor=BackC;
  txtcolor=TextC;
  choosecolor=ChooseC;
  bordercolor=BorderC;
  titlecolor=TitleC;
}

int Menu::Exec (int y) {
  Menu *M,*L,*Last,*Save;
  int
    maxx,               // Maior comprimento x
    xi,                 // Inicio da janela em x
    totop=0,            // Total de opcoes
    j=0,                // Variavel temporaria
    lop=1,              // Ultima opcao absoluta escolhida
    op=1;               // Opcao absoluta escolhida
  char c;

  // Verifica se o menu esta vazio
  if (!OpNumber) {
    cout << "Menu vazio\n";
    return MenuEmpty;
  }
  // Acha o comprimento horizontal da janela
  maxx=titlestr->Len();
  Save=M=this;
  while (M!=NULL) {
    if (M->item.Len()>maxx)
      maxx=M->item.Len();
    totop++;
    Last=M;
    M=M->Next;
  }
  xi=(MaxResX-maxx)/2-2;
  // Desenha a janela
  Cursor (0);
  SetColors (bordercolor, backcolor);
  DrawWindow (xi,y,xi+maxx+3,y+3+totop);
  SetPos ((MaxResX-titlestr->Len())/2,y);
  SetColors (titlecolor, backcolor);
  Write (*titlestr);
  M=Save;
  SetColors (txtcolor, backcolor);
  while (M!=NULL) {
    SetPos ((MaxResX-M->item.Len())/2,y+2+j);
    Write (M->item);
    j++;
    M=M->Next;
  }
  M=Save;
  SetColors (choosecolor,backcolor);
  SetPos ((MaxResX-(M->item.Len()))/2,y+2);
  Write (M->item);
  // Laco principal
  L=Save;
  do {
    if (lop!=op) {
      SetPos ((MaxResX-L->item.Len())/2,y+1+lop);
      SetColors (txtcolor, backcolor);
      Write (L->item);
      SetPos ((MaxResX-M->item.Len())/2,y+1+op);
      SetColors (choosecolor, backcolor);
      Write (M->item);
      lop=op;
      L=M;
    }
    c=getch ();
    if (!c) {
      switch (getch ()) {
        case 72:                //up
          op--;
          M=M->Prev;
          if (M==NULL) {
            M=Last;
            op=M->OpNumber;
          }
          break;
        case 80:                //down
          op++;
          M=M->Next;
          if (M==NULL) {
            M=Save;
            op=1;
          }
          break;
      }
    }
  } while (c!=13 && c!=27);
  SetPos (1,20);
  Cursor (1);
  if (c==13)
    return MenuOk;
  else
    return MenuEsc;
}

int Menu::Choice (void) {
  return Result;
}

void Menu::DrawWindow (int x1, int y1, int x2, int y2) {
  string Linha (196,x2-x1-1),Espacos (32,x2-x1-1);
  int y;

  gotoxy (x1,y1);
  cprintf ("%c%s%c",218,Linha.c(),191);
  for (y=y1+1; y<=y2-1; y++) {
    gotoxy (x1,y);
    cprintf ("%c%s%c",179,Espacos.c(),179);
  }
  gotoxy (x1,y2);
  cprintf ("%c%s%c",192,Linha.c(),217);
}

void Menu::AddTitle (string t) {
  Title=1;
  titlestr=new string;
  *titlestr=t;
}