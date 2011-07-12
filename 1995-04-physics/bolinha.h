// Demetrio 1.0
// Bolinha.h

#ifndef __BOLINHA_H
#define __BOLINHA_H

#include "Objetos.h"
#include "Parser.h"

typedef struct {
  double x;
  double y;
} bolinha_coords;

class Bolinha : public Objeto {
public:
  Bolinha (char *x="", char *y="");
  void Receive (char *x, char *y);
  virtual void Precalculate (double ti, double tf, int frames);
  virtual void Draw (int frame);
private:
  bolinha_coords *tabelao;
  double tabelao_ti, tabelao_tf;
  int tabelao_frames;
  Parser xt,yt;
};

#endif