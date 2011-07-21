// RBRT 1.0
// by Ricardo Bittencourt
// Module VECTOR_H

#ifndef __VECTOR_H
#define __VECTOR_H
                 
#include <math.h>

#define Abs(x) ((x)>0.0?(x):-(x))
#define epsilon 1e-6

class Vector {
public:
  double dx,dy,dz;

  Vector (double x=0, double y=0, double z=0) {
    dx=x;
    dy=y;
    dz=z;
  }
  void operator= (Vector v) {
    dx=v.dx;
    dy=v.dy;
    dz=v.dz;
  }
  Vector operator- (Vector a) {
    return Vector (dx-a.dx,dy-a.dy,dz-a.dz);
  }
  Vector operator+ (Vector a) {
    return Vector (dx+a.dx,dy+a.dy,dz+a.dz);
  }
  double operator* (Vector a) {
    return dx*a.dx+dy*a.dy+dz*a.dz;
  }
  Vector operator* (double k) {
    return Vector (k*dx,k*dy,k*dz);
  }
  Vector operator^ (Vector a) {
    return Vector (dy*a.dz-dz*a.dy,dz*a.dx-dx*a.dz,dx*a.dy-dy*a.dx);
  }
  Vector operator! (void) {
    double module=dx*dx+dy*dy+dz*dz;
    if (Abs (module)>epsilon) {
      module=1.0/sqrt (module);
      dx*=module;
      dy*=module;
      dz*=module;
    }
    return *this;
  }
  Vector operator~ (void) {
    dx=(dx>1.0?1.0:dx);
    dy=(dy>1.0?1.0:dy);
    dz=(dz>1.0?1.0:dz);
    return *this;
  }
  Vector operator+= (Vector a) {
    dx+=a.dx;
    dy+=a.dy;
    dz+=a.dz;
    return *this;
  }
  Vector operator& (Vector a) {
    return Vector (dx*a.dx,dy*a.dy,dz*a.dz);
  }
};

class Reta {
public:
  Vector O,R;
};

#endif

