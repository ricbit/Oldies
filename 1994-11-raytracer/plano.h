// Ray 2.0
// Plano.h

#ifndef kPlano
#define kPlano

#include <iostream.h>
#include <math.h>
#include "YoMath.h"
#include "Surface.h"
#include "Objects.h"

class InfPlane: public Objeto {
public:
  Plano p;
  Vetor n,nn;
  Float d;
  // Constructors
  InfPlane (Plano P, Surface surf);
  // Interseccao
  virtual void Intersect (Reta r, Ponto *p);
  // Vetor normal
  virtual Vetor Normal (Vetor v);
  // Saida para texto
  virtual ostream& _Cdecl operator<< (ostream &a);
};

#endif