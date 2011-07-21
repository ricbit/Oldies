#include <stdio.h>

#define MAX 1000

void digit (int a) {
  putchar (a+(a<10?48:55));
}

int n;

void number (int a, int base) {
  n=1;
  while (base<a/n+1) n*=base;
  while (n) {  
    digit (a/n);
    a%=n; n/=base;
  } 
}

void puts (char *string) {
  while (*string)
    putchar (*string++);
  putchar (13);
  putchar (10);
}

int i;
int j;
char *table;
char *p;
char *title="Crivo de Eratostenes";

void main () {
  puts (title);
  table=(char *) malloc (MAX);
  p=table;
  for (i=0; i<MAX; i++)
    *p++=1;
  for (i=2; i<MAX; i++) {
    if (table[i]) {
      number (i,10);
      putchar (',');
      for (j=i<<1; j<MAX; j+=i) 
        table[j]=0;
    }
  }
}
