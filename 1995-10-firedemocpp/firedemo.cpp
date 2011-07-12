#include <\borlandc\doom\fgraph.h>
#include <conio.h>
#include <stdlib.h>

typedef unsigned char byte;

unsigned int i,j;

void main (void) {
  int b,k;
  InitGraph ();
  for (i=0; i<=255; i++) {
    Line (i,0,i,199,i);
  }
  for (i=0; i<64; i++) {
    SetRGB (i,i,0,0);
    SetRGB (64+i,63,i,0);
    SetRGB (64+64+i,63-i,63-i,i);
    SetRGB (64+64+64+i,i,i,63);
  }
  getch ();
  ClearScreen (0);
  do {
    for (i=0; i<320; i++) {
      PutPixel (i,199,0);
      PutPixel (i,198,0);
    }
    for (i=0; i<100; i++) {
      PutPixel (random (320),199,255);
      PutPixel (random (320),198,255);
    }
    for (j=198; j>0; j--) {
      for (i=1; i<319; i++) {
        k=random (5)-2;
        i+=k;
        b=((int)GetPixel(i-1,j)+(int)GetPixel(i+1,j)+8*(int)GetPixel(i,j)+(int)GetPixel(i,j-1)+(int)GetPixel(i,j+1))/12;
        i-=k;
        PutPixel (i,j-1,(b>0)?b:0);
      }
    }
  } while (!kbhit());
  CloseGraph ();
}