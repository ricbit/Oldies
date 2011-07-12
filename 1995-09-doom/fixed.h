/* Fixed-point vector header file */
/* Ricardo Bittencourt (9/95) */

#ifndef __FIXED_H
#define __FIXED_H

#include <dos.h>

typedef long int fixed;

typedef struct {
  fixed dx,dy,dz;
} vector;

typedef struct {
  fixed a,b,c,d;
} plane;

typedef struct {
  vector F,T,Up,Q,Ud,Vd,R,P;
} obs;

typedef struct {
  int x,y;
  fixed dist;
  unsigned char Valid;
} pixel;

vector init;

#define ToFixed(x) ((fixed)((x)*65536.0))
#define ToFloat(x) (((float)(x))/65536.0)
#define Assume(x,y,z,v) \
{ (v).dx=ToFixed((x)); (v).dy=ToFixed((y)); (v).dz=ToFixed((z)); }
#define AssumeFixed(x,y,z,v) \
{ (v).dx=(x); (v).dy=(y); (v).dz=(z); }
#define Vector(x,y,z) \
( init.dx=ToFixed((x)), init.dy=ToFixed((y)), init.dz=ToFixed((z)), init)
#define AssumePlane(a1,b1,c1,d1,p) \
{ (p).a=ToFixed((a1)); (p).b=ToFixed((b1)); \
  (p).c=ToFixed((c1)); (p).d=ToFixed((d1)); }

#ifdef __cplusplus
extern "C" {
#endif

extern void AddVector (vector far *a, vector far *b, vector far *c);
extern void SubVector (vector far *a, vector far *b, vector far *c);
extern void ScalarProduct (vector far *a, fixed n, vector far *v);
extern void DotProduct (vector far *a, vector far *b, fixed far *n);
extern void CrossProduct (vector far *a, vector far *b, vector far *v);
extern void FSetViewer (obs far *o);
extern void FInvert (fixed far *n);
extern void FProject (obs far *o, vector far *W, pixel far *p);
extern void DiffTime (struct time far *tf, struct time far *ti,
                      long int far *t);
extern void CalcPlane (plane far *p, vector far *v, fixed far *n);
extern void DepthInit (fixed d1, fixed d2, int dx, fixed far *dinc);
extern void DepthInc (fixed dinc, fixed far *da, unsigned char *dac);

#ifdef __cplusplus
}
#endif

#endif