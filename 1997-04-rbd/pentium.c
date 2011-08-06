#include <stdio.h>
#include "pentium.h"

clock_t time;

clock_t rdtsc (void) {
  int low,high;
  asm (".byte 0xf,0x31" : "=a" (low), "=d" (high) : : "%eax","%edx");
  return ((clock_t)(low))+((clock_t)(high)<<32);
}

void install_pentium (void) {
  int cpuid,features;
  char name[13];

  asm (
    "pushf \n\t"
    "popl %%eax \n\t"
    "movl %%eax,%%ebx \n\t"
    "xorl $0x200000,%%eax \n\t"
    "pushl %%eax \n\t"
    "popf \n\t"
    "pushf \n\t"
    "popl %%eax \n\t"
    "xorl %%ebx,%%eax \n\t"
    : "=a" (cpuid)
    : 
    : "%ebx" 
  );
  if (cpuid) {
    asm (
      "xorl %%eax,%%eax \n\t"
      ".byte 0xf,0xa2 \n\t"
      : "=b" (*(int *)(&name[0])),
	"=d" (*(int *)(&name[4])),
	"=c" (*(int *)(&name[8]))
      :
      : "%eax"
    );
    asm (
      "movl $1,%%eax \n\t"
      ".byte 0xf,0xa2 \n\t"
      : "=a" (cpuid), "=d" (features)
    );
    name[12]=0;
    printf ("CPU type: ");
    switch ((cpuid&0xf00)>>8) {
      case 3:
	printf ("386\n");
	break;
      case 4:
	printf ("486\n");
	break;
      case 5:
	printf ("Pentium\n");
	break;
      case 6:
	printf ("Pentium Pro\n");
	break;
      default:
	printf ("Unknown\n");
	break;
    }
    printf ("Vendor Name: %s\n",name);
  } 
  else
    printf ("CPU unknown\n");
}                      

void start_time (void) {
  time=rdtsc ();
}

void end_time (void) {
  printf ("total time: %d\n",(int) (rdtsc ()-time));
}
