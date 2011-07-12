#include <conio.h>
#include <dos.h>

void main (void) {
  int sc;
  clrscr ();
  do {
    sc=inp (0x060);
    gotoxy (1,1);
    cprintf ("Scan code: %d ",sc);
    if (kbhit()) getch ();
  } while (sc!=1+128);
}