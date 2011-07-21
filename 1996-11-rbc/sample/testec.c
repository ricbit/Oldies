#include <stdlib.h>

#define SUM(a,b) ((a)+(b))

/* Teste do RBC */
/* Calculo dos numeros primos menores que 200 */

void digit (int a) {
  putchar (SUM (a,a<10?48:55));
}

void enter () {
  putchar (13);
  putchar (10);
}

char i;

void number (int a, int base) {
  i=1;
  while (base<a/i+1) i*=base;
  while (i) {  
    digit (a/i);
    a%=i; i/=base;
  } 
}

char temp;

int prime (int p) {
  temp=2;
  while (temp<p) 
    if (!(p%temp++)) 
      return 0;
  return 1;
}

char x;

void all () {
  for (x=2; x<200; x++)    
    if (prime (x)) {
      number (x,10);
      putchar (',');
    }
}

void main () {
  putchar ('R');
  putchar ('B');
  putchar ('C');
  enter ();
  all ();
}


