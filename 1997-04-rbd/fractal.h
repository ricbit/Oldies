#ifndef __FRACTAL
#define __FRACTAL

#include "types.h"

typedef struct {
  int size;  
  byte *height;
} landscape;

landscape *generate_landscape (short *buffer);
void draw_landscape (landscape *land, short *buffer, int x, int y);

#endif
