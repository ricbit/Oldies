#include <stdio.h>
#include <malloc.h>
#include <math.h>
#include <conio.h>
#include <\borlandc\doom\fgraph.h>

#define pi2 2*3.1415926535

typedef unsigned char byte;

double isin (int i) {
  return sin ((double)i/63.0*pi2);
}

double icos (int i) {
  return cos ((double)i/63.0*pi2);
}

void main (void) {
  int phi,theta,i,alpha,beta;
  double v,*table;

  table=(double *) malloc (4100*sizeof (double));
  InitGraph ();
  for (i=0; i<64; i++)
    SetRGB ((byte)i,(byte)i,(byte)i,(byte)i);
  for (i=0; i<4096; i++) {
    theta=i%64;
    phi=i/64;
    v=cos ((double)theta/63.0*pi2)*sin ((double)phi/63.0*pi2)*63.0;
    if (v>0) {
      table[i]=v;
      PutPixel (theta,phi,(byte)v);
    } else table[i]=0;
  }
  for (i=0; i<4096; i++) {
    theta=i%64;
    phi=i/64;
    PutPixel (theta+100,phi,(byte)(table[i]));
  }
  for (i=0; i<4096; i++) {
    theta=(i+632)%64;
    phi=(i+632)/64;
    PutPixel (i%64+200,i/64,(byte)(table[(i+632)%4096]));
  }
  for (i=0; i<4096; i++) {
    theta=i%64;
    phi=i/64;
    alpha=(i+632)%64;
    beta=(i+632)/64;
    v=icos (theta)*icos (alpha)*isin (phi)*isin (beta)+
      isin (theta)*isin (alpha)*isin (phi)*isin (beta)+
      icos (phi)*icos (beta);
    v*=63.0;
    PutPixel (i%64+200,i/64+100,(byte)v);
  }
  getch ();
  CloseGraph ();
}