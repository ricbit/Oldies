#include <allegro.h>
#include <stdlib.h>
#include <conio.h>
#include <math.h>

#define M 80

#define SQR(x) ((x)*(x))

double px[M],py[M];

int main (void) {
  int i,j,k;
  RGB pal[256];

  allegro_init();
  set_gfx_mode (GFX_AUTODETECT,320,200,320,200);

  for (i=0; i<M; i++) {
    px[i]=100; py[i]=100;
  }

  for (i=0; i<64; i++)
    pal[i].r=pal[i].g=pal[i].b=i;

  set_palette(pal);
    

  do {
    for (j=0; j<200; j++)
      for (i=0; i<320; i++) {
        double value=0.0;
        for (k=0; k<M; k++) {
          if (ABS(i-(int)px[k])+ABS(j-(int)py[k])<50)
          value+=100*(1.0/((SQR((double)i-px[k])+SQR((double)j-py[k]))));
        }
        if (value>63.0)
          value=63.0;
        putpixel (screen,i,j,(int)value);
      }
    for (k=0; k<M; k++) {
      px[k]+=1*((double)rand()/(double)RAND_MAX-0.5);
      py[k]+=1*((double)rand()/(double)RAND_MAX-0.5);
      if (px[k]<80.0) px[k]=80.0;
      if (py[k]<80.0) py[k]=80.0;
      if (px[k]>120.0) px[k]=120.0;
      if (py[k]>120.0) py[k]=120.0;
    }
  } while (!kbhit());

  return 0;  
}
