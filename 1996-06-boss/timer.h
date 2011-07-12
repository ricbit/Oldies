// BOSS 1.0
// by Ricardo Bittencourt 1996
// header TIMER

#ifndef __TIMER_H
#define __TIMER_H

void InstallTimer (int basefreq);
void RemoveTimer (void);
int  RegisterFunction (int freq,void (*f)(...));
void RemoveFunction (int f);
void DisableInterrupts (void);
void EnableInterrupts (void);

#endif

