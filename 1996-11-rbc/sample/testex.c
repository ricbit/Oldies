#include <stdlib.h>

int i;

void main () {
  for (i=0; i<10; i++)
    putchar (i+'0');
  i=0;
  do {
    putchar ('9' - i++);
  } while (i<10);
  for (i=0; i<=9; i++)
    putchar (i+'0');
  for (i=9; i>0; i=i-1)
    putchar (i+'0');
  for (i=0; i!=10; i++)
    putchar (i+'0');
  for (i=9; i>0; i--)
    putchar (i+'0');
  for (i=9; i>0; --i)
    putchar (i+'0');
}
