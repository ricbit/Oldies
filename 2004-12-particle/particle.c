#include <stdio.h>
#include <stdlib.h>
#include <allegro.h>
#include <math.h>

#define SQR(x) ((x)*(x))

int main (void) {
  int i,j,ang;
  double *x,*y,*z;
  int *color;
  double xx,yy,xi,yi,zi,xil,yil,zil;
  double ss,cc,zk,ss2,cc2;
  RGB pal[256];
  BITMAP *image,*buf;
  int black=0;

  allegro_init();
  install_keyboard();
  install_timer();

  set_gfx_mode (GFX_AUTODETECT,320,200,320,200);
  image=load_pcx("emperor.pcx",pal);
  set_palette (pal);
  buf=create_bitmap(320,200);

  x=(double *) malloc (100*100*sizeof (double));
  y=(double *) malloc (100*100*sizeof (double));
  z=(double *) malloc (100*100*sizeof (double));
  color=(int *) malloc (100*100*sizeof (int));

  for (i=0; i<256; i++) {
    if (pal[i].r==0 && pal[i].g==0 && pal[i].b==0)
      black=i;
  }

  for (i=0; i<100; i++)
    for (j=0; j<100; j++) {
      do {
        z[i*100+j]=(double)rand()/(double)RAND_MAX*2.0-1.0;
        x[i*100+j]=((double)i-50.0)*(30.0+z[i*100+j])/2560.0;
        y[i*100+j]=((double)j-50.0)*(30.0+z[i*100+j])/2560.0;
      } while (SQR(z[i*100+j])+SQR(x[i*100+j])+SQR(y[i*100+j])>1.0);
      color[i*100+j]=getpixel(image,i,j);
    }

   for (ang=500*4; ang>=0; ang--) {
     clear_to_color(buf,black);                        
     for (i=0; i<100*100; i++) {
       ss=sin((double)ang/300.0*2.0*PI/4.0);
       cc=cos((double)ang/300.0*2.0*PI/4.0);
       ss2=sin((double)ang/900.0*2.0*PI/4.0);
       cc2=cos((double)ang/900.0*2.0*PI/4.0);

       yil=(y[i]*cc2+z[i]*ss2);
       zil=(z[i]*cc2-y[i]*ss2);
       xil=x[i];

       xi=(xil*cc+zil*ss);
       zi=(zil*cc-xil*ss);
       yi=yil;

       zk=(double)(500-ang/4)/500.0*29.0+1.0;
       xx=160.0+xi*2560.0/(zi+zk);
       yy=100.0+yi*2560.0/(zi+zk);
       putpixel (buf,(int)(xx+0.5),(int)(yy+0.5),color[i]);
     }
     vsync();
     blit(buf, screen, 0, 0, 0, 0, 320, 200);
   }

  readkey();
  allegro_exit();
  return 0;
}
