#ifndef __CURSOR_H
#define __CURSOR_H

typedef unsigned char byte;

class Cursor {
public:
  int x,y,lx,ly;
  int sizex,sizey;
  byte *buffer;
  int visible;

  Cursor (void);
  void Show (void);
  void Hide (void);
  void Atualize (void);
};

#endif