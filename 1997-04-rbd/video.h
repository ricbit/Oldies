#ifndef __VIDEO_H
#define __VIDEO_H

#include "types.h"

typedef enum {
  AUTODETECT,
  VESA,
  TCLTK
} video_boards;

extern int RESX,RESY;

void install_video (video_boards board);
int video_check_mode (int resx, int resy);
void set_graph_mode (int mode, void (*drawimage)());
void blit (short *buffer);

#endif
