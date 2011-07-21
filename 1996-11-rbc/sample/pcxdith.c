#include <stdio.h>

#define INT(a,b) (((int)(a[b+1])<<8)+(int)(a[b]))

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

/*
byte fromRGB (byte r, byte g, byte b, word x, word y) {
  int DithR=r,DithG=g,DithB=b,LastXBits,DithValue;
  DithR=(DithR>>5)+
    ((DithR&0x1f)>(DithValue=*(DithMatrix32+((y&0x3)<<3)+
    (LastXBits=(x&0x7)))))-1;
  DithG=(DithG>>5)+((DithG&0x1f)>DithValue)-1;
  DithB=(DithB>>6)+((DithB&0x3f)>*(DithMatrix64+((y&0x7)<<3)+LastXBits));
  if (DithR<0) DithR=0;
  if (DithG<0) DithG=0;
  if (DithB>3) DithB=3;
  return ((DithR<<5)+(DithG<<2)+DithB);
}
*/

char *dither32;
char *dither64;
int lastxbits;
char dithvalue;

char fromRGB (char r, char g, char b, int x, int y) {
  lastxbits=x&0x07;
  dithvalue=*(dither32+((y&0x3)<<3)+lastxbits);
  r=(r>>5)+((r&0x1f)>dithvalue)-1;
  g=(g>>5)+((g&0x1f)>dithvalue)-1;
  b=(b>>6)+((b&0x3f)>*(dither64+((y&0x7)<<3)+lastxbits));
  if (r>0xf0) r=0;
  if (g>0xf0) g=0;
  if (b>3) b=3;
  return ((r<<2)+(g<<5)+b);
}

char uniformRGB (char r, char g, char b) {
  return (g&0xe0)+((r&0xe0)>>3)+((b&0xc0)>>6);
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

int xmax;
int ymax;
char nplanes;
int bytesperline;
int i;
int j;
char k;
char l;
char *bufferr;
char *bufferg;
char *bufferb;
char *pb;
char d;
char d2;
char *pbufr;
char *pbufg;
char *pbufb;

void read_pcx (int file, char *header) {
  xmax=INT (header,8);
  ymax=INT (header,10);
  nplanes=header[65];
  bytesperline=INT (header,66);
  bufferr=(char *) malloc (bytesperline);
  bufferg=(char *) malloc (bytesperline);
  bufferb=(char *) malloc (bytesperline);
  prepare ();
  for (j=0; j<=ymax; j++) {
    for (k=0; k<nplanes; k++) {
      if (k==0) pb=bufferr;
      if (k==1) pb=bufferg;
      if (k==2) pb=bufferb;
      for (i=0; i<bytesperline;) {
        d=fetch (file);
        if (d>0xc0) {
          d2=fetch (file);
          for (l=0; l<d-0xc0; l++) {
            *pb++=d2;
            i++;
          }
        }
        if (0xc0>d) {
          *pb++=d;
          i++;
        }
      }
    }
    pbufr=bufferr;
    pbufg=bufferg;
    pbufb=bufferb;
    for (i=0; i<=xmax; i++) {
/*      vpoke ((j<<8)+i,uniformRGB (*pbufr++,*pbufg++,*pbufb++)); */
      vpoke ((j<<8)+i,fromRGB (*pbufr++,*pbufg++,*pbufb++,i,j)); 
    }
  }
}
              
char *root;
char bi;
char bj;

void build_dither () {
  root=(char *) malloc (4);
  dither64=(char *) malloc (64);
  dither32=(char *) malloc (32);
  root[0]=0;
  root[1]=3;
  root[2]=2;
  root[3]=1;
  for (bj=0; bj<8; bj++)
    for (bi=0; bi<8; bi++)
      *(dither64+bj*8+bi)=
        16*root[bi%2+(bj%2)*2]+
        4*root[(bi%4)/2+bj%4]+
        root[(bi%8)/4+(bj%8)/2];
  for (bj=0; bj<4; bj++)
    for (bi=0; bi<8; bi++)
      *(dither32+bj*8+bi)=
        8*root[bi%2+(bj%2)*2]+
        2*root[(bi%4)/2+(bj%4)]+
        (bi/4);
}               

char *filename;
int file;
char *header;

void main (void) {
  filename=parse_args ();
  puts ("PCX Viewer v1.0");
  puts ("by Ricardo Bittencourt");
  putchar (10);
  build_dither ();
  file=open (filename);
  header=(char *) malloc (128);
  read (file,header);
  print ("Name: ");
  puts (filename);
  print ("Xmax: ");
  number (INT (header,8),10);
  putchar (13); putchar (10);
  print ("Ymax: ");
  number (INT (header,10),10);
  putchar (13); putchar (10); putchar (10);
  print ("Press any key to start...");
  getchar ();
  screen (8);
  read_pcx (file,header);
  getchar ();
  screen (0);
}

