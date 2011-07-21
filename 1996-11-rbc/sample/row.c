#include <stdlib.h>

#define SUM(a,b) ((a)+(b))

void digit (int a) {
  if (a<10)
    putchar (SUM (a,48));
  if (9<a)
    putchar (SUM (a,55));
}

void enter () {
  putchar (13);
  putchar (10);
}

int i;

void number (int a, int base) {
  i=1;
  while (base<a/i+1) i*=base;
  while (i) {  
    digit (a/i);
    a%=i; i/=base;
  } 
}

int x;

void main () {
  for (x=0; x<1000; x++) {
    number (x,10);
    putchar (' ');
  }
}
