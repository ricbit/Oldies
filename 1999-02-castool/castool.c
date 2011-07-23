#include <stdio.h>
#include <io.h>
#include <malloc.h>

typedef signed short int word;

double fir[64];
int len;
int level=1000;
FILE *fout;

void filter (word *buffer) {
  int i,j;
  double sum;

  for (i=0; i<len-64; i++) {
    sum=0.0;
    for (j=0; j<64; j++)
      sum+=(double)buffer[i+j]*fir[j];
    buffer[i]=(word)sum;
  }
}

void schmitt (word *buffer) {
  word value=level;
  int i;

  for (i=0; i<len; i++) {
    if ((value==level && buffer[i]<-level) || 
        (value==-level && buffer[i]>level))
      value*=-1;
    buffer[i]=value;
  }

  for (i=0; i<len-1; i++) 
    if (buffer[i]>0 && buffer[i+1]<0)
      buffer[i]=10000;
    else
      buffer[i]=0;
}

int bitstream[11]={1,1,1,1,1,1,1,1,1,1,1};

void insertbit (int bit) {
  int i;
  unsigned char byte;

  for (i=0; i<10; i++)
    bitstream[i]=bitstream[i+1];
  bitstream[10]=bit;

  if (bitstream[0]==0 && bitstream[9]==1 && bitstream[10]==1) {
    byte=0;
    for (i=0; i<8; i++) 
      byte+=bitstream[i+1]<<i;
    fwrite (&byte,1,1,fout);
    for (i=0; i<11; i++)
      bitstream[i]=1;
  }
}

void demod (word *buffer) {
  int i=0,j,k;
  int count;
  int start;
  int cycle;
  
  for (i=0; i<len-44100/1200; i++)
    if (buffer[i]) {
      count=0;
      for (j=0; j<44100/1200-2; j++)
        if (buffer [i+j])
          count++;
      if (count==1) {
        insertbit (0);
        i+=44100/1200-2;
      }
      if (count==2) {         
        insertbit (1);
        i+=44100/1200-2;
      }
    }
}               

int main (int argc, char **argv) {
  FILE *fin;
  word *buffer,header[0x2C]; 
  int i;
  
  printf ("CAS Tool v1.0\n");
  printf ("Copyright (C) 1999 by Ricardo Bittencourt\n\n");

  printf ("Reading filter...\n");
  fin=fopen ("filt1200.mat","rt");
  for (i=0; i<512; i++) 
    fscanf (fin,"%lf",&fir[i]);
  fclose (fin);

  printf ("Reading <%s>...\n",argv[1]);
  fin=fopen (argv[1],"rb");
  len=filelength (fileno (fin));
  buffer=(word *) malloc (len);
  fread (header,0x2C,1,fin);
  fread (buffer,len-0x2C,1,fin);
  len=(len-0x2C)/2;
  fclose (fin);

  printf ("Filtering ...\n");
  filter (buffer);

  printf ("Schmitt-trigger ...\n");
  schmitt (buffer);

  fout=fopen (argv[2],"wb");
  
  printf ("Demodulation ...\n");
  demod (buffer);

  fclose (fout);

  return 0;
}

