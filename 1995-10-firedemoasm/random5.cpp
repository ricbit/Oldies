#include <stdio.h>
#include <stdlib.h>

void main (void) {
  int i,j;
  FILE *f;

  f=fopen ("rand320.inc","w");
  for (i=0; i<1024; i++) {
    fprintf (f,"  dd ");
    for (j=0; j<7; j++)
      fprintf (f,"%d,",random(640));
    fprintf (f,"%d\n",random(640));
  }
  fclose (f);
}