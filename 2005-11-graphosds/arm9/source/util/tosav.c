#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main (int argc, char **argv) {
  FILE *f;
  int i,len;
  unsigned char grp[16384],raw[256*192*3];

  if (argc!=4) {
    printf ("usage: tosav image.sav image.grp image.jpg\n");
    exit (1);
  }

  f=fopen (argv[2],"rb");
  fread (grp,1,7,f);
  fread (grp,1,16384,f);
  fclose (f);

  f=fopen (argv[3],"rb");
  fseek (f,0,SEEK_END);
  len=ftell(f);
  fseek (f,0,SEEK_SET);
  fread (raw,1,len,f);
  fclose (f);

  if (4+16384+len>64*1024) {
    printf ("error: jpeg too big\n");
    exit (1);
  }

  f=fopen (argv[1],"wb");
  fputc ('G',f);
  fputc ('D',f);
  fputc ('S',f);
  fputc (1,f);
  fwrite (grp,1,16384,f);
  fwrite (raw,1,len,f);
  for (i=0; i<64*1024-4-16384-len; i++)
    fputc (0,f);
  fclose (f);

  return 0;

}
