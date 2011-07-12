// ScanEdit 1.0
// by Ricardo Bittencourt 1996
// header FILESYS

#ifndef __FILESYS_H
#define __FILESYS_H

#include "general.h"

class File {
private:
  int file,avail;
  byte *buffer,*pos;

public:
  void Open (const char *name);
  void Read (void *ptr, int size);
  void ReadByte (void *ptr);
  void Close (void);
  dword Length (void);
};

#endif