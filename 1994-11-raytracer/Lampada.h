// Ray 2.0
// Lampada.h

#ifndef kLampada
#define kLampada

#include <math.h>
#include "YoMath.h"
#include "Objects.h"

class Light {
public:
  Vetor o,cor;

  // Constructor
  Light (Vetor O, Vetor C);
};

class LightList {
public:
  Light *L;
  LightList *Prox;

  // Constructor
  LightList (void);
  // Inclui uma lampada na lista de lampadas
  void operator+= (Light *l);
  // Verifica se um ponto nao esta sombreado em relacao a uma lampada
  int Shadow (Vetor pos, Vetor lamp, List list);
  // Calcula a cor total de um ponto devido a todas as lampadas
  Vetor LightSources (Ponto P, Reta r, List list);
};

ostream& _Cdecl operator<< (ostream &a, Light &l);
ostream& _Cdecl operator<< (ostream &a, LightList &l);

#endif
