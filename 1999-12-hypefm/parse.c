#include <stdio.h>
#include <malloc.h>

int main (int argc, char **argv) {
  FILE *f;
  int len,i,ping=0,j;
  unsigned char *buffer;
  int fm[0x40*256];
  int ev_reg[256],ev_val[256];
  unsigned char minibuf[2];

  f=fopen (argv[1],"rb");
  len=filelength (fileno (f));
  buffer=(unsigned char *) malloc (len);
  fread (buffer,1,len,f);
  fclose (f);

  for (i=0; i<256*0x40; i++)
    fm[i]=0;

  for (i=0; i<256; i++)
    ev_reg[i]=ev_val[i]=0;

  for (i=4; i<len; ) {
    if (buffer[i]==0xFF) {
      //printf ("HALT\n");
      i++; ping++;
      continue;
    }
    if (buffer[i]==0xFE) {
      ////printf ("HALT x %d\n",buffer[i+1]);
      i+=2; ping++;
      continue;
    }
    if (buffer[i]<16) {
      //printf ("PSG[%d]=%d\n",buffer[i],buffer[i+1]);
      i+=2;
      continue;
    }
    if (buffer[i]>=0xA0) {
      //printf ("FM[0x%02X]=%d\n",buffer[i]-0xA0,buffer[i+1]);
      fm[((buffer[i]-0xa0)*256)+buffer[i+1]]=1;
      i+=2;
      continue;
    }
    printf ("unknown %d\n",buffer[i]);
    i++;
  }

  //printf ("pings: %d\n",ping);

  ping=0;
  for (i=0; i<0x40*256; i++) {
    if (fm[i]) {
      ev_reg[ping]=i/256;
      ev_val[ping]=i%256;
      ping++;
    }
  }

  for (i=0; i<256; i++)
    printf ("\tDB\t%d\t\t; %d\n",ev_reg[i],i);

  for (i=0; i<256; i++)
    printf ("\tDB\t%d\t\t; %d\n",ev_val[i],i);

  //printf ("symbols: %d\n",ping);

  f=fopen (argv[2],"wb");

  for (i=4; i<len; ) {
    if (buffer[i]==0xFF) {
      //printf ("HALT\n");
      i++; ping++;
      minibuf[0]=0xFF;
      fwrite (minibuf,1,1,f);
      continue;
    }
    if (buffer[i]==0xFE) {
      //printf ("HALT x %d\n",buffer[i+1]);
      minibuf[0]=0xFE;
      minibuf[1]=buffer[i+1];
      i+=2; ping++;
      fwrite (minibuf,1,2,f);
      continue;
    }
    if (buffer[i]<16) {
      //printf ("PSG[%d]=%d\n",buffer[i],buffer[i+1]);
      minibuf[0]=200+buffer[i];
      minibuf[1]=buffer[i+1];
      i+=2;
      fwrite (minibuf,1,2,f);
      continue;
    }
    if (buffer[i]>=0xA0) {
      //printf ("FM[0x%02X]=%d\n",buffer[i]-0xA0,buffer[i+1]);
      j=0;
      while (ev_reg[j]!=buffer[i]-0xa0 || ev_val[j]!=buffer[i+1])
        j++;
      minibuf[0]=j;
      printf ("FM[0x%02X]=%d\n",buffer[i]-0xA0,buffer[i+1]);
      printf ("FM[0x%02X]=%d\n",ev_reg[j],ev_val[j]);
      fwrite (minibuf,1,1,f);
      i+=2;
      continue;
    }
    //printf ("unknown %d\n",buffer[i]);
    i++;
  }

  fclose (f);

  return 1;
}
