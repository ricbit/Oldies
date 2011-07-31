#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "wise_gen.h"
#include "wise_rle.h"

#define SINGLE 0
#define DOUBLE 1
#define MULTI 2
#define RAW 3

#define MAXBLOCKS 2000

typedef struct block {
  int type;
  int size;
  unsigned char value;
  unsigned char value2;
  unsigned char *buffer;
  struct block *next;
} block;
  
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

block *compress (unsigned char *buffer, int size) {  
  int i,j;
  block *base=NULL,*p=NULL,*q=NULL;

  /* reading */
  for (i=0; i<size; i++) {
    if (p==NULL) {
      base=(block *) safe_malloc (sizeof (block));
      p=base;
    }
    else {
      p->next=(block *) safe_malloc (sizeof (block));
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
      q=p->next->next;
      free_block (p->next);
      p->next=q;
    }
    else {
      p->buffer=(unsigned char *) safe_malloc (2);
      p->buffer[0]=p->value;
      p->buffer[1]=p->next->value;
      p->size=2;
      p->type=RAW;
      q=p->next->next;
      free_block (p->next);
      p->next=q;
    } 
  }

  /* compressing */
  p=base;
  while (p!=NULL && p->next!=NULL) {
    if ((p->type==RAW && p->size>=254) || (p->type==MULTI && p->size>=126)) {
      p=p->next;
      continue;
    }
    if (p->type==MULTI && p->next->type==MULTI && p->value==p->next->value && p->size+p->next->size<=126) {
      p->size+=p->next->size;
      q=p->next->next;
      free_block (p->next);
      p->next=q;
      continue;
    }
    if (p->type==RAW && p->next->type==RAW) {
      j=p->size+p->next->size;
      if (j>=254) {
        p=p->next;
        continue;
      }
      buffer=(unsigned char *) safe_malloc (j);
      for (i=0; i<p->size; i++)
        buffer[i]=p->buffer[i];
      for (i=0; i<p->next->size; i++)
        buffer[i+p->size]=p->next->buffer[i];
      p->size=j;
      p->buffer=buffer;
      q=p->next->next;
      free_block (p->next);
      p->next=q;
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
      buffer=(unsigned char *) safe_malloc (j);
      for (i=0; i<p->size; i++)
        buffer[i]=p->buffer[i];
      for (i=0; i<p->next->size; i++)
        buffer[i+p->size]=p->next->value;
      p->size=j;
      p->buffer=buffer;
      q=p->next->next;
      free_block (p->next);
      p->next=q;
      continue;
    }
    if (p->type==RAW && p->next->type==RAW) {
      j=p->size+p->next->size;
      if (j>=254) {
        p=p->next;
        continue;
      }
      buffer=(unsigned char *) safe_malloc (j);
      for (i=0; i<p->size; i++)
        buffer[i]=p->buffer[i];
      for (i=0; i<p->next->size; i++)
        buffer[i+p->size]=p->next->buffer[i];
      p->size=j;
      p->buffer=buffer;
      q=p->next->next;
      free_block (p->next);
      p->next=q;
      continue;
    }
    p=p->next;
  }

  return base;
}
    
compressed *flush_pool (block *base) {
  block *p;    
  int i=0;
  compressed *comp;

  comp=(compressed *) safe_malloc (sizeof (compressed));
  comp->size=0;
  
  for (p=base; p!=NULL; p=p->next) 
    if (p->type==2)
      comp->size+=2;
    else
      comp->size+=p->size+1;

  comp->buffer=(unsigned char *) safe_malloc (++comp->size);
  
  i=0;
  for (p=base; p!=NULL; p=p->next) {
    if (p->type==MULTI) {
      comp->buffer[i++]=(p->size/2)+0x80;
      comp->buffer[i++]=p->value;
    }
    else {
      comp->buffer[i++]=(p->size/2);
      memcpy (comp->buffer+i,p->buffer,p->size);
      i+=p->size;
    }
  }
  comp->buffer[i++]=0;

  return comp;
}

compressed *compress_line (unsigned char *buffer, int size) {
  block *base;
  compressed *comp;

  base=compress (buffer,size);
  comp=flush_pool (base);
  free_frame (base);
  return comp;
}

void free_compressed (compressed *comp) {
  free (comp->buffer);
  free (comp);
}
