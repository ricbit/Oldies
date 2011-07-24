#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main (int argc, char **argv) {
  FILE *f;
  int i;
  unsigned char scr[0x80+0x1800*2],grp[16384];

  if (argc!=3) {
    printf ("%d usage: scr2grp image.scr image.grp\n",argc);
    exit (1);
  }

  f=fopen (argv[1],"rb");
  fread (scr,1,0x80+0x1800*2,f);
  fclose (f);

  memset (grp,0,16384);
  memcpy (grp,scr+0x80,0x1800);
  memcpy (grp+0x2000,scr+0x80+0x1800,0x1800);

  for (i=0; i<256*3; i++)
    grp[0x1800+i]=i&0xFF;

  f=fopen (argv[2],"wb");
  fputc (0xFE,f);
  fputc (0x00,f);
  fputc (0x00,f);
  fputc (0xFF,f);
  fputc (0x3F,f);
  fputc (0xFF,f);
  fputc (0x3F,f);
  fwrite (grp,1,16384,f);
  fclose (f);

  return 0;

}
