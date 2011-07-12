#include <stdio.h>
#include <io.h>
#include <fcntl.h>

typedef long int fixed;

typedef struct vertex {
  fixed dx,dy,dz;
  fixed number;
  vertex *next;
} vertex;

typedef struct wall {
  fixed v[4];
} wall;

FILE *f;
int fout;
int i,j,at;
double dx,dy,dz;
wall *w;
fixed fx,fy,fz,actual,max;
vertex *p,*v=NULL;

void main (void) {
  f=fopen ("walls.txt","r");
  fscanf (f,"%ld",&max);
  printf ("Total walls: %d\n",max);
  w=new wall[max];
  for (i=0; i<max; i++) {
    for (j=0; j<4; j++) {
      fscanf (f,"%lf",&dx);
      fscanf (f,"%lf",&dy);
      fscanf (f,"%lf",&dz);
      fx=(fixed)(dx*65536.0);
      fy=(fixed)(dy*65536.0);
      fz=(fixed)(dz*65536.0);
      if (v==NULL) {
        v=new vertex;
        v->dx=fx;
        v->dy=fy;
        v->dz=fz;
        v->number=0;
        v->next=NULL;
        actual=0;
        w[i].v[j]=actual;
      }
      else {
        p=v;
        at=1;
        do {
          if (p->dx==fx && p->dy==fy && p->dz==fz) {
            w[i].v[j]=p->number;
            at=0;
          }
          else if (p->next==NULL) {
            p->next=new vertex;
            p->next->dx=fx;
            p->next->dy=fy;
            p->next->dz=fz;
            p->next->number=++actual;
            p->next->next=NULL;
            w[i].v[j]=actual;
            at=0;
          }
          else p=p->next;
        } while (at);
      }
    }
  }
  fclose (f);
  for (i=0; i<max; i++) {
    printf ("Wall %d: ",i);
    for (j=0; j<4; j++)
      printf ("%ld ",w[i].v[j]);
    printf ("\n");
  }
  printf ("Total vertex: %ld\n",++actual);
  p=v;
  while (p!=NULL) {
    printf ("vertex %ld - %ld %ld %ld\n",p->number,p->dx,p->dy,p->dz);
    p=p->next;
  }
  fout=open ("scene.dat",O_BINARY|O_CREAT);
  write (fout,&actual,4);
  p=v;
  while (p!=NULL) {
    write (fout,&p->dx,4);
    write (fout,&p->dy,4);
    write (fout,&p->dz,4);
    p=p->next;
  }
  write (fout,&max,4);
  for (i=0; i<max; i++)
    for (j=0; j<4; j++)
      write (fout,&(w[i].v[j]),4);
  close (fout);
}