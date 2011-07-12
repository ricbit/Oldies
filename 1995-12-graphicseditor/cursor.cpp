#include "cursor.h"
#include "mouse.h"
#include "\borlandc\doom\fgraph.h"

Mouse m;

Cursor::Cursor (void) {
  sizex=sizey=4;
  m.Read ();
  x=lx=m.x;
  y=ly=m.y;
  visible=0;
  buffer=new byte[sizex*sizey];
}

void Cursor::Show (void) {
  if (x-1>=0 || y-1>=0 || x-1+sizex<320 || y-1+sizey<200)
    GetShape (x-1,y-1,sizex,sizey,buffer);
  PutPixel (x,y+1,15);
  PutPixel (x,y-1,15);
  PutPixel (x+1,y,15);
  PutPixel (x-1,y,15);
  visible=1;
}

void Cursor::Hide (void) {
  if (visible) {
    if (x-1>=0 || y-1>=0 || x-1+sizex<320 || y-1+sizey<200)
      PutShape (x-1,y-1,sizex,sizey,buffer);
    visible=0;
  }
}

void Cursor::Atualize (void) {
  m.Read ();
  lx=x; ly=y;
  if (m.x!=x || m.y!=y) {
    if (visible) {
      Hide ();
      x=m.x;
      y=m.y;
      Show ();
    } else {
      x=m.x;
      y=m.y;
    }
  }
}

