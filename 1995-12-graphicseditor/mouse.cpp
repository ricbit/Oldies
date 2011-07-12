// Mouse.cpp
// Mouse driver for C++
// Written by Ricardo Bittencourt

#include <stdio.h>
#include <stdlib.h>

class Mouse {
public:
  int x,y;

  Mouse (void);
  void Read (void);
  int Left (void);
  int Right (void);
};

Mouse::Mouse (void) {
  unsigned int exist;

  asm {
    mov         ax,0
    int         $33
    mov         exist,ax
  }
  if (exist!=0xffff) {
    printf ("A mouse driver was not found.\n");
    exit (1);
  }
}

void Mouse::Read (void) {
  int rx,ry;

  asm {
    mov         ax,3
    int         $33
    mov         rx,cx
    mov         ry,dx
  }
  x=rx>>1;
  y=ry;
}

int Mouse::Left (void) {
  int t;

  asm {
    mov         ax,3
    int         $33
    mov         t,bx
  }

  return ((t & 1)>0);
}

int Mouse::Right (void) {
  int t;

  asm {
    mov         ax,3
    int         $33
    mov         t,bx
  }

  return ((t & 2)>0);
}

