#ifndef __GRAPHICS_H
#define __GRAPHICS_H

typedef struct {
  double dx,dy,dz;
} vector;

typedef struct {
  double x,y,z,u,v;
} vertex;

typedef struct {
  int a,b,c;
} triangle;

typedef struct {
  int x,y;
  double t;
  int z;
} point;

typedef struct {
  vertex *vertex_list;
  triangle *triangle_list;
  point *point_list;
  int total_vertex;
  int total_triangle;
} object;

typedef struct {
  vector from,up,to,ud,vd;
} observer;

#define BOUND(x,y) ((x)>=0 && (x)<RESX && (y)>=0 && (y)<=RESY)

extern object *model;
extern observer obs;

object *read_object (char *name);
void init_engine (void);
void init_observer (double phi, double theta);
void adjust_observer (void);
void project_vertex (vertex *vert, point *p);
void draw_object (object *model, short *buffer, int *z_buffer);

#endif

