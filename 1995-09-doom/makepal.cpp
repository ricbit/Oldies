#include <conio.h>
#include "fgraph.h"

void main (void) {
  int r,g,b,x,y;
  InitGraph ();
  SetRGBUniform ();
  for (b=0; b<8; b++)
    for (g=0; g<8; g++)
      for (r=0; r<8; r++)
        for (x=0; x<4; x++)
          for (y=0; y<4; y++)
            PutPixel (r*4+g*8*4+x,b*4+y,fromRGB(r,g,b));
  for (b=0; b<8; b++)
    for (g=0; g<8; g++)
      for (r=0; r<8; r++)
        for (x=0; x<4; x++)
          for (y=0; y<4; y++)
            PutPixel (b*4+r*8*4+x,g*4+y+8*4,fromRGB(r,g,b));
  for (b=0; b<8; b++)
    for (g=0; g<8; g++)
      for (r=0; r<8; r++)
        for (x=0; x<4; x++)
          for (y=0; y<4; y++)
            PutPixel (g*4+b*8*4+x,r*4+y+8*4*2,fromRGB(r,g,b));
  getch ();
  CloseGraph ();
}