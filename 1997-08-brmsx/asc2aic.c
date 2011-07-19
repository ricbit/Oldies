#include <stdio.h>

void main (int argc, char **argv) {
  unsigned char buf1[3840],buf2[3840];
  FILE *f;
  int i;

  f=fopen (argv[1],"rb");
  fread (buf1,1,3840,f);
  fclose (f);

  for (i=0; i<3840/2; i++) {
    buf2[i]=buf1[i*2];
    buf2[i+3840/2]=buf1[i*2+1];
  }

  f=fopen (argv[2],"wb");
  fwrite (buf2,1,3840,f);
  fclose (f);

}
