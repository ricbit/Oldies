#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  unsigned char len;
  unsigned long value;
} hufcode;

typedef int (*callback)();

typedef struct huftree {
  union {
    struct huftree **choice;
    unsigned char **str;
    void **space;
  } u1;
  union {
    callback getbitsn;
    unsigned char len;
  } u2;
  unsigned char *type;
} huftree;

/* ------------------------- */

#ifdef MSX_UZIX_TARGET
#asm
GETBIT  MACRO   N

        LD      HL,_gleft       ; 11
        LD      A,(HL)          ; 8
        SUB     N
        JR      C,1f
        LD      (HL),A          ; 8
        LD      HL,_gtemp
        XOR     A
        IF N<3
          REPT    N
            SLA (HL)            ; 17
            RLA                 ; 5
          ENDM
        ENDC
        IF N=3
          RLD
          SRA A
          RR (HL)
        ENDC
        IF N=4
          RLD                   ; 20
        ENDC     
        IF N>4
          RLD
          REPT N-4
            SLA (HL)
            RLA
          ENDM
        ENDC
        LD      L,A
        LD      H,0
        RET
1:
        ENDM
#endasm
#endif

/* ------------------------- */

#ifdef MSX_UZIX_TARGET
#define msx_getbits(n) asm ("GETBIT " #n );
#else
#define msx_getbits(n)
#endif

/* ------------------------- */

void *my_malloc (int size) {
  void *p;

  if ((p=malloc (size))==NULL) {
    printf ("PANIC: out of memory\n");
    exit (1);
  }
  else
    return p;
}

/* ------------------------- */

unsigned char gtemp,gleft=0;
unsigned char *buffer,*bufpos;
unsigned int buflen;

int getbits (unsigned char len) {
  unsigned oldleft;
  unsigned int split;

  if (gleft==0) {
    if (buflen--==0)
      return -1;

    gtemp=*bufpos++;
    gleft=8;
  }

  if (len<=gleft) {
#ifdef MSX_UZIX_TARGET
#asm
        PUSH    BC
        LD      HL,_gtemp
        LD      B,E 
        LD      A,(_gleft)
        SUB     B
        LD      (_gleft),A
        XOR     A
1:
        SLA     (HL)
        RLA
        DJNZ    1b
        LD      L,A
        LD      H,0
        POP     BC
#endasm
#else
    split=gtemp>>(8-len);
    gtemp<<=len;
    gleft-=len;
    return split;
#endif
  } else {
#ifdef MSX_UZIX_TARGET
#asm
        PUSH    BC
        LD      A,(_gleft)
        LD      C,A
        LD      B,A
        XOR     A
        LD      H,A
        LD      (_gleft),A
        LD      A,(_gtemp)
1:
        RLCA
        DJNZ    1b
        LD      L,A
        LD      A,E 
        SUB     C
        LD      B,A
        LD      C,A
1:
        ADD     HL,HL
        DJNZ    1b
        PUSH    HL
        LD      E,C
        CALL    _getbits
        POP     BC
        BIT     7,H
        JR      NZ,1f
        ADD     HL,BC
1:
        POP     BC
#endasm
#else
    split=gtemp>>(8-gleft);
    oldleft=gleft;
    gleft=0;
    return (split<<(len-oldleft)) | getbits (len-oldleft);
#endif
  }
}

/* ------------------------- */

int getbits1 (void) {
  msx_getbits (1);
  return getbits(1);
}

int getbits2 (void) {
  msx_getbits (2);
  return getbits(2);
}

int getbits3 (void) {
  msx_getbits (3);
  return getbits(3);
}

int getbits4 (void) {
  msx_getbits (4);
  return getbits(4);
}

int getbits5 (void) {
  msx_getbits (5);
  return getbits(5);
}

int getbits6 (void) {
  msx_getbits (6);
  return getbits(6);
}

int getbits7 (void) {
  msx_getbits (7);
  return getbits(7);
}

callback getbitsg[7]=
  {getbits1,getbits2,getbits3,getbits4,getbits5,getbits6,getbits7};

/* ------------------------- */

hufcode *h;

huftree *build_tree (unsigned int start, unsigned int end, unsigned char ignore) {
  huftree *p;
  unsigned int j,newstart,newend;
  unsigned char i,iend,bits;

  p=(huftree *) my_malloc (sizeof (huftree));
  p->u2.len=h[start].len-ignore;
  if (p->u2.len>7)
    p->u2.len=7;
  iend=1<<p->u2.len;
  p->u1.space=(void **) my_malloc (iend*sizeof (void *));
  p->type=(unsigned char *) my_malloc (iend*sizeof (unsigned char));
  bits=ignore+p->u2.len;

  j=start;
  for (i=0; i<iend; i++) {
    newstart=j;
    do {
      if (j<end) {
        if (((h[j+1].value>>(h[j+1].len-bits))&(iend-1))==i)
          j++;
        else break;
      } else break;
    } while (1);
    newend=j++;

    if (newstart==newend) 
      p->type[i]=0;
    else {
      p->type[i]=1;
      p->u1.choice[i]=build_tree (newstart,newend,bits);
    }
  }

  return p;
}

/* ------------------------- */

void read_kernels (huftree *p) {
  unsigned char i,j,len,ilen,size,*s;

  ilen=p->u2.len;
  len=1<<ilen;
  for (i=0; i<len; i++)
    if (p->type[i])
      read_kernels (p->u1.choice[i]);
    else {
      size=getbits (4);
      s=p->u1.str[i]=(unsigned char *) my_malloc (size+1);
      for (j=0; j<size; j++)
        *s++=getbits (8);
      *s=0;
    }
  p->u2.getbitsn=getbitsg[ilen-1];
}

/* ------------------------- */

huftree *read_header (void) {
  unsigned char klen,start,end,total,ic;
  unsigned long kval;
  unsigned int hsize,*len,i,j,k;
  huftree *ht;

  start=getbits (5);
  end=getbits (5);
  total=end-start+1;

  hsize=0;
  len=(unsigned int *) my_malloc (total*sizeof (unsigned int));
  for (ic=0; ic<total; ic++) 
    hsize+=(len[ic]=getbits (9));

  h=(hufcode *) my_malloc (hsize*sizeof (hufcode));  

  j=k=0;
  for (ic=0; ic<total; ic++) {
    for (j=0; j<len[ic]; j++) {
      h[k].value=0;
      h[k++].len=ic+start;
    }
  }

  kval=0; klen=start;
  for (i=1; i<hsize; i++) {
    kval++;
    if (h[i].len>klen) {
      kval=(kval<<(h[i].len-klen));
      klen+=h[i].len-klen;
    }
    h[i].value=kval;
  }

  free (len);
  ht=build_tree (0,hsize-1,0);

  free (h);
  read_kernels (ht);

  return ht;
}

/* ------------------------- */

void read_cover (FILE *fout, huftree *base) {
  huftree *p;
  int g;

  do {
    p=base;
    do {
      if ((g=(p->u2.getbitsn)())<0)
        return;

      if (p->type[g])  
        p=p->u1.choice[g];
      else {
        fputs (p->u1.str[g],fout);
        break;
      }
        
    } while (1);
  } while (1);
}

/* ------------------------- */

int main (int argc, char **argv) {
  FILE *f,*fout;
  huftree *hcode;

  f=fopen (argv[1],"rb");
  fseek (f,0,SEEK_END);
  buflen=ftell (f);
  fseek (f,0,SEEK_SET);
  bufpos=buffer=(unsigned char *) my_malloc (buflen);
  fread (buffer,1,buflen,f);
  fclose (f);

  fout=fopen (argv[2],"wb");
  hcode=read_header ();
  read_cover (fout,hcode);
  fclose (fout);

  return 1;
}
