#include <stdio.h>
#include <malloc.h>
#include <pc.h>
#include <io.h>

/*

SYNC PROTOCOL:

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
  int i,len;
  unsigned char *buffer;

  f=fopen (argv[1],"rb");
  len=filelength (fileno (f));
  buffer=(unsigned char *) malloc (len);
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

  asm ("cli\n");
  for (i=27; i<len-27; i++) {
    if (i%65535==255) {
      printf ("%8d bytes sent%c",i,13);
      fflush (stdout);  
    }
    send_byte (buffer[i]);
  }
  asm ("sti\n");

  printf ("\nFinished.\n");

  return 1;

}
