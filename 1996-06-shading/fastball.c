#include <stdio.h>
#include <conio.h>
#include <dpmi.h>
#include <malloc.h>
#include <math.h>
#include <allegro.h>

#define epsilon 1e-10

typedef unsigned char byte;

int time_elapsed,start_count;
signed char *difftable1,*difftable2;
int *gradient_map;
byte *data_init;
BITMAP *bmp;

void time_counter (void) {
  if (start_count) 
    time_elapsed++;
}

END_OF_FUNCTION (time_counter);

void start_time (void) {
  time_elapsed=0;
  start_count=1;
}

void end_time (void) {
  start_count=0;
}

void init_palette (void) {
  int i;
  RGB rgb[256];

  for (i=0; i<64; i++) {
    rgb[i].r=rgb[i].g=rgb[i].b=i;
    rgb[i+64].r=i;
    rgb[i+64].g=rgb[i+64].b=0;
    rgb[i+128].g=i;
    rgb[i+128].r=rgb[i+128].b=0;
  }
  set_pallete (rgb);
}

void draw_ball_dumb (double lx, double ly, double lz) {
  int x,y;
  double dx,dy,dz,dz2,l,modulo;

  modulo=1.0/sqrt (lx*lx+ly*ly+lz*lz);
  lx*=modulo;
  ly*=modulo;
  lz*=modulo;

  for (x=320-240; x<320+240; x++)
    for (y=0; y<480; y++) {
      dx=(double)(x-320)/240.0;
      dy=(double)(y-240)/240.0;
      dz2=dx*dx+dy*dy;
      if (dz2<1.0) {
        if (dz2>epsilon) 
          dz=sqrt (1.0-dz2);
        else 
          dz=1.0;
        l=63.0*(dx*lx+dy*ly+dz*lz);
        if (l>0) 
          ((byte *) bmp->dat)[x+y*640]=(int)l;
        else
          ((byte *) bmp->dat)[x+y*640]=0;
      }
    }
}

void init_shader (void) {
  int i,j;  
  double phi,theta;

  difftable1=(signed char *) malloc (256*256*sizeof (signed char));
  difftable2=(signed char *) malloc (256*256*sizeof (signed char));
  for (i=0; i<256; i++)
    for (j=0; j<256; j++) {
      phi=(double)j/256.0*PI;
      theta=(double)i/256.0*2.0*PI;
      difftable1[i+256*j]=(signed char)(63.0*0.5*cos (phi)*(1+cos (theta)));
      difftable2[i+256*j]=(signed char)(63.0*0.5*cos (phi)*(1-cos (theta)));
    }
}

void init_gradient_map (void) {
  int i,j;
  double dx,dy,dz,dz2,phi,theta;

  gradient_map=(int *) malloc (640*480*sizeof (int));
  for (i=0; i<640; i++)
    for (j=0; j<480; j++) {
      dx=(double)(i-320)/240.0;
      dy=(double)(j-240)/240.0;
      dz2=dx*dx+dy*dy;
      if (dz2<1.0) {
        if (dz2<epsilon) 
          dz=1.0;
        else
          dz=sqrt (1.0-dz2);
        phi=255.0*acos (dz)/PI;
        theta=255.0*atan2 (dy,dx)/2.0/PI;
        gradient_map[i+j*640]=(int)theta+256*(int)phi;
      }
      else gradient_map[i+j*640]=0;
    }
}

void draw_ball_smart (double lx, double ly, double lz) {
  int x,y,*gradient;
  register signed char *a;
  register signed char *b;
  byte *data;

  a=b=difftable1;
  gradient=gradient_map+(320-240);
  data=data_init+(320-240);
  for (y=479; y>=0; y--) {
    for (x=479; x>=0; x--) {
      *data++=*(a=(b+*gradient++))+*(a+128);
    }
    gradient+=640-480;
    data+=640-480;
  }
}

void show_maps (void) {
  int i,j,color;

  for (i=0; i<256; i++)
    for (j=0; j<256; j++) {
      color=difftable1[i+j*256];
      if (color<0) 
        color=128-color;
      else
        color=64+color;
      putpixel (screen,i,j,color);
    
      color=difftable2[i+j*256];
      if (color<0) 
        color=128-color;
      else
        color=64+color;
      putpixel (screen,i+300,j,color);
    }
}

void main (int argc, char **argv) {
  char str[200];

  if (argc<4) {
    printf ("usage: %s lx ly lz\n",argv[0]);
    exit (1);
  }
  cprintf ("Fastball by Ricardo Bittencourt\n\r");
  init_shader ();
  init_gradient_map ();
  allegro_init ();
  install_timer ();
  LOCK_VARIABLE (start_count);
  LOCK_VARIABLE (time_elapsed);
  LOCK_FUNCTION (time_counter);
  start_count=0;
  install_int (time_counter,1);
  set_gfx_mode (GFX_VESA1,640,480,640,480);
  init_palette ();
  bmp=create_bitmap (640,480);
  data_init=(byte *) bmp->dat;
  
  clear (screen);
  show_maps ();
  getch ();

  clear (screen);
  textout (screen,font,"Dumb test",0,0,63);
  start_time ();
  draw_ball_dumb (atof (argv[1]),atof (argv[2]),atof (argv[3]));
  end_time ();
  blit (bmp,screen,0,0,0,0,640,480);
  sprintf (str,"Elapsed time: %d",time_elapsed);
  textout (screen,font,str,0,10,63);
  getch ();
  
  clear (screen);
  textout (screen,font,"Smart test",0,0,63);
  start_time ();
  draw_ball_smart (atof (argv[1]),atof (argv[2]),atof (argv[3]));
  end_time ();
  blit (bmp,screen,0,0,0,0,640,480);
  sprintf (str,"Elapsed time: %d",time_elapsed);
  textout (screen,font,str,0,10,63);
  getch ();
  
  allegro_exit ();
}
