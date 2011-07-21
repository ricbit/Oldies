#include <stdio.h>

char a;
char b;

void main () {
  a=0;
  for (b=0; b<5;) {    
    a++;
    a%=8;
    putchar (a+'0');
    if (!a)  {
      putchar (13);
      putchar (10);
      b++;
    }
  }
}
