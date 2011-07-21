// RBRT 1.0
// by Ricardo Bittencourt
// Module OBJECT.H

#ifndef __OBJECT_H
#define __OBJECT_H

#include "vector.h"
#include "surface.h"

class Object;

class Point {
public:
  double t;
  Object *owner;
  Point *next;
};

class PointList {
private:
  Point *list,*last;

public:
  PointList ();
  void Insert (double dist, Object *owner);
  void Print (void);
  Point *First (void);
  int Shadow (void);
  ~PointList ();
};

class Object {
public:  
  Surface *surface;
  virtual void Intersect (Reta R, PointList *P)=0;
  virtual void Print (void)=0;
  virtual Vector Normal (Vector v)=0;
  virtual void Init (void)=0;
};

class ObjectElement {
public:
  Object *obj;
  ObjectElement *next;
};

class ObjectList: public Object {
private:
  ObjectElement *list,*last;
public:
  ObjectList ();
  void Intersect (Reta R, PointList *P);
  void Insert (Object *o);
  void Print (void);
  Vector Normal (Vector v);
  void Init (void);
};

#endif

