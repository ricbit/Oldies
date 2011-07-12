// Demetrio 1.0
// DemTeste.cpp

#include <iostream.h>
#include "objetos.h"
#include "bolinha.h"

void main (void) {
  Scene S;
  char *xt,*yt;

  cout << "Entre equacao parametrica x(t) ";
  cin >> xt;
  cout << "Entre equacao parametrica y(t) ";
  cin >> yt;
  Bolinha B(xt,yt);
  S.obj = &B;
  S.Precalculate(0.0, 2*3.14159265, 320);
  S.Animate();
}
