#include <stdio.h>
#include <allegro.h>
#include <conio.h>

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
  double x[2],y[2];
  double fx,fy;
  double vcx,vcy;
  double m;
  int color;
  fixed_coil *f;
  int fixed_number;
  dynamic_coil *d;
  int dynamic_number;
} particle;

void main (void) {
  char c=0;
  int lx,ly;
  particle *p;
  int np=0;
  
  p=(particle *) malloc (500*sizeof (particle));
  allegro_init ();  
  install_mouse ();
  install_timer ();
  set_gfx_mode (GFX_VGA,320,200,320,200);
  lx=mouse_x; ly=mouse_y;  
  xor_mode (TRUE);
  putpixel (screen,lx,ly,15);
  xor_mode (FALSE);
  do {
    if (kbhit ()) {
      c=getch ();
    }
    xor_mode (TRUE);
    putpixel (screen,lx,ly,15);
    lx=mouse_x; ly=mouse_y;
    xor_mode (FALSE);
    
    if (mouse_b&1) {
      putpixel (screen,lx,ly,15);
      while (mouse_b&1);
      p[np].x[0]=lx;
      p[np].y[0]=ly;
      p[np].dynamic_number=0;
      p[np].fixed_number=0;
      np++;
    }
    
    xor_mode (TRUE);
    putpixel (screen,lx,ly,15);
    xor_mode (FALSE);
  } while (c!=27);
  set_gfx_mode (GFX_TEXT,80,24,80,24);
  allegro_exit ();
  printf ("%d\n",np);
  for (c=0; c<np; c++) {
    printf ("%f %f\n",p[c].x[0],p[c].y[0]);
    printf ("0 0\n 2 0\n 0\n 1 %c 3\n\n",(c+1)%np);
  }
}
