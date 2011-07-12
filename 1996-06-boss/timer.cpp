// BOSS 1.0
// by Ricardo Bittencourt 1996
// module TIMER

#include <dos.h>
#include <stdlib.h>

#include <error.h>
#include <timer.h>
#include <general.h>

#define MAXFUNCTIONS 10

typedef struct {
  int freq,time;
  int counter;
  int free;
  void (*function)(...);
} FunctionDescriptor;

FunctionDescriptor func[MAXFUNCTIONS];  // functions
volatile dword ticks;                   // ticks of timer
dword counter;                          // on this value must call BIOS
int totalfuncs;                         // functions installed
int TimerInstalled;                     // timer installed
int Enabled;                            // enable functions
int BaseFreq;                           // Base frequency

void interrupt (*OldTimerHandler) (...);

void interrupt NewTimerHandler (...) {
  int i;

  if (Enabled)
    if (totalfuncs>0) {
      for (i=0; i<MAXFUNCTIONS; i++) {
        if (!func[i].free) {
          func[i].counter++;
          if (func[i].counter>=func[i].time) {
            func[i].counter-=func[i].time;
            (func[i].function)();
          }
        }
      }
    }
  ticks+=counter;
  if (ticks>=0x10000) {
    ticks-=0x10000;
    OldTimerHandler ();
  }
  else outportb (0x20,0x20);
}

void InstallTimer (int basefreq) {
  int i;

  for (i=0; i<MAXFUNCTIONS; i++)
    func[i].free=1;
  ticks=0;
  counter=0x1234dd/basefreq;
  BaseFreq=basefreq;
  totalfuncs=0;
  TimerInstalled=1;
  atexit (RemoveTimer);
  Enabled=1;
  OldTimerHandler=getvect (0x08);
  setvect (0x08,NewTimerHandler);
  outportb (0x43,0x34);
  outportb (0x40,counter & 0xff);
  outportb (0x40,(counter >> 8));
}

void RemoveTimer (void) {
  if (TimerInstalled) {
    outportb (0x43,0x34);
    outportb (0x40,0);
    outportb (0x40,0);
    setvect (0x08,OldTimerHandler);
  }
}

int RegisterFunction (int freq,void (*f)(...)) {
  int i;

  Enabled=0;
  if (totalfuncs<MAXFUNCTIONS) {
    for (i=0; i<MAXFUNCTIONS; i++)
      if (func[i].free) break;
    func[i].function=f;
    func[i].freq=freq;
    func[i].time=BaseFreq/freq;
    func[i].counter=0;
    func[i].free=0;
    totalfuncs++;
  }
  else ReportError (ERROR_FATAL,"Not enough timer handlers");
  Enabled=1;
  return (i);
}

void RemoveFunction (int f) {
  Enabled=0;
  if (func[f].free)
    ReportError
      (ERROR_RETRY,"Attempt to remove timer function not installed");
  func[f].free=1;
  totalfuncs--;
  Enabled=1;
}

void EnableInterrupts (void) {
  Enabled=1;
}

void DisableInterrupts (void) {
  Enabled=0;
}
