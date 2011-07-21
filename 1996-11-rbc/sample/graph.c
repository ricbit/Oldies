#include <stdio.h>

int i;

void main () {
  screen (2);
  getchar ();
  for (i=0; i<6144;) {
    vpoke (i,0xaa);
    vpoke (i+++0x2000,0xf1);
  }
  getchar ();
  fill_vram (0,6144,0x0f);
  fill_vram (0x2000,6144,0x1f);
  getchar ();
  screen (0);
}
