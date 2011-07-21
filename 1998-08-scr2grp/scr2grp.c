/* 
    SCR2GRP v1.0 
    Copyright (C) 1998 by Ricardo Bittencourt

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

    Project started at 9/8/1998. Last modification was on 9/8/1998.
    Contact the author through the addresses: 
        
        ricardo@lsi.usp.br
        http://www.lsi.usp.br/~ricardo

*/

#include <stdio.h>
#include <malloc.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

int main (int argc, char **argv) {
  unsigned char *buf_in,*buf_out,header[7]={0xfe,0,0,0xff,0x3f,0,0};
  int color[16]={1,4,6,13,2,7,10,14,1,5,8,13,3,7,11,15};
  int file;  
  int i,j,k,l;
  int addr=0;

  printf ("SCR2GRP 1.0\n");
  printf ("Copyright (C) 1998 by Ricardo Bittencourt\n");
  printf ("This program is free software, read COPYING for details\n");

  if (argc<3) {
    printf ("\nUsage: SCR2GRP file.scr file.grp\n");
    exit (1);
  }
  
  printf ("\nConverting <%s> to <%s>...\n",argv[1],argv[2]);

  buf_in=(unsigned char *) malloc (6912);
  buf_out=(unsigned char *) calloc (16384,1);
  
  file=open (argv[1],O_BINARY|O_RDONLY);  
  read (file,buf_in,6912);
  close (file);

  /* pattern table */
  for (k=0; k<3; k++) 
    for (j=0; j<8; j++) 
      for (i=0; i<32; i++) 
        for (l=0; l<8; l++) 
          buf_out[addr++]=buf_in[i+j*32+l*256+k*8*256];

  /* color table */
  for (i=0; i<32*24; i++) 
    for (j=0; j<8; j++) 
      buf_out[0x2000+i*8+j]=
        (color[buf_in[6144+i]&7]<<4)+color[(buf_in[6144+i]>>3)&15];

  /* name table */
  for (i=0; i<256*3; i++)
    buf_out[0x1800+i]=i&0xff;

  /* sprite attr table */
  buf_out[0x1b00]=0xd0;

  file=open (argv[2],O_BINARY|O_WRONLY|O_CREAT,S_IRUSR|S_IWUSR);
  write (file,header,7);
  write (file,buf_out,16384);
  close (file);

  return 0;
}
