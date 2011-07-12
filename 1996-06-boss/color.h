// BOSS 1.0
// by Ricardo Bittencourt 1996
// header COLOR

#ifndef __COLOR_H
#define __COLOR_H

#ifdef __COLOR_CPP
#define _COLOREXT
#else
#define _COLOREXT extern
#endif

#include "general.h"

enum ImageType {
  Bit8,
  Bit24
};

typedef struct {
  byte R,G,B;
} RGBtriple;

class Color {
private:
  RGBtriple rgb;
  byte      index;

public:
  inline void SetRGBValue (byte r, byte g, byte b);
  inline void SetIndexValue (byte i);
};

byte pascal fromRGB (byte r, byte g, byte b, word x, word y);
byte pascal matchRGB (byte r, byte g, byte b, byte *palette);
RGBtriple HSVtoRGB (real h, real s, real v);
void DrawColorCircle (void);

_COLOREXT byte Color1,Color2;
_COLOREXT ImageType GlobalState;

inline void Color::SetRGBValue (byte r, byte g, byte b) {
  rgb.R=r;
  rgb.G=g;
  rgb.B=b;
}

inline void Color::SetIndexValue (byte i) {
  index=i;
}

#endif

