// RBRT 1.0
// by Ricardo Bittencourt
// Module VESA.H

#ifndef __VESA_H
#define __VESA_H

typedef struct {
  unsigned char r,g,b;
} RGB;

#ifdef __cplusplus
extern "C" {
#endif

void SetGraphMode (void) ;
void RestoreTextMode (void);
void PutPixel (int x, int y, RGB rgb);

#ifdef __cplusplus
}
#endif

#endif

