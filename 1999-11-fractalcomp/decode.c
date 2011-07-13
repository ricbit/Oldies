#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <allegro.h>
#include <conio.h>

int a;

#define CROP(x) (a=(x),a>255?255:a<0?0:a)
#define IABS(x) ((x)%10000)

typedef struct {
  int block,mean1,mean2;
  int error[64];
} block;

int *buf1,*buf2;

void draw (int *buf) {
  int i,j;

  for (j=0; j<400; j++)
    for (i=0; i<576; i++)
       putpixel (screen,i,j,CROP(buf[j*576+i]));
}

void iteration (block *b) {
  int i,j,ii,jj,m,n;
  int code,x,y;

  for (j=0; j<400/8; j++)
    for (i=0; i<576/8; i++) {
      code=j*72+i;
      x=IABS(b[code].block)%(36);
      y=IABS(b[code].block)/(36);
      for (ii=0; ii<8; ii++)
        for (jj=0; jj<8; jj++) {
          if (b[code].block<10000) {
            m=ii; n=jj;
          } else if (b[code].block<20000) {
            m=7-ii; n=jj;
          } else if (b[code].block<30000) {
            m=ii; n=7-jj;
          } else if (b[code].block<40000) {
            m=7-ii; n=7-jj;
          } else if (b[code].block<50000) {
            m=jj; n=ii;
          } else if (b[code].block<60000) {
            m=7-jj; n=ii;
          } else if (b[code].block<70000) {
            m=jj; n=7-ii;
          } else {
            m=7-jj; n=7-ii;
          }

          buf2[(j*8+n)*576+i*8+m]=(
              (buf1[(y*16+jj*2+0)*576+x*16+ii*2+0]
              +buf1[(y*16+jj*2+1)*576+x*16+ii*2+0]
              +buf1[(y*16+jj*2+0)*576+x*16+ii*2+1]
              +buf1[(y*16+jj*2+1)*576+x*16+ii*2+1])/4*
              b[code].mean1/b[code].mean2 
              );
        }
    }
  memcpy (buf1,buf2,576*400*sizeof (int));
}

int main (void) {
  FILE *f;
  block *b;
  int i,j,ii,jj;
  RGB pal[256];
  int hist[512];

  f=fopen ("lixo","rt");
  b=(block *) malloc (3600*sizeof (block));
  for (i=0; i<512; i++)
    hist[i]=0;
  for (i=0; i<3600; i++) {
    fscanf (f,"%d",&(b[i].block));
    fscanf (f,"%d",&(b[i].mean1));
    fscanf (f,"%d",&(b[i].mean2));
  }
  fclose (f);
  printf ("ready...\n");
  fflush (stdout);
  getch ();

  allegro_init ();
  set_gfx_mode (GFX_VESA1,640,480,640,480);
  for (i=0; i<256; i++) 
    pal[i].r=pal[i].g=pal[i].b=i/4;
  set_palette (pal);

  buf1=(int *) malloc (576*400*sizeof (int));
  buf2=(int *) malloc (576*400*sizeof (int));

  for (i=0; i<576; i++)
    for (j=0; j<400; j++) 
      buf1[i+j*576]=255;
  i=0;
  do {
    char str[200];
    unsigned char *buf;
    FILE *fout;
    buf=(unsigned char *) malloc (576*400);
    draw (buf1);
    for (j=0; j<576*400;j++)
      buf[j]=buf1[j]>255?255:buf1[j];
    sprintf (str,"frac%02d.gry",i++);
    fout=fopen (str,"wb");
    fwrite (buf,1,576*400,fout);
    fclose (fout);
    iteration (b);
    free (buf);
  } while (getch()!=27);
  allegro_exit ();

  return 0;

}

