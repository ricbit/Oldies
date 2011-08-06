#include <stdio.h>
#include <malloc.h>
#include <io.h>

void fix (char *name, char *buffer, int size) {
  FILE *f;

  f=fopen (name,"wb");
  fwrite (buffer,1,size,f);
  fclose (f);
}

int main (int argc, char **argv) {
  FILE *f;
  int size,i=0,original;
  char *buffer;

  printf ("SMSFIX v1.0\n");
  printf ("Copyright (C) 1999 by Ricardo Bittencourt\n\n");

  if (argc<2) {
    printf ("Usage: SMSFIX game.sms\n");
    return 1;
  }

  f=fopen (argv[1],"rb");
  size=filelength (fileno (f));
  buffer=(char *) malloc (size);

  if (size&512)
    fread (buffer,512,1,f);

  original=size&=0xFFFFC000;
  fread (buffer,1,size,f);
  fclose (f);

  do {
    for (i=0; i<size/2; i++)
      if (buffer[i]!=buffer[i+size/2]) {
        printf ("[%s]\t Original: %3dkb ",argv[1],original/1024);
        printf ("Real: %3dkb %c\n",size/1024,original!=size?'*':' ');
        if (original!=size)
          fix (argv[1],buffer,size);
        return 1;
      }
    size/=2;
  } while (1);
}


