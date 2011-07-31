#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <math.h>
#include <jpeglib.h>
#include "wise_gen.h"
#include "palette.h"
#include "wise_grp.h"

#define R 0
#define G 1
#define B 2

#define SQR(x) ((x)*(x))

#define PIXEL(img,px,py,channel) \
  ((img)->buffer[((py)*(img)->x+(px))*3+(channel)])

#define CLAMP(img,px,py,channel,bg) \
  ((px)<(img)->x&&(py)<(img)->y?PIXEL(img,px,py,channel):(bg))

typedef struct {
  int x,y;
  unsigned char *buffer;
} image;

typedef struct {
  int index;
  int value;
} histogram;

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

  if ((f=fopen (name,"rb"))==NULL)
    return NULL;

  fread (&header,sizeof (PCXHeader),1,f);

  if (header.Manufacturer!=0xA && header.Version!=0x5 &&
      header.Encoding!=0x1 && header.BitsPerPixel!=0x8 )
  {
    fclose (f);
    return NULL;
  }

  img=(image *) safe_malloc (sizeof (image));
  img->x=header.Xmax-header.Xmin+1;
  img->y=header.Ymax-header.Ymin+1;
  img->buffer=(unsigned char *) safe_malloc (img->x*img->y*3);
  
  line_size=header.NPlanes*header.BytesPerLine;
  temp=(unsigned char *) safe_malloc (line_size);
  
  for (line=0; line<img->y; line++) {
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
  
  fclose (f);

  return img;
}

image *open_jpg (char * filename)
{
  struct jpeg_decompress_struct cinfo;
  FILE * infile;		/* source file */
  JSAMPARRAY buffer;		/* Output row buffer */
  int row_stride;		/* physical row width in output buffer */
  image *img;
  struct jpeg_error_mgr jerr;

  if ((infile = fopen(filename, "rb")) == NULL) 
    return NULL;

  cinfo.err = jpeg_std_error(&jerr);
  jpeg_create_decompress(&cinfo);
  jpeg_stdio_src(&cinfo, infile);
  jpeg_read_header(&cinfo, TRUE);

  if (!cinfo.saw_JFIF_marker) {
    jpeg_destroy_decompress(&cinfo);
    fclose (infile);
    return NULL;
  }

  jpeg_start_decompress(&cinfo);
  row_stride = cinfo.output_width * cinfo.output_components;
  buffer = (*cinfo.mem->alloc_sarray)
    ((j_common_ptr) &cinfo, JPOOL_IMAGE, row_stride, 1);

  img=(image *) safe_malloc (sizeof (image));
  img->x=cinfo.image_width;
  img->y=cinfo.image_height;
  img->buffer=(unsigned char *) safe_malloc (img->x*img->y*3);

  while (cinfo.output_scanline < cinfo.output_height) {
    jpeg_read_scanlines(&cinfo, buffer, 1);
    memcpy (img->buffer+cinfo.output_scanline*img->x*3,buffer[0],img->x*3);
  }

  jpeg_finish_decompress(&cinfo);
  jpeg_destroy_decompress(&cinfo);
  fclose(infile);

  return img;
}


int match_color (int encoded) {
  int i;
  int index=1,current;
  int value=1048576;
  int r,g,b;

  r=(encoded>>16)&0xFF;
  g=(encoded>>8)&0xFF;
  b=(encoded)&0xFF;

  for (i=1; i<16; i++) {
    current=
      SQR(r-palette[i*3+0])+SQR(g-palette[i*3+1])+SQR(b-palette[i*3+2]);
    if (current<value) {
      index=i;
      value=current;
    }
  }

  return index;
}

int match_color_near (int encoded, int excluded) {
  int i;
  int index=1,current;
  int value=1048576;
  int r,g,b;

  r=(encoded>>16)&0xFF;
  g=(encoded>>8)&0xFF;
  b=(encoded)&0xFF;

  for (i=1; i<16; i++) {
    if (i!=excluded) {
      current=
        SQR(r-palette[i*3+0])+SQR(g-palette[i*3+1])+SQR(b-palette[i*3+2]);
      if (current<value) {
        index=i;
        value=current;
      }
    }
  }

  return index;
}

int sort_colors (const void *e1, const void *e2) {
  return ((histogram *)e2)->value - ((histogram *)e1)->value;
}

screen2 *convert_scr2 (image *img, int bgcolor) {
  image *new;
  int x,y,i,save;
  histogram hist[16];
  unsigned char pattern;
  screen2 *grp;

  new=(image *) safe_malloc (sizeof (image));
  new->x=((img->x+1)/2+7)&(-8);
  new->y=((img->y+1)/2+7)&(-8);
  new->buffer=(unsigned char *) safe_malloc (new->x*new->y*3);

  grp=(screen2 *) safe_malloc (sizeof (screen2));
  grp->blocks=new->y/8;
  grp->size=new->x/8;
  grp->pattern=(unsigned char *) safe_malloc (grp->blocks*grp->size*8);
  grp->color=(unsigned char *) safe_malloc (grp->blocks*grp->size*8);

  for (y=0; y<new->y; y++)
    for (x=0; x<new->x; x++) {
      PIXEL(new,x,y,R)=
        (CLAMP(img,x*2+0,y*2+0,R,palette[3*bgcolor+0])+
         CLAMP(img,x*2+1,y*2+0,R,palette[3*bgcolor+0])+
         CLAMP(img,x*2+0,y*2+1,R,palette[3*bgcolor+0])+
         CLAMP(img,x*2+1,y*2+1,R,palette[3*bgcolor+0]))/4;
      PIXEL(new,x,y,G)=
        (CLAMP(img,x*2+0,y*2+0,G,palette[3*bgcolor+1])+
         CLAMP(img,x*2+1,y*2+0,G,palette[3*bgcolor+1])+
         CLAMP(img,x*2+0,y*2+1,G,palette[3*bgcolor+1])+
         CLAMP(img,x*2+1,y*2+1,G,palette[3*bgcolor+1]))/4;
      PIXEL(new,x,y,B)=
        (CLAMP(img,x*2+0,y*2+0,B,palette[3*bgcolor+2])+
         CLAMP(img,x*2+1,y*2+0,B,palette[3*bgcolor+2])+
         CLAMP(img,x*2+0,y*2+1,B,palette[3*bgcolor+2])+
         CLAMP(img,x*2+1,y*2+1,B,palette[3*bgcolor+2]))/4;
    }

  for (y=0; y<new->y; y++)
    for (x=0; x<new->x/8; x++) {

      for (i=0; i<16; i++) {
        hist[i].index=i;
        hist[i].value=0;
      }

      for (i=0; i<8; i++)
        hist[match_color(ENCODE_RGB(PIXEL(new,x*8+i,y,R),
          PIXEL(new,x*8+i,y,G),PIXEL(new,x*8+i,y,B)))].value++;

      qsort (hist,16,sizeof (histogram),sort_colors);

      if (hist[1].index==0)
        hist[1].index=hist[2].index;

      if (hist[1].value==0) {
        save=hist[0].index;
        for (i=0; i<16; i++) {
          hist[i].index=i;
          hist[i].value=0;
        }
        for (i=0; i<8; i++)
          hist[match_color_near(ENCODE_RGB(PIXEL(new,x*8+i,y,R),
            PIXEL(new,x*8+i,y,G),PIXEL(new,x*8+i,y,B)),save)].value++;

        qsort (hist,16,sizeof (histogram),sort_colors);
        hist[1].index=hist[0].index;
        hist[0].index=save;
      }

      if (hist[0].index>hist[1].index) {
        i=hist[0].index;
        hist[0].index=hist[1].index;
        hist[1].index=i;
      }

      pattern=0;

      for (i=0; i<8; i++) {
        double pr,pg,pb,rr,rg,rb,t;

        pr=(double)(PIXEL(new,x*8+i,y,R))-0.5*(double)(
                palette[3*hist[1].index+0]+
                palette[3*hist[0].index+0]);

        pg=(double)(PIXEL(new,x*8+i,y,G))-0.5*(double)(
                palette[3*hist[1].index+1]+
                palette[3*hist[0].index+1]);

        pb=(double)(PIXEL(new,x*8+i,y,B))-0.5*(double)(
                palette[3*hist[1].index+2]+
                palette[3*hist[0].index+2]);

        rr=0.5*(double)(palette[3*hist[1].index+0]-
                palette[3*hist[0].index+0]);

        rg=0.5*(double)(palette[3*hist[1].index+1]-
                palette[3*hist[0].index+1]);

        rb=0.5*(double)(palette[3*hist[1].index+2]-
                palette[3*hist[0].index+2]);

        t=(sqrt(pr*pr+pg*pg+pb*pb)*sqrt(rr*rr+rg*rg+rb*rb));
        if (t<1e-6) t=1e-6;
        t=(pr*rr+pg*rg+pb*rb)/t;

        if (t<-0.25) 
          pattern|=1<<(7-i);
        else if (t<0.25) 
          pattern|=((i+y)%2)<<(7-i);
      }  
      grp->pattern[(y/8)*(new->x/8)*8+x*8+y%8]=pattern;
      grp->color[(y/8)*(new->x/8)*8+x*8+y%8]=
        (hist[0].index<<4)+hist[1].index;
    }

  erase_image (new);
  
  return grp;
}

screen2 *open_screen2 (char *name, int bgcolor) {
  image *img;
  screen2 *grp;

  if ((img=open_pcx (name))==NULL)
    if ((img=open_jpg (name))==NULL)
      return NULL;

  grp=convert_scr2 (img,bgcolor);
  erase_image (img);
  return grp;
}

void free_screen2 (screen2 *grp) {
  free (grp->pattern);
  free (grp->color);
  free (grp);
}

