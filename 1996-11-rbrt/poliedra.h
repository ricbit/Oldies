// RBRT 1.0
// by Ricardo Bittencourt
// Module POLIEDRA.H

#ifndef __POLIEDRA_H
#define __POLIEDRA_H

#include "object.h"

typedef struct {
  double t;
  Vector N;
} PointInfo;

class Face {
private:
  int maxvertex;
  Vector side[50];
  double d;
  Vector Normal;
public:
  Vector vertex[50];
  Face ();
  void SetVertex (Vector v);
  void Init (void);
  PointInfo Intersect (Reta R);
};

class Poliedra: public Object {
private:
  Vector vertex[50];
  Face face[50];
  int maxvertex;
  int maxface;
  Vector CurrentNormal;
  Vector Center;
  double Radius,Radius2,InverseRadius;
  unsigned char *texture;
public:  
  Poliedra ();
  void SetVertex (int number, Vector v);
  void SetFace (Vector v);
  void SetCenter (Vector C);
  void SetRadius (double R);
  void Intersect (Reta R, PointList *P);
  void Print (void);
  void Init (void);
  Vector Normal (Vector v);
};

#endif

