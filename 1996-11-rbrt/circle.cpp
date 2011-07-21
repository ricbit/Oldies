// RBRT 1.0
// by Ricardo Bittencourt
// Module CIRCLE.CPP

#include <stdio.h>
#include "circle.h"

// class Circle

void Circle::SetRadius (double r) {
  Radius=r;
  Radius2=r*r;
}

void Circle::SetCenter (Vector x) {
  Center=x;  
}

void Circle::SetdirU (Vector x) {
  dirU=x;  
}

void Circle::SetdirV (Vector x) {
  dirV=x;
}

void Circle::Init (void) {
  Norm = !(dirU^dirV);
  d=Norm*Center;
}

void Circle::Intersect (Reta R, PointList *P) {
  double x,t;
  Vector Hit;

  x=R.R*Norm;
  if (Abs (x)>epsilon) {
    t=(d-R.O*Norm)/x;    
    Hit=R.O+R.R*t-Center;
    if (Hit*Hit<=Radius2)
      P->Insert (t,this);
  }
}

Vector Circle::Normal (Vector v) {
  return Norm;
}

void Circle::Print (void) {
  printf ("Circle\n");
  printf ("\tCenter (%f,%f,%f)\n",Center.dx,Center.dy,Center.dz);
  printf ("\tdirU (%f,%f,%f)\n",dirU.dx,dirU.dy,dirU.dz);
  printf ("\tdirV (%f,%f,%f)\n",dirV.dx,dirV.dy,dirV.dz);
  printf ("\tRadius %f\n",Radius);
}

