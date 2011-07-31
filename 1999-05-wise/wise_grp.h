#ifndef WISE_GRP
#define WISE_GRP

#define ENCODE_RGB(r,g,b) (((r)<<16)+((g)<<8)+(b))

typedef struct {
  int blocks,size;
  unsigned char *pattern;
  unsigned char *color;
} screen2;

screen2 *open_screen2 (char *name, int bgcolor);
void free_screen2 (screen2 *grp);
int match_color (int encoded);

#endif
