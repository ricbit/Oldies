#include <stdlib.h>

int i;

void newputchar (int x) {
  putchar (x);
}

void main () {
  i=9; 
  while (i) {
    newputchar (i+'0');
    i--;
  }
}
