#include <stdio.h>
#include <malloc.h>
#include <time.h>
#include <pc.h>
#include <io.h>

/*

PROTOCOL:

        MSX             PC
        send 000        wait
        wait            send 000
        send 111        wait
        wait            send 111

*/

void send_bibble (int b) {
  outportb (0x378,b&0x7);
}

int recv_bibble (void) {
  return (inportb (0x379)>>4)&0x7;
}

void send_byte (int b) {

  while (recv_bibble ()!=0);
  send_bibble ((b>>0)&0x3);

  while (recv_bibble ()!=7);
  send_bibble (((b>>2)&0x3)+4);

  while (recv_bibble ()!=0);
  send_bibble ((b>>4)&0x3);

  while (recv_bibble ()!=7);
  send_bibble (((b>>6)&0x3)+4);

}

int main (int argc, char **argv) {
  FILE *f;
  int i,len,s;
  unsigned char *buffer;

  buffer=(unsigned char *) malloc (32768);

  f=fopen (argv[1],"rb");
  len=filelength (fileno (f));
  if (len!=16384 && len!=32768) {
    printf ("ROM type not supported. Only 16kb or 32kb ROMs.\n");
    exit (1);
  }
  fread (buffer,1,len,f);
  fclose (f);

  printf ("Waiting for MSX ...\n");
  fflush (stdout);

  while (recv_bibble ()!=000);
  send_bibble (000);
  while (recv_bibble ()!=7);
  send_bibble (7);

  printf ("Sending...\n");
  fflush (stdout);

  send_byte ((len>>8)+0x40);

/*  asm ("cli\n\t"); */
  s=clock ();
  for (i=0; i<len; i++) {
    if (i%256==255) {
      printf ("%6d bytes sent%c",i,13);
      fflush (stdout);  
    }
    send_byte (buffer[i]);
  }
  send_byte (0xFF);
/* asm ("sti\n\t");*/
  s=clock()-s;
  printf ("\n\nrate = %f kbytes/s\n",(double)len*
          (double)CLOCKS_PER_SEC/(double)s/1024.0);

  return 1;

}
