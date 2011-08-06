#ifndef __VESA_H
#define __VESA_H

void install_vesa (void);
int vesa_check_mode (int resx, int resy);
void vesa_set_graph_mode (int mode, void (*drawimage)());
void vesa_blit (short *buffer);

#endif
