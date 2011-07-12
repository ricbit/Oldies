#include <conio.h>
#include <mem.h>
#include <stdlib.h>
#include <time.h>

#define STARTX          15
#define STARTY          2
#define UPKEY           72
#define DOWNKEY         80
#define LEFTKEY         75
#define RIGHTKEY        77
#define OO              1
#define XX              2

typedef void (*evalfunc)(int,int,int,int,int,int*);

class Board {
public:
  int *pos;
  int max;
  int First,Xmin,Xmax,Ymin,Ymax;
  int Imin,Imax,Jmin,Jmax,Imax4,Jmax4;

  Board (int size);
  void Show (void);
  char Decode (int i, int j);
  int GameOver (void);
  void Update (int pos, int value);
  void TestAll (evalfunc f);
};

class Player {
public:
  int x,y;

  virtual int Process (Board *B)=0;
};

class Human: public Player {
public:
  Human (void);
  virtual int Process (Board *B);
};

class Computer: public Player {
public:
  int side;

  Computer (int s);
  virtual int Process (Board *B);
};

// Global

int Aborted=0;
int gameover=0;
long int count;
int *maxtable=NULL;
Board B(18),B2(18);

// Board class

Board::Board (int size) {
  int i;

  randomize ();
  max=size;
  pos=new int[size*size];
  memset (pos,0,size*size*sizeof (int));
  First=1;
  Xmin=Xmax=random (max);
  Ymin=Ymax=random (max);
  Imin=(Xmin-5<0?0:Xmin-5);
  Jmin=(Ymin-5<0?0:Ymin-5);
  Imax=(Xmax+5>=max?max-1:Xmax+5);
  Jmax=(Ymax+5>=max?max-1:Ymax+5);
  Imax4=(Imax>max-5?max-5:Imax);
  Jmax4=(Jmax>max-5?max-5:Jmax);
  if (maxtable==NULL) {
    maxtable=new int[max];
    for (i=0; i<max; i++)
      maxtable[i]=i*max;
  }
}

void Board::Show (void) {
  int i,j;

  for (i=0; i<max; i++)
    for (j=0; j<max; j++) {
      gotoxy (i*2+STARTX,j+STARTY);
      cprintf ("%c",Decode (i,j));
    }
}

char Board::Decode (int i, int j) {
  switch (pos[i+j*max]) {
    case 0: return '.';
    case OO: return 'O';
    case XX: return 'X';
  }
  return 0;
}

void Check (int p1, int p2, int p3, int p4, int p5, int *pos) {
  if (pos[p1]==pos[p2] && pos[p2]==pos[p3] && pos[p3]==pos[p4] &&
      pos[p4]==pos[p5] && pos[p1]!=0)
    gameover=1;
}

void CountOO (int p1, int p2, int p3, int p4, int p5, int *pos) {
  int c[3];
  c[0]=c[1]=c[2]=0;
  c[pos[p1]]++;
  c[pos[p2]]++;
  c[pos[p3]]++;
  c[pos[p4]]++;
  c[pos[p5]]++;
  if (c[0]==5) return;
  if (c[0]+c[1]==5) {
    switch (c[1]) {
      case 1: count+=1; break;
      case 2: count+=10; break;
      case 3: count+=10000; break;
      case 4: count+=100000; break;
      case 5: count+=1000000; break;
    }
    return;
  }
  if (c[0]+c[2]==5) {
    switch (c[2]) {
      case 1: count-=1; break;
      case 2: count-=10; break;
      case 3: count-=50000; break;
      case 4: count-=500000; break;
      case 5: count-=5000000; break;
    }
    return;
  }
}

void CountXX (int p1, int p2, int p3, int p4, int p5, int *pos) {
  int c[3];
  c[0]=c[1]=c[2]=0;
  c[pos[p1]]++;
  c[pos[p2]]++;
  c[pos[p3]]++;
  c[pos[p4]]++;
  c[pos[p5]]++;
  if (c[0]==5) return;
  if (c[0]+c[2]==5) {
    switch (c[2]) {
      case 1: count+=1; break;
      case 2: count+=10; break;
      case 3: count+=10000; break;
      case 4: count+=100000; break;
      case 5: count+=1000000; break;
    }
    return;
  }
  if (c[0]+c[1]==5) {
    switch (c[1]) {
      case 1: count-=1; break;
      case 2: count-=10; break;
      case 3: count-=50000; break;
      case 4: count-=500000; break;
      case 5: count-=5000000; break;
    }
    return;
  }
}

void Board::TestAll (evalfunc f) {
  int i,j,jscaled;

  // horizontal line
  for (j=Jmin; j<=Jmax; j++) {
    jscaled=maxtable[j];
    for (i=Imin; i<=Imax4; i++)
      f (jscaled+i,jscaled+i+1,jscaled+i+2,jscaled+i+3,jscaled+i+4,pos);
  }

  // vertical line
  for (j=Jmin; j<=Jmax4; j++) {
    jscaled=maxtable[j];
    for (i=Imin; i<=Imax; i++)
      f (jscaled+i,jscaled+i+max,jscaled+i+2*max,jscaled+i+3*max,jscaled+i+4*max,pos);
  }

  // diag\ line
  for (j=Jmin; j<=Jmax4; j++) {
    jscaled=maxtable[j];
    for (i=Imin; i<=Imax4; i++)
      f (jscaled+i,jscaled+i+(max+1),jscaled+i+2*(max+1),jscaled+i+3*(max+1),jscaled+i+4*(max+1),pos);
  }

  // diag/ line
  for (j=Jmin+4; j<=Jmax; j++) {
    jscaled=maxtable[j];
    for (i=Imin; i<=Imax4; i++)
      f (jscaled+i,jscaled+i+(-max+1),jscaled+i+2*(-max+1),jscaled+i+3*(-max+1),jscaled+i+4*(-max+1),pos);
  }

}

int Board::GameOver (void) {
  gameover=0;
  TestAll (Check);
  return gameover;
}

void Board::Update (int p, int value) {
  pos[p]=value;
  if (First) {
    Xmin=p%max;
    Xmax=p%max;
    Ymin=p/max;
    Ymax=p/max;
    First=0;
  }
  else {
    if (p%max<Xmin) Xmin=p%max;
    if (p%max>Xmax) Xmax=p%max;
    if (p/max<Ymin) Ymin=p/max;
    if (p/max>Ymax) Ymax=p/max;
    gotoxy (40,22);
    cprintf ("P %d",p);
  }
  Imin=0;
  Jmin=0;
  Imax=(max+5>=max?max-1:max+5);
  Jmax=(max+5>=max?max-1:max+5);
  Imax4=(Imax>max-5?max-5:Imax);
  Jmax4=(Jmax>max-5?max-5:Jmax);
  gotoxy (p%max*2+STARTX,p/max+STARTY);
  cprintf ("%c",Decode (p%max,p/max));
  gotoxy (1,20);
  cprintf ("Xm %d XM %d Ym %d YM %d",Xmin,Xmax,Ymin,Ymax);
  gotoxy (1,21);
  cprintf ("Im %d IM %d Jm %d JM %d IM4 %d JM4 %d",
           Imin,Imax,Jmin,Jmax,Imax4,Jmax4);
}

// Human class

Human::Human (void) {
  x=y=0;
}

#pragma argsused
int Human::Process (Board *B) {
  char c;

  do {
    gotoxy (x*2+STARTX,y+STARTY);
    c=getch ();
    if (c==0)
      switch (getch ()) {
        case DOWNKEY:
          if (++y>=B->max) y=0;
          break;
        case UPKEY:
          if (--y<0) y=B->max-1;
          break;
        case RIGHTKEY:
          if (++x>=B->max) x=0;
          break;
        case LEFTKEY:
          if (--x<0) x=B->max-1;
          break;
      }
  } while (c!=13 && c!=27 && c!=32);
  if (c==27) Aborted=1;
  return (x+y*B->max);
}

Computer::Computer (int s) {
  x=y=0;
  side=s;
}

int Computer::Process (Board *B) {
  int si,sj,i,j,first,imin,imax,jmin,jmax,jscaled;
  long int smax;

  gotoxy (1,22);
  cprintf ("Pensando...");
  imin=(B->Xmin-2<0?0:B->Xmin-2);
  jmin=(B->Ymin-2<0?0:B->Ymin-2);
  imax=(B->max+2>=B->max?B->max-1:B->max+2);
  jmax=(B->max+2>=B->max?B->max-1:B->max+2);
  gotoxy (60,20);
  cprintf ("Im %d Jm %d IM %d JM %d",imin,jmin,imax,jmax);
  memcpy (B2.pos,B->pos,B->max*B->max*sizeof (int));
  first=1;
  for (j=jmin; j<=jmax; j++) {
    jscaled=maxtable[j];
    for (i=imin; i<=imax; i++)
      if (B2.pos[jscaled+i]==0) {
        count=0;
        B2.pos[jscaled+i]=side;
        if (side==OO)
          B2.TestAll (CountOO);
        else
          B2.TestAll (CountXX);
        if (count>smax || first) {
          smax=count;
          si=i;
          sj=j;
          first=0;
        }
        B2.pos[jscaled+i]=0;
      }
  }
  B2.Show ();
  gotoxy (1,22);
  cprintf ("Pensado ...");
  return (sj*B->max+si);
}

void main (void) {
  Player *POO,*PXX,*player;
  int Actual,Choice;

  clrscr ();
  B.Show ();
  POO=new Human;
  PXX=new Computer (XX);
  Actual=OO;
  do {
    if (Actual==OO) {
      player=POO;
      POO->x=PXX->x;
      POO->y=PXX->y;
    }
    else {
      player=PXX;
      PXX->x=POO->x;
      PXX->y=POO->y;
    }
    do {
      Choice=player->Process (&B);
    } while (B.pos[Choice]!=0 && !Aborted);
    if (!Aborted) {
      B.Update (Choice,Actual);
      Actual=(Actual==OO?XX:OO);
    }
  } while (!B.GameOver () && !Aborted);

}