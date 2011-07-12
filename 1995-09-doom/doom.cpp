#include <dos.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <io.h>
#include <math.h>
#include <conio.h>
#include <iostream.h>
#include <mem.h>
#include "fgraph.h"
#include "fixed.h"

#define PI2      2*3.1415926535
#define TPERSEC  0.1
#define RPERSEC  ((0.001)/PI2*8192.0)
#define UP       72
#define DOWN     80
#define LEFT     75
#define RIGHT    77
#define ALT      56
#define ESC      1
#define RELEASED 128
#define EPS      (ToFixed (0.0001))

/* #define CONTROLLINES */
/* #define WIREFRAME */
#define TEXTURE

typedef unsigned char byte;
typedef int *pint;
typedef struct Wall {
  vector Normal;
  plane Plane;
  pixel P[4];
  byte *Texture,hasFront,hasSame,hasBack,hasOpp;
  Wall *Front,*Same,*Back,*Opp;
  vector V[2];
} Wall;

class Time {
public:
  struct time ti,tf;
  int frames;
  long int total;

  Time (void);
  void Start (void);
  void Stop (void);
  void Show (void);
  void Restart (void);
  double fps (void);
};

long int lastpixel=0,traced=0,frames=0;
int Mult100[256];
int Mult320[256];
int Rejected,ClipX320,ClipX0;
int totalWalls;
int LineBuffer[321];
int BigLine[5000],BigSteps[5000];
pint LookUpLines[200];
pint PrecU,PrecB,PrecV,PrecH;
Wall *WR,InW,OutW,*In,*Out;
void interrupt (*Old9Handler) (...);
vector NewPos;
Time Clock;
unsigned char uk=0,rk=0,lk=0,dk=0,ek=0,ak=0;
fixed *sintable;
byte *Vid;
obs Obs;

void InitWall (Wall *W) {
  W->Front=W->Same=W->Back=W->Opp=NULL;
  W->hasSame=W->hasFront=W->hasBack=W->hasOpp=0;
}

void InitWall (Wall *W, vector *v, plane p, vector n) {
  W->V[0]=v[0];
  W->V[1]=v[1];
  W->Plane=p;
  W->Normal=n;
  W->Front=W->Same=W->Back=W->Opp=NULL;
  W->hasSame=W->hasFront=W->hasBack=W->hasOpp=0;
}

void GlobalError (char *op, char *name) {
  cout << op << name << "\n";
  cout << "Press any key to exit...";
  getch ();
  exit (1);
}

void interrupt New9Handler (...) {
  int v=inp (0x60);
  Old9Handler ();
  switch (v) {
    case UP:                    uk=1; break;
    case DOWN:                  dk=1; break;
    case LEFT:                  lk=1; break;
    case RIGHT:                 rk=1; break;
    case ESC:                   ek=1; break;
    case ALT:                   ak=1; break;
    case RELEASED+UP:           uk=0; break;
    case RELEASED+DOWN:         dk=0; break;
    case RELEASED+LEFT:         lk=0; break;
    case RELEASED+RIGHT:        rk=0; break;
    case RELEASED+ESC:          ek=0; break;
    case RELEASED+ALT:          ak=0; break;
  }
}

void InitKeyboard (void) {
  Old9Handler=getvect (9);
  setvect (9,New9Handler);
}

void RestoreKeyboard (void) {
  setvect (9,Old9Handler);
}

void ClipX (pixel B,pixel *A) {
  int y;
  y=A->y-(A->x*(B.y-A->y)/(B.x-A->x));
  A->y=y;
  A->x=0;
}

void ClippedLine (int x1, int y1, int x2, int y2, int color) {
  if (x1<0 && x2<0) return;
  if (x1>=320 && x2>=320) return;
  if (y1<0 && y2<0) return;
  if (y1>=200 && y2>=200) return;
  if (x1<0) {
    y1=y1+(y2-y1)*(-x1)/(x2-x1);
    x1=0;
  }
  if (x2<0) {
    y2=y1+(y2-y1)*(-x1)/(x2-x1);
    x2=0;
  }
  if (x1>=320) {
    y1=y1+(y2-y1)*(319-x1)/(x2-x1);
    x1=319;
  }
  if (x2>=320) {
    y2=y1+(y2-y1)*(319-x1)/(x2-x1);
    x2=319;
  }
  if (y1<0) {
    x1=x1+(x2-x1)*(-y1)/(y2-y1);
    y1=0;
  }
  if (y2<0) {
    x2=x1+(x2-x1)*(-y1)/(y2-y1);
    y2=0;
  }
  if (y1>=200) {
    x1=x1+(x2-x1)*(200-y1)/(y2-y1);
    y1=200;
  }
  if (y2>=200) {
    x2=x1+(x2-x1)*(200-y1)/(y2-y1);
    y2=200;
  }
  Line (x1,y1,x2,y2,color);

}

Time::Time (void) {
  frames=0;
  total=0;
}

void Time::Start (void) {
  gettime (&ti);
}

void Time::Stop (void) {
  gettime (&tf);
  total+=(long int) (tf.ti_hour-ti.ti_hour)*60*60*100+
         (long int) (tf.ti_min-ti.ti_min)*60*100+
         (long int) (tf.ti_sec-ti.ti_sec)*100+
         (long int) (tf.ti_hund-ti.ti_hund);
  ti=tf;
  frames++;
}

void Time::Restart (void) {
  gettime (&tf);
/*  DiffTime (&tf,&ti,&total); */
  total =(long int) (tf.ti_hour-ti.ti_hour)*60*60*100+
         (long int) (tf.ti_min-ti.ti_min)*60*100+
         (long int) (tf.ti_sec-ti.ti_sec)*100+
         (long int) (tf.ti_hund-ti.ti_hund);
  ti=tf;
  frames++;
}

double Time::fps (void) {
  return ((double)frames/((double)total)/100.0);
}

void Time::Show (void) {
  cout << "Frames per second: " << (double)frames/((double)total/100.0)
       << "\n";
}

void Print (Wall *W) {
  int i;

  for (i=0; i<4; i++)
    cout << ToFloat(W->V[i].dx) << " "
         << ToFloat(W->V[i].dy) << " "
         << ToFloat(W->V[i].dz) << "\n";
}

void Project (Wall *W) {
  pixel *P;
  P=W->P;
  FProject (&Obs,W->V,P);
  FProject (&Obs,W->V+1,P+1);
  P[2].x=P[1].x;
  P[3].x=P[0].x;
  P[2].y=200-P[1].y;
  P[3].y=200-P[0].y;
}

void Draw (Wall *W) {
  pixel Pui,Puf,Pbi,Pbf;
  int x,y,endx,dx,dy,sty,v,i;
  int *pb,*ph,*pu,*lb;
  fixed n;
  fixed d1,d2,da,dinc;
  byte *Tex,*Buf,dac;
  pixel *P;

  P=W->P;
#pragma warn -pia
  if (v=(P[1].x<P[0].x)) {
#pragma warn +pia
    x=P[1].x;
    endx=P[0].x;
    if (LineBuffer[(x<0?0:x)]>endx) return;
  }
  else {
    x=P[0].x;
    endx=P[1].x;
    if (LineBuffer[(x<0?0:x)]>endx) return;
  }
  if (v) {
    Pui=P[1];
    Puf=P[0];
    Pbi=P[2];
    Pbf=P[3];
  }
  else {
    Pui=P[0];
    Puf=P[1];
    Pbi=P[3];
    Pbf=P[2];
  }
  dx=endx-x;
  if (!dx) return;
  if (endx>=320) endx=319;
  if ((v=*(lb=(LineBuffer+endx+1)))==0) v=endx;
  while ((--lb)!=(LineBuffer-1) && *lb) *lb=v;
  DotProduct (&W->Normal,&Obs.T,&n);
//  d1=P[0].dist;
//  d2=P[1].dist;
  d1=Pui.dist;
  d2=Puf.dist;
  da=d1;
  DepthInit (d1,d2,dx,&dinc);
  DepthInc ((ToFixed(1.0)+n>>1)<<4,&da,&dac);
  if (Pui.x>=320) {
    ClipX320=1;
    return;
  }
  if (Pui.x<0)
    if (Puf.x>0) {
      ClipX (Puf,&Pui);
      ClipX (Pbf,&Pbi);
    } else {
      ClipX0=1;
      return;
    }
  PrecYLine (Pui.x,Pui.y,Puf.x,Puf.y,PrecU);
  PrecYLine (Pbi.x,Pbi.y,Pbf.x,Pbf.y,PrecB);
  MappingLine (dx,PrecH);
  pb=PrecB;
  pu=PrecU;
  ph=PrecH;
  if (x<0) {
    ph-=x;
    x=0;
  }
  for (lb=LineBuffer+x; x<=endx; DepthInc (dinc,&da,&dac)) {
    y=*pb++;
    dy=*pu++-y;
    if (!*lb) {
      if (dy<200) {
        *lb++=v;
        PrecV=LookUpLines[dy];
        Buf=Vid+Mult320[y]+(x++);
        Tex=W->Texture+Mult100[*(ph++)];
        BufferMapping (Buf,Tex,++PrecV,dy,dac);
      }
      else {
        if (dy<200) {
          *lb++=v;
          MappingLine (dy,BigLine);
          BigSteps[0]=0;
          for (i=1; i<dy; i++) {
            BigSteps[i]=BigLine[i]-BigLine[i-1];
          }
          sty=(dy-200)/2;
          dy=100+sty;
//          PrecV=LookUpLines[dy]+sty;
//          Buf=Vid+(x++);
//          Tex=Texture+Mult100[*(ph++)]+sty*100/dy;
//          BufferMapping2 (Buf,Tex,PrecV,dy);
//          PrecV=LookUpLines[dy];
          PrecV=BigLine+sty*100/dy;
          Buf=Vid+Mult320[y]+(x++);
          Tex=W->Texture+Mult100[*(ph++)];
          BufferMapping (Buf,Tex,PrecV,dy,dac);
        }
        else {
          x++;
          ph++;
          lb++;
        }
      }
    }
    else {
      x++;
      ph++;
      lb++;
    }
  }
}

void WireFrame (Wall *W) {
  pixel *P;
  P=W->P;
  if (!P[0].Valid || !P[1].Valid) return;
  ClippedLine ((P[0]).x,(P[0]).y,(P[1]).x,(P[1]).y,63);
  ClippedLine ((P[1]).x,(P[1]).y,(P[2]).x,(P[2]).y,53);
  ClippedLine ((P[2]).x,(P[2]).y,(P[3]).x,(P[3]).y,43);
  ClippedLine ((P[3]).x,(P[3]).y,(P[0]).x,(P[0]).y,33);
}

void ReadTexture (Wall *W, char *name) {
  int file;
  if (!(W->Texture=new byte[100*100]))
    GlobalError ("Cannot allocate memory for texture ",name);
  file=open (name,O_RDONLY | O_BINARY);
  if (file==-1)
    GlobalError ("Cannot open file ",name);
  read (file,W->Texture,100*100);
  close (file);
  cout << "Texture " << name << " loaded\n";
}

void TestTexture (Wall *W) {
  PutShape (0,0,100,100,W->Texture);
  PutShape (100,0,100,100,W->Texture);
  PutShape (200,0,100,100,W->Texture);
  PutShape (0,100,100,100,W->Texture);
  PutShape (100,100,100,100,W->Texture);
  PutShape (200,100,100,100,W->Texture);
  getch ();
}

void PrepareLookUpTables (void) {
  int i,j,prev,save;

  cout << "Conjuring daemons...\n";
  for (i=0; i<200; i++) {
    Mult100[i]=i*100;
    Mult320[i]=i*320;
  }
  sintable=new fixed[8192];
  for (i=0; i<8192; i++)
    sintable[i]=ToFixed (sin ((double)i*PI2/8192.0));
  for (i=0; i<200; i++) {
    if (!(LookUpLines[i]=new int[200]))
      GlobalError ("Cannot allocate memory for LookUpTables","");
    MappingLine (i,LookUpLines[i]);
    prev=LookUpLines[i][0];
    if (prev!=0) exit (1);
    for (j=1; j<200; j++) {
      save=LookUpLines[i][j];
      LookUpLines[i][j]-=(prev);
      prev=save;
    }
  }
  if (!(PrecU=new int[5000]) || !(PrecB=new int[5000]) ||
      !(PrecH=new int[1000]))
    GlobalError ("Cannot allocate memory for line buffer","");
}

void LoadWalls (void) {
  int i,j,k,inserted;
  FILE *f;
  float f1,f2,f3,f4;
  vector v;
  Wall X,*P;
  fixed n1,n2;

  cout << "Constructing scene ...\n";
  f=fopen ("walls.txt","r");
  fscanf (f,"%d",&totalWalls);
  WR=NULL;
  for (i=0; i<totalWalls; i++) {
    for (j=0; j<4; j++) {
      fscanf (f,"%f",&f1);
      fscanf (f,"%f",&f2);
      fscanf (f,"%f",&f3);
      Assume (f1,f2,f3,v);
      if (j<3) X.V[j]=v;
    }
    fscanf (f,"%f",&f1);
    fscanf (f,"%f",&f2);
    fscanf (f,"%f",&f3);
    fscanf (f,"%f",&f4);
    Assume (f1,f2,f3,X.Normal);
    AssumePlane (f1,f2,f3,f4,X.Plane);
    if (WR==NULL) {
      WR=new Wall;
      InitWall (WR,X.V,X.Plane,X.Normal);
    } else {
      P=WR;
      inserted=0;
      while (!inserted) {
        CalcPlane (&(P->Plane),&(X.V[0]),&n1);
        CalcPlane (&(P->Plane),&(X.V[1]),&n2);
        if (n1>0 || n2>0) {
          if (P->Front==NULL) {
            P->Front=new Wall;
            InitWall (P->Front,X.V,X.Plane,X.Normal);
            P->hasFront=1;
            inserted=1;
          }
          else {
            P=P->Front;
          }
        }
        else {
          if (n1>-EPS && n1<EPS && n2>-EPS && n2<EPS) {
            if (P->Normal.dx==X.Normal.dx && P->Normal.dz==X.Normal.dz) {
              if (P->Same==NULL) {
                P->Same=new Wall;
                InitWall (P->Same,X.V,X.Plane,X.Normal);
                P->hasSame=1;
                inserted=1;
              }
              else {
                P=P->Same;
              }
            }
            else {
              if (P->Opp==NULL) {
                P->Opp=new Wall;
                InitWall (P->Opp,X.V,X.Plane,X.Normal);
                P->hasOpp=1;
                inserted=1;
              }
              else {
                P=P->Opp;
              }
            }
          }
          else {
            if (P->Back==NULL) {
              P->Back=new Wall;
              InitWall (P->Back,X.V,X.Plane,X.Normal);
              P->hasBack=1;
              inserted=1;
            }
            else {
             P=P->Back;
            }
          }
        }
      }
    }
  }
}

void DrawAll (Wall *W) {
  fixed n,p;
  if (*LineBuffer==319) return;
  traced++;
  CalcPlane (&(W->Plane),&(Obs.F),&n);
  if (n>0) {
    if (W->hasFront) DrawAll (W->Front);
    if (W->hasSame) DrawAll (W->Same);
    Project (W);
    if (W->P[0].Valid && W->P[1].Valid) Draw (W);
    if (W->hasBack) DrawAll (W->Back);
  }
  else {
    if (W->hasBack) DrawAll (W->Back);
    if (W->hasOpp) DrawAll (W->Opp);
    if (W->hasFront) DrawAll (W->Front);
  }
}

int Inside (Wall *W) {
  fixed n;
  Wall *P;

  P=W;
  while (P!=In && P!=Out) {
    CalcPlane (&P->Plane,&NewPos,&n);
    if (n>0)
      P=P->Front;
    else
      P=P->Back;
  }
  return (P==In);
}

void Run (void) {
  int i,Altered=1;
  float totalT,totalR;
//  double Angle=0.0;
  int Angle=0;
  fixed sinAngle,cosAngle;
  Time Speed;
  vector FastT,LongT,Ahead,Left,Right;

//  Assume (-cos (Angle),0,sin (Angle),Right);
//  Assume (cos (Angle),0,-sin (Angle),Left);
  Assume (-1.0,0.0,0.0,Right);
  Assume (1.0,0.0,0.0,Left);
  Speed.Start ();
   do {
    if (Altered) {
      Clock.Start ();
      FSetViewer (&Obs);
      ClearBuffer (Vid);
      Rejected=0;
      ClipX320=0;
      ClipX0=0;
#ifdef TEXTURE
      memset (LineBuffer,0,321*sizeof(int));
      frames++;
      DrawAll (WR);
      lastpixel+=*LineBuffer;
#endif
      FlushBuffer (Vid);
#ifdef CONTROLLINES
      if (Rejected) Line (0,0,319,0,63);
      if (ClipX320) Line (0,1,319,1,53);
      if (ClipX0) Line (0,2,319,2,33);
      Line (0,100,319,100,63);
#endif
#ifdef WIREFRAME
      for (i=0; i<totalWalls; i++)
        W[i].WireFrame ();
#endif
      Clock.Stop ();
      Altered=0;
    }
    Speed.Restart ();
    totalT=(float)(Speed.total)*TPERSEC;
    ScalarProduct (&(Obs.T),ToFixed (totalT),&FastT);
    ScalarProduct (&(Obs.T),ToFixed (totalT)+ToFixed (2.0),&LongT);
    totalR=(float)(Speed.total)*RPERSEC;
    if (uk) {
      AddVector (&(Obs.F),&LongT,&(NewPos));
      if (Inside (WR) && (NewPos=Left, Inside (WR)) &&
          (NewPos=Right, Inside (WR))) {
        AddVector (&(Obs.F),&FastT,&(Obs.F));
        Altered=1;
      }
    }
    if (dk) {
      SubVector (&(Obs.F),&LongT,&(NewPos));
      if (Inside (WR) && (NewPos=Left, Inside (WR)) &&
          (NewPos=Right, Inside (WR))) {
        SubVector (&(Obs.F),&FastT,&(Obs.F));
        Altered=1;
      }
    }
    if (ak) {
      if (lk) {
        AddVector (&(Obs.F),&LongT,&(NewPos));
        if (Inside (WR) && (NewPos=Left, Inside (WR)) &&
             (NewPos=Right, Inside (WR))) {
          AddVector (&(Obs.F),&FastT,&(Obs.F));
          Altered=1;
        }
      }
    }
    else {
      if (lk) {
        Angle+=(int) totalR;
        Angle&=8191;
        sinAngle=sintable[Angle];
        cosAngle=sintable[(Angle+2048)&8191];
        AssumeFixed (sinAngle,0,cosAngle,Obs.T);
        AssumeFixed (-cosAngle,0,sinAngle,Right);
        AssumeFixed (cosAngle,0,-sinAngle,Left);
        Altered=1;
      }
      if (rk) {
        Angle-=(int) totalR;
        if (Angle<0) Angle+=8192;
        sinAngle=sintable[Angle];
        cosAngle=sintable[(Angle+2048)&8191];
        AssumeFixed (sinAngle,0,cosAngle,Obs.T);
        AssumeFixed (-cosAngle,0,sinAngle,Right);
        AssumeFixed (cosAngle,0,-sinAngle,Left);
        Altered=1;
      }
    }
    while (kbhit ()) getch ();
  } while (!ek);
}

void TextureAll (Wall *P) {
  if (P==In || P==Out) return;
  P->Texture=WR->Texture;
  TextureAll (P->Front);
  TextureAll (P->Same);
  TextureAll (P->Opp);
  TextureAll (P->Back);
}

void PrepareWalls (Wall *W) {
  if (W->Front==NULL)
    W->Front=In;
  else
    PrepareWalls (W->Front);
  if (W->Back==NULL)
    W->Back=Out;
  else
    PrepareWalls (W->Back);
  if (W->Same==NULL)
    W->Same=Out;
  else
    PrepareWalls (W->Same);
  if (W->Opp==NULL)
    W->Opp=Out;
  else
    PrepareWalls (W->Opp);
}

void main (void) {
  int i;
  double fps;

  Assume (0.0,0.0,-60.0,Obs.F);
  Assume (0.0,0.0,1.0,Obs.T);
  Assume (0.0,1.0,0.0,Obs.Up);
  Vid=new byte[64000];
  cout << "\nLoading RB Doom ...\n";
  LoadWalls ();
  cout << "Total walls: " << totalWalls << "\n";
  In=&InW;
  Out=&OutW;
  PrepareWalls (WR);
  ReadTexture (WR,"ice.shp");
  TextureAll (WR->Front);
  TextureAll (WR->Same);
  TextureAll (WR->Back);
  PrepareLookUpTables ();
  cout << "Ready... Press any key to start\n";
  getch ();
  InitGraph ();
  for (i=0; i<64; i++)
    SetRGB (i,i,i,i);
  InitKeyboard ();
  Run ();
  RestoreKeyboard ();
  delete Vid;
  CloseGraph ();
  Clock.Show ();
  cout << "Polygons per frame: " << (double)traced/(double)frames << "\n";
  cout << "Average last pixel: "<< (double)lastpixel/(double)frames << "\n";
}