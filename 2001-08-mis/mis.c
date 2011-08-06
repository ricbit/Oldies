#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <math.h>
#include <values.h>

#define MAXLEN 15
#define MAXKER 256

typedef struct kernel {
  unsigned char *str;
  int len;
  int size;
  struct kernel *left,*right;
} kernel;

typedef struct {
  kernel *top[256];
} dict;

typedef struct {
  unsigned char *str;
  int save;
} kernel_array;

typedef struct huftree {
  unsigned char *str;
  int strl;
  int size;
  int value,len;
  struct huftree *bit0,*bit1;
} huftree;

typedef struct hufcap {
  huftree *h;
  int total;
} hufcap;

/* ------------------------- */

int eval_entropy (kernel *k, int size) {
  int e;

  e=(int)(-(double)k->size*log2((double)k->size/(double)size));
  e+=8*(k->len)+4;

  return e;
}

/* ------------------------- */

dict *init_dict (void) {
  dict *d;
  int i;

  d=(dict *) malloc (sizeof (dict));
  for (i=0; i<256; i++) {
    d->top[i]=(kernel *) malloc (sizeof (kernel));
    d->top[i]->str=(unsigned char *) malloc (2);
    d->top[i]->str[0]=i;
    d->top[i]->str[1]=0;
    d->top[i]->len=1;
    d->top[i]->size=0;
    d->top[i]->left=NULL;
    d->top[i]->right=NULL;
  }

  return d;
}

/* ------------------------- */

void print_kernel (kernel *n, int size) {
  if (n->size)
    printf ("%4d %4d %4d <%s>\n",
            n->size,eval_entropy (n,size),n->len*n->size*8,n->str);

  if (n->left!=NULL) 
    print_kernel (n->left,size);

  if (n->right!=NULL)
    print_kernel (n->right,size);
}

/* ------------------------- */

void print_dict (dict *d, int size) {
  int i;

  for (i=32; i<256; i++)
    print_kernel (d->top[i],size);
}

/* ------------------------- */

kernel *search_kernel (unsigned char *buf, int len, kernel *k) {
  int sc;

  if (!(sc=strncmp (buf,k->str,len)))
    return k;

  if (sc<0 && k->left!=NULL)
    return search_kernel (buf,len,k->left);

  if (sc>0 && k->right!=NULL)
    return search_kernel (buf,len,k->right);

  return NULL;
}

/* ------------------------- */

kernel *search (unsigned char *buf, int len, dict *d) {
  return search_kernel (buf,len,d->top[buf[0]]);
}

/* ------------------------- */

kernel *insert (unsigned char *buf, int len, dict *d) {
  kernel *k,*p;
  int sc;

  k=d->top[buf[0]];
  do {
    sc=strncmp (buf,k->str,len); 
    p=NULL;

    if (sc<=0) {
      if (k->left==NULL) {
        k->left=(kernel *) malloc (sizeof (kernel));
        p=k->left;
      }
      else
        k=k->left;
    }

    if (sc>0) {
      if (k->right==NULL) {
        k->right=(kernel *) malloc (sizeof (kernel));
        p=k->right;
      }
      else k=k->right;
   }

   if (p!=NULL) {
     p->str=(unsigned char *) malloc (len+1);
     strncpy (p->str,buf,len);
     p->str[len]=0;
     p->size=0;
     p->len=len;
     p->right=NULL;
     p->left=NULL;
   }

  } while (p==NULL);

  return p;
}

/* ------------------------- */

dict *lz78 (unsigned char *buf, int size) {
  int pos=0,len=1;
  dict *d;
  kernel *k;

  d=init_dict ();
  while (pos+len<size) {
    if ((k=search (buf+pos,len,d))!=NULL)
    {
      if (buf[pos]>32 && buf[pos+len]>32 && len<MAXLEN) {
        len++;
      } else {
        pos+=len;
        len=1;
      }
      k->size++;
    } else {
      (insert (buf+pos,len,d))->size=1;
      pos+=len-1;
      len=1;
    }
  }
  return d;
}

/* ------------------------- */

void heur1 (kernel *k, dict *d) {
  if (k->size>=k->len && k->len>1)
    insert (k->str,k->len,d);

  if (k->left!=NULL) 
    heur1 (k->left,d);

  if (k->right!=NULL)
    heur1 (k->right,d);
}

/* ------------------------- */

dict *apply_heur1 (dict *d) {
  dict *new;
  int i;

  new=init_dict ();
  for (i=0; i<256; i++)
    heur1 (d->top[i],new);

  return new;
}

/* ------------------------- */

kernel *search_kernel_max (unsigned char *buf, kernel *k) {
  int sc;
  kernel *k2;

  sc=strncmp (buf,k->str,k->len);

  if (sc<0) {
    if (k->left!=NULL)
      return search_kernel_max (buf,k->left);
    else
      return NULL;
  }

  if (sc>0) {
    if (k->right!=NULL)
      return search_kernel_max (buf,k->right);
    else
      return NULL;
  }

  sc=strncmp (buf,k->str,k->len+1);

  if (sc<0 && k->left!=NULL) {
    k2=search_kernel_max (buf,k->left);
    if (k2!=NULL) {
      if (k->len > k2->len)
        return k;
      else
        return k2;
    } else  
      return k;  
  }

  if (sc>0 && k->right!=NULL) {
    k2=search_kernel_max (buf,k->right);
    if (k2!=NULL) {
      if (k->len > k2->len)
        return k;
      else
        return k2;
    } else  
      return k;  
  }

  return k;
}

/* ------------------------- */

kernel *search_max (unsigned char *buf, dict *d) {
  return search_kernel_max (buf,d->top[buf[0]]);
}

/* ------------------------- */

void cover (unsigned char *buf, int size, dict *d) {
  int pos=0;
  kernel *k;

  while (pos<size) {
/*    if (buf[pos]>32) {*/
      k=search_max (buf+pos,d);
      k->size++;
      pos+=k->len;
/*    }
    else
      pos++; */
  }
}

/* ------------------------- */

int check_kernel_heur1 (kernel *k) {
  if (k->size<k->len && k->size) 
    return 1;

  if (k->left!=NULL)
    if (check_kernel_heur1 (k->left))
      return 1;

  if (k->right!=NULL)
    if (check_kernel_heur1 (k->right))
      return 1;

  return 0;
}

/* ------------------------- */

int check_heur1 (dict *d) {
  int i;

  for (i=0; i<256; i++)
    if (check_kernel_heur1 (d->top[i]))
      return 1;

  return 0;
}

/* ------------------------- */

dict *min_cover (unsigned char *buf, int size, dict *d) {
  dict *h;
  
  h=d;
  do {
    h=apply_heur1 (h);
    cover (buf,size,h);
  } while (check_heur1 (h));

  return h;
}

/* ------------------------- */

void apply_kernel_heur2 (kernel *k, int size, dict *d) {
  int e,r;

  if (k->size>0) {
    e=eval_entropy (k,size);
    r=k->size*k->len*8;
    if (e<r && k->len>1)
      insert (k->str,k->len,d);
  }

  if (k->left!=NULL)
    apply_kernel_heur2 (k->left,size,d);

  if (k->right!=NULL)
    apply_kernel_heur2 (k->right,size,d);
}

/* ------------------------- */

dict *apply_heur2 (dict *d, int size) {
  int i;
  dict *new;

  new=init_dict ();
  for (i=0; i<256; i++)
    apply_kernel_heur2 (d->top[i],size,new);
  return new;
}

/* ------------------------- */

int check_kernel_heur2 (kernel *k, int size) {
  int e,r;

  e=eval_entropy (k,size);
  r=k->size*k->len*8;

  if (e>=r && k->len>1) 
    return 1;

  if (k->left!=NULL)
    if (check_kernel_heur2 (k->left,size))
      return 1;

  if (k->right!=NULL)
    if (check_kernel_heur2 (k->right,size))
      return 1;

  return 0;
}

/* ------------------------- */

int check_heur2 (dict *d, int size) {
  int i;

  for (i=0; i<256; i++)
    if (check_kernel_heur2 (d->top[i],size))
      return 1;

  return 0;
}

/* ------------------------- */

dict *opt_cover (unsigned char *buf, int size, dict *d) {
  dict *h;
  
  h=d;
  do {
    h=apply_heur2 (h,size);
    cover (buf,size,h);
  } while (check_heur2 (h,size));

  return h;
}

/* ------------------------- */

int count_kernel (kernel *k) {
  int c=0;

  if (k->size)
    c++;

  if (k->left!=NULL)
    c+=count_kernel (k->left);

  if (k->right!=NULL)
    c+=count_kernel (k->right);

  return c;
}

/* ------------------------- */

int count_dict (dict *d) {
  int i,c=0;

  for (i=0; i<256; i++)
    c+=count_kernel (d->top[i]);

  return c;
}

/* ------------------------- */

void fill_kernel (kernel_array *ka, kernel *k, int *i, int size) {
  int e,r;

  if (k->size) {
    e=eval_entropy (k,size);
    r=k->size*k->len*8;

    ka[*i].str=(unsigned char *) malloc (k->len+1);
    strcpy (ka[*i].str,k->str);
    ka[(*i)++].save=r-e;
  }

  if (k->left!=NULL)
    fill_kernel (ka,k->left,i,size);

  if (k->right!=NULL)
    fill_kernel (ka,k->right,i,size);
}

/* ------------------------- */

void fill_array (kernel_array *ka, dict *d, int size) {
  int i,actual=0;

  for (i=0; i<256; i++) {
    fill_kernel (ka,d->top[i],&actual,size);
  }
}

/* ------------------------- */

int comp_kernel (const void *e1, const void *e2) {
  kernel_array *k1,*k2;

  k1=(kernel_array *)e1;
  k2=(kernel_array *)e2;
  return k2->save - k1->save;
}

/* ------------------------- */

dict *trim (unsigned char *buf, int size, dict *d) {
  dict *new;
  kernel_array *ka;
  int old,total,i,s=0,db,dbfree;

  new=d;
  total=0;
  do {
    s=0;
    old=total;
    total=count_dict (new);
    ka=(kernel_array *) malloc (total*sizeof (kernel_array));
    fill_array (ka,new,size);

    qsort (ka,total,sizeof (kernel_array),comp_kernel);

    db=0;
    for (i=0; i<total; i++)   {
      s+=ka[i].save;
      if (strlen(ka[i].str)>1)
        db++;
    }

    dbfree=0;
    new=init_dict ();
    for (i=0; i<total; i++) 
      if (strlen(ka[i].str)>1 && dbfree<MAXKER-(total-db)) {
        insert (ka[i].str,strlen (ka[i].str),new);
        dbfree++;
      }
    cover (buf,size,new);

  } while (total>MAXKER);

  return new;
}

/* ------------------------- */

void fill_huffkernel (kernel *k, huftree **h, int *pos) {

  if (k->size) {
    h[*pos]=(huftree *) malloc (sizeof (huftree));
    h[*pos]->str=(unsigned char *) malloc (k->len+1);
    strcpy (h[*pos]->str,k->str);
    h[*pos]->strl=k->len;
    h[*pos]->bit0=NULL;
    h[*pos]->bit1=NULL;
    h[*pos]->value=0;
    h[*pos]->len=0;
    h[(*pos)++]->size=k->size;
  }

  if (k->left!=NULL)
    fill_huffkernel (k->left,h,pos);

  if (k->right!=NULL)
    fill_huffkernel (k->right,h,pos);
}

/* ------------------------- */

void fill_huffarray (dict *d, huftree **h) {
  int i,actual=0;

  for (i=0; i<256; i++)
    fill_huffkernel (d->top[i],h,&actual);
}

/* ------------------------- */

int comp_huftree (const void *e1, const void *e2) {
  huftree *k1,*k2;

  k1=(huftree *)e1;
  k2=(huftree *)e2;
  return k1->len - k2->len;
}

/* ------------------------- */

void insert_hufarray (huftree *ha, huftree *hf, int *pos) {
  if (ha->str!=NULL) {
    hf[*pos].str=(unsigned char *) malloc (strlen (ha->str)+1);
    strcpy (hf[*pos].str,ha->str);
    hf[*pos].strl=ha->strl;
    hf[*pos].value=0;
    hf[*pos].size=ha->size;
    hf[(*pos)++].len=ha->len;
  }

  if (ha->bit0!=NULL)
    insert_hufarray (ha->bit0,hf,pos);

  if (ha->bit1!=NULL)
    insert_hufarray (ha->bit1,hf,pos);
}

/* ------------------------- */

void eval_huftree (huftree *h, int level) {

  if (h->str!=NULL)
    h->len=level;
  else {
    if (h->bit0!=NULL)
      eval_huftree (h->bit0,level+1);
    if (h->bit1!=NULL)
      eval_huftree (h->bit1,level+1);
  }

}

/* ------------------------- */

unsigned char *binary (int val, int len) {
  unsigned char *str;
  int i;

  str=(unsigned char *) malloc (len+1);
  for (i=0; i<len; i++)
    if (val & (1<<(len-i-1)))
      str[i]='1';
    else
      str[i]='0';
  str[i]=0;

  return str;
}

/* ------------------------- */

hufcap *huffman (dict *d) {
  huftree **ha,*p,*hf;
  int total,i,min,minv,min2,min2v,t;
  int klen,kval;
  hufcap *hc;

  t=total=count_dict (d);
  ha=(huftree **) malloc (total*sizeof (huftree *));

  fill_huffarray (d,ha);

  do {

    minv=MAXINT; min=0;
    for (i=0; i<total; i++)
      if (ha[i]!=NULL)
        if (ha[i]->size<minv) {
          min=i;
          minv=ha[i]->size;
        }

    min2v=MAXINT; min2=1;
    for (i=0; i<total; i++)
      if (ha[i]!=NULL)
        if (ha[i]->size<min2v && i!=min) {
          min2=i;
          min2v=ha[i]->size;
        }

    p=(huftree *) malloc (sizeof (huftree));
    p->str=NULL;
    p->size=minv+min2v;
    p->bit0=ha[min];
    p->bit1=ha[min2];

    if (min>min2) {
      ha[min]=NULL;
      ha[min2]=p;
    } else {
      ha[min]=p;
      ha[min2]=NULL;
    }

    t--;

  } while (t>1);

  eval_huftree (ha[0],0);
  hf=(huftree *) malloc (total*sizeof (huftree));
  t=0;
  insert_hufarray (ha[0],hf,&t);
  qsort (hf,total,sizeof (huftree),comp_huftree);

  kval=0; klen=hf[0].len;
  for (i=1; i<total; i++) {
    kval++;
    if (hf[i].len>klen) {
      kval=(kval<<(hf[i].len-klen));
      klen+=hf[i].len-klen;
    }
      
    hf[i].value=kval;
  }

/*  for (i=0; i<total; i++)
    printf ("%02d %s <%s>\n",
            hf[i].len,binary(hf[i].value,hf[i].len),hf[i].str);*/

  hc=(hufcap *) malloc (sizeof (hufcap));
  hc->h=hf;
  hc->total=total;
  return hc;

}

/* ------------------------- */

int count_huffman (hufcap *h) {
  int size=0,i;

  for (i=0; i<h->total; i++) 
    size+=h->h[i].size*h->h[i].len;

  return size;
}

/* ------------------------- */

int gleft=8,gtemp=0;

void putbits (FILE *f, int value, int len) {
  int split;
  int newvalue,newleft;

  if (gleft>len) {
    gtemp<<=len;
    gtemp|=value;
    gleft-=len;
  }

  else if (gleft==len) {
    gtemp<<=len;
    gtemp|=value;
    fputc (gtemp,f);
    gtemp=0;
    gleft=8;
  }

  else {
    split=value>>(len-gleft);
    gtemp<<=gleft;
    gtemp|=split;
    fputc (gtemp,f);
    newvalue=value&((1<<(len-gleft))-1);
    newleft=len-gleft;
    gtemp=0;
    gleft=8;
    putbits (f,newvalue,newleft);
  }
}

/* ------------------------- */

void write_header (FILE *f, hufcap *h) {
  int actual,size,i,j;

  fputc (h->h[0].len,f);
  fputc (h->h[h->total-1].len,f);

  for (i=0; i<h->total;) {
    actual=h->h[i].len;
    for (size=0; h->h[i].len==actual && i<h->total; i++,size++);
    fputc (size,f);
    if (i<h->total)
      while (h->h[i].len!=actual+1) {
        fputc (0,f);
        actual++;
      }
  }

  for (i=0; i<h->total; i++) {
    putbits (f,strlen (h->h[i].str),4);
    for (j=0; j<strlen (h->h[i].str); j++)
      putbits (f,h->h[i].str[j],8);
  }

}

/* ------------------------- */

int comp_hufsize (const void *e1, const void *e2) {
  huftree *k1,*k2;

  k1=(huftree *)e1;
  k2=(huftree *)e2;

  if (k2->str[0]<k1->str[0])
    return +1;

  if (k2->str[0]>k1->str[0])
    return -1;

  return k2->strl - k1->strl;
}

/* ------------------------- */

void write_cover (FILE *f, unsigned char *buf, int size, hufcap *h) {
  int i,j,pos=0;
  int start[256];

  qsort (h->h,h->total,sizeof (huftree),comp_hufsize);

  j=0;
  for (i=0; i<256; i++) {
    start[i]=j;
    while (h->h[j].str[0]==i && j<h->total-1)
      j++;
  }

  while (pos<size) {
    for (i=start[buf[pos]]; i<h->total; i++)
      if (!strncmp (h->h[i].str,buf+pos,h->h[i].strl)) {
        putbits (f,h->h[i].value,h->h[i].len);
        pos+=h->h[i].strl;
        break;
      }
  }
}

/* ------------------------- */

void flush_file (FILE *f) {
  if (gleft<8) {
    gtemp<<=gleft;
    gtemp|=((1<<gleft)-1);
    fputc (gtemp,f);
  }
}

/* ------------------------- */

int main (int argc, char **argv) {
  FILE *f;
  unsigned char *buf;
  int size;
  dict *orig,*min,*opt,*final;
  hufcap *code;

  f=fopen (argv[1],"rb");
  fseek (f,0,SEEK_END);
  size=ftell (f);
  fseek (f,0,SEEK_SET);
  buf=(unsigned char *) malloc (size);
  fread (buf,1,size,f);
  fclose (f);

  orig=lz78 (buf,size);
  min=min_cover (buf,size,orig);
  opt=opt_cover (buf,size,min);
  final=trim (buf,size,opt);
  code=huffman (final);

  f=fopen (argv[2],"wb");
  write_header (f,code);
  write_cover (f,buf,size,code);
  flush_file (f);
  fclose (f);

  /*print_dict (final);*/

  return 0;
}
