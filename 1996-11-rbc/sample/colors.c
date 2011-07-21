#include <stdio.h>

int i;

void main (void) {
  screen (8);
  for (i=0; i<=256*192; i++) {
    vpoke (i,(char)i);
  }
  getchar ();
  screen (0);
}
