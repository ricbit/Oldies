// BOSS 1.0
// by Ricardo Bittencourt 1996
// header SB

#ifndef __SB_H
#define __SB_H

#include <general.h>

void InitSoundBlaster (int BaseAddress);
void ResetSoundBlaster (void);
void SetRegister (byte number, byte value);

#endif
