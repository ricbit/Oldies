#ifndef __OPSYS_H

#ifdef __DJGPP
#define SYS_MSDOS
#define INTEL
#endif

#ifdef linux
#define SYS_LINUX
#define INTEL
#endif

#endif
