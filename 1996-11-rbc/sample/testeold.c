#include <stdlib.h>

#define SUM(a,b) ((a)+(b))

/* Teste do RBC */
/* Calculo dos numeros primos menores que 200 */

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
  while (++x<1000) {
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


