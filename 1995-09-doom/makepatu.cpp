#include <io.h>
#include <math.h>
#include <fcntl.h>
#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include "fgraph.h"

#define filtro 10
#define kfiltro ((2*filtro+1)*(2*filtro+1))
#define ruido 1000
#define pi 3.1415926535

unsigned char pat[100][100];
  int i,j,x1,y1,x2,y2,ix,iy,s,file,k;
  int b;


void Pattern (int x, int y) {
  PutShape (x,y,100,100,(unsigned char far *) pat);
}

void Ruido (void) {
  for (i=0; i<1000; i++) {
    x1=random (120);
    y1=random (120);
    x2=random (120);
    y2=random (120);
    k=random (256);
    Line (x1,y1,x2,y2,k);
  }
  for (i=0; i<120; i++)
    for (j=0; j<120; j++) {
      PutPixel (i+200,j,GetPixel (i,j));
    }
}

void Filtro (void) {
  int sr,sg,sb,k,r,g,b;
  for (i=10; i<110; i++)
    for (j=10; j<110; j++) {
      sr=sg=sb=0;
      for (ix=-filtro; ix<=filtro; ix++)
        for (iy=-filtro; iy<=filtro; iy++) {
          k=GetPixel ((i+ix+100)%100+10,(j+iy+100)%100+10);
          r=k/32;
          g=(k&28)/4;
          b=(k&3)*2;
          sr+=r;
          sg+=g;
          sb+=b;
        }
      pat[i-10][j-10]=fromRGB (sr/kfiltro,sg/kfiltro,sb/kfiltro);
      PutPixel (i+200,j,pat[i-10][j-10]);
    }
}

void Deforma (void) {
  for (i=0; i<100; i++)
    for (j=0; j<100; j++) {
      b=GetPixel (210+(i+50+j+(int)(5.0*sin(-pi/2.0+2.0*pi*(double)j/100.0)))%100,j+10);
      PutPixel (i+10,j+10,b);
      pat[i][j]=b;
    }
}

void Quantiza (void) {
  int k;
  for (i=0; i<100; i++)
    for (j=0; j<100; j++) {
      pat[i][j]>>=2;
      k=pat[i][j];
      PutPixel (i+10,j+10,fromRGB (k,k,8));
    }
}

void Grava (void) {
  file=open ("gold.shp",O_CREAT | O_BINARY);
  if (file!=-1) {
    write (file,pat,100*100);
    close (file);
  }
}

void Exemplo (void) {
  Pattern (0,0);
  Pattern (100,0);
  Pattern (200,0);
  Pattern (0,100);
  Pattern (100,100);
  Pattern (200,100);

}

void main (void) {
  InitGraph ();
  for (i=0; i<64; i++)
    SetRGB (i,i,i,i);
  SetRGBUniform ();
  Ruido ();
  Filtro ();
  Deforma ();
  SetRGBUniform ();
  getch ();
//  Quantiza ();
  Grava ();
  Exemplo ();
  getch ();
  CloseGraph ();
  printf ("File status: %d\n",file);
}