#include <stdio.h>

int main (int argc, char **argv) {
  FILE *file;
  int i;

  file=fopen (argv[1],"w");
  for (i=2; i<argc; i++)
    fprintf (file,"%s ",argv[i]);
  fclose (file);
}
