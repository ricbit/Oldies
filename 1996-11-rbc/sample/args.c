#include <stdio.h>

char *n=0x81;
char i;
char *message="Arguments v1.0";

void main () {
  while (*message)
    putchar (*message++);
  for (i=*(char *)0x80; i>0; i--) {
    putchar (*n++);
  }
}
