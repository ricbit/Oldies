#include <stdio.h>
#include <conio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>

void main (int argc, char **argv) {
  int file;
  int i,len;
  unsigned char *buffer;
  FILE *f;

  f=fopen (argv[2],"w");
  file=open (argv[1],O_BINARY|O_RDONLY);
  len=filelength (file);
  buffer=(unsigned char *) malloc (len);
  read (file,buffer,len);
  close (file);
  for (i=0; i<len; i++) {
    if (i%8==0) 
      fprintf (f,"\tdb\t");
    fprintf (f,"0%02Xh",buffer[i]);
    if (i%8==7)
      fprintf (f,"\n");
    else
      if (i!=len-1)
        fprintf (f,",");
  }
  fclose (f);
}
