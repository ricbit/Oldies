// BOSS 1.0
// by Ricardo Bittencourt 1996
// header VESA

#ifndef __VESA_H
#define __VESA_H

#ifdef __VESA_CPP
#define _VESAEXT
#else
#define _VESAEXT extern
#endif

#include "general.h"
#include "timer.h"

typedef struct {
  byte  VESASignature[4];
  word  VESAVersion;
  dword OEMStringPtr;
  byte  Capabilities[4];
  dword VideoModePtr;
  word  TotalMemory;
  byte  Reserved[236];
} VGAInfoBlock;

typedef struct {
  word  ModeAttributes;
  byte  WinAAttributes;
  byte  WinBAttributes;
  word  WinGranularity;
  word  WinSize;
  word  WinASegment;
  word  WinBSegment;
  dword WinFuncPtr;
  word  BytesPerScanLine;

  word  XResolution;
  word  YResolution;
  byte  XCharSize;
  byte  YCharSize;
  byte  NumberOfPlanes;
  byte  BitsPerPixel;
  byte  NumberOfBanks;
  byte  MemoryModel;
  byte  BankSize;
  byte  NumberOfImagePages;
  byte  Reserved;

  byte  RedMaskSize;
  byte  RedFieldPosition;
  byte  GreenMaskSize;
  byte  GreenFieldPosition;
  byte  BlueMaskSize;
  byte  BlueFieldPosition;
  byte  RsvdMaskSize;
  byte  DirectColorModeInfo;
  byte  Filler[216];
} ModeInfoBlock;

typedef void (*PixelAction) (word,word);

_VESAEXT VGAInfoBlock Info;             // Info about system
_VESAEXT ModeInfoBlock *ModeInfo;       // Info about each mode
_VESAEXT byte *SVGAbuffer;              // Pointer to frame buffer
_VESAEXT word *Modes;                   // Physical number of each mode
_VESAEXT int MaxModes;                  // Number of modes
_VESAEXT int ActualMode;                // Logical number of actual mode
_VESAEXT int ActualPage;                // Number of actual page
_VESAEXT int LastPage;                  // Last page before switch
_VESAEXT void (*SetVESAPage)();         // Pointer to switching function
_VESAEXT int VESAMaxX,VESAMaxY;         // Maximum value of a pixel
_VESAEXT int VESAResX,VESAResY;         // Resolution of actual mode
_VESAEXT byte White,Black;              // Closest colors of White and Black
_VESAEXT dword *LineOffset;             // Offset of start of each line
_VESAEXT int *DithMatrix64;             // used on fromRGB
_VESAEXT int *DithMatrix32;             // also used on fromRGB
_VESAEXT byte *VESApalette;             // palette being used

void InstallVESA (void);
void VESAShowVersion (void);
void PrintInfo (int mode);
void SetVideoMode (int x, int y, int bits);
void VESASetPalette (void *palette);
void TextMode ();
void PutPixel (word x, word y, byte color);
void GenericLine (word x1, word y1, word x2, word y2, PixelAction action);
void Line (int x1, int y1, int x2, int y2, byte color);
void GetLine (int x1, int y1, int x2, int y2, byte *buffer);
void PutLine (int x1, int y1, int x2, int y2, byte *buffer);
byte DottedLine (int x1, int y1, int x2, int y2, byte pos);

inline void SetPage (int page) {
  _DX=ActualPage=page;
  _BX=0;
  SetVESAPage ();
}

inline void SmartSetPage (int page) {
  if (ActualPage!=page) SetPage (page);
}

inline void SwitchPage (int page) {
  LastPage=ActualPage;
  SmartSetPage (page);
}

inline void RestorePage (void) {
  SmartSetPage (LastPage);
}

#endif
