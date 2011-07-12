#include <stdio.h>
#include <math.h>
#include <malloc.h>
#include <io.h>
#include <fcntl.h>
#include <sys\stat.h>

typedef long int fixed;

void main (void) {
  int i;
  fixed *table;

  table=(fixed *) malloc (0x1000*4);
  for (i=0; i<0x1000; i++) {
    table[i]=(fixed) (65536.0*sin ((double)i*2.0*3.1415926535/(double)0x1000));
  }
  i=open ("sintable.dat",O_BINARY|O_WRONLY|O_CREAT,S_IREAD|S_IWRITE);
  write (i,table,0x1000*4);
  close (i);


}