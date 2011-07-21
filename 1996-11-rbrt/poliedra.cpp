
// RBRT 1.0
// by Ricardo Bittencourt
// Module POLIEDRA.CPP

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include "poliedra.h"

// class Face

Face::Face () {
  maxvertex=0;
}

void Face::SetVertex (Vector v) {
  vertex[maxvertex++]=v;
}

void Face::Init (void) {
  int i;

  for (i=0; i<maxvertex; i++)
    side[i]=vertex[(i+1)%maxvertex]-vertex[i];

  Normal=!(side[1]^side[0]);
  d=Normal*vertex[0];
}

PointInfo Face::Intersect (Reta R) {
  double x,t;
  Vector Hit;
  PointInfo p;
  int i,flag=1;

  x=R.R*Normal;
  if (Abs (x)>epsilon) {
    t=(d-R.O*Normal)/x;    
    Hit=R.O+R.R*t;
    for (i=0; i<=maxvertex; i++) {
      if ((((Hit-vertex[i])^(side[i]))*Normal)<0.0)
        flag=0;        
    }
    if (flag) {
      p.N=Normal;
      p.t=t;
      return p;
    }
  }
  p.t=-1.0;
  return p;
}

// class Poliedra

Poliedra::Poliedra () {
  maxvertex=0;
  maxface=0;
}

void Poliedra::SetVertex (int number, Vector v) {
  vertex[number]=v;
  if (maxvertex<number) maxvertex=number;
}

void Poliedra::SetFace (Vector v) {
  face[maxface].SetVertex (vertex[int(v.dx)]);
  face[maxface].SetVertex (vertex[int(v.dy)]);
  face[maxface].SetVertex (vertex[int(v.dz)]);
  maxface++;
}

void Poliedra::SetCenter (Vector C) {
  Center=C;
}

void Poliedra::SetRadius (double R) {
  Radius=R;
}

void Poliedra::Intersect (Reta R, PointList *P) {
  double a,b,c,d;
  Vector E;
  int i;
  Reta RR;
  PointInfo Chosen,Actual;
  int flag=0;
  int facenumber=0;

  E=R.O-Center;
  a=R.R*R.R;
  b=2.0*(E*R.R);
  c=E*E-Radius2;
  d=b*b-4.0*a*c;
  if (d<0.0) return;
  a=0.5/a;
  d=sqrt (d)*a;
  b*=-a;
  
  
  /* P->Insert (b-d,this); */
  /* P->Insert (b+d,this); */

  RR.O=R.O+R.R*(b-d);
  RR.R=!(Center-RR.O);

  Chosen.t=1e6;
  for (i=0; i<maxface; i++) {
    Actual=face[i].Intersect(RR);
    if (Actual.t>0.0 && Actual.t<Chosen.t) {
      Chosen=Actual;
      flag=1;
      facenumber=i;
    }
  }
  if (flag) {    
      Vector Hit;
      Vector v1,v2;
      double tx,ty;
      int txi,tyi;

      /* facenumber */
      Hit=RR.O+RR.R*Chosen.t;

      v2=(face[facenumber].vertex[2]-face[facenumber].vertex[0]);
      v1=(face[facenumber].vertex[1]-face[facenumber].vertex[0]);

      v1=v1-((!v2)*(v1*(!v2)));

      tx=(Hit-face[facenumber].vertex[0])*v1;
      ty=(Hit-face[facenumber].vertex[0])*v2;
      txi=int (ty*253.0);
      tyi=218-int (tx*218.0);

      this->surface->SetColor (Vector (
/*        tx,ty,0.0 )); */

        (double)texture[(254*tyi+txi)*3+0]/255.0,
        (double)texture[(254*tyi+txi)*3+1]/255.0,
        (double)texture[(254*tyi+txi)*3+2]/255.0 ));
  
      P->Insert (b-d,this);
  }

  
}

void Poliedra::Init (void) {
  int i;

  for (i=0; i<maxface; i++)
    face[i].Init ();
  Radius2=Radius*Radius;
  InverseRadius=1.0/Radius;

  texture=new unsigned char[254*219*3];
  i=open ("texture.rgb",O_BINARY|O_RDONLY);
  read (i,texture,254*219*3);
  close (i);
}

Vector Poliedra::Normal (Vector v) {
  return (v-Center)*InverseRadius;
}

void Poliedra::Print (void) {
  int i;
  printf ("Poliedra %d\n",maxvertex);
  /*
  for (i=0; i<=maxvertex; i++)
    printf ("Vertex %d: (%.4f,%.4f,%.4f)\n",i,
            vertex[i].dx,vertex[i].dy,vertex[i].dz);
  for (i=0; i<maxface; i++) {
    printf ("Face %d: (%.4f,%.4f,%.4f)\n",i,
            face[i].vertex[0].dx,
            face[i].vertex[0].dy,
            face[i].vertex[0].dz);
    printf ("Face %d: (%.4f,%.4f,%.4f)\n",i,
            face[i].vertex[1].dx,
            face[i].vertex[1].dy,
            face[i].vertex[1].dz);
    printf ("Face %d: (%.4f,%.4f,%.4f)\n",i,
            face[i].vertex[2].dx,
            face[i].vertex[2].dy,
            face[i].vertex[2].dz);
  }
  */
}

