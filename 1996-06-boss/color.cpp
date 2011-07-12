// BOSS 1.0
// by Ricardo Bittencourt 1996
// module COLOR

#define __COLOR_CPP

#include <math.h>
#include <stdlib.h>
#include "color.h"
#include "vesa.h"

byte pascal fromRGB (byte r, byte g, byte b, word x, word y) {
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

byte pascal matchRGB (byte r, byte g, byte b, byte *palette) {
  int i,delta,ActualDelta;
  byte *color,ActualColor;

  ActualColor=0;
  ActualDelta=1000;
  color=palette;
  r<<=2;
  g<<=2;
  b<<=2;
  for (i=0; i<255; i++) {
    delta=abs (r-*color++)+abs (g-*color++)+abs (b-*color++);
    if (delta==0) return i;
    if (delta<ActualDelta) {
      ActualDelta=delta;
      ActualColor=i;
    }
  }
  return ActualColor;
}

RGBtriple RealtoRGB (real r, real g, real b) {
  RGBtriple color;

  color.R=(byte) (255.0*r);
  color.G=(byte) (255.0*g);
  color.B=(byte) (255.0*b);

  return color;
}

RGBtriple HSVtoRGB (real h, real s, real v) {
  RGBtriple color;
  int in;
  real x,y,z,re;

  if (s<epsilon) {
    color=RealtoRGB (v,v,v);
    return color;
  }
  h=h/PI*(3-epsilon);
  in=(int) h;
  re=h-in;
  x=v*(1-s);
  y=v*(1-s*re);
  z=v*(1-s*(1-re));
  switch (in) {
    case 0:
      color=RealtoRGB (v,z,x);
      break;
    case 1:
      color=RealtoRGB (y,v,x);
      break;
    case 2:
      color=RealtoRGB (x,v,z);
      break;
    case 3:
      color=RealtoRGB (x,y,v);
      break;
    case 4:
      color=RealtoRGB (z,x,v);
      break;
    case 5:
      color=RealtoRGB (v,x,y);
      break;
  }
  return color;
}

void DrawColorCircle (void) {
  int x,y;
  real X,Y,Z,h;
  RGBtriple rgb;

  for (y=0; y<100; y++)
    for (x=0; x<100; x++) {
      X=(real)(x-50)/50.0;
      Y=(real)(y-50)/50.0;
      Z=sqrt (X*X+Y*Y);
      if (Z<=1.0) {
        if (Y==0.0 && X==0.0)
          h=0.0;
        else
          h=atan2 (Y,X)+PI;
        rgb=HSVtoRGB (h,Z,1.0);
        if (GlobalState==Bit8)
          PutPixel (x,y,matchRGB (rgb.R,rgb.G,rgb.B,VESApalette));
        else
          PutPixel (x,y,fromRGB (rgb.R,rgb.G,rgb.B,x,y));
      }
      else PutPixel (x,y,0);
    }
}
