// RBRT 1.0
// by Ricardo Bittencourt
// Module SPHERE.H

#ifndef __SPHERE_H
#define __SPHERE_H

#include "object.h"

class Sphere: public Object {
private:
  Vector Center;
  double Radius,Radius2,InverseRadius;
public:  
  void SetCenter (Vector C);
  void SetRadius (double R);
  void Intersect (Reta R, PointList *P);
  void Print (void);
  Vector Normal (Vector v);
  void Init (void);
};

#endif

