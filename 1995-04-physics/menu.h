// Menu.h
// Ricardo Bittencourt

#ifndef kMenu
#define kMenu

#include <iostream.h>
#include <conio.h>
#include <dos.h>
#include "StrClass.h"

#define MenuOk 0
#define MenuEsc 1
#define MenuEmpty 2

class Menu {
public:
  // Constructor
  Menu (void);
  // Destrcutor
  ~Menu (void);
  // Desenha uma janela
  virtual void DrawWindow (int x1, int y1, int x2, int y2);
  // Posiciona o cursor
  virtual void SetPos (int x, int y);
  // Escreve na tela
  virtual void Write (string s);
  // Troca as cores
  virtual void SetColors (int fore, int back);
  // a=1 Apresenta o cursor a=0 Some o cursor
  virtual void Cursor (int a);
  // Adiciona um item ao menu
  void operator+= (string s);
  // Executa o menu na posicao vertical y e retorna o codigo de erro
  int Exec (int y);
  // Retorna o item escolhido (primeiro=1)
  inline int Choice (void);
  // Muda as cores
  void Colors (int BackC, int TextC, int ChooseC, int BorderC, int TitleC);
  // Adiciona um titulo
  void AddTitle (string t);

private:
  Menu *Next,*Prev;
  string item,*titlestr;
  int ErrorCode,OpNumber,Result;
  int Title;
  int SpacesChar,MaxResX;
  int titlecolor,bordercolor,backcolor,txtcolor,choosecolor;

  void InitPointers (void);
};

#endif