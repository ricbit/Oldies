/* Fast Graphics Header File */
/* Ricardo Bittencourt (9/1995) */

#ifndef __FGRAPH_H
#define __FGRAPH_H

#define fromRGB(r,g,b) (((r)<<5)|((g)<<2)|((b)>>1))

#ifdef __cplusplus
extern "C" {
#endif

extern void far InitGraph (void);
extern void far CloseGraph (void);
extern void far PutPixel (int x, int y, unsigned char color);
extern void far ClearScreen (unsigned char color);
extern void far SetRGB (unsigned char color, unsigned char r,
                    unsigned char g, unsigned char b);
extern void far Line (int x1, int y1, int x2, int y2, unsigned char color);
extern unsigned char far GetPixel (int x, int y);
extern void far PutShape (int x, int y, int dx, int dy,
                      unsigned char far *shape);
extern void far PrecLine (int x1, int y1, int x2, int y2, int far *points);
extern void far MappingLine (int dx, int far *points);
extern void far FlushBuffer (unsigned char far *buffer);
extern void far ClearBuffer (unsigned char far *buffer);
extern void far PrecYLine (int x1, int y1, int x2, int y2, int far *points);
extern void far BufferMapping (unsigned char far *Buf,
                               unsigned char far *Tex,
                               int far *PrecV, int dy,
                               unsigned char decay);
extern void far BufferMapping2 (unsigned char far *Buf,
                           unsigned char far *Tex,
                           int far *PrecV, int dy);
extern void far SetRGBUniform (void);
extern void far GetShape (int x, int y, int dx, int dy,
                      unsigned char far *shape);

#ifdef __cplusplus
}
#endif

#endif