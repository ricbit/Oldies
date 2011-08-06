#include <stdio.h>
#include <malloc.h>
#include <fcntl.h>
#include <unistd.h>
#include <math.h>
#include "opsys.h"
#include "video.h"
#include "graphics.h"

#define iabs(x) ((x)<0?-(x):(x))

object *model;

observer obs;
double one=1.0;
double zscale=1000000.0;
double RESX2,RESY2;
short *screen;
int *zbuffer;
double zmax,zmin;

object *read_object (char *name) {
  int file;  
  object *model;
  
  model=(object *) malloc (sizeof (object));
  file=open (name,O_BINARY|O_RDONLY);
  if (file<0) {
    printf ("error in file <%s>\n",name);
    exit (1);
  }
  read (file,&(model->total_vertex),sizeof (int));

  model->vertex_list=(vertex *) malloc (model->total_vertex*sizeof (vertex));
  read (file,model->vertex_list,model->total_vertex*sizeof (vertex));

  read (file,&(model->total_triangle),sizeof (int));

  model->triangle_list=(triangle *) malloc 
    (model->total_triangle*sizeof (triangle));
  read (file,model->triangle_list,model->total_triangle*sizeof (triangle));

  close (file);

  model->point_list=(point *) malloc (model->total_vertex*sizeof (point));
  return model;
}

void init_engine (void) {
  RESX2=(double)(RESX)/2.0;
  RESY2=(double)(RESY)/2.0;
}

void adjust_observer (void) {
  obs.vd.dx=((double) RESY)*obs.up.dx;
  obs.vd.dy=((double) RESY)*obs.up.dy;
  obs.vd.dz=((double) RESY)*obs.up.dz;
  obs.ud.dx=((double) RESX)*(obs.to.dy*obs.up.dz-obs.to.dz*obs.up.dy);
  obs.ud.dy=((double) RESX)*(obs.to.dz*obs.up.dx-obs.to.dx*obs.up.dz);
  obs.ud.dz=((double) RESX)*(obs.to.dx*obs.up.dy-obs.to.dy*obs.up.dx);
}

void init_observer (double phi, double theta) {
  obs.to.dx=-cos (phi)*cos (theta);
  obs.to.dy=-sin (phi);
  obs.to.dz=-cos (phi)*sin (theta);
  obs.from.dx=-obs.to.dx*800.0;
  obs.from.dy=-obs.to.dy*800.0;
  obs.from.dz=-obs.to.dz*800.0;
  obs.up.dx=-sin (phi)*cos (theta);
  obs.up.dy=cos (phi);
  obs.up.dz=-sin (phi)*sin (theta);
  adjust_observer ();
}         

#ifdef INTELX

void project_vertex (vertex *vert, point *p) {
  vector R,K;

  asm (
    "fldl (%0) \n\t"                    /* Clock cycle 1       */
    "fsubl _obs \n\t"                   /* Clock cycle 2-4     */
    "fldl 8(%0) \n\t"                   /* Clock cycle 3       */
    "fsubl _obs+8 \n\t"                 /* Clock cycle 4-6     */
    "fxch %%st(1) \n\t"                 /* Clock cycle 4       */
    "fstl (%1) \n\t"                    /* Clock cycle 5-6     */    
    "fmull _obs+48 \n\t"                /* Clock cycle 7-9     */
    "fxch %%st(1) \n\t"                 /* Clock cycle 7       */
    "fldl 16(%0) \n\t"                  /* Clock cycle 8       */
    "fsubl _obs+16 \n\t"                /* Clock cycle 9-11    */
    "fxch %%st(1) \n\t"                 /* Clock cycle 9       */
    "fstl 8(%1) \n\t"                   /* Clock cycle 10-11   */
    "fmull _obs+48+8 \n\t"              /* Clock cycle 12-14   */
    "fxch %%st(1) \n\t"                 /* Clock cycle 12      */
    "fstl 16(%1) \n\t"                  /* Clock cycle 13-14   */
    "fmull _obs+48+16 \n\t"             /* Clock cycle 15-17   */
    "fxch %%st(2) \n\t"                 /* Clock cycle 15      */
    "faddp %%st,%%st(1) \n\t"           /* Clock cycle 16-18   */
    "faddp %%st,%%st(1) \n\t"           /* Clock cycle 19-21   */
    "fstpl 8(%2) \n\t"                  /* Clock cycle 22-23   */
    "movl 8+4(%2),%%eax \n\t"           /* Clock cycle 24      */ 
    "cmpl $0x80000000,%%eax \n\t"       /* Clock cycle 25 U    */
    "ja 0 \n\t"                         /* Clock cycle 25 V    */
    "fldl _one \n\t"                    /* Clock cycle 26      */
    "fdivl 8(%2) \n\t"                  /* Clock cycle 27-65   */
    "fstl 8(%2) \n\t"                   /* Clock cycle 66-67   */
    "fmull (%1) \n\t"                   /* Clock cycle 68-70   */
    "fldl 8(%2) \n\t"                   /* Clock cycle 69      */
    "fmull 8(%1) \n\t"                  /* Clock cycle 70-72   */
    "fldl 8(%2) \n\t"                   /* Clock cycle 71      */
    "fmull 16(%1) \n\t"                 /* Clock cycle 72-74   */
    "fxch %%st(2) \n\t"                 /* Clock cycle 72      */
    "fsubl _obs+48 \n\t"                /* Clock cycle 73-75   */
    "fxch %%st(1) \n\t"                 /* Clock cycle 73      */
    "fsubl _obs+48+8 \n\t"              /* Clock cycle 74-76   */
    "fxch %%st(2) \n\t"                 /* Clock cycle 74      */
    "fsubl _obs+48+16 \n\t"             /* Clock cycle 75-77   */
    "fxch %%st(1) \n\t"                 /* Clock cycle 75      */
    "fstl (%3) \n\t"                    /* Clock cycle 76-77   */
    "fmull _obs+72 \n\t"                /* Clock cycle 78-80   */
    "fxch %%st(2) \n\t"                 /* Clock cycle 78      */
    "fstl 8(%3) \n\t"                   /* Clock cycle 79-80   */
    "fmull _obs+72+8 \n\t"              /* Clock cycle 81-83   */
    "fxch %%st(2) \n\t"                 /* Clock cycle 81      */
    "faddl _RESX2 \n\t"                 /* Clock cycle 82-84   */
    "fxch %%st(1) \n\t"                 /* Clock cycle 82      */
    "fstl 16(%3) \n\t"                  /* Clock cycle 83-84   */
    "fmull _obs+72+16 \n\t"             /* Clock cycle 85-87   */
    "fxch %%st(2) \n\t"                 /* Clock cycle 85      */
    "faddp %%st,%%st(1) \n\t"           /* Clock cycle 86-88   */
    "fldl (%3) \n\t"                    /* Clock cycle 87      */
    "fmull _obs+96 \n\t"                /* Clock cycle 88-90   */
    "fxch %%st(2) \n\t"                 /* Clock cycle 88      */
    "faddp %%st,%%st(1) \n\t"           /* Clock cycle 89-91   */
    "fldl 8(%3) \n\t"                   /* Clock cycle 90      */
    "fmull _obs+96+8 \n\t"              /* Clock cycle 91-93   */
    "fxch %%st(1) \n\t"                 /* Clock cycle 91      */
    "fistpl (%2) \n\t"                  /* Clock cycle 92-97   */
    "faddp %%st,%%st(1) \n\t"           /* Clock cycle 98-100  */
    "fldl 16(%3) \n\t"                  /* Clock cycle 99      */  
    "fmull _obs+96+16 \n\t"             /* Clock cycle 100-102 */
    "fxch %%st(1) \n\t"                 /* Clock cycle 100     */ 
    "fldl _RESY2 \n\t"                  /* Clock cycle 101     */
    "fsubrp %%st,%%st(1) \n\t"          /* Clock cycle 102-104 */
    "fsubrp %%st,%%st(1) \n\t"          /* Clock cycle 105-107 */
    "fistpl 4(%2) \n\t"                 /* Clock cycle 113-118 */
    "0: \n\t"
  :                                      
  : "r" (vert), "r" (&R), "r" (p), "r" (&K)
  : "%eax"
  );
}

#else

void project_vertex (vertex *vert, point *p) {
  vector R,K;

  R.dx=vert->x-obs.from.dx;
  R.dy=vert->y-obs.from.dy;
  R.dz=vert->z-obs.from.dz;
  p->t=R.dx*obs.to.dx+R.dy*obs.to.dy+R.dz*obs.to.dz;
  if (p->t<=0.0) return;
  p->t=1/p->t;
  K.dx=R.dx*p->t-obs.to.dx;
  K.dy=R.dy*p->t-obs.to.dy;
  K.dz=R.dz*p->t-obs.to.dz;
  p->x=(int)(K.dx*obs.ud.dx+K.dy*obs.ud.dy+K.dz*obs.ud.dz)+RESX/2;
  p->y=RESY/2-(int)(K.dx*obs.vd.dx+K.dy*obs.vd.dy+K.dz*obs.vd.dz);
}

#endif

void draw_object (object *model, short *buffer, int *z_buffer) {
  int i;

  screen=buffer;
  for (i=0; i<model->total_vertex; i++) {
    project_vertex (model->vertex_list+i,model->point_list+i);
  }
  zmax=model->point_list[0].t;
  zmin=model->point_list[0].t;
  for (i=0; i<model->total_vertex; i++) {
    if (model->point_list[i].t>zmax) zmax=model->point_list[i].t;
    if (model->point_list[i].t<zmin) zmin=model->point_list[i].t;
  }
  printf ("zmax: %f\nzmin: %f\n",zmax,zmin);
  for (i=0; i<model->total_vertex; i++)
    screen[model->point_list[i].x+model->point_list[i].y*RESX]=15;
}
