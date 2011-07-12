// Ray 2.0
// Scene.h

#ifndef kScene
#define kScene

#include "YoMath.h"
#include "Objects.h"
#include "Lampada.h"

class Scene {
public:
  List l;               // Lista de objetos da cena
  LightList ll;         // Lista de lampadas;
  int Rx,Ry;            // Resolucao do arquivo de saida
  int Wx,Wy;            // Resolucao da janela do observador
  int x1,y1,x2,y2;      // Janela de renderizacao
  Vetor la;             // Luz ambiente
  Vetor Obs;            // Posicao do observador
  Plano Proj;           // Plano de projecao
  Vetor Back;           // Cor de fundo

  // Altera a resolucao de saida
  void OutRes (int x, int y);
  // Altera o tamanho da janela de projecao
  void WinRes (int x, int y);
  // Altera os limites de renderizacao
  void Limits (int X1, int Y1, int X2, int Y2);
  // Altera a luz ambiente
  void AmbLight (Vetor l);
  // Altera a posicao do observador
  void Observer (Vetor o);
  // Altera o plano de projecao
  void ProjPlane (Plano p);
  // Altera a cor de fundo
  void Background (Vetor b);
  // Acrescenta um objeto `a cena
  void operator+= (Objeto *o);
  // Acrescenta uma lampada `a cena
  void operator+= (Light *l);
};

ostream& _Cdecl operator<< (ostream &a, Scene &s);

#endif
