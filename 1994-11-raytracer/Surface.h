// Ray 2.0
// Surface.h

#ifndef kSurface
#define kSurface

#include <iostream>
#include "YoMath.h"

#ifndef __BORLANDC__
#define _Cdecl
#endif

using namespace std;

class Surface {
public:
  Vetor cor;
  Float kdl,ksl,csl;

  // Constructors
  Surface (void);
  Surface (Vetor c);
  Surface (Vetor c, Float KDL, Float KDS, Float CSL);
  // Atribuicao
  void operator= (Surface x);
};

ostream& _Cdecl operator<< (ostream &a, Surface s);

#endif
