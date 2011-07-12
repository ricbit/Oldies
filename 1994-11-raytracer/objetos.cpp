// Ray 2.0
// Objetos.h

#include <iostream.h>
#include <math>
#include "Objetos.h"

Vetor::Vetor (Float xx=0, Float yy=0, Float zz=0) {
  v[0]=xx;
  v[1]=yy;
  v[2]=zz;
  v[3]=1;
}

Float Vetor::operator* (Vetor a) {
  return (v[0]*a.v[0]+v[1]*a.v[1]+v[2]*a.v[2]);
}


Vetor Vetor::operator* (Float lambda) {
  Vetor r;
  r.v[0]=lambda*v[0];
  r.v[1]=lambda*v[1];
  r.v[2]=lambda*v[2];
  return (r);
}


Vetor Vetor::operator= (Vetor a) {
  v[0]=a.v[0];
  v[1]=a.v[1];
  v[2]=a.v[2];
}

Vetor Vetor::operator+ (Vetor a) {
  Vetor r;
  r.v[0]=v[0]+a.v[0];
  r.v[1]=v[1]+a.v[1];
  r.v[2]=v[2]+a.v[2];
  return (r);
}


Vetor Vetor::operator- (Vetor a) {
  Vetor r;
  r.v[0]=v[0]-a.v[0];
  r.v[1]=v[1]-a.v[1];
  r.v[2]=v[2]-a.v[2];
  return (r);
}


int Vetor::operator== (Vetor a) {
  return((fabs(v[0]-a.v[0])<eps)&&
         (fabs(v[1]-a.v[1])<eps)&&
         (fabs(v[2]-a.v[2])<eps));
}


void Vetor::operator+= (Vetor a) {
  v[0]+=a.v[0];
  v[1]+=a.v[1];
  v[2]+=a.v[2];
}

void Vetor::operator-= (Vetor a) {
  v[0]-=a.v[0];
  v[1]-=a.v[1];
  v[2]-=a.v[2];
}

void Vetor::operator*= (Float lambda) {
  v[0]*=lambda;
  v[1]*=lambda;
  v[2]*=lambda;
}

void Vetor::Print (void) {
  cout << "(" << v[0] << "," << v[1] << "," << v[2] << ")\n";
}