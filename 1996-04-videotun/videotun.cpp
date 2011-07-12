#include <conio.h>
#include "\borlandc\doom\fgraph.h"

void main (void) {
  int x,y;

  InitGraph ();
  for (y=0; y<10; y++)
    for (x=0; x<64; x++) {
      SetRGB (x,x,x,x);
      PutPixel (x,y,(char)x);
      PutPixel (x,y+10,(char)(63-x));
      SetRGB (64+x,x,0,0);
      PutPixel (320-64+x,y,64+(char)(x));
      PutPixel (320-64+x,y+10,64+(char)(63-x));
      SetRGB (64+64+x,0,x,0);
      PutPixel (x,179+y,64+64+(char)x);
      PutPixel (x,179+y+10,64+64+(char)(63-x));
      SetRGB (64+64+64+x,0,0,x);
      PutPixel (320-64+x,179+y,64+64+64+(char)x);
      PutPixel (320-64+x,179+y+10,64+64+64+(char)(63-x));
    }
  for (x=100; x<200; x+=2)
    Line (x,0,x,199,63);
  for (y=0; y<64; y++)
    Line (0,30+y*2,319,30+y*2,(char)y);
  getch ();
  CloseGraph ();
}