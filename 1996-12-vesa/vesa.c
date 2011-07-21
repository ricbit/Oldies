#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dpmi.h>
#include <go32.h>
#include <conio.h>
#include <sys/movedata.h>
#include <sys/farptr.h>

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

void PutPixel (int x, int y, int r, int g, int b) {
  int address;
  
  SmartSetPage (y>>5);
  address=((y&0x1f)<<11)+x+x+x;
  _farpokeb (_dos_ds,0xa0000+address,b);
  _farpokeb (_dos_ds,0xa0000+address+1,g);
  _farpokeb (_dos_ds,0xa0000+address+2,r);
}

void SetGraphMode (void) {
  int i;
  short mode;
  
  printf ("vesa 1.0\n");
  regs.x.ax=0x4f00;
  regs.x.di=RM_OFFSET (__tb);
  regs.x.es=RM_SEGMENT (__tb);
  __dpmi_int (0x10,&regs);
  dosmemget (MASK_LINEAR(__tb), sizeof(VESA_INFO), &vesa_info);
  printf ("vv: %x tt: %d\n",vesa_info.VESAVersion,vesa_info.TotalMemory);
  i=RM_TO_LINEAR (vesa_info.VideoModePtr);
  total=0;
  do {
    mode=_farpeekw (_dos_ds,i);
    printf ("mode %d\n",mode);
    i+=2;
    if (mode!=-1)
      modes[total++]=mode;
  } while (mode!=-1);
  for (i=0; i<total; i++) {
    printf ("Mode %d: ",modes[i]);
    regs.x.ax=0x4f01;
    regs.x.cx=modes[i];
    regs.x.es=RM_SEGMENT (__tb);
    regs.x.di=RM_OFFSET (__tb);
    __dpmi_int (0x10,&regs);
    dosmemget (MASK_LINEAR(__tb), sizeof(MODE_INFO), &mode_info);
    printf ("%d %d %d %d\n",
            mode_info.XResolution,
            mode_info.YResolution,
            mode_info.BitsPerPixel, mode_info.WinSize);
    if (mode_info.XResolution==640 && mode_info.YResolution==480 &&
        mode_info.BitsPerPixel==24) chosen=modes[i];
  }
  printf ("\n\nThe Chosen One: %d\n",chosen);
  getch ();
  regs.x.ax=0x4f02;
  regs.x.bx=chosen;
  __dpmi_int (0x10,&regs);
  regs.x.ax=0x4f05;
  regs.x.bx=0;
  regs.x.dx=0;
  __dpmi_int (0x10,&regs);
  bank=0;
}

