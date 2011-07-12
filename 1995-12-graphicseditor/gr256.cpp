#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <malloc.h>
#include <dos.h>
#include "\borlandc\doom\fgraph.h"
#include "mouse.h"
#include "cursor.h"

typedef unsigned char byte;
typedef struct {
  int x,y;
} pixel;
typedef struct {
  int min,max,vis;
} buffer;

Mouse mouse;

void GrowRegion1 (int x, int y) {
  byte color=GetPixel (x,y);
  pixel *p;
  byte *map;
  int at=1,last,px,py;
  long int i,d;

  p=new pixel[10000];
  map=new byte[64000];
  for (i=0; i<64000; i++) map[i]=0;

  p[0].x=x;
  p[0].y=y;

  do {
    at--;
    px=p[at].x;
    py=p[at].y;
    if (px>=0 && px<320 && py>=0 && py<200) {
      d=px+320*py;
      if (!map[d])
        if (GetPixel (px,py)==color) {
          PutPixel (px,py,15);
          map[d]=1;

          p[at].x=px+1;
          p[at++].y=py;

          p[at].x=px-1;
          p[at++].y=py;

          p[at].x=px;
          p[at++].y=py+1;

          p[at].x=px;
          p[at++].y=py-1;

        }
    }
  } while (at>0 && at<10000);

  delete p;
  delete map;
}

void GrowRegion2 (int x, int y) {
  pixel *p;
  buffer *b;
  byte *fb,*pfb,*map,*cop,*pcop;
  long int i,d;
  int px,py,at=1;
  byte color;

  fb=(byte far *) MK_FP (0xa000,0);
  p=new pixel[10000];
  b=new buffer[200];
  map=new byte[64000];
  cop=new byte[64000];
  pfb=fb;
  for (i=0; i<200; i++) b[i].vis=0;
  for (i=0; i<64000; i++) map[i]=0;
  for (i=0; i<64000; i++) cop[i]=*pfb++;

  color=GetPixel (x,y);

  // primeiro passo: achar a borda
  px=x;
  py=y;
  pfb=fb+px+py*320;
  while (px<319 && *++pfb==color) px++;
  p[0].x=px;
  p[0].y=py;

  // Segundo passo: construir a borda

  do {
    at--;
    px=p[at].x;
    py=p[at].y;
    d=px+py*320;
    pcop=cop+d;

    if (*pcop==color) {

      // Check borda fisica

      if (px==319) {
        map[d]=1;
        p[at].x=px-1;
        p[at++].y=py;
        if (py>0) {
          p[at].x=px;
          p[at++].y=py-1;
        }
        if (py<199) {
          p[at].x=px;
          p[at++].y=py+1;
        }
        PutPixel (px,py,15);
        continue;
      }

      if (px==0) {
        map[d]=1;
        p[at].x=px+1;
        p[at++].y=py;
        if (py>0) {
          p[at].x=px;
          p[at++].y=py-1;
        }
        if (py<199) {
          p[at].x=px;
          p[at++].y=py+1;
        }
        PutPixel (px,py,15);
        continue;
      }

      if (py==199) {
        map[d]=1;
        p[at].x=px;
        p[at++].y=py-1;
        if (px>0) {
          p[at].x=px+1;
          p[at++].y=py;
        }
        if (px<319) {
          p[at].x=px+1;
          p[at++].y=py;
        }
        PutPixel (px,py,15);
        continue;
      }

      if (py==0) {
        map[d]=1;
        p[at].x=px;
        p[at++].y=py+1;
        if (px>0) {
          p[at].x=px+1;
          p[at++].y=py;
        }
        if (px<319) {
          p[at].x=px+1;
          p[at++].y=py;
        }
        PutPixel (px,py,15);
        continue;
      }

      // Check borda logica
      if (*(pcop+1)!=color   || *(pcop-1)!=color ||
          *(pcop+320)!=color || *(pcop-320)!=color)

      {
        map[d]=1;

        p[at].x=px+1;
        p[at++].y=py;

        p[at].x=px-1;
        p[at++].y=py;

        p[at].x=px;
        p[at++].y=py-1;

        p[at].x=px;
        p[at++].y=py+1;

        PutPixel (px,py,15);
        continue;
      }

      // Checa casquinha
      if (map[d-1]==1 || map[d+1]==1 || map[d+320]==1 || map[d-320]==1)
      {
        p[at].x=px+1;
        p[at++].y=py;

        p[at].x=px-1;
        p[at++].y=py;

        p[at].x=px;
        p[at++].y=py-1;

        p[at].x=px;
        p[at++].y=py+1;

        PutPixel (px,py,13);
        continue;
      }

    }

  } while (at);

  // Mostra resultados

//  pfb=fb;
//  for (i=0; i<64000; i++,pfb++) if (map[i]==1) *pfb=15;

  delete p;
  delete b;
  delete map;
  delete cop;
}

void main (void) {
  byte buffer[100];
  InitGraph ();
  Cursor c;

  c.Show ();
  do {
    c.Atualize ();
    if (mouse.Left ()) {
      c.Hide ();
      Line (c.lx,c.ly,c.x,c.y,12);
      c.Show ();
    }
    if (mouse.Right ()) {
      c.Hide ();
      GrowRegion2 (c.x,c.y);
      c.Show ();
    }
  } while (!kbhit ());

  CloseGraph ();
}