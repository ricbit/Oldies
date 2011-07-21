#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dpmi.h>
#include <go32.h>
#include <conio.h>
#include <pc.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/movedata.h>
#include <sys/farptr.h>
#include "vesa.h"

/* #define VESADRAW */

typedef struct VESA_INFO         /* VESA information block structure */
{ 
   unsigned char  VESASignature[4]     __attribute__ ((packed));
   unsigned short VESAVersion          __attribute__ ((packed));
   unsigned long  OEMStringPtr         __attribute__ ((packed));
   unsigned char  Capabilities[4]      __attribute__ ((packed));
   unsigned long  VideoModePtr         __attribute__ ((packed)); 
   unsigned short TotalMemory          __attribute__ ((packed)); 
   unsigned short OemSoftwareRev       __attribute__ ((packed)); 
   unsigned long  OemVendorNamePtr     __attribute__ ((packed)); 
   unsigned long  OemProductNamePtr    __attribute__ ((packed)); 
   unsigned long  OemProductRevPtr     __attribute__ ((packed)); 
   unsigned char  Reserved[222]        __attribute__ ((packed)); 
   unsigned char  OemData[256]         __attribute__ ((packed)); 
} VESA_INFO;

typedef struct MODE_INFO         /* VESA information for a specific mode */
{
   unsigned short ModeAttributes       __attribute__ ((packed)); 
   unsigned char  WinAAttributes       __attribute__ ((packed)); 
   unsigned char  WinBAttributes       __attribute__ ((packed)); 
   unsigned short WinGranularity       __attribute__ ((packed)); 
   unsigned short WinSize              __attribute__ ((packed)); 
   unsigned short WinASegment          __attribute__ ((packed)); 
   unsigned short WinBSegment          __attribute__ ((packed)); 
   unsigned long  WinFuncPtr           __attribute__ ((packed)); 
   unsigned short BytesPerScanLine     __attribute__ ((packed)); 
   unsigned short XResolution          __attribute__ ((packed)); 
   unsigned short YResolution          __attribute__ ((packed)); 
   unsigned char  XCharSize            __attribute__ ((packed)); 
   unsigned char  YCharSize            __attribute__ ((packed)); 
   unsigned char  NumberOfPlanes       __attribute__ ((packed)); 
   unsigned char  BitsPerPixel         __attribute__ ((packed)); 
   unsigned char  NumberOfBanks        __attribute__ ((packed)); 
   unsigned char  MemoryModel          __attribute__ ((packed)); 
   unsigned char  BankSize             __attribute__ ((packed)); 
   unsigned char  NumberOfImagePages   __attribute__ ((packed));
   unsigned char  Reserved_page        __attribute__ ((packed)); 
   unsigned char  RedMaskSize          __attribute__ ((packed)); 
   unsigned char  RedFieldPosition     __attribute__ ((packed)); 
   unsigned char  GreenMaskSize        __attribute__ ((packed)); 
   unsigned char  GreenFieldPosition   __attribute__ ((packed));
   unsigned char  BlueMaskSize         __attribute__ ((packed)); 
   unsigned char  BlueFieldPosition    __attribute__ ((packed)); 
   unsigned char  RsvdMaskSize         __attribute__ ((packed)); 
   unsigned char  DirectColorModeInfo  __attribute__ ((packed));
   unsigned long  PhysBasePtr          __attribute__ ((packed)); 
   unsigned long  OffScreenMemOffset   __attribute__ ((packed)); 
   unsigned short OffScreenMemSize     __attribute__ ((packed)); 
   unsigned char  Reserved[206]        __attribute__ ((packed)); 
} MODE_INFO;

VESA_INFO vesa_info;
MODE_INFO mode_info;

#define MASK_LINEAR(addr)     (addr & 0x000FFFFF)
#define RM_TO_LINEAR(addr)    (((addr & 0xFFFF0000) >> 12) + (addr & 0xFFFF))
#define RM_OFFSET(addr)       (MASK_LINEAR(addr) & 0xFFFF)
#define RM_SEGMENT(addr)      ((MASK_LINEAR(addr) & 0xFFFF0000) >> 4)


__dpmi_regs regs;

short modes[256];
int total;
short chosen;
int bank;
int *DithMatrix64,*DithMatrix32;

unsigned char *bigbuffer;

void putpixelVESA (int address, int c) {
  int high,low;

  high=(address & 0xffff0000)>>16;
  low=(address & 0x0000ffff);
  if (high!=bank) {
    regs.x.ax=0x4f05;
    regs.x.bx=0;
    regs.x.dx=high;
    bank=high;
    __dpmi_int (0x10,&regs);
  }
  _farpokeb (_dos_ds,0xa0000+low,c);
}

inline void SmartSetPage (int newbank) {
  if (newbank!=bank) {
    regs.x.ax=0x4f05;
    regs.x.bx=0;
    regs.x.dx=newbank;
    bank=newbank;
    __dpmi_int (0x10,&regs);
  }
}

unsigned char fromRGB 
  (unsigned char r, unsigned char g, unsigned char b, 
   unsigned short x, unsigned short y) 
{
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

void BuildDitherMatrix (void) {
  int root[2][2],i,j;

  root[0][0]=0;
  root[1][0]=3;
  root[0][1]=2;
  root[1][1]=1;
  DithMatrix64=(int *) malloc (sizeof (int)*8*8);
  DithMatrix32=(int *) malloc (sizeof (int)*8*4);
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

void PutPixel (int x, int y, RGB rgb) {
  int address;
  
#ifdef VESADRAW
/*  address=(y*320+x);
  _farpokeb (_dos_ds,0xa0000+address,fromRGB(rgb.r,rgb.g,rgb.b,x,y));*/
  address=y*mode_info.BytesPerScanLine+x*4;
  
  SmartSetPage (address>>16);
  address&=65535;
  _farpokeb (_dos_ds,0xa0000+address,rgb.b);
  _farpokeb (_dos_ds,0xa0000+address+1,rgb.g);
  _farpokeb (_dos_ds,0xa0000+address+2,rgb.r);
  

#else
  bigbuffer[(x+y*1024)*3+0]=rgb.r;
  bigbuffer[(x+y*1024)*3+1]=rgb.g;
  bigbuffer[(x+y*1024)*3+2]=rgb.b;

  return;
#endif
  
}
  
void BuildPalette (void) {
  int i;
  
  outportb (0x3c8,0);
  for (i=0; i<256; i++) {
    outportb (0x3c9,(i&0xe0)>>2);
    outportb (0x3c9,(i&0x1c)<<1);
    outportb (0x3c9,(i&0x03)<<4);
  }
}

void SetGraphMode (void) {

#ifdef VESADRAW
  regs.x.ax=0x13;
  __dpmi_int (0x10,&regs);
  BuildDitherMatrix ();  
  BuildPalette ();
#else
    
  int i;

  short mode;
  
  bigbuffer=(unsigned char *) malloc (1024*768*3);
  return;

  regs.x.ax=0x4f00;
  regs.x.di=RM_OFFSET (__tb);
  regs.x.es=RM_SEGMENT (__tb);
  __dpmi_int (0x10,&regs);
  dosmemget (MASK_LINEAR(__tb), sizeof(VESA_INFO), &vesa_info);
  i=RM_TO_LINEAR (vesa_info.VideoModePtr);
  total=0;
  do {
    mode=_farpeekw (_dos_ds,i);
    i+=2;
    if (mode!=-1)
      modes[total++]=mode;
  } while (mode!=-1);
  for (i=0; i<total; i++) {
    regs.x.ax=0x4f01;
    regs.x.cx=modes[i];
    regs.x.es=RM_SEGMENT (__tb);
    regs.x.di=RM_OFFSET (__tb);
    __dpmi_int (0x10,&regs);
    dosmemget (MASK_LINEAR(__tb), sizeof(MODE_INFO), &mode_info);
    if (mode_info.XResolution==800 && mode_info.YResolution==600 &&
        mode_info.BitsPerPixel==32) 
    {
      chosen=modes[i];
      break;
    }
  }
  printf ("chosen mode : %d\n",chosen);
  getch ();
  regs.x.ax=0x4f02;
  regs.x.bx=chosen;
  __dpmi_int (0x10,&regs);
  regs.x.ax=0x4f05;
  regs.x.bx=0;
  regs.x.dx=0;
  __dpmi_int (0x10,&regs);
  bank=0;
#endif  
}


void RestoreTextMode (void) {
  int i;

#ifndef VESADRAW
  i=open ("image.raw",O_BINARY|O_RDONLY|O_CREAT,S_IWUSR|S_IRUSR);
  write (i,bigbuffer,1024*768*3);
  close(i);
#endif

  textmode (C80);
}
