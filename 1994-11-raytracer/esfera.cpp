// Ray 2.0
// Esfera.cpp

#include "Esfera.h"

// Procedures da Esfera

Esfera::Esfera (Vetor Origem, Float Raio, Surface surf) {
  o=Origem;
  r=Raio;
  ir=1/r;
  r2=r*r;
  s=surf;
}

void Esfera::Intersect (Reta r, Ponto *p) {
  Vetor v1;
  Float a,b,c,d,l,t;
  v1=r.o-o;
  a=r.r*r.r;
  b=(v1*r.r)*2;
  c=(v1*v1)-r2;
  d=b*b-4*a*c;
  if (d<0) return;
  a*=2;
  l=-b/a;
  d=sqrt (d)/a;
  t=l-d;
  p->Inclui (t,this);
  t=l+d;
  p->Inclui (t,this);
}

Vetor Esfera::Normal (Vetor v) {
  return (v-o)*ir;
}

ostream& _Cdecl Esfera::operator<< (ostream &a) {
  ostream_withassign x;
  x=a << "Esfera\n\tCentro " << o << "\n\tRaio " << r;
  x=x << "\n\t" << s << "\n";
  return x;
}

