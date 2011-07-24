#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <math.h>
#include <allegro.h>
#include <conio.h>

#define R 0
#define G 1
#define B 2

#define SQR(x) ((x)*(x))

#define PIXEL(img,px,py,channel) \
  ((img)->buffer[((py)*(img)->x+(px))*3+(channel)])

#define PIXEL8(img,px,py) \
  ((img)->buffer[(py)*(img)->x+(px)])

#define CLAMP(img,px,py,channel,bg) \
  ((px)<(img)->x&&(py)<(img)->y?PIXEL(img,px,py,channel):(bg))

#define ENCODE(img,px,py) \
  ((PIXEL(img,px,py,R)&0xE0)+((PIXEL(img,px,py,G)&0xE0)>>3)+ \
  ((PIXEL(img,px,py,B)&0xC0)>>6))

typedef struct {
  int x,y;
  unsigned char *buffer;
} image;

typedef struct {
  int index;
  int value;
} histogram;

typedef struct {
  int blocks,size;
  unsigned char *pattern;
  unsigned char *color;
} screen2;

typedef struct {
  unsigned char Manufacturer;
  unsigned char Version;
  unsigned char Encoding;
  unsigned char BitsPerPixel;
  unsigned short Xmin;
  unsigned short Ymin;
  unsigned short Xmax;
  unsigned short Ymax;
  unsigned short Hdpi;
  unsigned short Vdpi;
  unsigned char ColorMap[48];
  unsigned char Reserved;
  unsigned char NPlanes;
  unsigned short BytesPerLine;
  unsigned short PaletteInfo;
  unsigned short HscreenSize;
  unsigned short VscreenSize;
  unsigned char Filler[54];
} PCXHeader;

void erase_image (image *img) {
  free (img->buffer);
  free (img);
}

image *open_pcx (char *name) {
  FILE *f;
  image *img;
  PCXHeader header;
  unsigned char *temp,*ptr,b1,b2;
  int line_size,line,x;

  img=(image *) malloc (sizeof (image));
  f=fopen (name,"rb");
  fread (&header,sizeof (PCXHeader),1,f);
  
  img->x=header.Xmax-header.Xmin+1;
  img->y=header.Ymax-header.Ymin+1;
  img->buffer=(unsigned char *) malloc (img->x*img->y*3);
  
  line_size=header.NPlanes*header.BytesPerLine;
  temp=(unsigned char *) malloc (line_size);
  
  for (line=0; line<img->y; line++) {
    printf (".");
    ptr=temp;
    for (x=0; x<line_size;) {
      b1=fgetc (f);
      if (b1>0xc0) {
        b1-=0xc0;
        b2=fgetc (f);
        memset (ptr,b2,b1);
        ptr+=b1;
        x+=b1;
      }
      else {
        *ptr++=b1;
        x++;
      }
    }
    for (x=0; x<img->x; x++) {
      PIXEL (img,x,line,R)=temp[x];
      PIXEL (img,x,line,G)=temp[x+header.BytesPerLine];
      PIXEL (img,x,line,B)=temp[x+header.BytesPerLine*2];
    }
  }
  
  printf ("\nsize %d x %d\n",img->x,img->y);
  fclose (f);

  return img;
}

int match_color (int r,int g,int b,histogram *hist) {
  int i;
  int index=1,current;
  int value=1048576*32;

  for (i=0; i<8; i++) {
    current=
      SQR(r-(((hist[i].index>>6)&0x7)<<5))+
      SQR(g-(((hist[i].index>>3)&0x7)<<5))+
      SQR(b-(((hist[i].index>>0)&0x7)<<5));
    if (current<value) {
      index=i;
      value=current;
    }
  }

  return hist[index].index;
}

int sort_histogram (const void *e1, const void *e2) {
  double x;

  x=((histogram *)e2)->value - ((histogram *)e1)->value;
  return (x<0.0?-1:1);
}

void show_pal (int in, histogram *hist) {
  int c,i,j;

  for (c=0; c<16; c++)
    for (i=0; i<8; i++)
      for (j=0; j<8; j++)
        putpixel (screen,639-c*8-i,in*4+j,hist[c].index);
}

void custom_blit (image *img) {
  int i,j;

  for (j=0; j<480; j++)
    for (i=0; i<640; i++)
      if (i<img->x && j<img->y)
        putpixel (screen,i,j,PIXEL8(img,i,j));
}

void convert_scr7 (image *img) {
  image *temp;
  int i,j;
  histogram hist[256];

  temp=(image *) malloc (sizeof (image));
  temp->x=img->x;
  temp->y=img->y;
  temp->buffer=(unsigned char *) malloc (img->x*img->y);

  for (i=0; i<256; i++) {
    hist[i].value=0;
    hist[i].index=i;
  }
  
  for (j=0; j<img->y; j++)
    for (i=0; i<img->x; i++)
      hist[ENCODE(img,i,j)].value++;

  qsort (hist,256,sizeof (histogram),sort_histogram);
  
  for (j=0; j<temp->y; j++)
    for (i=0; i<temp->x; i++)
      PIXEL8(temp,i,j)=
        match_color(PIXEL(img,i,j,R),PIXEL(img,i,j,G),PIXEL(img,i,j,B),hist);

  custom_blit (temp);
  show_pal (0,hist);
}

void setup_palette (void) {
  PALETTE pal;
  int i;

  for (i=0; i<256; i++) {
    pal[i].r=(i&0xE0)>>2;
    pal[i].g=(i&0x1C)<<1;
    pal[i].b=(i&0x3)<<4;
  }
  set_palette (pal);
}

int main (int argc, char **argv) {
  image *img;
  
  printf ("start\n");
  allegro_init ();
  set_gfx_mode (GFX_VESA1,640,480,640,480);
  setup_palette ();
  img=open_pcx (argv[1]);
  convert_scr7 (img);
  getch ();
  erase_image (img);
  allegro_exit ();
  return 0;
}

