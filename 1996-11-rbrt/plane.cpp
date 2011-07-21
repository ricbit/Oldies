// RBRT 1.0
// by Ricardo Bittencourt
// Module PLANE.CPP

#include <stdio.h>
#include "plane.h"

// class Plane

void Plane::SetCenter (Vector x) {
  Center=x;  
}

void Plane::SetdirU (Vector x) {
  dirU=x;  
}

void Plane::SetdirV (Vector x) {
  dirV=x;
}

void Plane::Init (void) {
  Norm = !(dirU^dirV);
  d=Norm*Center;
}

void Plane::Intersect (Reta R, PointList *P) {
  double x;

  x=R.R*Norm;
  if (Abs (x)>epsilon)
    P->Insert ((d-R.O*Norm)/x,this);
}

Vector Plane::Normal (Vector v) {
  return Norm;
}

void Plane::Print (void) {
  printf ("Plane\n");
  printf ("\tCenter (%f,%f,%f)\n",Center.dx,Center.dy,Center.dz);
  printf ("\tdirU (%f,%f,%f)\n",dirU.dx,dirU.dy,dirU.dz);
  printf ("\tdirV (%f,%f,%f)\n",dirV.dx,dirV.dy,dirV.dz);
}

