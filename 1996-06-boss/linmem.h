// BOSS 1.0
// by Ricardo Bittencourt 1996
// header LINMEM

#ifndef __LINMEM_H
#define __LINMEM_H

#include "general.h"
#include "xms.h"
#include "timer.h"

class Array {
private:
  XMSblock *XMSbuffer;
  byte     *RAMbuffer;
  dword    *offset;
  word      Actual,Lines;
  word      Size;

public:
  Array ();
  Array (word lines, word size);
  ~Array ();
  void Kill (void);
  void Alloc (word lines, word size);
  inline pbyte operator[] (word line);
};

class LinearMemory {
private:
  XMSblock *XMSbuffer;
  byte     *RAMbuffer;
  dword     Actual;
  dword     Size;

public:
  LinearMemory ();
  LinearMemory (dword size);
  ~LinearMemory ();
  void Alloc (dword size);
  void Kill ();
  pbyte buffer (dword number);
  inline pbyte operator[] (dword offset);
};

inline pbyte Array::operator[] (word line) {
  if (line==Actual) {
    return RAMbuffer;
  }
  else {
    XMSbuffer->RAMtoXMS (RAMbuffer,offset[Actual],Size);
    XMSbuffer->XMStoRAM (offset[line],RAMbuffer,Size);
    Actual=line;
    return RAMbuffer;
  }
}

inline pbyte LinearMemory::operator[] (dword offset) {
  if ((offset>>13)==Actual) {
    return (RAMbuffer+(offset & 0x1FFF));
  }
  else {
    XMSbuffer->RAMtoXMS (RAMbuffer,Actual<<13,8192);
    XMSbuffer->XMStoRAM ((offset>>13)<<13,RAMbuffer,8192);
    Actual=offset>>13;
    return (RAMbuffer+(offset & 0x1FFF));
  }
}

#endif
