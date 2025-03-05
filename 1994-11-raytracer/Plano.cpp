// Ray 2.0
// Plano.cpp

#include "Plano.h"

// Procedures do InfPlane

InfPlane::InfPlane (Plano P, Surface surf) {
  p=P;
  n=p.u^p.v;
  nn=!n;
  d=n*p.o;
  s=surf;
}

void InfPlane::Intersect (Reta r, Ponto *p) {
  Float t,k;
  k=n*r.r;
  if (fabs (k)<eps) return;
  t=(d-(n*r.o))/k;
  p->Inclui (t,this);
}

Vetor InfPlane::Normal (Vetor v) {
  return nn;
}

ostream& _Cdecl InfPlane::operator<< (ostream &a) {
  return a << "Plano infinito: " << p << "\n\t" << s << "\n";
}

