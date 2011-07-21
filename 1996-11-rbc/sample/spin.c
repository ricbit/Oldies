#include <stdio.h>

char *title="Ricardo Bittencourt";
char *temp;

int i=0;

int setup (char *s) {
  temp=title;
  while (*temp) {
    i++;
    temp++;
  }
  temp=(char *) malloc (++i);
}

void spin (char *s) {
    
}

void main (void) {
  while (1) {
    puts (title);
    spin (title);
  }
}
