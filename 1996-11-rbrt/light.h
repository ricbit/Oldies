// RBRT 1.0
// by Ricardo Bittencourt
// Module LIGHT_H

#ifndef __LIGHT_H
#define __LIGHT_H

#include "vector.h"
#include "object.h"

class Light {
protected:
  Vector Color;
public:
  virtual Vector Shade (Vector P, Vector Normal, Object *Scene)=0;
  virtual void Print (void)=0;
  void SetColor (Vector c);
};

class PunctualLight: public Light {
private:
  Vector Position;
public:
  void SetPosition (Vector Pos);
  Vector Shade (Vector P, Vector Normal, Object *Scene);
  void Print (void);
};

typedef struct LightElement {
  Light *light;
  LightElement *next;
} LightElement;

class LightList {
private:
  LightElement *list,*last;
public:
  LightList ();
  void Insert (Light *l);
  Vector Shade (Vector P, Vector Normal, Object *scene);
  void Print (void);
};

#endif

