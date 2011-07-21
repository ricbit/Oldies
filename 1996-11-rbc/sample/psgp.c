#include <stdio.h>

#define INT(a,b) (((int)((a)[b+1])<<8)+(int)((a)[b]))

void digit (int a) {
  putchar (a+(a<10?48:55));
}

int n;

void number (int a, int base) {
  n=1;
  while (base<a/n+1) n*=base;
  while (n) {  
    digit (a/n);
    a%=n; n/=base;
  } 
}

char *fcb;
char *p;
char ii;

int open (char *name) {
  fcb=(char *) malloc (37);
  *fcb=0;
  for (ii=1; ii<=11; ii++)
    fcb[ii]=32;
  for (ii=12; ii<37; ii++)
    fcb[ii]=0;
  p=name;
  ii=1;
  while (*p!='.') 
    fcb[ii++]=*p++;
  p++; ii=9;
  while (*p)
    fcb[ii++]=*p++;
  bdos (0xf,(int)fcb,0);
  return (int)fcb;
}

int read (int file, char *buffer) {
  bdos (0x1a,(int)buffer,0);
  return !bdos (0x14,file,0);
}

void print (char *string) {  
  while (*string)
    putchar (*string++);
}

void puts (char *string) {
  print (string);
  putchar (13);
  putchar (10);
}

char *name;
char *pname;
char *arg;
char total;

char *parse_args (void) {
  name=(char *) malloc (50);
  total=*((char *) 0x80);
  arg=(char *) 0x81;
  while (*arg==32) {
    arg++;
    total--;
  }
  pname=name;
  while (total) {
    *pname++=*arg++;
    total--;
  }
  *pname=0;
  return name;
}

char avail=0;
char *readbuffer;
char *next;

void prepare (void) {
  readbuffer=(char *) malloc (128);
}

char fetch (int file) {
  if (!avail) {
    read (file,readbuffer);
    next=readbuffer;
    avail=128;
  }
  avail--;
  return *next++;
}

void readall (int file, char *buffer, int size) {
  while (size>128) {
    bdos (0x1a,(int)buffer,0);
    bdos (0x14,file,0);
    size-=128;
    buffer+=128;
  }
}

char *filename;
int file;
int size;
char *psgstream;
int varre;

void main (void) {
  filename=parse_args ();
  puts ("PSG Player v1.0");
  puts ("by Ricardo Bittencourt");
  putchar (10);
  file=open (filename);
  print ("Name: ");
  puts (filename);
  print ("Tam: ");
  size=INT((char *)file,16);
  number (size,10);
  psgstream=(char *) malloc (size);
  readall (file,psgstream,size);
  for (varre=0; varre<size; varre++) {
    number (psgstream[varre],10);
    putchar (32);
  }
}

