// RBRT 1.0
// by Ricardo Bittencourt
// Module SURFACE.CPP

#include "surface.h"

// class Surface

void Surface::SetColor (Vector c) {
  Color=c;
}

Vector Surface::Apply (Vector shade, Vector reflected) {
  return ~(Color*ka+(shade&Color)*kd+(reflected&Color)*ks);
}

void Surface::SetKa (double x) {
  ka=x;
}

void Surface::SetKd (double x) {
  kd=x;
}

void Surface::SetKs (double x) {
  ks=x;
}

double Surface::GetKs (void) {
  return ks;
}

