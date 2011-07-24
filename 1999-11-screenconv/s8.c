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
  fread (buffer,1,3*atoi(argv[3])*atoi(argv[4]),f);
  fclose (f);

  for (j=0; j<atoi(argv[4]); j++)
    for (i=0; i<atoi(argv[3]); i++)
      buffer2[j*atoi(argv[3])+i]=
        ((buffer[(j*atoi(argv[3])+i)*3+0]&0xE0)>>3)+
        ((buffer[(j*atoi(argv[3])+i)*3+1]&0xE0)>>0)+
        ((buffer[(j*atoi(argv[3])+i)*3+2]&0xC0)>>6);

  f=fopen (argv[2],"wb");
  fputc (0xfe,f);
  fputc (0x00,f);
  fputc (0x00,f);
  fputc (0xff,f);
  fputc (0xbf,f);
  fputc (0x00,f);
  fputc (0x00,f);
  fwrite (buffer2,1,atoi(argv[3])*atoi(argv[4]),f);
  fclose (f);

  return 0;
}
