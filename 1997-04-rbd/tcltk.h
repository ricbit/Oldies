#ifndef __TCLTK_H

#include "types.h"

void install_tcltk (void);
int tcltk_check_mode (int resx, int resy);
void tcltk_set_graph_mode (int mode, void (*drawimage)());
void tcltk_blit (short *buffer);

#endif
