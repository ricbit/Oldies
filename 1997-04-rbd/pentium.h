#ifndef __PENTIUM_H
#define __PENTIUM_H

#include "types.h"

typedef qword clock_t;

void install_pentium (void);
clock_t rdtsc (void);
void start_time (void);
void end_time (void);

#endif
