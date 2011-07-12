// ScanEdit 1.0
// by Ricardo Bittencourt 1996
// module FILESYS

#include <stdio.h>
#include <io.h>
#include <fcntl.h>
#include <sys\stat.h>
#include <mem.h>
#include "filesys.h"
#include "error.h"

#define BUFSIZE 20000

void File::Open (const char *name) {
  char *s;

  sprintf (s,"Cannot open file %s",name);
  do {
    file=open (name,O_BINARY|O_RDONLY);
  } while (file==-1 && ReportError (ERROR_RETRY,s)==ACTION_RETRY);
  buffer=new byte[BUFSIZE];
  avail=0;
}

void File::Read (void *ptr, int size) {
  byte *newptr;

  if (avail==0) {
    avail=read (file,buffer,BUFSIZE);
    pos=buffer;
  }
  if (avail<size) {
    memcpy (ptr,pos,avail);
    newptr=(byte *) ptr+avail;
    read (file,buffer,BUFSIZE);
    pos=buffer;
    memcpy (newptr,pos,size-avail);
    pos+=avail;
    avail-=(size-avail);
  }
  else {
    memcpy (ptr,pos,size);
    pos+=size;
    avail-=size;
  }
}

void File::ReadByte (void *ptr) {
  if (avail==0) {
    avail=read (file,buffer,BUFSIZE);
    pos=buffer;
  }
  *((byte *) ptr)=*pos++;
  avail--;
}

void File::Close (void) {
  close (file);
  delete buffer;
}

dword File::Length (void) {
  return (filelength (file));
}