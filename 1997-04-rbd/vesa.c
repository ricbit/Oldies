#include "opsys.h"

#ifdef SYS_MSDOS

#include <stdio.h>
#include <dpmi.h>
#include <go32.h>
#include <conio.h>
#include <sys\farptr.h>
#include "types.h"
#include "video.h"

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

#define MASK_LINEAR(addr)  (addr & 0x000FFFFF)
#define RM_TO_LINEAR(addr) (((addr & 0xFFFF0000) >> 12) + (addr & 0xFFFF))
#define RM_OFFSET(addr)    (MASK_LINEAR(addr) & 0xFFFF)
#define RM_SEGMENT(addr)   ((MASK_LINEAR(addr) & 0xFFFF0000) >> 4)

VESA_INFO vesa_info;            /* vesa information */

void install_vesa (void) {
  __dpmi_regs regs;  
  char vendor[250];
  int vendor_addr;
  int i=0;
  
  regs.x.ax=0x4f00;
  regs.x.di=RM_OFFSET (__tb);
  regs.x.es=RM_SEGMENT (__tb);
  __dpmi_int (0x10,&regs);
  dosmemget (MASK_LINEAR (__tb), sizeof (VESA_INFO), &vesa_info);
  vendor_addr=RM_TO_LINEAR (vesa_info.OEMStringPtr);
  do {
    vendor[i]=_farpeekb (_dos_ds,vendor_addr++);
  } while (vendor[i++]!=0);
  printf ("Searching for VESA ... found <%s>\n",vendor);
}
  
int vesa_check_mode (int resx, int resy) {  
  __dpmi_regs regs;
  MODE_INFO mode_info;
  int mode_addr;
  short mode_number;
 
  mode_addr=RM_TO_LINEAR (vesa_info.VideoModePtr);
  mode_number=_farpeekw (_dos_ds,mode_addr);
  printf ("Searching for mode %d %d ... ",resx,resy);
  while (mode_number!=-1) {  
    regs.x.ax=0x4f01;
    regs.x.cx=mode_number;
    regs.x.es=RM_SEGMENT (__tb);
    regs.x.di=RM_OFFSET (__tb);
    __dpmi_int (0x10,&regs);
    dosmemget (MASK_LINEAR (__tb), sizeof (MODE_INFO), &mode_info);
    if (mode_info.XResolution==resx && mode_info.YResolution==resy &&
        mode_info.BitsPerPixel==16 && mode_info.DirectColorModeInfo==0) 
    {
      printf ("found mode 0x%x\n",mode_number);
      return mode_number;
    }
    mode_addr+=2;
    mode_number=_farpeekw (_dos_ds,mode_addr);
  };
  printf ("not found. \n");
  exit (1);
}

void vesa_set_graph_mode (int mode, void (*drawimage)()) {
  __dpmi_regs regs;

  regs.x.ax=0x4f02;
  regs.x.bx=mode;
  __dpmi_int (0x10,&regs);
  drawimage ();
}

void vesa_blit (short *buffer) {
  __dpmi_regs regs;
  int size,page;

  size=RESX*RESY*2;
  page=0;
  while (size>0) {
    regs.x.ax=0x4f05;
    regs.x.bx=0;
    regs.x.dx=page;
    __dpmi_int (0x10,&regs);
    if (size>=65536)
      movedata (_my_ds(),(int)buffer,_dos_ds,0xa0000,65536);
    else
      movedata (_my_ds(),(int)buffer,_dos_ds,0xa0000,size);
    size-=65536;
    buffer+=32768;
    page++;
  }
}

#endif
