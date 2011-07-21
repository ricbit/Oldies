// RBRT 1.0
// by Ricardo Bittencourt
// Module PLANE_H

#ifndef __PLANE_H
#define __PLANE_H

#include "object.h"

class Plane: public Object {
private:
  Vector Center,dirU,dirV;
  Vector Norm;
  double d;
public:  
  void SetCenter (Vector x);
  void SetdirU (Vector x);
  void SetdirV (Vector x);
  void Intersect (Reta R, PointList *P);
  void Print (void);
  Vector Normal (Vector v);
  void Init (void);
};

#endif

