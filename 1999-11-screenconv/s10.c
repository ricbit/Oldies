#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>

#define SQR(a) ((a)*(a))

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
  int i,j,ii,jj;
  int r,g,b,cy,cj,ck;
  hist h[32];
  int color[4];
  int ly,lj,lk;
  int hy[256],hj[256],hk[256];
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
    for (i=0; i<256/4; i++) {
      r=g=b=0;

      for (ii=0; ii<4; ii++)  {
        r+=buffer[(j*256+i*4+ii)*3+0];
        g+=buffer[(j*256+i*4+ii)*3+1];
        b+=buffer[(j*256+i*4+ii)*3+2];
      }
      cy=r/4+g/8+b/2;
      cj=(r-cy)/16;
      ck=(g-cy)/16;
      cy/=64;
      cy=cy>16?15:cy;
      cj=cj<-32?-32:cj>63?63:cj; 
      ck=ck<-32?-32:ck>63?63:ck; 

      for (jj=0; jj<4; jj++) {
        for (ii=0; ii<16; ii++) {
          r=ii*16+(cj)*4;
          g=ii*16+(ck)*4;
          b=ii*20-(cj)*2-(ck);
          h[ii].index=ii;
          if (r>255 || g>255 || b>255 || r<0 || g<0 || b<0)
            h[ii].value=256*256*256; 
          else
            h[ii].value=SQR(r-buffer[(j*256+i*4+jj)*3+0])+
                        SQR(g-buffer[(j*256+i*4+jj)*3+1])+
                        SQR(b-buffer[(j*256+i*4+jj)*3+2]);
        }

        qsort (h,16,sizeof (hist),sort_function);
        color[jj]=h[0].index;
      }

      buffer2[j*256+i*4+0]=(color[0]<<4)+(ck&7);
      buffer2[j*256+i*4+1]=(color[1]<<4)+(ck>>3);
      buffer2[j*256+i*4+2]=(color[2]<<4)+(cj&7);
      buffer2[j*256+i*4+3]=(color[3]<<4)+(cj>>3);
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
  /*printf ("pixels: %d bits %d\n",pixels,bits);*/

  return 0;
}
