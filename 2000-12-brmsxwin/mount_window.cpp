//---------------------------------------------------------------------------

#include <vcl.h>
#include <stdio.h>
#include <dir.h>
#include <dos.h>
#include <io.h>
#include <fcntl.h>
#pragma hdrstop

#include "msxboot.h"
#include "mount_window.h"

extern unsigned char *diskA;

//---------------------------------------------------------------------------
#pragma package(smart_init)
#pragma link "cdiroutl"
#pragma resource "*.dfm"
TMount *Mount;
//---------------------------------------------------------------------------
__fastcall TMount::TMount(TComponent* Owner)
        : TForm(Owner)
{
}
//---------------------------------------------------------------------------


void __fastcall TMount::Button2Click(TObject *Sender)
{
  Close();
}
//---------------------------------------------------------------------------

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

byte *dskimage=NULL;
byte *fat;
byte *direc;
byte *cluster;
int sectorsperfat,numberoffats,reservedsectors;
int bytespersector,direlements,fatelements;
int availsectors;

void load_dsk (void) {
  dskimage=(byte *) calloc (1,720*1024);
  memset (dskimage,0,720*1024);
  memcpy (dskimage,msxboot,512);
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
  fat[0]=0xF9;
  fat[1]=0xFF;
  fat[2]=0xFF;
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

int next_link (int link) {
  int pos;

  pos=(link>>1)*3;
  if (link&1)
    return (((int)(fat[pos+2]))<<4)+(fat[pos+1]>>4);
  else
    return (((int)(fat[pos+1]&0xF))<<8)+fat[pos];
}


int bytes_free (void) {
  int i,avail=0;

  for (i=2; i<2+fatelements; i++)
    if (!next_link (i)) avail++;
  return avail*1024;
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

void wipe (fileinfo *file) {
  int current;

  current=file->first;
  do {
    current=remove_link (current);
  } while (current!=0xFFF);
  direc[file->pos*32]=0xE5;
}

int get_free (void) {
  int i;

  for (i=2; i<2+fatelements; i++)
    if (!next_link (i)) return i;
  //printf ("Internal error\n");
  //exit (5);
  return 0;
}

int get_next_free (void) {
  int i,status=0;

  for (i=2; i<2+fatelements; i++)
    if (!next_link (i)) 
      if (status) 
        return i;
      else
        status=1;
  //printf ("Internal error\n");
  //exit (5);
  return 0;
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

int add_single_file (char *name, char *pathname) {
  int i,total;
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
        wipe (file);
      }
      free (file);
    }
  }

  if ((size=filelength(fileid))>bytes_free())
    return 1;

  for (i=0; i<direlements; i++)
    if (direc[i*32]<0x20 || direc[i*32]>=0x80)
      break;
  if (i==direlements)
    return 2;

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
  return 0;
}



int add_files (char *name) {
  struct ffblk finfo;
  int status;
  char *temp1,*temp2;
  char dir[200];
  int val;

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
    val=add_single_file (finfo.ff_name,dir);
    if (val)
      return val;
    status=findnext (&finfo);
  }
  return 0;
}


void __fastcall TMount::Button1Click(TObject *Sender)
{
   int val;

   load_dsk();
   val=add_files ((dirlist->Directory+"\\*.*").c_str());
   switch (val) {
     case 0:
       if (diskA!=NULL)
         free (diskA);
       diskA=dskimage;
       dskimage=NULL;
       Close();
       break;
     case 1:
     	Application->MessageBox( "Directory is too big.",
        "BrMSX Warning", MB_ICONEXCLAMATION | MB_OK );
       break;
     case 2:
     	Application->MessageBox( "Directory has too many files.",
        "BrMSX Warning", MB_ICONEXCLAMATION | MB_OK );
       break;
   }
}
//---------------------------------------------------------------------------

