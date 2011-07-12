// Ray 2.0
// Surface.cpp

// Ray 2.0
// Surface.cpp

#include "Surface.h"

Surface::Surface (void) {
  cor=Vetor (0,0,0);
  kdl=1;
  ksl=0;
  csl=0;
}

Surface::Surface (Vetor c) {
  cor=c;
  kdl=1;
  ksl=0;
  csl=0;
}

Surface::Surface (Vetor c, Float KDL, Float KSL, Float CSL) {
  cor=c;
  kdl=KDL;
  ksl=KSL;
  csl=CSL;
}

void Surface::operator= (Surface x) {
  cor=x.cor;
  kdl=x.kdl;
  ksl=x.ksl;
  csl=x.csl;
}

ostream& _Cdecl operator<< (ostream &a, Surface s) {
  if (s.ksl==0)
    return a << "Cor: " << s.cor << "\n";
  else
    return a << "Difusa: " << s.kdl << ":" << s.cor
             << "\tEspecular: " << s.ksl << "^" << s.csl << "\n";
}
