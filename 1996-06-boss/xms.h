// BOSS 1.0
// by Ricardo Bittencourt 1996
// header XMS

#ifndef __XMS_H
#define __XMS_H

#include "general.h"

void InstallXMS (void);
void XMSShowVersion (void);
word XMSAvailable (void);
word XMSLargest (void);

class XMSblock {
private:
  word handle;

public:
  XMSblock (dword size);
  ~XMSblock ();
  void RAMtoXMS (void *ram, dword offset, dword len);
  void XMStoRAM (dword offset, void *ram, dword len);
};

#endif
