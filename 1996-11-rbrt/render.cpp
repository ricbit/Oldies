// RBRT 1.0
// by Ricardo Bittencourt
// Module RENDER_CPP

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <conio.h>
#include <math.h>
#include <time.h>
#include "vesa.h"
#include "light.h"
#include "render.h"

int BoardType,ResX=1024,ResY=768;
double threshold;
Object *scene;
extern LightList *lightlist;
Vector Observer;
int interpolation=0;
int RaysShooted=0,Pixels=0;
double reflection;

Vector ShootRay (Reta R, double Relative) {
  PointList *P;
  Point *hit;
  Vector Target;
  Vector color;
  Vector Normal;
  Vector Zero (0,0,0);
  Reta S;

  if (Relative<reflection) 
    return Zero;
  RaysShooted++;
  P=new PointList;
  scene->Intersect (R,P);
  hit=P->First ();
  if (hit!=NULL) {
    Target=R.O+R.R*hit->t;
    Normal=hit->owner->Normal (Target);
    color=lightlist->Shade (Target,Normal,scene);
    delete P;
    if (hit->owner->surface->GetKs()!=0.0) {
      S.O=Target+Normal*epsilon;
      S.R=R.R-Normal*(R.R*Normal)*2.0;
      return 
        hit->owner->surface->Apply 
         (color,ShootRay (S,Relative*hit->owner->surface->GetKs()));
    }
    else 
      return hit->owner->surface->Apply (color,Zero);
  }
  else {
    delete P;
    return Zero;
  }
}

RGB MakeRGB (Vector color) {
  RGB rgb;

  rgb.r=int (255.0*color.dx);
  rgb.g=int (255.0*color.dy);
  rgb.b=int (255.0*color.dz);
  return rgb;
}

Reta BuildReta (int x, int y) {
  double px,py;
  Reta R;
  
  px=(double (x))/double(ResX)*2.0-1.0;
  py=(double (y))/double(ResY)*2.0-1.0;
  R.O=Observer;
  R.R=Vector (px,py,-1.0)-R.O;
  return R;
}

double diff (Vector a, Vector b) {
  return Abs (a.dx-b.dx)+Abs (a.dy-b.dy)+Abs (a.dz-b.dz);
}

void Draw (int x1, int y1, int length) {
  Vector t1,t2,t3,t4;  
  int x2,y2;

  x2=x1+length-1;
  y2=y1+length-1;
  if (length==2) {
    Pixels+=4;
    PutPixel (x1,y1,MakeRGB (ShootRay (BuildReta (x1,y1),1.0)));
    PutPixel (x2,y1,MakeRGB (ShootRay (BuildReta (x2,y1),1.0)));
    PutPixel (x1,y2,MakeRGB (ShootRay (BuildReta (x1,y2),1.0)));
    PutPixel (x2,y2,MakeRGB (ShootRay (BuildReta (x2,y2),1.0)));
  } 
  else {
    int factor;

    t1=ShootRay (BuildReta (x1,y1),1.0);
    t2=ShootRay (BuildReta (x2,y1),1.0);
    t3=ShootRay (BuildReta (x1,y2),1.0);
    t4=ShootRay (BuildReta (x2,y2),1.0);
    if (diff (t1,t2)+diff (t2,t3)+diff (t3,t4)+diff (t4,t1)>threshold) {
      factor=length/2;
      Draw (x1,y1,factor);
      Draw (x1+factor,y1,factor);
      Draw (x1,y1+factor,factor);
      Draw (x1+factor,y1+factor,factor);
    }
    else {
      int i,j;
      double alpha,beta;
      Vector p1,p2,p3;

      Pixels+=4;
      if (interpolation) {
        alpha=1.0/double (x2-x1);
        beta=1.0/double (y2-y1);
        p1=t1;
        p2=t3;
        for (i=x1; i<=x2; i++) {
          p3=p1;        
          for (j=y1; j<=y2; j++) {
            PutPixel (i,j,MakeRGB (p3)); 
            p3+=(p2-p1)*beta;
          }
          p1+=(t2-t1)*alpha;
          p2+=(t4-t3)*alpha;
        }
      }
      else {
        int i,j;
        for (i=x1; i<=x2; i++)
          for (j=y1; j<=y2; j++)
            PutPixel (i,j,MakeRGB (t1));
      }
    }
  }
}

void Render (Object *o) {
  int x,y;
  clock_t time;

  scene=o;
  SetGraphMode ();
  Observer=Vector (0.0,0.0,-2.0);
  clock ();
  for (y=0; y<ResY; y+=32) {
    for (x=0; x<ResX; x+=32) {
      Draw (x,y,32);
    }
  }
  time=clock ();  
  getch ();
  RestoreTextMode ();
  printf ("Rays Shooted=%d\n",RaysShooted);
  printf ("Pixels=%d\n",Pixels);
  printf ("Average RS/P=%f\n",double(RaysShooted)/double(Pixels));
  printf ("Seconds=%f\n",double(time)/double(CLOCKS_PER_SEC));
  printf ("Miliseconds per pixel=%f\n",double(time)/double(CLOCKS_PER_SEC)/
          double(Pixels)*1000.0);
}
