#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <io.h>

typedef unsigned char byte;

#define SINGLE 0
#define DOUBLE 1
#define MULTI 2
#define RAW 3

#define MAXBLOCKS 2000

typedef struct block {
  int type;
  int size;
  byte value;
  byte *buffer;
  struct block *next;
} block;
  
FILE *fin,*fout;

void free_block (block *p) {
  if (p->type==RAW) 
    free (p->buffer);
  free (p);
}

void free_frame (block *base) {
  block *p,*q;

  for (p=base; p!=NULL; ) {
    q=p;      
    p=q->next;
    free_block (q);
  }
}  

block *compress (byte *buffer, int size) {  
  int bi,i,j;
  block *base=NULL,*p=NULL,*q=NULL;

  /* reading */
  for (i=0; i<size; i++) {
    if (p==NULL) {
      base=(block *) malloc (sizeof (block));
      p=base;
    }
    else {
      p->next=(block *) malloc (sizeof (block));
      p=p->next;
    }
    p->type=SINGLE;
    p->value=buffer[i];
    p->next=NULL;
  }

  /* preparing */
  for (p=base; p!=NULL; p=p->next) {
    if (p->value==p->next->value) {
      p->size=2;
      p->type=MULTI;
      free_block (p->next);
      p->next=p->next->next;
    }
    else {
      p->buffer=(byte *) malloc (2);
      p->buffer[0]=p->value;
      p->buffer[1]=p->next->value;
      p->size=2;
      p->type=RAW;
      free_block (p->next);
      p->next=p->next->next;
    } 
  }

  /* compressing */
  p=base;
  while (p!=NULL && p->next!=NULL) {
    if (p->size>=254) {
      p=p->next;
      continue;
    }
    if (p->type==MULTI && p->next->type==MULTI && p->value==p->next->value) {
      p->size+=p->next->size;
      free_block (p->next);
      p->next=p->next->next;
      continue;
    }
    if (p->type==RAW && p->next->type==RAW) {
      j=p->size+p->next->size;
      if (j>=254) {
        p=p->next;
        continue;
      }
      buffer=(byte *) malloc (j);
      for (i=0; i<p->size; i++)
        buffer[i]=p->buffer[i];
      for (i=0; i<p->next->size; i++)
        buffer[i+p->size]=p->next->buffer[i];
      p->size=j;
      p->buffer=buffer;
      free_block (p->next);
      p->next=p->next->next;
      continue;
    }
    p=p->next;
  }

  /* optimizing */
  p=base;
  while (p!=NULL && p->next!=NULL) {
    if (p->size>=254) {
      p=p->next;
      continue;
    }
    if (p->type==RAW && p->next->type==MULTI && p->next->size==2) {
      j=p->size+p->next->size;
      if (j>=254) {
        p=p->next;
        continue;
      }
      buffer=(byte *) malloc (j);
      for (i=0; i<p->size; i++)
        buffer[i]=p->buffer[i];
      for (i=0; i<p->next->size; i++)
        buffer[i+p->size]=p->next->value;
      p->size=j;
      p->buffer=buffer;
      free_block (p->next);
      p->next=p->next->next;
      continue;
    }
    if (p->type==RAW && p->next->type==RAW) {
      j=p->size+p->next->size;
      if (j>=254) {
        p=p->next;
        continue;
      }
      buffer=(byte *) malloc (j);
      for (i=0; i<p->size; i++)
        buffer[i]=p->buffer[i];
      for (i=0; i<p->next->size; i++)
        buffer[i+p->size]=p->next->buffer[i];
      p->size=j;
      p->buffer=buffer;
      free_block (p->next);
      p->next=p->next->next;
      continue;
    }
    p=p->next;
  }

  /* checking */
  j=0;
  for (p=base; p!=NULL; p=p->next) 
    j++;

  /* minimizing */
  while (j>MAXBLOCKS) {

    i=300;
    for (p=base; p->next!=NULL; p=p->next)
      if (p->type==RAW && p->next->type==MULTI && 
          p->next->size<i && (p->size+p->next->size<=254)) 
      {
        i=p->next->size;
        q=p;
      }

    buffer=(byte *) malloc (q->size+q->next->size);
    for (i=0; i<q->size; i++)
      buffer[i]=q->buffer[i];
    for (i=0; i<q->next->size; i++)
      buffer[i+q->size]=q->next->value;
    q->size=q->size+q->next->size;
    q->buffer=buffer;
    free_block (q->next);
    q->next=q->next->next;

    p=base;
    while (p!=NULL && p->next!=NULL) {
      if (p->size>=254) {
        p=p->next;
        continue;
      }
      if (p->type==RAW && p->next->type==RAW) {
        j=p->size+p->next->size;
        if (j>=254) {
          p=p->next;
          continue;
        }
        buffer=(byte *) malloc (j);
        for (i=0; i<p->size; i++)
          buffer[i]=p->buffer[i];
        for (i=0; i<p->next->size; i++)
          buffer[i+p->size]=p->next->buffer[i];
        p->size=j;
        p->buffer=buffer;
        free_block (p->next);
        p->next=p->next->next;
        continue;
      }
      p=p->next;
    }

    j=0;
    for (p=base; p!=NULL; p=p->next)
      j++;
  }

  /* rechecking */
  i=0; j=0; bi=0;
  for (p=base; p!=NULL; p=p->next) {
    i+=p->size;
    j++;
    if (p->type==2)
      bi+=2;
    else
      bi+=p->size+1;
  }
  
  fflush (stdout);
  
  return base;
}
    
void flush_pool (block *base) {
  block *p;    
  int i=0;
  byte *buffer;

  buffer=(byte *) malloc (40000);
  i=0;

  for (p=base; p!=NULL; p=p->next) {
    if (p->type==MULTI) {
      buffer[i++]=(p->size/2)+0x80;
      buffer[i++]=p->value;
    }
    else {
      buffer[i++]=(p->size/2);
      memcpy (buffer+i,p->buffer,p->size);
      i+=p->size;
    }
  }
  buffer[i++]=0;
  fflush (stdout);
  fwrite (buffer,1,i,fout);
  free (buffer);
  fflush (stdout);
}


void main (int argc, char **argv) {
  byte *buffer;
  block *base;
  int size;

  fin=fopen (argv[1],"rb");
  fout=fopen (argv[2],"wb");
    
  size=filelength (fileno (fin));
  fflush (stdout);
  buffer=(byte *) malloc (size);
  fread (buffer,1,size,fin);
  fclose (fin);

  fflush (stdout);
  base=compress (buffer,size);
  fflush (stdout);
  flush_pool (base);
/*  free_frame (base);*/
  fclose (fout);
}
