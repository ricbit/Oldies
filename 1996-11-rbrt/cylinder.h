// RBRT 1.0
// by Ricardo Bittencourt
// Module CYLINDER.H

#ifndef __CYLINDER_H
#define __CYLINDER_H

#include "object.h"

class Cylinder: public Object {
private:
  Vector Center,Axis;
  double Radius,Radius2,InverseRadius;
  double thetaA,phiA,Length;
public:  
  void SetCenter (Vector C);
  void SetAxis (Vector A);
  void SetRadius (double R);
  void SetLength (double L);
  void Intersect (Reta R, PointList *P);
  void Print (void);
  Vector Normal (Vector v);
  void Init (void);
};

#endif

