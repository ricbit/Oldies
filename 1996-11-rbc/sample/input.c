#include <stdio.h>

int a;

void main () {
  do {
    a=getchar ();
    putchar (a);
  } while (a!=27);
}
