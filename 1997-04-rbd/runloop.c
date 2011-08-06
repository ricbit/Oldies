#include <stdio.h>
#include <malloc.h>
#include <conio.h>
#include <ctype.h>
#include "runloop.h"
#include "video.h"
#include "graphics.h"
#include "fractal.h"
#include "pentium.h"

void run_loop (void) {
  double phi=0.0,theta=0.0;    
  short *buffer;  
  int *zbuffer;  

  buffer=(short *) calloc (RESX*RESY,sizeof (short));
  zbuffer=(int *) calloc (RESX*RESY,sizeof (int));
  init_engine ();
  init_observer (phi,theta);
  start_time ();
  draw_object (model,buffer,zbuffer);
  end_time ();
  blit (buffer);
  getch ();
}

void test_video (void) {
  short *buffer;
  int size,i;
  
  size=RESX*RESY;
  buffer=(short *) malloc (size*sizeof (short));
  for (i=0; i<size; i++)
    buffer[i]=((i%RESX)%32)+(((i%RESX)>>5)<<6)+((i/RESX)<<11);
  blit (buffer);
}

void landscape_demo (void) {
  short *buffer;
  landscape *land;
  int i,x=0,y=0;  
  char c;

  buffer=(short *) malloc (RESX*RESY*sizeof (short));
  for (i=0; i<RESX*RESY; i++) 
    buffer[i]=0;
  land=generate_landscape (buffer);
  blit (buffer);
  getch();
  init_engine ();
  do {
    for (i=0; i<RESX*RESY; i++) 
      buffer[i]=0;
    draw_landscape (land,buffer,x,y);
    blit (buffer);
    c=toupper (getch ());
    switch (c) {
      case 'Q': y--; if (y<0) y=land->size-1; break;
      case 'A': y++; if (y>=land->size) y=0; break;
      case 'P': x--; if (x<0) x=land->size-1; break;
      case 'O': x++; if (x>=land->size) x=0; break;
    }
  } while (c!=27);
}

