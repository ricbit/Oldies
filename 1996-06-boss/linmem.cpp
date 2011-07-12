// BOSS 1.0
// by Ricardo Bittencourt 1996
// module LINMEM

#include <stddef.h>
#include <stdio.h>

#include "general.h"
#include "linmem.h"

Array::Array (void) {
  XMSbuffer=NULL;
  RAMbuffer=NULL;
  offset=NULL;
}

Array::Array (word lines, word size) {
  Alloc (lines,size);
}

void Array::Alloc (word lines, word size) {
  word i;

  XMSbuffer=new XMSblock ((dword)lines*size);
  RAMbuffer=new byte[size];
  offset=new dword[lines];
  Actual=0;
  Size=size;
  Lines=lines;
  for (i=0; i<lines; i++)
    offset[i]=(dword)i*size;
}

void Array::Kill (void) {
  if (XMSbuffer!=NULL) delete XMSbuffer;
  if (RAMbuffer!=NULL) delete RAMbuffer;
  if (offset!=NULL) delete offset;
}

Array::~Array () {
  Kill ();
}

LinearMemory::LinearMemory () {
  XMSbuffer=NULL;
  RAMbuffer=NULL;
}

LinearMemory::LinearMemory (dword size) {
  Alloc (size);
}

void LinearMemory::Alloc (dword size) {
  XMSbuffer=new XMSblock (((size+8191)>>13)<<13);
  RAMbuffer=new byte[8192];
  Actual=0;
  Size=size;
}

LinearMemory::~LinearMemory () {
  printf ("Killed\n");
  if (XMSbuffer!=NULL) delete XMSbuffer;
  if (RAMbuffer!=NULL) delete RAMbuffer;
}

void LinearMemory::Kill () {
  printf ("Killed\n");
  if (XMSbuffer!=NULL) delete XMSbuffer;
  if (RAMbuffer!=NULL) delete RAMbuffer;
}

pbyte LinearMemory::buffer (dword number) {
  if (number==Actual) {
    return (RAMbuffer);
  }
  else {
    XMSbuffer->RAMtoXMS (RAMbuffer,Actual<<13,8192);
    XMSbuffer->XMStoRAM (number<<13,RAMbuffer,8192);
    Actual=number;
    return (RAMbuffer);
  }
}
