#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>

#define SQR(a) ((a)<0?-(a):(a))

int total=0,pos=1;

unsigned char *buffer;
unsigned char *buffer2;
unsigned char *bufy;
unsigned char *comp;

typedef struct {
  int index;
  int value;
} hist;

void insert (int value) {
  printf ("value %d\n",value);
  if (pos)
    comp[total]=value<<4;
  else
    comp[total++]|=value;
  pos^=1;
}

int sort_function (const void *c1, const void *c2) {
  return ((hist *)c1)->value - ((hist *)c2)->value;
}

int main (int argc, char **argv) {
  FILE *f;
  int i,j,ii,jj,ccj,cck;
  int r,g,b;
  hist h[32];
  hist jk[64*64];
  int color[4];
  unsigned char *p;
  int pixels,bits,count;

  f=fopen (argv[1],"rb");
  buffer=(unsigned char *) malloc (256*192*3);
  buffer2=(unsigned char *) malloc (256*192);
  bufy=(unsigned char *) malloc (256*192);
  comp=(unsigned char *) malloc (256*192*3);
  fread (buffer,256,192*3,f);
  fclose (f);

  for (j=0; j<192; j++)
    for (i=0; i<256/4; i++)
    {

      jk[0].value=255*255*255;  
      for (ccj=-32; ccj<32; ccj++)
        for (cck=-32; cck<32; cck++)
        {

          jk[1].value=0;
          for (jj=0; jj<4; jj++)
          {
            h[0].value=255*255*255;
            h[0].index=0;
            for (ii=0; ii<32; ii++)
            {
              r=ii+ccj;
              g=ii+cck;
              b=5*ii/4-ccj/2-cck/4;

              if (r<0 || g<0 || b<0 || r>255 || g>255 || b>255)
                continue;

              r*=8;
              g*=8;
              b*=8;

              h[1].value=
                SQR ((int)buffer[(j*256+i*4+jj)*3+0]-r)+
                SQR ((int)buffer[(j*256+i*4+jj)*3+1]-g)+
                SQR ((int)buffer[(j*256+i*4+jj)*3+2]-b);
              if (h[1].value<h[0].value)
              {
                h[0].value=h[1].value;
                h[0].index=ii;
              }
            }
            jk[1].value+=h[0].value;
          }
          if (jk[1].value<jk[0].value)
          {
            jk[0].value=jk[1].value;
            jk[0].index=(ccj+32)*64+(cck+32);
          }
        }

      ccj=(jk[0].index/64)-32;
      cck=(jk[0].index%64)-32;
      for (jj=0; jj<4; jj++)
      {
        h[0].value=255*255*255;
        h[0].index=0;
        for (ii=0; ii<32; ii++)
        {
          r=ii+ccj;
          g=ii+cck;
          b=5*ii/4-ccj/2-cck/4;

          r=r<0?0:r>31?31:r;
          g=g<0?0:g>31?31:g;
          b=b<0?0:b>31?31:b;

          r*=8;
          g*=8;
          b*=8;

          h[1].value=
            SQR ((int)buffer[(j*256+i*4+jj)*3+0]-r)+
            SQR ((int)buffer[(j*256+i*4+jj)*3+1]-g)+
            SQR ((int)buffer[(j*256+i*4+jj)*3+2]-b);
          if (h[1].value<h[0].value)
          {
            h[0].value=h[1].value;
            h[0].index=ii;
          }

        }
        color[jj]=h[0].index;
        /* printf ("%d: %d\n",h[0].index,h[0].value);*/
      }

      buffer2[j*256+i*4+0]=(color[0]<<3)+(cck&7);
      buffer2[j*256+i*4+1]=(color[1]<<3)+(cck>>3);
      buffer2[j*256+i*4+2]=(color[2]<<3)+(ccj&7);
      buffer2[j*256+i*4+3]=(color[3]<<3)+(ccj>>3);

      printf ("%3d,%3d%c",i,j,13);
      fflush (stdout);
    }

  buffer[0]=0xfe;
  buffer[1]=0x00;
  buffer[2]=0x00;
  buffer[3]=0xff;
  buffer[4]=0xbf;
  buffer[5]=0x00;
  buffer[6]=0x00;
  
  f=fopen (argv[2],"wb");
  fwrite (buffer,1,7,f);
  fwrite (buffer2,1,0xc000,f);
  fclose (f);
           
  return 0;
}

