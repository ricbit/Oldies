#include <stdlib.h>
#include "brmsx_vdp.h"

unsigned char Value;
int vdptemp,vdpaddr=0,vdpcond=0;
unsigned char vdpreg[8];
unsigned char keymatrix[16]=
{255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255};
unsigned char keyline;
unsigned char vdpstatus;
extern unsigned char *vram;


extern "C" void outemul98 (void) {
  asm pushad
  asm mov Value,bl
  vram[vdpaddr]=Value;
  vdpaddr=(vdpaddr+1)&0x3FFF;
  asm popad
}

extern "C" void outemul99 (void) {
  asm pushad
  asm mov Value,bl
  if (vdpcond) {
    if (Value & 0x80) {
      vdpreg[Value&7]=vdptemp;
    } else {
      vdpaddr=((Value&0x3F)<<8)|vdptemp;
    }
    vdpcond=0;
  } else {
    vdptemp=Value;
    vdpcond=1;
  }
  asm popad
}

extern "C" void outemulAA (void) {
  asm pushad
  asm mov Value,bl
  keyline=Value&15;
  asm popad
}

extern "C" void inemul98 (void) {
  asm pushad
  Value=vram[vdpaddr];
  vdpaddr=(vdpaddr+1)&0x3FFF;
  asm popad
}

extern "C" void inemul99 (void) {
  asm pushad
  Value=vdpstatus;
  vdpstatus&=0x7F;
  asm popad
}

extern "C" void inemulA9 (void) {
  asm pushad
  Value=keymatrix[keyline];
  asm popad
}

#define RESTORE         0x0
#define SEEK            0x1
#define STEP1           0x2
#define STEP2           0x3
#define STEP_IN1        0x4
#define STEP_IN2        0x5
#define STEP_OUT1       0x6
#define STEP_OUT2       0x7
#define READ_SECTOR     0x8
#define FORCE_INTERRUPT 0xD

unsigned char drive_status=0;
unsigned char command_type=0;
unsigned char portD3=0,portD4=0,portD2=0,portD0=0,portD1=0;
int current_track=0,current_offset=0,current_command=0,current_direction=0;
int avail_bytes=0;
extern unsigned char *diskA;

extern "C" void inemulD0 (void) {
  asm pushad

  drive_status|=64;

  if (command_type) {

    if (current_track)
      drive_status&=~4;
    else
      drive_status|=4;

    drive_status^=2;  
  } else {
    drive_status&=~4;
  }

  Value=drive_status;
  asm popad
}

extern "C" void outemulD0 (void) {
  asm pushad
  asm mov Value,bl
  portD0=Value;
  current_command=Value>>4;
  switch (current_command) {
    case FORCE_INTERRUPT:
      drive_status&=~1;
      command_type=1;
      break;
    case RESTORE:
      current_track=0;
      drive_status&=~1;
      command_type=1;
      break;
    case SEEK:
      current_track=portD3;
      command_type=1;
      drive_status&=~1;
      break;
    case STEP_IN1:
    case STEP_IN2:
      if (current_track<79)
        current_track++;
      current_direction=1;
      command_type=1;
      drive_status&=~1;
      break;
    case STEP_OUT1:
    case STEP_OUT2:
      if (current_track)
        current_track--;
      current_direction=0;
      command_type=1;
      drive_status&=~1;
      break;
    case STEP1:
    case STEP2:
      if (current_direction) {
        if (current_track<79)
          current_track++;
      } else {
        if (current_track)
          current_track--;
      }
      command_type=1;
      drive_status&=~1;
      break;
    case READ_SECTOR:
      current_offset=512*(current_track*18+(portD2-1)+((portD4>>4)&1)*9);
      drive_status|=3;
      avail_bytes=512;
      command_type=0;
      break;
  }

  asm popad
}

extern "C" void outemulD3 (void) {
  asm pushad
  asm mov Value,bl
  portD3=Value;
  asm popad
}

extern "C" void outemulD4 (void) {
  asm pushad
  asm mov Value,bl
  portD4=Value;
  asm popad
}

extern "C" void inemulD4 (void) {
  asm pushad
  Value=portD4;
  asm popad
}

extern "C" void inemulD3 (void) {
  asm pushad

  if (current_command!=READ_SECTOR) {
    Value=0xFF;
  } else {
    if (diskA!=NULL)
      Value=diskA[current_offset++];
    else
      Value=0;
    if (!--avail_bytes)
      drive_status&=~3;
  }
  asm popad
}

extern "C" void outemulD2 (void) {
  asm pushad
  asm mov Value,bl
  portD2=Value;
  asm popad
}

extern "C" void outemulD1 (void) {
  asm pushad
  asm mov Value,bl
  portD1=Value;
  asm popad
}

extern "C" void inemulD1 (void) {
  asm pushad
  Value=current_track;
  asm popad
}

extern "C" void inemulD2 (void) {
  asm pushad
  Value=portD2;
  asm popad
}


