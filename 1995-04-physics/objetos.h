// Demetrio 1.0
// Objetos.h

#ifndef __OBJETOS_H
#define __OBJETOS_H

#include <graphics.h>
#include <dos.h>
#include "parser.h"

class Objeto {
public:
  double xmax, ymax, xmin, ymin;
  virtual void Precalculate (double ti, double tf, int frames) {};
  virtual void Draw (int frame) {};
};

class Scene {
public:
  void Animate (void);
  void Precalculate (double ti, double tf, int fr);
  Objeto *obj;
private:
  double xmax, ymax, xmin, ymin;
  int frames;
};

#endif