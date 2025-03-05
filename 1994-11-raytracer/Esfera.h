// Ray 2.0
// Esfera.h

#ifndef kEsfera
#define kEsfera

#include "Compiler.h"
#include "YoMath.h"
#include "Surface.h"
#include "Objects.h"

class Esfera: public Objeto {
public:
//  Surface s;
  Vetor o;
  Float r,r2,ir;
  // Constructors
  Esfera (Vetor Origem, Float Raio, Surface surf);
  // Interseccao
  virtual void Intersect (Reta r, Ponto *p);
  // Vetor normal
  virtual Vetor Normal (Vetor v);
  // Saida para texto
  virtual ostream& _Cdecl operator<< (ostream &a);
};

#endif
