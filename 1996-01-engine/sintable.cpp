#include <stdio.h>
#include <math.h>

#define pi2 3.1415926535*2.0

void main (void) {
  int i;

  printf ("sintable ");
  for (i=0; i<64; i++) {
    printf ("dd %ld\n",(long int) (65536.0*sin ((double)i*pi2/64.0)));
  }
  printf ("\ncostable ");
  for (i=0; i<64; i++) {
    printf ("dd %ld\n",(long int) (65536.0*cos ((double)i*pi2/64.0)));
  }
}