#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <malloc.h>
#include <math.h>
#include <sys/stat.h>

typedef unsigned char byte;
typedef signed short word;
  
int sizeout=0,current=0,bits=0;
byte *output;
byte *buffer;
word *p;
int error[40];
int size;

double signal,noise;

void single (int code) {
  current=(current<<2)+code;  
  bits+=2;
  if (bits==8) {
    output[sizeout++]=current;
    current=bits=0;
  }
}

int quantiz (int error) {
  if (error<-3) 
    return -3;
  if (error>+3) 
    return +3;
  return error;
}

void insert (int coef) {
  if (coef==-1) {
    single (2);
    return;
  }
  if (coef==+1) {
    single (1);
    return;
  }
  if (coef== 0) {
    single (0);
    return;
  }
  single (3);
  if (coef==-3) single (0);
  if (coef==-2) single (1);
  if (coef==+2) single (2);
  if (coef==+3) single (3);
}

double compress (double factor) {
  int sample;
  int coef;
  int i;
  int predic=9;
  double original,recon;
  
  p=(word *)(buffer+0x20+12);
  signal=0;
  noise=0;
  sizeout=0;
  current=0;
  bits=0;

  for (i=0; i<40; i++) 
    error[i]=0;

  for (i=0; i<(size-0x20-12)/2; i++) {
    original=(double)(*p++ + 2048)*factor;
    sample=((int)(original))/4096;
    sample+=8;
    if (sample<0) sample=1;
    if (sample>15) sample=14;
    signal+=original*original;
    error[sample-predic+20]++;
    coef=quantiz (sample-predic);
    predic+=coef;
    recon=(double)(predic*4096-8*4096)-original;
    noise+=recon*recon;
    insert (coef);
  }

  insert (0);
  insert (0);
  insert (0);
  insert (0);
  
  return (10.0*log(signal/noise)/log(10.0));
}

int main (int argc, char **argv) {
  int file;  
  int i,j,k;
  double factor;
  double last,lastsnr=0.0;
  double maxsnr=0.0,snr;
  double chosen=1.0;
  double skip=2.0;
  double limits;
  byte header[256];
  
  printf ("WAV2WVZ 1.1\n");
  printf ("Copyright (C) 1998 by Ricardo Bittencourt\n\n");
  
  file=open (argv[1],O_BINARY|O_RDONLY);
  size=filelength (file);
  printf ("converting %s, original size %d\n\n",argv[1],size);
  buffer=(byte *) malloc (size);
  read (file,buffer,size);
  close (file);

  sizeout=0;
  output=(byte *) malloc (size);

  do {
    last=chosen*1.01;
    lastsnr=maxsnr;
    limits=pow(skip,8.0);
 
    for (factor=last/limits; 
         factor<last*limits; 
         factor*=skip) 
    {
      snr=compress (factor);
      printf ("factor: %.2f\t",factor);
      printf ("snr: %.3f\t",snr);
      printf ("size: %d\n",sizeout);
      if (snr>maxsnr) {
        maxsnr=snr;
        chosen=factor;
      }
    }
    skip=pow(skip,0.125);
  } while (fabs (maxsnr-lastsnr)>0.01);

  printf ("final factor: %.2f\n",chosen);
  printf ("final snr: %.2f\n",maxsnr);

  compress (chosen);
  
  printf ("final size: %d\n",sizeout);

  header[0]='W';
  header[1]='V';
  header[2]='Z';
  header[3]=0x1A;

  header[4]=((sizeout+16383)/16384)%256;
  header[5]=((sizeout+16383)/16384)/256;

  if (argc>3) {  
    j=6;
    for (i=3; i<argc; i++) {
      k=0;
      while (argv[i][k]!=0) 
        header[j++]=argv[i][k++];
      header[j++]=32;
    }
    if (j<32+6)
      for (;j<32+6;j++)
        header[j]=32;
    for (j=32+6; j<256; j++)
      header[j]=0;
  }

  file=open (argv[2],O_BINARY|O_WRONLY|O_CREAT,S_IRUSR|S_IWUSR);
  write (file,header,128);
  write (file,output,sizeout);
  close (file);

  return 0;
}
