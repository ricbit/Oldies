#include <stdio.h>

#define MAX 500

char *table;
char *p;
int i;
int j;

void main () {
  table=(char *) malloc (MAX);
  p=table;
  for (i=0; i<256; i++)
    *p++=i;
  p=table;
  for (i=0; i<256; i++) {
    if (i>31)
      putchar (*p);
    if (i%16==0xf) {
      putchar (13);
      putchar (10);
    }  
    p++;
  }
}
