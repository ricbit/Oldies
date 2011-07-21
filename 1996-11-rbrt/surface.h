// RBRT 1.0
// by Ricardo Bittencourt
// Module SURFACE_H

#ifndef __SURFACE_H
#define __SURFACE_H

#include "vector.h"

class Surface {
private:
  Vector Color;
  double ka,kd,ks;
public:
  void SetColor (Vector c);
  void SetKa (double x);
  void SetKd (double x);
  void SetKs (double x);
  double GetKs (void);
  Vector Apply (Vector shade, Vector reflected);
};

#endif

