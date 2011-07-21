// RBRT 1.0
// by Ricardo Bittencourt
// Module SPHERE.CPP

#include <stdio.h>
#include <math.h>
#include "sphere.h"

// class Sphere

void Sphere::SetCenter (Vector C) {
  Center=C;
}

void Sphere::SetRadius (double R) {
  Radius=R;
}

void Sphere::Intersect (Reta R, PointList *P) {
  double a,b,c,d;
  Vector E;

  E=R.O-Center;
  a=R.R*R.R;
  b=2.0*(E*R.R);
  c=E*E-Radius2;
  d=b*b-4.0*a*c;
  if (d<0.0) return;
  a=0.5/a;
  d=sqrt (d)*a;
  b*=-a;
  P->Insert (b-d,this);
  P->Insert (b+d,this);
}

void Sphere::Print (void) {
  printf ("Sphere:\n");
  printf ("\tCenter: (%f,%f,%f)\n",Center.dx,Center.dy,Center.dz);
  printf ("\tRadius: %f\n",Radius);
}

Vector Sphere::Normal (Vector v) {
  return (v-Center)*InverseRadius;
}

void Sphere::Init (void) {
  Radius2=Radius*Radius;
  InverseRadius=1.0/Radius;
}
