// Video.cpp

#include "Compiler.h"
#include "Video.h"

#define sgn(x) (x)<0?-1:(x)>0?1:0

#ifndef __BORLANDC__

void Video::Init () {}

void Video::Close () {}

void Video::Point (int x, int y, byte_ cor) {
  cout << "x " << x << " y " << y << " cor " << int(cor) << "\n";
}

void Video::WaitForKey (void) {}

void Video::SetRGB (byte_ n, byte_ r, byte_ g, byte_ b) {}

int Video::KeyPressed (void) {
  return false;
}

#endif

Video::Video () {
  maxpal=0;
}

#ifdef __BORLANDC__

void Video::Init () {
  MaxX=319;
  MaxY=199;
  asm {
    mov   ax,013h
    int	  10h
  }
}

void Video::Close () {
  asm {
    mov   ax,03h
    int   10h
  }
}

void Video::Point (int x, int y, byte_ cor) {
  asm {
    mov   bx,320
    mov   ax,y
    mul   bx
    mov   bx,x
    add   bx,ax
    mov   cx,0a000h
    mov   es,cx
    mov   al,cor
    mov   es:[bx],al
  }
}

void Video::SetRGB (byte_ n, byte_ r, byte_ g, byte_ b) {
  asm {
    mov   dx,03c8h
    mov   al,n
    out   dx,al
    inc   dx
    mov   al,r
    out   dx,al
    mov   al,g
    out   dx,al
    mov   al,b
    out   dx,al
  }
}

void Video::CopyLine (int n, int y, byte_ far *line) {
  word s,o;
  s=((dword) line / 65536);
  o=((dword) line & 0xffff);
  asm {
    mov   bx,320
    mov   ax,y
    mul   bx
    mov   cx,n
    push  ds
    push  si
    push  di
    mov   di,ax
    mov   si,o
    mov   ax,s
    mov   ds,ax
    mov   ax,0a000h
    mov   es,ax
    rep   movsb
    pop   di
    pop   si
    pop   ds
  }
}

void Video::Line (int x1, int y1, int x2, int y2, int cor) {
  int d,x,y,ax,ay,dx,dy,sx,sy;
  dx=x2-x1;
  ax=abs (dx)*2;
  sx=sgn (dx);
  dy=y2-y1;
  ay=abs (dy)*2;
  sy=sgn (dy);
  x=x1;
  y=y1;
  if (ax>ay) {
    d=ay-(ax/2);
    do {
      Point (x,y,cor);
      if (x==x2) return;
      if (d>=0) {
        y+=sy;
        d-=ax;
      }
      x+=sx;
      d+=ay;
    } while (1);
  } else {
    d=ax-(ay/2);
    do {
      Point (x,y,cor);
      if (y==y2) return;
      if (d>=0) {
        x+=sx;
        d-=ay;
      }
      y+=sy;
      d+=ax;
    } while (1);
  }
}

void Video::Rectangle (int x1, int y1, int x2, int y2, int cor) {
  Line (x1,y1,x2,y1,cor);
  Line (x1,y2,x2,y2,cor);
  Line (x1,y1,x1,y2,cor);
  Line (x2,y1,x2,y2,cor);
}

void Video::Bar (int x1, int y1, int x2, int y2, int cor) {
  int i;
  for (i=y1; i<=y2; i++) 
    Line (x1,i,x2,i,cor);
}

void Video::WaitForKey (void) {
  asm {
    mov   ax,0
    int   16h
  }
}

int Video::KeyPressed (void) {
  int s;
  asm {
    mov   s,0
    mov   ah,01h
    int   16h
    jz    end
    mov   s,1
  }
  end:
  return s;
}

#endif

byte_ Video::Inclui (Cor c) {
  int i;
  if (maxpal>0)
    for (i=0; i<maxpal; i++)
      if (pal[i].c[0]==c.c[0] && pal[i].c[1]==c.c[1] && pal[i].c[2]==c.c[2])
        return i;
  pal[maxpal]=c;
  SetRGB (maxpal,c.c[0],c.c[1],c.c[2]);
  maxpal++;
  cout << " maxpal " << maxpal << "\n";
  if (maxpal>255) {
    WaitForKey ();
    Close ();
    cout << "Estourou o numero maximo de cores";
    exit (0);
  }
  return maxpal-1;
}

Cor::Cor () {
  c[0]=c[1]=c[2]=0;
}

Cor::Cor (Vetor v) {
  c[0]=byte_ (v.v[0]*63+0.5);
  c[1]=byte_ (v.v[1]*63+0.5);
  c[2]=byte_ (v.v[2]*63+0.5);
}

