#ifndef WISE_RLE
#define WISE_RLE

typedef struct {
  int size;
  unsigned char *buffer;
} compressed;

compressed *compress_line (unsigned char *buffer, int size);
void free_compressed (compressed *comp);

#endif
