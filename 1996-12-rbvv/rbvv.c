/* RBVV 1.0 */
/* by Ricardo Bittencourt */

#include <stdio.h>
#include <ctype.h>
#include <allegro.h>
#include <conio.h>
#include <stdlib.h>
#include <math.h>

#define RES 64
#define THRESHOLD 5
#define RESX 128
#define RESY 100
#define RUNLENGTH 6
#define VERYBIG 10000
#define VOXEL(v,x,y,z) \
  (*((v)+(x)+((y)*RES)+((z)*RES*RES)))
#define CLAMPVOXEL(v,x,y,z) \
  (((x)>=0 && (x)<RES && (y)>=0 && (y)<RES && (z)>=0 && (z)<RES)? \
    VOXEL((v),(x),(y),(z)):0)
#define Abs(x) ((x)<0?-(x):(x))
#define fAbs(x) ((x)<0.0?-(x):(x))

typedef unsigned char byte;

typedef struct voxel {
  byte i,j,k;
  unsigned short gradient;
} voxel;

typedef struct {
  double dx,dy,dz;
} vector;

typedef struct {
  vector from,up,to,ud,vd;
} observer;

typedef struct {
  int x,y;
} point;

typedef struct {
  signed char dx,dy,dz;
} gradint;

typedef enum {
  AXIS_I,AXIS_J,AXIS_K
} axis_t;

byte *mask,*shell;
unsigned short *gradient;
gradint *gradtable;
int time_elapsed,start_count;
voxel *list;
voxel *xplist,*xmlist,*yplist,*ymlist,*zplist,*zmlist;
int voxcountxp,voxcountxm,voxcountyp,voxcountym,voxcountzp,voxcountzm;
int voxcount;
signed char *difftable1,*difftable2;
signed char *shadetable1,*shadetable2;
int ymin,ymax;
observer obs;
double scale=4.0;
int ymin,ymax;

void init_observer (double phi, double theta) {
  obs.to.dx=-cos (phi)*cos (theta);
  obs.to.dy=-sin (phi);
  obs.to.dz=-cos (phi)*sin (theta);
  obs.from.dx=-obs.to.dx*5.0;
  obs.from.dy=-obs.to.dy*5.0;
  obs.from.dz=-obs.to.dz*5.0;
  obs.up.dx=-sin (phi)*cos (theta);
  obs.up.dy=cos (phi);
  obs.up.dz=-sin (phi)*sin (theta);
  obs.vd.dx=((double) RESY/scale)*obs.up.dx;
  obs.vd.dy=((double) RESY/scale)*obs.up.dy;
  obs.vd.dz=((double) RESY/scale)*obs.up.dz;
  obs.ud.dx=((double) RESX/scale)*(obs.to.dy*obs.up.dz-obs.to.dz*obs.up.dy);
  obs.ud.dy=((double) RESX/scale)*(obs.to.dz*obs.up.dx-obs.to.dx*obs.up.dz);
  obs.ud.dz=((double) RESX/scale)*(obs.to.dx*obs.up.dy-obs.to.dy*obs.up.dx);
}         

point project_vertex (vector vertex) {
  point p;
  vector P;

  P.dx=vertex.dx-obs.from.dx;
  P.dy=vertex.dy-obs.from.dy;
  P.dz=vertex.dz-obs.from.dz;
  p.x=(int)(obs.ud.dx*P.dx+obs.ud.dy*P.dy+obs.ud.dz*P.dz)+RESX/2;
  p.y=RESY/2-(int)(obs.vd.dx*P.dx+obs.vd.dy*P.dy+obs.vd.dz*P.dz);
  return p;
}

void time_counter (void) {
  if (start_count) 
    time_elapsed++;
}

END_OF_FUNCTION (time_counter);

void start_time (void) {
  time_elapsed=0;
  start_count=1;
}

void end_time (void) {
  start_count=0;
}

void init_shader (void) {
  int i,j;  
  double phi,theta;

  difftable1=(signed char *) malloc (256*768);
  difftable2=(signed char *) malloc (256*768);
  for (i=0; i<256; i++)
    for (j=0; j<768; j++) {
      phi=(double)(j-256)/256.0*PI;
      theta=(double)(i)/256.0*2.0*PI;
      difftable1[i+256*j]=(signed char)(63.0*0.5*cos (phi)*(1+cos (theta)));
      difftable2[i+256*j]=(signed char)(63.0*0.5*cos (phi)*(1-cos (theta)));
    }
}

int convert_vector (double dx, double dy, double dz) {        
  double modulus;
  
  modulus=sqrt (dx*dx+dy*dy+dz*dz);
  if (modulus>1e-6) {
    dx/=modulus;
    dy/=modulus;
    dz/=modulus;
    return ((int) (255.0*atan2 (dy,dx)/2.0/PI)+
            256*(int) (255.0*acos (dz)/PI));
  }
  else return 0;
}

gradint convert_gradint (double dx, double dy, double dz) {
  double modulus;
  gradint gradient;

  modulus=dx*dx+dy*dy+dz*dz;
  if (modulus>1e-6) {
    dx/=modulus;            
    dy/=modulus;            
    dz/=modulus;            
    gradient.dx=(signed char) (100.0*dx);
    gradient.dy=(signed char) (100.0*dy);
    gradient.dz=(signed char) (100.0*dz);
  }
  else {
    gradient.dx=0;
    gradient.dy=0;
    gradient.dz=0;
  }
  return gradient;
}

void add_sphere (double xc, double yc, double zc, double r) {
  double r2;
  double x,y,z;
  int i,j,k;

  r2=r*r;
  for (i=0; i<RES; i++) 
    for (j=0; j<RES; j++)
      for (k=0; k<RES; k++) {
        x=(double) i;
        y=(double) j;
        z=(double) k;
        if ((x-xc)*(x-xc)+(y-yc)*(y-yc)+(z-zc)*(z-zc)<r2) {
          VOXEL (mask,i,j,k)=1;
          VOXEL (gradient,i,j,k)=convert_vector (x-xc,y-yc,z-zc);
          VOXEL (gradtable,i,j,k)=convert_gradint (x-xc,y-yc,z-zc);
        }
      }
}

void add_xcylinder (double xc, double yc, double zc, double r, double l) {
  double r2;
  double x,y,z;
  int i,j,k;

  r2=r*r;
  for (i=0; i<RES; i++) 
    for (j=0; j<RES; j++)
      for (k=0; k<RES; k++) {
        x=(double) i;
        y=(double) j;
        z=(double) k;
        if (x>=xc && x<=xc+l && (y-yc)*(y-yc)+(z-zc)*(z-zc)<r2) {
          VOXEL (mask,i,j,k)=1;
          VOXEL (gradient,i,j,k)=convert_vector (0,y-yc,z-zc);
          VOXEL (gradtable,i,j,k)=convert_gradint (0,y-yc,z-zc);
        }
      }
}

void GenerateMask (void) {
  int i,j,k;
  
  mask=(byte *) malloc (RES*RES*RES);
  gradient=(unsigned short *) malloc (RES*RES*RES*sizeof (unsigned short));
  gradtable=(gradint *) malloc (RES*RES*RES*sizeof (gradint));
  for (i=0; i<RES; i++) 
    for (j=0; j<RES; j++)
      for (k=0; k<RES; k++) 
        VOXEL (mask,i,j,k)=0;        
  add_sphere (RES/4,RES/2,RES/2,RES/4);
  add_sphere (RES-RES/4,RES/2,RES/2,RES/4);
  add_xcylinder (RES/4,RES/2,RES/2,RES/4,RES/2);
}

int isshell (byte *vol, int i, int j, int k) {
  int test;
  
  if (VOXEL (vol,i,j,k)!=1) 
    return 0;
  test=CLAMPVOXEL (vol,i+1,j,k)+  
       CLAMPVOXEL (vol,i-1,j,k)+
       CLAMPVOXEL (vol,i,j+1,k)+
       CLAMPVOXEL (vol,i,j-1,k)+
       CLAMPVOXEL (vol,i,j,k+1)+
       CLAMPVOXEL (vol,i,j,k-1);
  return (test!=6);
}

void ExtractShell (void) {
  int i,j,k;

  shell=(byte *) malloc (RES*RES*RES);
  for (i=0; i<RES; i++) 
    for (j=0; j<RES; j++)
      for (k=0; k<RES; k++) {
        if (isshell (mask,i,j,k))
          VOXEL (shell,i,j,k)=1;
        else
          VOXEL (shell,i,j,k)=0;
      }
}

int count (byte *vol) {
  int i,j,k;
  int total=0;

  for (i=0; i<RES; i++) 
    for (j=0; j<RES; j++)
      for (k=0; k<RES; k++) 
        total+=VOXEL (vol,i,j,k);
  return total;
}

void init_palette (void) {
  int i;
  RGB rgb[256];

  for (i=0; i<64; i++) {
    rgb[i].r=rgb[i].g=rgb[i].b=i;
    rgb[i+64].r=i;
    rgb[i+64].g=0;
    rgb[i+64].b=63-i;
    rgb[i+128].g=i;
    rgb[i+128].r=rgb[i+128].b=0;
  }
  set_pallete (rgb);
}

#define CREATE(a1,a2,a3,list,voxcount,start,end,incr,d1,d2,d3,dir) \
  number=0; \
  for (a1=start; a1 end; a1 incr) \
    for (a2=start; a2 end; a2 incr) \
      for (a3=start; a3 end; a3 incr) \
        if (VOXEL (shell,i,j,k)==1) { \
          if (!(VOXEL (gradtable,i,j,k).d1 dir 0 && \
              Abs (VOXEL (gradtable,i,j,k).d1)> \
              Abs (VOXEL (gradtable,i,j,k).d2) && \
              Abs (VOXEL (gradtable,i,j,k).d1)> \
              Abs (VOXEL (gradtable,i,j,k).d3))) \
          { \
            list[number].i=i; \
            list[number].j=j; \
            list[number].k=k; \
            list[number++].gradient=VOXEL (gradient,i,j,k); \
          } \
        } \
  voxcount=number; \
  ;

#define CREATEUP(a1,a2,a3,list,voxcount,d1,d2,d3,dir) \
  CREATE (a1,a2,a3,list,voxcount,0,<RES,++,d1,d2,d3,dir)

#define CREATEDOWN(a1,a2,a3,list,voxcount,d1,d2,d3,dir) \
  CREATE (a1,a2,a3,list,voxcount,RES-1,>=0,--,d1,d2,d3,dir)

void BuildShell (void) {
  int i,j,k;  
  int number;

  voxcount=count (shell);
  printf ("Area=%d\n",voxcount);

  zplist=(voxel *) malloc (voxcount*sizeof (voxel));  
  zmlist=(voxel *) malloc (voxcount*sizeof (voxel));  
  yplist=(voxel *) malloc (voxcount*sizeof (voxel));  
  ymlist=(voxel *) malloc (voxcount*sizeof (voxel));  
  xplist=(voxel *) malloc (voxcount*sizeof (voxel));  
  xmlist=(voxel *) malloc (voxcount*sizeof (voxel));  

  CREATEUP (k,j,i,zplist,voxcountzp,dz,dx,dy,>);
  CREATEDOWN (k,j,i,zmlist,voxcountzm,dz,dx,dy,<);
  CREATEUP (j,k,i,yplist,voxcountyp,dy,dz,dx,>);
  CREATEDOWN (j,k,i,ymlist,voxcountym,dy,dz,dx,<);
  CREATEUP (i,j,k,xplist,voxcountxp,dx,dz,dy,>);
  CREATEDOWN (i,j,k,xmlist,voxcountxm,dx,dz,dy,<);
}

void raster (int *table, int x1, int y1, int x2, int y2) {
  int dx,dy;
  int x,y;
  int step,start;
  int number=0;
  int auxtable[200];
  int i;

  dx=Abs (x2-x1);
  dy=Abs (y2-y1);
  if (dy==dx && dx==0) {
    for (i=0; i<RES; i++) {
      table[i]=0;
    }
    return;
  }
  if (dy>dx) {
    if (y2>y1) {
      step=((x2-x1)<<16)/(y2-y1);
      start=(x1<<16)+step/2;
      for (y=y1; y<=y2; y++) {
        auxtable[number++]=((start>>16)-x1)+(y-y1)*RESX;
        start+=step;
      }
    }
    else {
      step=((x2-x1)<<16)/(y2-y1);
      start=(x1<<16)-step/2;
      for (y=y1; y>=y2; y--) {
        auxtable[number++]=((start>>16)-x1)+(y-y1)*RESX;
        start-=step;
      }
    }
  }
  else {
    if (x2>x1) {
      step=((y2-y1)<<16)/(x2-x1);
      start=(y1<<16)+step/2;
      for (x=x1; x<=x2; x++) {
        auxtable[number++]=(x-x1)+((start>>16)-y1)*RESX;
        start+=step;
      }
    }
    else {
      step=((y2-y1)<<16)/(x2-x1);
      start=(y1<<16)-step/2;
      for (x=x1; x>=x2; x--) {
        auxtable[number++]=(x-x1)+((start>>16)-y1)*RESX;
        start-=step;
      }
    }
  }
  for (i=0; i<RES; i++) {
    table[i]=auxtable[(int)((double)i*(double)number/(double)RES)];
  }
}

inline void fixm (BITMAP *buffer, BITMAP *zbuffer, byte cropvalue, int px) {
  int i,j;
  byte *start,*zstart;
  int istart,iend;
  int jstart,jend;
  int runstart,runend;
  int run;
  int runlen;
  int step,value;

  jstart=ymin;    
  jend=ymax;

  if (jstart<0) jstart=0;
  if (jend>=RESY) jend=RESY-1;

  for (j=jstart; j<=jend; j++) {
    start=((byte *)buffer->dat)+j*RESX;
    zstart=((byte *)zbuffer->dat)+j*RESX;
    
    for (i=0; i<RESX && zstart[i]==cropvalue; i++);
    istart=i;      
    if (istart==RESX) 
      continue;
    
    for (i=RESX-1; i>=0 && zstart[i]==cropvalue; i--);
    iend=i;      
    
    for (i=istart+1; i<iend; i++)
      if (((int)zstart[i]-(int)zstart[i-1])<-THRESHOLD) {
        if (((int)zstart[i+1]-(int)zstart[i-1])<-THRESHOLD) {
          runstart=i-1;
          do {
            for (runend=i+1; 
                 runend<iend && 
                 (int)zstart[runend]-(int)zstart[runstart]<-THRESHOLD;
                 runend++);
            runlen=runend-runstart;
            if (runlen>=RUNLENGTH) {
              start[runstart+runlen/2]=start[runstart+runlen/2-RESX];
              zstart[runstart+runlen/2]=zstart[runstart];
            }
          } while (runlen>=RUNLENGTH);
          step=((start[runend]-start[runstart])<<16)/(runend-runstart);
          value=start[runstart]<<16;
          for (run=runstart; run<runend; run++) {
            start[run]=value>>16;
            zstart[run]=zstart[runstart];
            value+=step;
          }
          i=runend;
        }
        else {
          start[i]=(start[i-1]+start[i+1])/2;
          zstart[i]=zstart[i-1];
        }
      }  
  }

}

inline void fixp (BITMAP *buffer, BITMAP *zbuffer, byte cropvalue, int px) {
  int i,j;
  byte *start,*zstart;
  int istart,iend;
  int jstart,jend;
  int runstart,runend;
  int run;
  int runlen;
  int step,value;

  jstart=ymin;    
  jend=ymax;

  if (jstart<0) jstart=0;
  if (jend>=RESY) jend=RESY-1;

  for (j=jstart; j<=jend; j++) {
    start=((byte *)buffer->dat)+j*RESX;
    zstart=((byte *)zbuffer->dat)+j*RESX;
    
    for (i=0; i<RESX && zstart[i]==cropvalue; i++);
    istart=i;      
    if (istart==RESX) 
      continue;
    
    for (i=RESX-1; i>=0 && zstart[i]==cropvalue; i--);
    iend=i;      
    
    for (i=istart+1; i<=iend; i++)
      if (((int)zstart[i]-(int)zstart[i-1])>THRESHOLD) {
        if (((int)zstart[i+1]-(int)zstart[i-1])>THRESHOLD) {
          runstart=i-1;
          do {
            for (runend=i+1; 
                 runend<iend && 
                 (int)zstart[runend]-(int)zstart[runstart]>THRESHOLD;
                 runend++);
            runlen=runend-runstart;
            if (runlen>=RUNLENGTH) {
              start[runstart+runlen/2]=start[runstart+runlen/2-RESX];
              zstart[runstart+runlen/2]=zstart[runstart];
            }
          } while (runlen>=RUNLENGTH);
          step=((start[runend]-start[runstart])<<16)/(runend-runstart);
          value=start[runstart]<<16;
          for (run=runstart; run<runend; run++) {
            start[run]=value>>16;
            zstart[run]=zstart[runstart];
            value+=step;
          }
          i=runend;
        }
        else {
          start[i]=(start[i-1]+start[i+1])/2;
          zstart[i]=zstart[i-1];
        }
      }  
  }

}

#define DRAW(comp,axis) \
  for (i=0; i<voxcount; i++) { \
    addr=tablex[list[i].i]+tabley[list[i].j]+tablez[list[i].k];\
    if (zstart[addr] comp list[i].axis) { \
      zstart[addr]=list[i].axis; \
      shade= \
        *(shadetable1+list[i].gradient)+ \
        *(shadetable2+list[i].gradient); \
      start[addr]=shade<0?0:shade; \
      ypos=(signed int) addr/RESX+p0.y; \
      if (ypos>ymax) ymax=ymin; \
      if (ypos<ymin) ymin=ypos; \
    } \
  }

int convert_light (double lphi, double ltheta) {
  double nphi,ntheta;    
    
  nphi=lphi;
  ntheta=ltheta;
  if (nphi>PI) {
    nphi=2.0*PI-nphi;
    ntheta=PI+ntheta;
    if (ntheta>2.0*PI)
      ntheta-=2.0*PI;
  }
  return (int)(255.0*ntheta/2.0/PI)+256*(int)(255.0*nphi/PI);
}

void Interactive (void) {
  BITMAP *buffer;
  BITMAP *zbuffer;
  double phi=0.0,theta=0.0;
  double lphi=0.0,ltheta=0.0;
  double ox,oy,oz;
  double mx,my,mz;
  char c;
  vector v0,vx,vy,vz;
  point p0,px,py,pz;
  int tablex[RES],tabley[RES],tablez[RES];
  int total_time=0,total_frames=0;
  byte *start,*zstart;
  int i,addr;
  signed char shade;
  int ofs1,ofs2,light;
  int ypos;

  allegro_init ();
  install_timer ();
  LOCK_VARIABLE (start_count);
  LOCK_VARIABLE (time_elapsed);
  LOCK_FUNCTION (time_counter);
  install_int (time_counter,1); 
  start_count=0;
  set_gfx_mode (GFX_VGA,320,200,320,200);
  buffer=create_bitmap (RESX,RESY);
  zbuffer=create_bitmap (RESX,RESY);
  init_palette ();

  v0.dx=v0.dy=v0.dz=-1.0;
  vx.dx=1.0; vx.dy=vx.dz=-1.0;
  vy.dy=1.0; vy.dx=vy.dz=-1.0;
  vz.dz=1.0; vz.dx=vz.dy=-1.0;
    
  do {
    start_time ();
    
    clear (buffer);
    init_observer (phi,theta);
    p0=project_vertex (v0);
    px=project_vertex (vx);
    py=project_vertex (vy);
    pz=project_vertex (vz);

    raster (tablex,p0.x,p0.y,px.x,px.y);
    raster (tabley,p0.x,p0.y,py.x,py.y);
    raster (tablez,p0.x,p0.y,pz.x,pz.y);

    light=convert_light (lphi,ltheta);

    ofs1=-light;
    ofs2=(light & 0xff00)-(light & 0xff);
    shadetable1=difftable1+ofs1+256*256;
    shadetable2=difftable2+ofs2+256*256;
    
    start=((byte *)buffer->dat)+p0.x+p0.y*RESX;
    zstart=((byte *)zbuffer->dat)+p0.x+p0.y*RESX;

    ox=obs.to.dx;
    mx=fAbs (ox);
    oy=obs.to.dy;
    my=fAbs (oy);
    oz=obs.to.dz;
    mz=fAbs (oz);

    ymin=RESY-1;
    ymax=0;

    if (mz>my && mz>mx) {
      if (oz>0.0) {    
        clear_to_color (zbuffer,255);
        list=zplist;
        voxcount=voxcountzp;
        DRAW (>,k);
        fixp (buffer,zbuffer,255,p0.x);
      }
      else {
        clear_to_color (zbuffer,0);
        list=zmlist;
        voxcount=voxcountzm;
        DRAW (<,k);
        fixm (buffer,zbuffer,0,p0.x);
      }
    }
    else if (my>mx) {
      if (oy>0.0) {    
        clear_to_color (zbuffer,255);
        list=yplist;
        voxcount=voxcountzp;
        DRAW (>,j);
        fixp (buffer,zbuffer,255,p0.x);
      }
      else {
        clear_to_color (zbuffer,0);
        list=ymlist;
        voxcount=voxcountym;
        DRAW (<,j);
        fixm (buffer,zbuffer,0,p0.x);
      }
    }
    else {
      if (ox>0.0) {    
        clear_to_color (zbuffer,255);
        list=xplist;
        voxcount=voxcountxp;
        DRAW (>,i);
        fixp (buffer,zbuffer,255,p0.x);
      }
      else {
        clear_to_color (zbuffer,0);
        list=xmlist;
        voxcount=voxcountxm;
        DRAW (<,i);
        fixm (buffer,zbuffer,0,p0.x);
      }
    }

    blit (buffer,screen,0,0,0,0,RESX,RESY);
    end_time ();

    switch (c=toupper (getch ())) {
      case 'Q': 
        phi+=0.1;
        break;
      case 'A': 
        phi-=0.1;
        break;
      case 'O': 
        theta+=0.1;
        break;
      case 'P': 
        theta-=0.1;
        break;
      case 'Z':
        ltheta+=0.1;
        break;
      case 'X':
        ltheta-=0.1;
        break;
      case 'I':
        lphi+=0.1;
        break;
      case 'J':
        lphi-=0.1;
        break;
      case '-':
        scale+=0.1;
        break;
      case '+':
        scale-=0.1;
        break;
    }
    
    ltheta=ltheta>2.0*PI?ltheta-2.0*PI:ltheta;
    ltheta=ltheta<0.0?ltheta+2.0*PI:ltheta;
    lphi=lphi>2.0*PI?lphi-2.0*PI:lphi;
    lphi=lphi<0.0?lphi+2.0*PI:lphi;

    total_time+=time_elapsed;
    total_frames++;

  } while (c!=27);

  allegro_exit ();
  printf ("t  : %f ms\n",(double)total_time/(double)total_frames);
  printf ("FPS: %f \n",(double)total_frames/(double)(total_time)/1e-3);
  printf ("voxcountxp=%d\n",voxcountxp);
  printf ("voxcountxm=%d\n",voxcountxm);
  printf ("voxcountyp=%d\n",voxcountyp);
  printf ("voxcountym=%d\n",voxcountym);
  printf ("voxcountzp=%d\n",voxcountzp);
  printf ("voxcountzm=%d\n",voxcountzm);
}

int main (void) {
  clrscr ();
  printf ("RBVV 1.0\n");
  printf ("Initializing shader...\n");
  init_shader ();
  printf ("Generating volume...\n");
  GenerateMask ();  
  printf ("Extracting shell...\n");
  ExtractShell ();
  free (mask);
  printf ("Building shell...\n");
  BuildShell ();
  printf ("Press any key to render. ");
  fflush (stdout);
  getch ();
  Interactive ();
  return 0;
}
