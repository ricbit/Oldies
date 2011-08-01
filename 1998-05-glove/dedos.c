#include <stdio.h>
#include <stdlib.h>
#include "glove.h"

void main (int argc, char **argv) {
  glove_data data;
  int flag=0;

  set_com_base (atoi (argv[1])-1);
  glove_init ();
  clrscr ();
  do {
    get_glove_data (&data);
    if (data.f2>20 && data.f4>20 && data.f5>20 && data.f3<20) {
      gotoxy (1,1);
      printf ("vai voce tambem.\n");
    }
    else {
      gotoxy (1,1);
      printf ("                \n");
    }
  } while (!kbhit ());
}
