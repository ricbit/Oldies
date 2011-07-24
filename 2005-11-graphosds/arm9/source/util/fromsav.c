#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main (int argc, char **argv) {
  FILE *f;
  unsigned char sram[65536];

  if (argc!=3) {
    printf ("usage: fromsav image.sav image.grp\n");
    exit (1);
  }

  f=fopen (argv[1],"rb");
  fread (sram,1,65536,f);
  fclose (f);

  if (sram[0]!='G' || sram[1]!='D' || sram[2]!='S') {
    printf ("error: invalid sram file\n");
    exit (1);
  }

  f=fopen (argv[2],"wb");
  fputc (0xFE,f);
  fputc (0x00,f);
  fputc (0x00,f);
  fputc (0xFF,f);
  fputc (0x3F,f);
  fputc (0xFF,f);
  fputc (0x3F,f);
  fwrite (sram+4,1,16384,f);
  fclose (f);

  return 0;

}
