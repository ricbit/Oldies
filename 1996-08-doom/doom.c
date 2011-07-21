/* RB DOOM 2.0 */
/* by Ricardo Bittencourt */

#include <stdio.h>
#include <ctype.h>
#include <conio.h>
#include <malloc.h>
#include <allegro.h>
#include <math.h>
#include "doom.h"
    
#define EPS 1e-6

typedef struct {
  vector from,up,to,ud,vd;
} observer;

observer obs;
vertex_list *vlist=NULL;
vector *varray,*vnormal;
point *parray;
int vnumber;
poly_list *plist=NULL;
BITMAP *framebuffer;
int *edgemin,*edgeminv,*edgemax,*edgemaxv;
int tick_enabled,tick_counter,frame_counter,tick_real_counter;

void insert_vertex (vector vertex) {
  vertex_list *p;
  if (vlist==NULL) {
    vlist=(vertex_list *) malloc (sizeof (vertex_list));
    p=vlist;
  }
  else {
    p=vlist;
    while (p->next!=NULL)
      p=p->next;
    p->next=(vertex_list *) malloc (sizeof (vertex_list));
    p=p->next;
  }
  p->next=NULL;
  p->vertex=vertex;
}

void convert_vertex (void) {
  vertex_list *p=vlist;
  int n=0;

  printf ("Converting vertex...\n");
  while (p!=NULL) {
    printf ("%f %f %f\n",p->vertex.dx,p->vertex.dy,p->vertex.dz);
    p=p->next;
    n++;
  }
  vnumber=n;
  varray=(vector *) malloc (vnumber*sizeof (vector));
  vnormal=(vector *) malloc (vnumber*sizeof (vector));
  parray=(point *) malloc (vnumber*sizeof (point));
  n=0;
  p=vlist;
  while (p!=NULL) {
    varray[n]=p->vertex;
    p=p->next;
    n++;
  }
}

poly adjust_poly (poly t) {
  vector lineA,lineB;    
  double module;
  poly p;

  printf ("%d %d %d -> ",t.a,t.b,t.c);
  lineA.dx=varray[t.c].dx-varray[t.a].dx;
  lineA.dy=varray[t.c].dy-varray[t.a].dy;
  lineA.dz=varray[t.c].dz-varray[t.a].dz;
  lineB.dx=varray[t.b].dx-varray[t.a].dx;
  lineB.dy=varray[t.b].dy-varray[t.a].dy;
  lineB.dz=varray[t.b].dz-varray[t.a].dz;
  t.normal.dx=lineA.dy*lineB.dz-lineA.dz*lineB.dy;
  t.normal.dy=lineA.dz*lineB.dx-lineA.dx*lineB.dz;
  t.normal.dz=lineA.dx*lineB.dy-lineA.dy*lineB.dx;
  module=1/sqrt (t.normal.dx*t.normal.dx+
                 t.normal.dy*t.normal.dy+
                 t.normal.dz*t.normal.dz);
  t.normal.dx*=module;
  t.normal.dy*=module;
  t.normal.dz*=module;
  p=t;
  p.pa=t.normal.dx;
  p.pb=t.normal.dy;
  p.pc=t.normal.dz;
  p.pd=-(p.pa*varray[t.a].dx+
         p.pb*varray[t.a].dy+
         p.pc*varray[t.a].dz);
/*  printf ("%f %f %f %f=0\n",p.pa,p.pb,p.pc,p.pd);*/
  return p;
}

vector intersect (double pa, double pb, double pc, double pd,
                  vector va, vector vb)
{
  vector p;
  double t;

  t=(pa*va.dx+pb*va.dy+pc*va.dz+pd)/
    (pa*va.dx+pb*va.dy+pc*va.dz-pa*vb.dx-pb*vb.dy-pc*vb.dz);
  p.dx=va.dx+t*(vb.dx-va.dx);
  p.dy=va.dy+t*(vb.dy-va.dy);
  p.dz=va.dz+t*(vb.dz-va.dz);
  return p;
}

void resize (int newsize) {
  vector *newvarray,*newvnormal;        
  point *newparray;
  int i;

  newvarray=(vector *) malloc ((newsize)*sizeof (vector));
  newvnormal=(vector *) malloc ((newsize)*sizeof (vector));
  newparray=(point *) malloc ((newsize)*sizeof (point));
  for (i=0; i<vnumber; i++) {
    newvarray[i]=varray[i];
  }
  varray=newvarray;
  vnormal=newvnormal;
  parray=newparray;
}

void insert_poly (poly t) {
  poly_list *p;
  poly a=adjust_poly (t);
  int inserted=0,split;

  if (a.a==a.b || a.a==a.c || a.b==a.c) {
    printf ("bugao! tem ponto igual\n");
    exit (1);
  }
  if (plist==NULL) {
    plist=(poly_list *) malloc (sizeof (poly_list));
    p=plist;
  }
  else {
    p=plist;
    do {
      double posa,posb,posc;
      posa=p->t.pa*varray[a.a].dx+p->t.pb*varray[a.a].dy+
           p->t.pc*varray[a.a].dz+p->t.pd;
      posb=p->t.pa*varray[a.b].dx+p->t.pb*varray[a.b].dy+
           p->t.pc*varray[a.b].dz+p->t.pd;
      posc=p->t.pa*varray[a.c].dx+p->t.pb*varray[a.c].dy+
           p->t.pc*varray[a.c].dz+p->t.pd;
      split=1;
      if (posa>=-EPS && posb>=-EPS && posc>=-EPS) {
        if (p->front==NULL) {
          p->front=(poly_list *) malloc (sizeof (poly_list));
          inserted=1;
        }
        p=p->front;
        split=0;
        printf ("F");
      }
      if (posa<=EPS && posb<=EPS && posc<=EPS && !inserted) {  
        if (p->back==NULL) {        
          p->back=(poly_list *) malloc (sizeof (poly_list));
          inserted=1;
        }
        p=p->back;
        split=0;
        printf ("B");
      }
      if (posa>=-EPS && posa<=EPS && split) {
        poly t1,t2;
        vector vbc;
        printf ("\ndeu bug na cena -> splitando caso a2\n");
        printf ("a,b,c : %f,%f,%f\n",posa,posb,posc);
        vbc=intersect (p->t.pa,p->t.pb,p->t.pc,p->t.pd,
                       varray[a.b],varray[a.c]);
        resize (vnumber+1);
        varray[vnumber]=vbc;
        vnumber++;
        t1.a=a.a; t1.b=a.b; t1.c=vnumber;
        t2.a=a.a; t2.b=vnumber; t2.c=a.c;
        insert_poly (t1);
        insert_poly (t2);
        return;
      }
      if (posb>=-EPS && posb<=EPS && split) {
        printf ("deu bug na cena -> nao sei splitar ainda * caso b2\n");
        printf ("a,b,c : %f,%f,%f\n",posa,posb,posc);
        exit (1);
      }
      if (posc>=-EPS && posc<=EPS && split) {
        printf ("deu bug na cena -> nao sei splitar ainda * caso c2\n");
        printf ("a,b,c : %f,%f,%f\n",posa,posb,posc);
        exit (1);
      }
      if (split) {
        int v1,v2,v3;
        vector vi12,vi13;
        poly t1,t2,t3;

        printf ("\ndeu bug na cena -> splitando caso 3\n");
        printf ("a,b,c : %f,%f,%f\n",posa,posb,posc);
        if (posa*posb<0.0 && posa*posc<0.0) {
          printf ("posa\n");
          v1=a.a;
          v2=a.b;
          v3=a.c;
        }
        else if (posa*posb<0.0 && posb*posc<0.0) {
          printf ("posb\n");
          v1=a.b;
          v2=a.c;
          v3=a.a;
        }
        else {
          printf ("posc\n");
          v1=a.c;
          v2=a.a;
          v3=a.b;
        }
        vi12=intersect (p->t.pa,p->t.pb,p->t.pc,p->t.pd,
                        varray[v1],varray[v2]);
        vi13=intersect (p->t.pa,p->t.pb,p->t.pc,p->t.pd,
                        varray[v1],varray[v3]);
        resize (vnumber+2);
        varray[vnumber]=vi12;
        varray[vnumber+1]=vi13;
        t1.a=v1; t1.b=vnumber; t1.c=vnumber+1;
        t2.a=vnumber; t2.b=v2; t2.c=v3;
        t3.a=vnumber+1; t3.b=vnumber; t3.c=v3;
        vnumber+=2;
        getch ();
        insert_poly (t1);
        insert_poly (t2);
        insert_poly (t3);
        return;        
      }
    } while (!inserted);
  }
  p->front=NULL;
  p->back=NULL;
  p->t=a;
  printf ("\n");
}

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
  obs.vd.dx=((double) RESY)*obs.up.dx;
  obs.vd.dy=((double) RESY)*obs.up.dy;
  obs.vd.dz=((double) RESY)*obs.up.dz;
  obs.ud.dx=((double) RESX)*(obs.to.dy*obs.up.dz-obs.to.dz*obs.up.dy);
  obs.ud.dy=((double) RESX)*(obs.to.dz*obs.up.dx-obs.to.dx*obs.up.dz);
  obs.ud.dz=((double) RESX)*(obs.to.dx*obs.up.dy-obs.to.dy*obs.up.dx);
}         

point project_vertex (vector vertex) {
  vector R,K;
  double t;
  point p;

  R.dx=vertex.dx-obs.from.dx;
  R.dy=vertex.dy-obs.from.dy;
  R.dz=vertex.dz-obs.from.dz;
  t=R.dx*obs.to.dx+R.dy*obs.to.dy+R.dz*obs.to.dz;
  if (t<=0.0) return p;
  t=1/t;
  K.dx=R.dx*t-obs.to.dx;
  K.dy=R.dy*t-obs.to.dy;
  K.dz=R.dz*t-obs.to.dz;
  p.x=(int)(K.dx*obs.ud.dx+K.dy*obs.ud.dy+K.dz*obs.ud.dz)+RESX/2;
  p.y=RESY/2-(int)(K.dx*obs.vd.dx+K.dy*obs.vd.dy+K.dz*obs.vd.dz);
  return p;
}

void project_all (void) {
  int i;
   
  for (i=0; i<vnumber; i++)
    parray[i]=project_vertex (varray[i]);
}

void red_line (int x1, int y1, int x2, int y2) {
  int dx,dy;
  dx=x2-x1;
  dy=y2-y1;
  if (abs (dx)>abs (dy)) {
    /* linha horizontal */
    int startx,stopx,stepy,actualy;
    if (dx==0) return;
    if (dx>0) {
      startx=x1;
      stopx=x2;
      actualy=y1<<16;
      stepy=(dy<<16)/dx;
    }
    else {
      startx=x2;
      stopx=x1;
      actualy=y2<<16;
      stepy=((-dy)<<16)/(-dx);
    }
    do {
      putpixel (framebuffer,startx,actualy>>16,127);
      actualy+=stepy;
    } while (++startx!=stopx);
  }
  else {
    /* linha vertical */
    int starty,stopy,stepx,actualx;
    if (dy==0) return;
    if (dy>0) {
      starty=y1;
      stopy=y2;
      actualx=x1<<16;
      stepx=(dx<<16)/dy;
    }
    else {
      starty=y2;
      stopy=y1;
      actualx=x2<<16;
      stepx=((-dx)<<16)/(-dy);
    }
    do {
      putpixel (framebuffer,actualx>>16,starty,127);
      actualx+=stepx;
    } while (++starty!=stopy);
  }
}

inline void raster (int x1, int y1, int x2, int y2, int v1, int v2) {
  int dy;

  dy=y1-y2;
  if (dy>0) {
    int starty,stepx,actualx,value,stopy,startv,stepv;

    actualx=x2<<16;
    starty=y2;
    stopy=y1<RESY?y1:RESY-1;
    startv=v2<<16;
    stepx=((x1-x2)<<16)/dy;
    stepv=((v1-v2)<<16)/dy;
    if (starty<0) {
      if (stopy<0) return;
        actualx+=-starty*stepx;
        startv+=-starty*stepv;
      starty=0;
    }
    do {
      value=actualx>>16;
      if (edgemin[starty]>value) {
        edgemin[starty]=value;
        edgeminv[starty]=startv>>16;
      }
      if (edgemax[starty]<value) {
        edgemax[starty]=value;
        edgemaxv[starty]=startv>>16;
      }
      actualx+=stepx;
      startv+=stepv;
    } while (++starty<=stopy);
  }
}

inline void gouraud_triangle (int x1, int y1, int x2, int y2, int x3, int y3, 
                           int a, int b, int c) {
  int xu,yu,xl,yl,xm,ym,xmax;  
  int i,u,l,m,j;  
  int du,dm,dl;
  int startv,stepv;
  unsigned char *pixel,*pixelend;

  if (y1>=y2 && y1>=y3) {
    xu=x1; yu=y1; u=a;
    if (y2>y3) {
      xm=x2; ym=y2; m=b;
      xl=x3; yl=y3; l=c;
    }
    else {
      xm=x3; ym=y3; m=c;
      xl=x2; yl=y2; l=b;
    }
  }
  else if (y2>=y1 && y2>=y3) {
    xu=x2; yu=y2; u=b;
    if (y1>y3) {
      xm=x1; ym=y1; m=a;
      xl=x3; yl=y3; l=c;
    }
    else {
      xm=x3; ym=y3; m=c;
      xl=x1; yl=y1; l=a;
    }
  }
  else {
    xu=x3; yu=y3; u=c;
    if (y1>y2) {
      xm=x1; ym=y1; m=a;
      xl=x2; yl=y2; l=b;
    }
    else {
      xm=x2; ym=y2; m=b;
      xl=x1; yl=y1; l=a;
    }
  }
  for (i=yl; i<=yu; i++) {  
    edgemin[i]=10*RESX;
    edgemax[i]=-10*RESX;
  }
  du=(int) (-63.0* (obs.to.dx*vnormal[u].dx+
     obs.to.dy*vnormal[u].dy+
     obs.to.dz*vnormal[u].dz));
  dm=(int) (-63.0*(obs.to.dx*vnormal[m].dx+
     obs.to.dy*vnormal[m].dy+
     obs.to.dz*vnormal[m].dz));
  dl=(int) (-63.0*(obs.to.dx*vnormal[l].dx+
     obs.to.dy*vnormal[l].dy+
     obs.to.dz*vnormal[l].dz));
  du=du<0?0:du;
  dm=dm<0?0:dm;
  dl=dl<0?0:dl;
  raster (xu,yu,xm,ym,du,dm);
  raster (xu,yu,xl,yl,du,dl);
  raster (xm,ym,xl,yl,dm,dl);
  yl=yl<0?0:yl;
  yu=yu>=RESY?RESY-1:yu;
    for (i=yl; i<yu; i++) {
      startv=edgeminv[i]<<16;                
      if ((edgemax[i]-edgemin[i])>0) {
        stepv=((edgemaxv[i]-edgeminv[i])<<16)/(edgemax[i]-edgemin[i]);
        j=edgemin[i];
        xmax=(edgemax[i]<RESX?edgemax[i]:RESX-1);
        if (j<0) {
          startv+=-j*stepv;
          j=0;
        }
        pixel=framebuffer->dat+j+i*RESX;
        pixelend=pixel+(xmax-j);
        for (; pixel<=pixelend; ) {
          *pixel++=startv>>16;
          startv+=stepv;
        }
      }
    }
}

void draw_one (poly_list *p) {
    gouraud_triangle (parray[p->t.a].x,parray[p->t.a].y,
              parray[p->t.b].x,parray[p->t.b].y,
              parray[p->t.c].x,parray[p->t.c].y,p->t.a,p->t.b,p->t.c);
    if (redlines_enabled) {
      red_line (parray[p->t.a].x,parray[p->t.a].y,
            parray[p->t.b].x,parray[p->t.b].y);
      red_line (parray[p->t.b].x,parray[p->t.b].y,
            parray[p->t.c].x,parray[p->t.c].y);
      red_line (parray[p->t.c].x,parray[p->t.c].y,
            parray[p->t.a].x,parray[p->t.a].y);
    }
}

void draw_all (poly_list *p) {
  double n;  

  if (p==NULL) return;
  n=p->t.pa*obs.from.dx+p->t.pb*obs.from.dy+p->t.pc*obs.from.dz+p->t.pd;
  if (n<0.0) {
    draw_all (p->front);
    draw_one (p);
    draw_all (p->back);
  }
  else {
    draw_all (p->back);
    draw_one (p);
    draw_all (p->front);
  }
}

void mainloop (void) {
  char c; 
  double phi=0.0,theta=0.0;

  do {
    tick_enabled=1;
    init_observer (phi,theta);
    project_all ();
    clear (framebuffer);
    draw_all (plist);
    tick_enabled=2;
    vsync ();
    blit (framebuffer,screen,0,0,0,0,RESX,RESY);
    tick_enabled=0;
    frame_counter++;
    c=toupper (getch ());
    switch (c) {
      case 'Q': phi+=0.1; break;
      case 'A': phi-=0.1; break;
      case 'O': theta+=0.1; break;
      case 'P': theta-=0.1; break;
    }
  } while (c!=27);
}

void palette_init (void) {
  int i;
  RGB rgb;

  for (i=0; i<64; i++) {
    rgb.r=rgb.g=rgb.b=i;
    set_color (i,&rgb);
    rgb.g=rgb.b=0;
    set_color (i+64,&rgb);
  }
}

void addnormals (poly_list *p, int i) {
  if (p->t.a==i || p->t.b==i || p->t.c==i) {
    vnormal[i].dx+=p->t.normal.dx;
    vnormal[i].dy+=p->t.normal.dy;
    vnormal[i].dz+=p->t.normal.dz;
  }
  if (p->front!=NULL) 
    addnormals (p->front,i);
  if (p->back!=NULL)
    addnormals (p->back,i);
}

void init_normals (void) {
  int i;
  vector vnull;
  double module;

  vnull.dx=vnull.dy=vnull.dz=0;
  for (i=0; i<vnumber; i++) {
    vnormal[i]=vnull;
    addnormals (plist,i);
    if (vnormal[i].dx==0.0 && vnormal[i].dy==0.0 && vnormal[i].dz==0.0)
      module=1.0;
    else
      module=1.0/sqrt (vnormal[i].dx*vnormal[i].dx+
                       vnormal[i].dy*vnormal[i].dy+
                       vnormal[i].dz*vnormal[i].dz);
    vnormal[i].dx*=module;
    vnormal[i].dy*=module;
    vnormal[i].dz*=module;
    printf ("normal %d - %f %f %f\n",i,vnormal[i].dx,
             vnormal[i].dy,vnormal[i].dz);
  }
}

void tick () {
  if (tick_enabled) {
    tick_real_counter++;
    if (tick_enabled==1)
      tick_counter++;
  }
}

int main (int argc, char **argv) {
  extern FILE *yyin;
  printf ("RB Doom 2.0\n");
  printf ("by Ricardo Bittencourt\n");
  yyin=fopen (argv[1],"r"); 
  yyparse ();
  init_normals ();
  edgemin=(int *) malloc (RESY*sizeof (int));
  edgemax=(int *) malloc (RESY*sizeof (int));
  edgeminv=(int *) malloc (RESY*sizeof (int));
  edgemaxv=(int *) malloc (RESY*sizeof (int));
  getch ();
  allegro_init ();
  install_timer ();
  tick_counter=0;
  frame_counter=0;
  tick_real_counter=0;
  install_int (tick,1);
  set_gfx_mode (GFXMODE,RESX,RESY,RESX,RESY);
  framebuffer=create_bitmap (RESX,RESY);
  palette_init ();
  mainloop ();
  remove_timer ();
  allegro_exit ();
  printf ("fps: %f\n",(double) (frame_counter)*1000.0/(double)tick_counter);
  printf ("real fps: %f\n",
          (double) (frame_counter)*1000.0/(double)tick_real_counter);
  return 0;
}
