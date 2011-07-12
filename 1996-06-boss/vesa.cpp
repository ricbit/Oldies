// BOSS 1.0
// by Ricardo Bittencourt 1996
// module VESA

#define __VESA_CPP

#include <stdio.h>
#include <stdlib.h>
#include <mem.h>
#include <dos.h>
#include <conio.h>
#include "vesa.h"
#include "error.h"
#include "color.h"

byte GenericColor;                      // used on GenericAction
byte *GenericBuffer;                    // used on GetLine & PutLine
word GenericPos;                        // used on *Line functions

void BuildDitherMatrix (void) {
  int root[2][2],i,j;

  root[0][0]=0;
  root[1][0]=3;
  root[0][1]=2;
  root[1][1]=1;
  DithMatrix64=new int[8*8];
  DithMatrix32=new int[8*4];
  for (j=0; j<8; j++) {
    for (i=0; i<8; i++) {
      *(DithMatrix64+j*8+i)=
        16*root[i%2][j%2]+
        4*root[i%4/2][j%4/2]+
        root[i%8/4][j%8/4];
    }
  }
  for (j=0; j<4; j++) {
    for (i=0; i<8; i++) {
      *(DithMatrix32+j*8+i)=
        8*root[i%2][j%2]+
        2*root[i%4/2][j%4/2]+
        (i/4);
    }
  }
}

void InstallVESA (void) {
  struct REGPACK regs;
  int mode;
  word *ptr;

  regs.r_ax=0x4f00;
  regs.r_es=FP_SEG (&Info);
  regs.r_di=FP_OFF (&Info);
  intr (0x10,&regs);
  if (regs.r_ax!=0x004f) ReportError (ERROR_FATAL,"VESA not supported");
  MaxModes=0;
  ptr=(word *) Info.VideoModePtr;
  do {
    MaxModes++;
  } while (*(++ptr)!=0xffff);
  Modes=new word[MaxModes];
  ModeInfo=new ModeInfoBlock[MaxModes];
  ptr=(word *) Info.VideoModePtr;
  mode=0;
  do {
    Modes[mode]=*ptr;
    regs.r_ax=0x4f01;
    regs.r_cx=*ptr++;
    regs.r_es=FP_SEG (&(ModeInfo[mode]));
    regs.r_di=FP_OFF (&(ModeInfo[mode++]));
    intr (0x10,&regs);
  } while (*ptr!=0xffff);
  SVGAbuffer=(byte *) MK_FP (0xa000,0);
  BuildDitherMatrix ();
  White=15;
  Black=0;
  LineOffset=NULL;
  VESApalette=new byte[768];
}

void VESAShowVersion (void) {
  printf ("\nVESA version %d.%d\n",(Info.VESAVersion>>8),
          Info.VESAVersion&0xff);
  printf ("%s\n",(char *)Info.OEMStringPtr);
  printf ("Total video memory: %d kb\n",Info.TotalMemory*64);
}

void PrintInfo (int mode) {
  printf ("Mode %x:\n",Modes[mode]);
  printf ("Resolution: %dx%d %d bits per pixel\n",
          ModeInfo[mode].XResolution,ModeInfo[mode].YResolution,
          ModeInfo[mode].BitsPerPixel);
  printf ("Memory model: %d\n",ModeInfo[mode].MemoryModel);
  printf ("Bytes per Scan Line: %d\n",ModeInfo[mode].BytesPerScanLine);
  printf ("Granularity: %d\n",ModeInfo[mode].WinGranularity);
  printf ("WinA: %d WinB: %d\n",ModeInfo[mode].WinAAttributes,
          ModeInfo[mode].WinBAttributes);
  printf ("WinSize: %d\n",ModeInfo[mode].WinSize);
  printf ("Images Pages: %d\n",ModeInfo[mode].NumberOfImagePages);
  getch ();
}

void SetVideoMode (int x, int y, int bits) {
  int mode;
  struct REGPACK regs;
  dword i;

  mode=0;
  while
    (mode<MaxModes && (ModeInfo[mode].XResolution!=x ||
    ModeInfo[mode].YResolution!=y || ModeInfo[mode].BitsPerPixel!=bits))
  {
      mode++;
  }
  if (mode==MaxModes) {
    char *s;
    sprintf (s,"Video mode %dx%d-%d not available\n",x,y,bits);
    ReportError (ERROR_FATAL,s);
  }
  ActualMode=mode;
  regs.r_ax=0x4f02;
  regs.r_bx=Modes[ActualMode];
  intr (0x10,&regs);
  SetVESAPage=(void (far*)()) ModeInfo[ActualMode].WinFuncPtr;
  VESAResX=x;
  VESAResY=y;
  VESAMaxX=x-1;
  VESAMaxY=y-1;
  if (LineOffset!=NULL) delete LineOffset;
  LineOffset=new dword[VESAResY];
  for (i=0; i<VESAResY; i++)
    LineOffset[i]=i*ModeInfo[ActualMode].BytesPerScanLine;
  SetPage (0);
}

void TextMode (void) {
  struct REGPACK regs;

  ActualMode=-1;
  regs.r_ax=3;
  intr (0x10,&regs);
}

void VESASetPalette (void *palette) {
  _BX=FP_SEG (palette);
  _SI=FP_OFF (palette);
  asm {
    push  ds
    mov   ds,bx
    mov   dx,03c8h
    mov   al,0
    out   dx,al
    inc   dx
    mov   cx,768
    rep   outsb
    pop   ds
  }
  White=matchRGB (255,255,255,(byte *)palette);
  Black=matchRGB (0,0,0,(byte *)palette);
  memcpy (VESApalette,palette,768);
}

void PutPixel (word x, word y, byte color) {
  dword address;

  address=LineOffset[y]+x;
  SmartSetPage (address>>16);
  SVGAbuffer[address & 0xffff]=color;
}

void GenericLine (word x1, word y1, word x2, word y2, PixelAction action) {
  int  dx,dy,ax,ay,sx,sy,d;
  word x,y;

  dx=x2-x1;
  dy=y2-y1;
  ax=2*abs (dx);
  ay=2*abs (dy);
  sx=dx<0?-1:1;
  sy=dy<0?-1:1;
  x=x1;
  y=y1;
  if (ax>ay) {
    d=ay-(ax/2);
    do {
      action (x,y);
      if (x==x2) return;
      if (d>=0) {
        y+=sy;
        d-=ax;
      }
      x+=sx;
      d+=ay;
    } while (1);
  }
  else {
    d=ax-(ay/2);
    do {
      action (x,y);
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

void LineAction (word x, word y) {
  dword address;

  address=LineOffset[y]+x;
  SmartSetPage (address>>16);
  SVGAbuffer[address&0xffff]=GenericColor;
}

void Line (int x1, int y1, int x2, int y2, byte color) {
  GenericColor=color;
  GenericLine (x1,y1,x2,y2,LineAction);
}

void GetLineAction (word x, word y) {
  dword address;

  address=LineOffset[y]+x;
  SmartSetPage (address>>16);
  GenericBuffer[GenericPos++]=SVGAbuffer[address & 0xffff];
}

void GetLine (int x1, int y1, int x2, int y2, byte *buffer) {
  GenericBuffer=buffer;
  GenericPos=0;
  GenericLine (x1,y1,x2,y2,GetLineAction);
}

void PutLineAction (word x, word y) {
  dword address;

  address=LineOffset[y]+x;
  SmartSetPage (address>>16);
  SVGAbuffer[address & 0xffff]=GenericBuffer[GenericPos++];
}

void PutLine (int x1, int y1, int x2, int y2, byte *buffer) {
  GenericBuffer=buffer;
  GenericPos=0;
  GenericLine (x1,y1,x2,y2,PutLineAction);
}

void DottedLineAction (word x, word y) {
  dword address;

  address=LineOffset[y]+x;
  SmartSetPage (address>>16);
  if (GenericPos<4)
    SVGAbuffer[address & 0xffff]=White;
  else
    SVGAbuffer[address & 0xffff]=Black;
  GenericPos=(GenericPos+1) & 0x7;
}

byte DottedLine (int x1, int y1, int x2, int y2, byte pos) {
  GenericPos=pos;
  GenericLine (x1,y1,x2,y2,DottedLineAction);
  return GenericPos;
}

