// Ray 2.0
// YoMath.cpp

#include "YoMath.h"

// procedures do Vetor

Vetor::Vetor (Float xx, Float yy, Float zz) {
  v[0]=xx;
  v[1]=yy;
  v[2]=zz;
  v[3]=1;
}

Float Vetor::operator* (Vetor a) {
  return (v[0]*a.v[0]+v[1]*a.v[1]+v[2]*a.v[2]);
}

Vetor Vetor::operator* (Float lambda) {
  return Vetor (lambda*v[0],lambda*v[1],lambda*v[2]);
}

Vetor Vetor::operator& (Vetor a) {
  return Vetor (v[0]*a.v[0],v[1]*a.v[1],v[2]*a.v[2]);
}

void Vetor::operator= (Vetor a) {
  v[0]=a.v[0];
  v[1]=a.v[1];
  v[2]=a.v[2];
}

Vetor Vetor::operator+ (Vetor a) {
  return Vetor (v[0]+a.v[0],v[1]+a.v[1],v[2]+a.v[2]);
}

Vetor Vetor::operator- (Vetor a) {
  return Vetor (v[0]-a.v[0],v[1]-a.v[1],v[2]-a.v[2]);
}

Vetor Vetor::operator^ (Vetor a) {
  return Vetor (v[1]*a.v[2]-v[2]*a.v[1],
                v[2]*a.v[0]-v[0]*a.v[2],
                v[0]*a.v[1]-v[1]*a.v[0]);
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

Vetor Vetor::operator! (void) {
  return (*this) * (1/sqrt ((*this) * (*this)));
}

Vetor Vetor::operator~ (void) {
  Float k;
  Vetor x;
  int i;
  k=v[0];
  if (v[1]>k) k=v[1];
  if (v[2]>k) k=v[2];
  if (k<=1) return *this;
  for (i=0; i<=2; i++)
    x.v[i]=v[i]/k;
  return x;
}

// procedures da Reta

Reta::Reta (Float xo, Float yo, Float zo,
	    Float xr, Float yr, Float zr) {
  o=Vetor (xo,yo,zo);
  r=Vetor (xr,yr,zr);
}

Reta::Reta (Vetor a, Vetor b) {
  o=a;
  r=b;
}

void Reta::TwoPoints (Vetor V1, Vetor V2) {
  o=V1;
  r=V2-V1;
}

void Reta::Normalize (void) {
  r=!r;
}

Vetor Reta::operator| (Float t) {
  return o+r*t;
}

// procedures do Plano

Plano::Plano (Float xo, Float yo, Float zo,
	      Float xu, Float yu, Float zu,
	      Float xv, Float yv, Float zv) {
  o=Vetor (xo,yo,zo);
  u=!Vetor (xu,yu,zu);
  v=!Vetor (xv,yv,zv);
}

Plano::Plano (Vetor a, Vetor b, Vetor c) {
  o=a;
  u=b;
  v=c;
}

ostream& _Cdecl operator<< (ostream &a, Vetor &v) {
  return a << "(" << v.v[0] << "," << v.v[1] << "," << v.v[2] << ")";
}

ostream& _Cdecl operator<< (ostream &a, Reta &r) {
  return a << r.o << "+t*" << r.r;
}

ostream& _Cdecl operator<< (ostream &a, Plano &p) {
  return a << "[" << p.o << ";" << p.u << ";" << p.v << "]";
}


