// RBRT 1.0
// by Ricardo Bittencourt
// Module CYLINDER.CPP

#include <stdio.h>
#include <math.h>
#include "cylinder.h"

// class Cylinder

void Cylinder::SetCenter (Vector C) {
  Center=C;
}

void Cylinder::SetAxis (Vector A) {
  Axis=!A;
  thetaA=atan2 (Axis.dy,Axis.dx);
  phiA=acos (Axis.dz);
}

void Cylinder::SetRadius (double R) {
  Radius=R;
}

void Cylinder::SetLength (double L) {
  Length=L;
}

void Cylinder::Intersect (Reta R, PointList *P) {
  Vector SO,SR,RR;
  double thetaR,phiR;
  double a,b,c,delta;
  double z1,z2,t1,t2;
  
  SO=R.O-Center;  
  
  RR=!(R.R);  
  if (Abs (RR.dx*RR.dx+RR.dy*RR.dy+RR.dz*RR.dz)<epsilon) return;
  thetaR=atan2 (R.R.dy,R.R.dx)-thetaA;
  phiR=acos (R.R.dz)-phiA;
  SR=Vector (cos (thetaR)*sin (phiR),sin (thetaR)*sin (phiR),cos (phiR));
  
  a=SR.dx*SR.dx+SR.dy*SR.dy;  
  b=2*(SO.dx*SR.dx+SO.dy*SR.dy);
  c=SO.dx*SO.dx+SO.dy*SO.dy-Radius2;
  delta=b*b-4*a*c;

  if (delta<0.0) return;

  a=0.5/a;
  delta=sqrt (delta)*a;
  b*=-a;

  t1=b-delta;
  t2=b+delta;

  z1=SO.dz+t1*SR.dz;
  z2=SO.dz+t2*SR.dz;

  if (z1>0.0 && z1<Length)    
    P->Insert (t1,this);

  if (z2>0.0 && z2<Length)    
    P->Insert (t2,this);
}

void Cylinder::Print (void) {
  printf ("Cylinder:\n");
  printf ("\tCenter: (%f,%f,%f)\n",Center.dx,Center.dy,Center.dz);
  printf ("\tAxis: (%f,%f,%f)\n",Axis.dx,Axis.dy,Axis.dz);
  printf ("\tRadius: %f\n",Radius);
}

Vector Cylinder::Normal (Vector v) {
//  return (v-Center)*InverseRadius;
  return Vector (1,1,1);
}

void Cylinder::Init (void) {
  Radius2=Radius*Radius;
  InverseRadius=1.0/Radius;
}
