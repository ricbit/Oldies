// BOSS 1.0
// by Ricardo Bittencourt 1996
// module XMS

#include <stdio.h>
#include <stdlib.h>
#include <dos.h>

#include <general.h>
#include <xms.h>
#include <error.h>

typedef struct {
  dword Length;
  word  SourceHandle;
  dword SourceOffset;
  word  DestHandle;
  dword DestOffset;
} ExtMemMoveStruct;

static ExtMemMoveStruct descriptor;
void (*XMSdriver)();
int XMSVersion;

void InstallXMS (void) {
  struct REGPACK regs;

  regs.r_ax=0x4300;
  intr (0x2f,&regs);
  if ((regs.r_ax&0xff)!=0x80) ReportError (ERROR_FATAL,"XMS not found");
  regs.r_ax=0x4310;
  intr (0x2f,&regs);
  XMSdriver=(void (far*)()) MK_FP (regs.r_es,regs.r_bx);
  _AH=0x00;
  XMSdriver();
  XMSVersion=_AX;
}

void XMSShowVersion (void) {
  printf ("\nXMS Version %x.%x\n",(XMSVersion>>8),XMSVersion&0xff);
  printf ("XMS available: %d kb\n",XMSAvailable ());
  printf ("XMS largest block: %d kb\n",XMSLargest ());
}

word XMSAvailable (void) {
  _AH=0x08;
  XMSdriver ();
  return (_DX);
}

word XMSLargest (void) {
  _AH=0x08;
  XMSdriver ();
  return (_AX);
}

XMSblock::XMSblock (dword size) {
  int ax,bx;

  _DX=(size+1023)/1024;
  _AH=0x09;
  XMSdriver ();
  handle=_DX;
  if (!_AX) ReportError (ERROR_FATAL,"Cannot allocate XMS block");
}

XMSblock::~XMSblock () {
  _DX=handle;
  _AH=0x0a;
  XMSdriver ();
}

void XMSblock::RAMtoXMS (void *ptr, dword offset, dword len) {
  descriptor.Length=len;
  descriptor.SourceHandle=0;
  descriptor.SourceOffset=(dword) ptr;
  descriptor.DestHandle=handle;
  descriptor.DestOffset=offset;
  asm push ds
  _DS=FP_SEG (&descriptor);
  _SI=FP_OFF (&descriptor);
  _AH=0x0b;
  XMSdriver ();
  asm pop ds
}

void XMSblock::XMStoRAM (dword offset, void *ptr, dword len) {
  descriptor.Length=len;
  descriptor.SourceHandle=handle;
  descriptor.SourceOffset=offset;
  descriptor.DestHandle=0;
  descriptor.DestOffset=(dword) ptr;
  asm push ds
  _DS=FP_SEG (&descriptor);
  _SI=FP_OFF (&descriptor);
  _AH=0x0b;
  XMSdriver ();
  asm pop ds
}