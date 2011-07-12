// BOSS 1.0
// by Ricardo Bittencourt 1996
// module MOUSE

#define __MOUSE_CPP

#include <stdlib.h>
#include <dos.h>
#include "general.h"
#include "mouse.h"

int  bytenum;
byte combytes[3];
int  installed=0;

void interrupt (*OldMouseHandler) (...);

void interrupt NewMouseHandler (...) {
  byte inbyte;
  int dx,dy;

  inbyte=inportb (0x3f8);
  if ((inbyte & 64)==64) bytenum=0;
  combytes[bytenum++]=inbyte;
  if (bytenum==3) {
    dx=((combytes[0] & 3) << 6)+combytes[1];
    dy=((combytes[0] & 12)<< 4)+combytes[2];
    if (dx>=128) dx-=256;
    if (dy>=128) dy-=256;
    MouseX+=dx;
    MouseY+=dy;
    if (MouseX>MouseMaxX) MouseX=MouseMaxX;
    if (MouseY>MouseMaxY) MouseY=MouseMaxY;
    if (MouseX<MouseMinX) MouseX=MouseMinX;
    if (MouseY<MouseMinY) MouseY=MouseMinY;
    LeftButton=((combytes[0] & 32)!=0);
    RightButton=((combytes[0] & 16)!=0);
    bytenum=0;
  }
  outportb (0x20,0x20);
}

void RemoveMouseDriver (void) {
  if (installed) setvect (0x0c,OldMouseHandler);
  installed=0;
}

void InstallMouseDriver (void) {
  struct REGPACK regs;
  regs.r_ax=0;
  intr (0x33,&regs);
  MouseX=0;
  MouseY=0;
  bytenum=0;
  OldMouseHandler=getvect (0x0c);
  setvect (0x0c,NewMouseHandler);
  installed=1;
  atexit (RemoveMouseDriver);
}

