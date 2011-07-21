#include <stdlib.h>

/* Teste do RBC */
/* Calculo dos numeros primos menores que 200 */

int temp;

int prime (int p) {
  temp=2;
  while (temp<p) 
    if (!(p%temp++)) 
      return 0;
  return 1;
}

int x;

void all () {
  x=1;
  while (++x<500) {
    if (prime (x)) {
      number (x,10);
      putchar (',');
    }
  }
}

void main () {
  putchar ('R');
  putchar ('B');
  putchar ('C');
  enter ();
  all ();
}


