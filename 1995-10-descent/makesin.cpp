#include <stdio.h>
#include <io.h>
#include <fcntl.h>
#include <math.h>

typedef long int fixed;

fixed *sintable;
fixed i;
int f;

void main (void) {
  sintable=new fixed[15000];
  f=open ("sintable.dat",O_BINARY|O_CREAT);
  if (sintable==NULL)
    printf ("Cannot allocate memory\n");
  for (i=0; i<65536; i++) {
    if (i%15000==0 && i!=0) write (f,sintable,15000*4);
    sintable[i%15000]=(fixed)(65536.0*sin((double)i/65536.0*2.0*3.1415926535));
    if (i%100==0) printf ("%ld - %ld\n",i,sintable[i%15000]);
  }
  write (f,sintable,5536*4);
  close (f);
}