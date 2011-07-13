#include <stdio.h>
#include <io.h>
#include <stdlib.h>
#include <malloc.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys\stat.h>

typedef unsigned char byte;
typedef struct {
  int magic;
  int layer;
  int protection_bit;
  int bitrate;
  int sample_rate;
  int padding_bit;
  int stereo_mode;
  int mode_extension;
  int copyright;
  int original;
  int frame_size;
} mpeg_header;

int mpeg_bitrate[16]= {
  0,32000,48000,56000,64000,80000,96000,112000,128000,
  160000,192000,224000,256000,320000,384000,0
};

int mpeg_sample_rate[4]= {
  44100,48000,32000,0
};

char *mpeg_stereo_mode[4]= {
  "Stereo",
  "Joint Stereo",
  "Dual Channel",
  "Single Channel"
};

int len;
byte *buffer,*p;

int avail=0;
byte current;

int getbits (int number) {
  int temp=0;

  do {
    if (!avail) {
      current=*p++;
      avail=8;
    }
    temp=(temp<<1)|(current>=128);
    current<<=1;
    avail--;
  } while (--number);
  return temp;
}

void read_header (mpeg_header *header) {
  header->magic=getbits (13);
  header->layer=4-getbits (2);
  header->protection_bit=getbits (1);
  header->bitrate=mpeg_bitrate[getbits (4)];
  header->sample_rate=mpeg_sample_rate[getbits (2)];
  header->padding_bit=getbits(1);
  getbits (1);
  header->stereo_mode=getbits(2);
  header->mode_extension=getbits(2);
  header->copyright=getbits(1);
  header->original=getbits(1);
  getbits (2);
  header->frame_size=144*header->bitrate/header->sample_rate;
  if (header->sample_rate==44100 && header->padding_bit)
    header->frame_size++;
  header->frame_size-=4;
  header->frame_size<<=2;
}

void read_frame (mpeg_header *header);

int main (int argc, char **argv) {
  int file;
  mpeg_header header;

  printf ("RBMP2\n\n");

  file=open (argv[1],O_BINARY|O_RDONLY);
  len=filelength (file);
  buffer=p=(byte *) malloc (len);
  read (file,buffer,len);
  close (file);

  read_header (&header);

  if (header.magic!=0x1FFF) {
    printf ("Not a valid MP2 file\n");
    exit (1);
  }

  printf ("MPEG Audio Layer %d\n",header.layer);
  printf ("Bitrate: %d\n",header.bitrate);
  printf ("Sample rate: %d\n",header.sample_rate);
  printf ("Stereo mode: %s\n",mpeg_stereo_mode[header.stereo_mode]);
  printf ("Padding bit: %d\n",header.padding_bit);
  printf ("Protection bit: %d\n",header.protection_bit);
  printf ("Frame size: %d\n",header.frame_size);

  read_frame (&header);

  return 0;
}
