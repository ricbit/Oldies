#include <stdio.h>
#include <allegro.h>
#include <conio.h>
#include <math.h>

typedef struct {
  double k;
  double x,y;
} fixed_coil;

typedef struct {
  double k;
  double rest;
  int number;
} dynamic_coil;

typedef struct {
  double x[3],y[3];
  double fx,fy;
  double vcx,vcy;
  double m;
  int color;
  fixed_coil *f;
  int fixed_number;
  dynamic_coil *d;
  int dynamic_number;
} particle;

int max=4;
double eps=1e-3;

void dynamic (particle *p) {
  int i,j;
  double rx,ry;
  double mod,tens;

  for (j=0; j<max; j++) {
    p[j].fx=0.0; p[j].fy=p->m;
    for (i=0; i<p[j].fixed_number; i++) {
      p[j].fx-=p[j].f[i].k*(p[j].x[0]-p[j].f[i].x);
      p[j].fy-=p[j].f[i].k*(p[j].y[0]-p[j].f[i].y);
    }
    for (i=0; i<p[j].dynamic_number; i++) {
      rx=p[p[j].d[i].number].x[0]-p[j].x[0];
      ry=p[p[j].d[i].number].y[0]-p[j].y[0];
      mod=sqrt(rx*rx+ry*ry);
      tens=mod-p[j].d[i].rest;
      mod=1/mod;
      rx*=mod;
      ry*=mod;
      p[j].fx+=tens*p[j].d[i].k*rx;
      p[j].fy+=tens*p[j].d[i].k*ry;
    }
  }
  for (j=0; j<max; j++) {
    p[j].x[2]+=eps*0.1;
    p[j].y[2]+=eps*0.1;
    if (p[j].x[2]>p[j].vcx) p[j].x[2]=p[j].vcx;
    if (p[j].y[2]>p[j].vcy) p[j].y[2]=p[j].vcy;
    p[j].x[0]+=eps*(p[j].x[1]+p[j].x[2]);
    p[j].y[0]+=eps*(p[j].y[1]+p[j].y[2]);
    p[j].x[1]+=eps*p[j].fx;
    p[j].y[1]+=eps*p[j].fy;
    p[j].x[1]*=0.9999;
    p[j].y[1]*=0.9999;
  }
}

void main (int argc, char **argv) {
  particle *p;
  int i,j;
  FILE *f;

  allegro_init ();
  set_gfx_mode (GFX_VGA,320,200,320,200);
  
  f=fopen (argv[1],"rt");
  fscanf (f,"%d",&max);
  p=(particle *) malloc (max*sizeof (particle));

  for (i=0; i<max; i++) {
    fscanf (f,"%lf",&p[i].x[0]);
    fscanf (f,"%lf",&p[i].y[0]);
    fscanf (f,"%lf",&p[i].x[1]);
    fscanf (f,"%lf",&p[i].y[1]);
    fscanf (f,"%lf",&p[i].vcx);
    fscanf (f,"%lf",&p[i].vcy);
    p[i].m=0.0;
    p[i].color=15;
    p[i].x[2]=p[i].y[2]=0.0;
    fscanf (f,"%d",&p[i].fixed_number);
    p[i].f=(fixed_coil *) malloc (max*sizeof (fixed_coil));
    for (j=0; j<p[i].fixed_number; j++) {
      fscanf (f,"%lf",&p[i].f[j].x);
      fscanf (f,"%lf",&p[i].f[j].y);
      fscanf (f,"%lf",&p[i].f[j].k);
    }      
    fscanf (f,"%d",&p[i].dynamic_number);
    p[i].d=(dynamic_coil *) malloc (max*sizeof (dynamic_coil));
    for (j=0; j<p[i].dynamic_number; j++) {
      fscanf (f,"%d",&p[i].d[j].number);
      fscanf (f,"%lf",&p[i].d[j].k);
    }      
  }
  for (i=0; i<max; i++) {
    for (j=0; j<p[i].dynamic_number; j++) {
      double dx,dy;
      dx=p[i].x[0]-p[p[i].d[j].number].x[0];
      dy=p[i].y[0]-p[p[i].d[j].number].y[0];
      p[i].d[j].rest=sqrt(dx*dx+dy*dy);
    }
  }

  do {
    vsync ();
    clear (screen);
    for (i=0; i<52; i++) {
      if (p[i].x[0]>=0 && p[i].x[0]<320 && p[i].y[0]>=0 && p[i].y[0]<200)
        putpixel (screen,(int)p[i].x[0],(int)p[i].y[0],p[i].color);
        line (screen,(int)p[i].x[0],(int)p[i].y[0],
              (int)p[(i+1)%52].x[0],(int)p[(i+1)%52].y[0],15);
    }
    for (i=0; i<1000; i++)
      dynamic (p);
  } while (!kbhit());
  getch ();
  set_gfx_mode (GFX_TEXT,80,24,80,24);
}
