#include <stdio.h>
#include <io.h>
#include <sys\stat.h>
#include <fcntl.h>
#include <unistd.h>

void main (int argc, char **argv) {
  int i,file,j;
  unsigned char b;

  file=open (argv[1],O_BINARY|O_RDONLY);
  printf ("unsigned char %s[] = {\n\t",argv[2]);
  for (i=0; i<filelength (file); i++) {
    read (file,&b,1);
    printf ("%d, ",b);
    if (i%10==9) printf ("\n\t");
  }
  printf ("\n\t");
  for (i=0; i<16; i++)
    for (j=0; j<10; j++) {
      printf ("0, ");
      if (j==9) printf ("\n\t");
    }
  printf ("0 };\n");
  close (file);
}
