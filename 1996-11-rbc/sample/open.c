#include <stdio.h>

char *fcb;
char *p;
char i;

int open (char *name) {
  fcb=(char *) malloc (37);
  *fcb=0;
  for (i=1; i<=11; i++)
    fcb[i]=32;
  for (i=12; i<37; i++)
    fcb[i]=0;
  p=name;
  i=1;
  while (*p!='.') 
    fcb[i++]=*p++;
  p++; i=9;
  while (*p)
    fcb[i++]=*p++;
  bdos (0xf,(int)fcb,0);
  return (int)fcb;
}

int read (int file, char *buffer) {
  bdos (0x1a,(int)buffer,0);
  return !bdos (0x14,file,0);
}

char *name="OPEN.PRN";
int file;
char *buffer;
int ii;

void main (void) {
  file=open (name);
  buffer=(char *) malloc (128);
  while (read (file,buffer)) {
    for (ii=0; ii<128; ii++)
      putchar (buffer[ii]);
  }
}

