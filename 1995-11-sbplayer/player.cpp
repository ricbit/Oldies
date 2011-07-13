#include <conio.h>
#include <dos.h>
#include <stdio.h>
#include <io.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>

typedef unsigned char byte;

typedef struct {
  unsigned int number;
  byte reg;
  byte value;
} event;

void interrupt (*Old8Handler) (...);
char name[100],fmname[100];
event *evlist;
int fh,maxev,atev,atlev;
long int freq,counter,ticks,i,j,k;

void interrupt New8Handler (...) {
  byte reg,val;

  while (atlev!=maxev && evlist[atlev].number==atev) {
    reg=evlist[atlev].reg;
    val=evlist[atlev].value;

    asm {
      pushf
      cli
      mov dx,388h
      mov al,reg
      out dx,al
      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx
      inc dx
      mov al,val
      out dx,al
      popf
      dec dx

      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx

      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx

      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx

      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx

      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx

      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx

      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx
      in  al,dx
    }

    atlev++;
  }
  ticks+=counter;
  if (ticks>=0x10000) {
    ticks-=0x10000;
    asm pushf;
    Old8Handler ();
  }
  else {
    outportb (0x20,0x20);
  }
  if (atlev==maxev)
    atlev=atev=0;
  else
    atev++;
}

void main (void) {
  evlist=(event *) malloc (10000*sizeof (event));
  printf ("Music (*.fm): ");
  scanf ("%s",name);
  strcpy (fmname,name);
  strcat (fmname,".fm");
  printf ("Loading <%s>...\n",fmname);
  fh=open (fmname,O_BINARY|O_RDONLY);
  maxev=filelength (fh)/sizeof (event);
  if (read (fh,evlist,filelength (fh))==-1)
    printf ("Error in file\n");
  close (fh);
  printf ("Frequency (Hz): ");
  scanf ("%ld",&freq);
  counter=0x1234dd/freq;
  atev=atlev=0;
  Old8Handler=getvect (8);
  setvect (8,New8Handler);
  outportb (0x43,0x34);
  outportb (0x40,counter & 0xff);
  outportb (0x40,counter >> 8);
  i=2;
  do {
    k=0;
    for (j=2; j<i; j++) {
      if (i%j==0) k++;
    }
    if (!k) printf ("%d ",i);
    i++;
  } while (!kbhit ());
  setvect (8,Old8Handler);
  outportb (0x43,0x34);
  outportb (0x40,0);
  outportb (0x40,0);
}