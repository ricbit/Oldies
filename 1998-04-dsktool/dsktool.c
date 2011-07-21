#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <ctype.h>
#include <malloc.h>
#include <string.h>
#include <dir.h>
#include <io.h>
#include <dos.h>
#include <sys/stat.h>
#include "msxboot.h"

typedef unsigned char byte;
typedef unsigned short word;
typedef struct {
  char name[9];
  char ext[4];
  int size;
  int hour,min,sec;
  int day,month,year;
  int first;
  int pos;
  int attr;
} fileinfo;

byte *dskimage;
byte *fat;
byte *direc;
byte *cluster;
int sectorsperfat,numberoffats,reservedsectors;
int bytespersector,direlements,fatelements;
int availsectors;

char **__crt0_glob_function (char *_argument) {
  return NULL;  
}

void load_dsk (char *name, int error) {
  int file;

  dskimage=(byte *) calloc (1,720*1024);
  file=open (name,O_BINARY|O_RDONLY);
  if (file<0) {
    if (error) {
      printf ("Error in .DSK file\n");
      exit (2);
    }
    memset (dskimage,0,720*1024);
    memcpy (dskimage,msxboot,512);
  }
  else {
    read (file,dskimage,720*1024);
    close (file);
  }
  reservedsectors=*(word *)(dskimage+0x0E);
  numberoffats=*(dskimage+0x10);
  sectorsperfat=*(word *)(dskimage+0x16);
  bytespersector=*(word *)(dskimage+0x0B);
  direlements=*(word *)(dskimage+0x11);
  fat=dskimage+bytespersector*reservedsectors;
  direc=fat+bytespersector*(sectorsperfat*numberoffats);
  cluster=direc+direlements*32;
  availsectors=80*9*2-reservedsectors-sectorsperfat*numberoffats;
  availsectors-=direlements*32/bytespersector;
  fatelements=availsectors/2;
  if (file<0) {
    fat[0]=0xF9;
    fat[1]=0xFF;
    fat[2]=0xFF;
  }
}

int next_link (int link) {
  int pos;

  pos=(link>>1)*3;
  if (link&1)
    return (((int)(fat[pos+2]))<<4)+(fat[pos+1]>>4);
  else 
    return (((int)(fat[pos+1]&0xF))<<8)+fat[pos];
}

int remove_link (int link) {
  int pos;
  int current;

  pos=(link>>1)*3;
  if (link&1) {
    current=(((int)(fat[pos+2]))<<4)+(fat[pos+1]>>4);
    fat[pos+2]=0;
    fat[pos+1]&=0xF;
    return current;
  }
  else  {
    current=(((int)(fat[pos+1]&0xF))<<8)+fat[pos];
    fat[pos]=0;
    fat[pos+1]&=0xF0;
    return current;
  }
}

void store_fat (int link, int next) {
  int pos;

  pos=(link>>1)*3;
  if (link&1) {
    fat[pos+2]=next>>4;
    fat[pos+1]&=0xF;
    fat[pos+1]|=(next&0xF)<<4;
  }
  else  {
    fat[pos]=next&0xFF;
    fat[pos+1]&=0xF0;
    fat[pos+1]|=next>>8;
  }
}

fileinfo *getfileinfo (int pos) {
  fileinfo *file;  
  byte *dir;
  int i;

  dir=direc+pos*32;
  if (*dir<0x20 || *dir>=0x80) return NULL;

  file=(fileinfo *) malloc (sizeof (fileinfo));
  for (i=0; i<8; i++)
    file->name[i]=dir[i]==0x20?0:dir[i];
  file->name[8]=0;

  for (i=0; i<3; i++)
    file->ext[i]=dir[i+8]==0x20?0:dir[i+8];
  file->ext[3]=0;

  file->size=*(int *)(dir+0x1C);

  i=*(word *)(dir+0x16);
  file->sec=(i&0x1F)<<1;
  file->min=(i>>5)&0x3F;
  file->hour=i>>11;

  i=*(word *)(dir+0x18);
  file->day=i&0x1F;
  file->month=(i>>5)&0xF;
  file->year=1980+(i>>9);

  file->first=*(word *)(dir+0x1A);
  file->pos=pos;
  file->attr=*(dir+0xB);

  return file;
}

int bytes_free (void) {
  int i,avail=0;

  for (i=2; i<2+fatelements; i++)
    if (!next_link (i)) avail++;
  return avail*1024;
}

void list_dsk (void) {
  int i;
  fileinfo *file;
  char name[20],date[30],time[30],size[30];

  for (i=0; i<8; i++)
    name[i]=dskimage[3+i];
  name[8]=0;
  printf ("Name of volume: %s\n\n",name);
  for (i=0; i<direlements; i++) {
    file=getfileinfo (i);    
    if (file!=NULL) {
      if (file->ext[0]) 
        sprintf (name,"%s.%s",file->name,file->ext);
      else
        strcpy (name,file->name);
      sprintf (size,"%7d",file->size);
      if (file->attr&0x8) strcpy (size,"  <VOL>");
      if (file->attr&0x10) strcpy (size,"  <DIR>");
      sprintf (date,"%d/%02d/%d",file->day,file->month,file->year);
      sprintf (time,"%d:%02d:%02d",file->hour,file->min,file->sec);
      printf ("%-13s %s %10s %8s\n",name,size,date,time);
      free (file);
    }
  }
  printf ("\n%d bytes free\n",bytes_free ());
}

int match (fileinfo *file, char *name) {
  char *p=file->name;
  int status=0,i;

  for (i=0; i<8; i++) {
    if (!*name)
      break;
    if (*name=='*') {
      status=1;
      name++;
      break;
    }
    if (*name=='.')
      break;
    if (toupper (*name++)!=toupper (*p++))
      return 0;
  }
  if (!status && i<8 && *p!=0) 
    return 0;
  p=file->ext;
  if (!*name && !*p) return 1;
  if (*name++!='.') return 0;
  for (i=0; i<3; i++) {
    if (*name=='*')
      return 1;
    if (toupper (*name++)!=toupper (*p++))
      return 0;
  }
  return 1;
}

void parse_tree (char *name, void (*action)(fileinfo *)) {
  int i;
  fileinfo *file;

  for (i=0; i<direlements; i++) {
    if ((file=getfileinfo (i))!=NULL) {
      if (match (file,name)) 
        action (file);
      free (file);
    }
  }
}

void parse_dsk (int argc, char **argv, void (*action)(fileinfo *)) {
  int i;

  if (argc==3)
    parse_tree ("*.*",action);
  else
    for (i=3; i<argc; i++)
      parse_tree (argv[i],action);
}

void extract (fileinfo *file) {
  byte *buffer,*p;
  int fileid;
  char name[20];
  int current;

  printf ("extracting %s.%s\n",file->name,file->ext);
  buffer=(byte *) malloc ((file->size+1023)&(~1023));
  memset (buffer,0x1a,file->size);
  sprintf (name,"%s.%s",file->name,file->ext);
  fileid=open (name,O_BINARY|O_WRONLY|O_CREAT,S_IRUSR|S_IWUSR);
  current=file->first;
  p=buffer;
  do {
    memcpy (p,cluster+(current-2)*1024,1024);
    p+=1024;
    current=next_link (current);
  } while (current!=0xFFF);
  write (fileid,buffer,file->size);
  close (fileid);
  free (buffer);
}

void wipe (fileinfo *file) {
  int current;

  current=file->first;
  do {
    current=remove_link (current);
  } while (current!=0xFFF);
  direc[file->pos*32]=0xE5;
}

void delete (fileinfo *file) {
  printf ("deleting %s.%s\n",file->name,file->ext);
  wipe (file);
}

void flush_dsk (char *name) {
  int file;

  memcpy (fat+bytespersector*sectorsperfat,fat,bytespersector*sectorsperfat);
  file=open (name,O_BINARY|O_WRONLY|O_CREAT,S_IWUSR|S_IRUSR);
  write (file,dskimage,720*1024);
  close (file);
}

int get_free (void) {
  int i;

  for (i=2; i<2+fatelements; i++)
    if (!next_link (i)) return i;
  printf ("Internal error\n");
  exit (5);
}

int get_next_free (void) {
  int i,status=0;

  for (i=2; i<2+fatelements; i++)
    if (!next_link (i)) 
      if (status) 
        return i;
      else
        status=1;
  printf ("Internal error\n");
  exit (5);
}

void add_single_file (char *name, char *pathname) {
  int i,total;
  int found=0;
  fileinfo *file;
  int fileid;
  byte *buffer;
  int size;
  struct time ti;
  struct date da;
  int first;
  int current;
  int next;
  int pos;
  char *p;
  char fullname[250];

  strcpy (fullname,pathname);
  strcat (fullname,name);
  fileid=open (fullname,O_BINARY|O_RDONLY);
  
  for (i=0; i<direlements; i++) {
    if ((file=getfileinfo (i))!=NULL) {
      if (match (file,name)) {
        found=1;
        wipe (file);
      }
      free (file);
    }
  }

  if ((size=filelength(fileid))>bytes_free()) {
    printf ("disk full\n");
    exit (4);
  }

  if (found)    
    printf ("updating %s\n",name);
  else
    printf ("  adding %s\n",name);

  for (i=0; i<direlements; i++)
    if (direc[i*32]<0x20 || direc[i*32]>=0x80)
      break;
  if (i==direlements) {
    printf ("directory full\n");
    exit (6);
  }
  pos=i;

  buffer=(byte *) malloc ((size+1023)&(~1023));
  read (fileid,buffer,size);
  close (fileid);

  total=(size+1023)>>10;
  current=first=get_free ();
  
  for (i=0; i<total;) {
    memcpy (cluster+(current-2)*1024,buffer,1024);
    buffer+=1024;
    if (++i==total)
      next=0xFFF;
    else
      next=get_next_free ();
    store_fat (current,next);
    current=next;
  }

  memset (direc+pos*32,0,32);
  memset (direc+pos*32,0x20,11);
  i=0; 
  for (p=name;*p;p++) {
    if (*p=='.') {
      i=8;
      continue;
    }
    direc[pos*32+i++]=toupper (*p);
  }
  *(word *)(direc+pos*32+0x1A)=first;
  *(int *)(direc+pos*32+0x1C)=size;
  gettime (&ti);
  getdate (&da);
  *(word *)(direc+pos*32+0x16)=
    (ti.ti_sec>>1)+(ti.ti_min<<5)+(ti.ti_hour<<11);
  *(word *)(direc+pos*32+0x18)=
    (da.da_day)+(da.da_mon<<5)+((da.da_year-1980)<<9);

  free (buffer);
}

void add_files (char *name) {
  struct ffblk finfo;  
  int status;
  char *temp1,*temp2;
  char dir[200];
  
  status=findfirst (name,&finfo,FA_ARCH|FA_RDONLY);
  temp1=NULL;
  temp2=name;
  while ((temp2=strstr (temp2,"\\"))!=NULL) {
    temp1=temp2;
    temp2++;
  }
  if (temp1!=NULL) {
    memset (dir,0,200);
    memcpy (dir,name,temp1-name);
    strcat (dir,"\\");
  }
  else {
    *dir=0;
  }
  while (!status) {  
    add_single_file (finfo.ff_name,dir);
    status=findnext (&finfo);
  }
}

void add_to_dsk (int argc, char **argv) {
  int i;

  for (i=3; i<argc; i++)
    add_files (argv[i]);
}

int main (int argc, char **argv) {
  printf ("DSK Tool v1.1\n");
  printf ("Copyright (C) 1998 by Ricardo Bittencourt\n");
  printf ("This file is under GNU GPL, read COPYING for details\n\n");

  if (argc<3) {
    printf ("Usage: DSKTOOL command archive [files]\n\n");
    printf ("commands:\n");
    printf ("\t\tL\tlist contents of .DSK\n");
    printf ("\t\tE\textract files from .DSK\n");
    printf ("\t\tA\tadd files to .DSK\n");
    printf ("\t\tD\tdelete files from .DSK\n");
    printf ("\nexamples:\n");
    printf ("\t\tDSKTOOL L TALKING.DSK\n");
    printf ("\t\tDSKTOOL E TALKING.DSK FUZZ*.*\n");
    printf ("\t\tDSKTOOL A TALKING.DSK MSXDOS.SYS COMMAND.COM\n");
    printf ("\t\tDSKTOOL D TALKING.DSK *.BAS *.BIN\n");
    exit (1);
  }
  switch (toupper (argv[1][0])) {
    case 'L':
      load_dsk (argv[2],1);
      list_dsk ();
      break;
    case 'E':
      load_dsk (argv[2],1);
      parse_dsk (argc, argv, extract);
      break;
    case 'D':
      load_dsk (argv[2],1);
      parse_dsk (argc, argv, delete);
      flush_dsk (argv[2]);
      break;
    case 'A':
      load_dsk (argv[2],0);
      add_to_dsk (argc, argv);
      flush_dsk (argv[2]);
      break;
    default:
      printf ("Command not supported\n");
      exit (3);
  }
  return 0;
}
