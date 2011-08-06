#include <malloc.h>
#include <stdlib.h>
#include "types.h"
#include "video.h"
#include "graphics.h"
#include "fractal.h"

#define RAND (rand()%32+32)
#define POS(x,y) (land->size*(y)+(x))
#define READ(x,y) \
  (land->height[POS((((x)+land->size)%land->size), \
    (((y)+land->size)%land->size))])
#define CROP(x) ((x)>0?(x):0)

short *screen;

short ymin[1024],ymax[1024];

void seed (landscape *land) {
  land->height[POS(0,0)]=RAND;
  land->height[POS(0,land->size>>1)]=RAND;
  land->height[POS(land->size>>1,0)]=RAND;
  land->height[POS(land->size>>1,land->size>>1)]=RAND;
}

void fill (landscape *land, int size, int sx, int sy, int x, int y) {
  land->height[POS(x,y)]=
    (land->height[POS(x,y)]>>1)+
    (land->height[POS(sx,sy)]>>2)+
    (RAND>>2);
  land->height[POS(x+(size>>2),y)]=
    (land->height[POS(x,y)]>>1)+
    (land->height[POS(sx+(size>>1),sy)]>>1);
  land->height[POS(x,y+(size>>2))]=
    (land->height[POS(x,y)]>>1)+
    (land->height[POS(sx,sy+(size>>1))]>>1);
  land->height[POS(x+(size>>2),y+(size>>2))]=
    (land->height[POS(x,y)]>>1)+
    (land->height[POS(sx+(size>>1),sy+(size>>1))]>>1);
}

void divide (landscape *land, int size, int x, int y) {
  if (size==1) return;

  fill (land,size,x,y,x,y);
  fill (land,size,x,y,x+(size>>1),y);
  fill (land,size,x,y,x,y+(size>>1));
  fill (land,size,x,y,x+(size>>1),y+(size>>1));

  divide (land,size>>1,x,y);
  divide (land,size>>1,x+(size>>1),y);
  divide (land,size>>1,x,y+(size>>1));
  divide (land,size>>1,x+(size>>1),y+(size>>1));
}

void average (landscape *land) {
  short *temp;
  int i,j;

  temp=(short *) malloc (land->size*land->size*sizeof (short));
  for (j=0; j<land->size; j++)
    for (i=0; i<land->size; i++)
      temp[POS(i,j)]=land->height[POS(i,j)];
  for (j=0; j<land->size; j++)
    for (i=0; i<land->size; i++)
      land->height[POS(i,j)]=(byte)((
          (temp[POS(i,j)])+
          (temp[POS((i+1)%land->size,j)])+
          (temp[POS(i,(j+1)%land->size)])+
          (temp[POS((i+land->size-1)%land->size,j)])+
          (temp[POS(i,(j+land->size-1)%land->size)])
        )/5);
}

void display (landscape *land) {
  int i,j;

  for (j=0; j<land->size; j++) 
    for (i=0; i<land->size; i++)
      screen[i+j*RESX]=land->height[POS(i,j)];
}

landscape *generate_landscape (short *buffer) {
  landscape *land;

  land=(landscape *) malloc (sizeof (landscape));
  land->size=128;
  land->height=(byte *) malloc (land->size*land->size);
  screen=buffer;
  seed (land);
  divide (land,128,0,0);
  average (land);
  average (land);
  average (land);
  average (land);
  display (land);
  return land;
}

void line (point *a, point *b) {
  int i,jstart,jstep;
  point *p1,*p2;

  if (a->x==b->x) return;

  if (a->x<b->x) {
    p1=a; p2=b;
  }
  else {
    p1=b; p2=a;
  }

  jstart=p1->y<<16;
  jstep=((p2->y-p1->y)<<16)/(p2->x-p1->x);

  for (i=p1->x; i<=p2->x; i++) {
    if (ymin[i]>jstart>>16) ymin[i]=jstart>>16;
    if (ymax[i]<jstart>>16) ymax[i]=jstart>>16;
    jstart+=jstep;
  }
  
}

void draw_triangle (point *pa, point *pb, point *pc) {
  int min,max,i,j;  

  if (!BOUND (pa->x,pa->y) || !BOUND (pb->x,pb->y) || !BOUND (pc->x,pc->y))
    return;
  
  min=max=pa->x;
  if (pb->x>max) max=pb->x;
  if (pc->x>max) max=pc->x;
  if (pb->x<min) min=pb->x;
  if (pc->x<min) min=pc->x;

  for (i=min; i<=max; i++) {
    ymin[i]=RESY;
    ymax[i]=-1;
  }

  line (pa,pb);
  line (pb,pc);
  line (pc,pa);

  for (i=min; i<=max; i++)
    for (j=ymin[i]; j<=ymax[i]; j++)
      screen[RESX*j+i]=pa->z;
}

void draw_landscape (landscape *land, short *buffer, int x, int y) {
  int i,j;
  vertex v;
  point *p,*pa;
  
  obs.from.dx=(double)x/12.0;
  obs.from.dy=(double)y/12.0;
  obs.from.dz=((double)land->height[POS(x,y)])/6.0+1.0;
  obs.to.dx=0.0;
  obs.to.dy=1.0;
  obs.to.dz=0.0;
  obs.up.dx=0.0;
  obs.up.dy=0.7;
  obs.up.dz=0.7;
  adjust_observer ();

  p=(point *) malloc (sizeof (point)*land->size*land->size);
  
  for (j=land->size-1; j>=0; j--)
    for (i=0; i<land->size; i++) {
      v.x=(double)i/12.0;
      v.y=(double)j/12.0;
      v.z=((double)land->height[POS(i,j)])/6.0;
      project_vertex (&v,&(p[POS(i,j)]));
      pa=p+POS(i,j);
      if (pa->t>0.0)
        if (BOUND (pa->x,pa->y))
          pa->z=CROP(-((((READ(i+1,j)-READ(i-1,j))))<<1))+15;
    }
  for (i=0; i<RESX; i++)
    ymax[i]=RESY;
  for (j=land->size-2; j>0; j--)
    for (i=1; i<land->size-1; i++) {
      pa=p+POS(i,j);
      if (pa->t>0.0)
        if (BOUND (pa->x,pa->y)) {
          draw_triangle (pa,p+POS(i+1,j),p+POS(i,j+1));
          draw_triangle (pa,p+POS(i,j+1),p+POS(i-1,j+1));
        }
    }  
  
  free (p);

}

