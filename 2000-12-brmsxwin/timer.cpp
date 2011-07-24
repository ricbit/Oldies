#include "timer.h"

unsigned int rdtsc (void) {
  asm rdtsc;
  return _EAX;
}
