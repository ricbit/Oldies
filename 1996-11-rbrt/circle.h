// RBRT 1.0
// by Ricardo Bittencourt
// Module CIRCLE.H

#ifndef __CIRCLE_H
#define __CIRCLE_H

#include "object.h"

class Circle: public Object {
private:
  Vector Center,dirU,dirV;
  Vector Norm;
  double d,Radius,Radius2;
public:  
  void SetCenter (Vector x);
  void SetdirU (Vector x);
  void SetdirV (Vector x);
  void SetRadius (double r);
  void Intersect (Reta R, PointList *P);
  void Print (void);
  Vector Normal (Vector v);
  void Init (void);
};

#endif

