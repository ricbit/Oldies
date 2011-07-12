#include <stdio.h>

void main (void) {
  int i;

  printf ("divtable dd 65536\n");

  for (i=1; i<320; i++) {
    printf ("dd %ld\n",(long int) (65536.0/(double)i));
  }
}