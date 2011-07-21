#include <stdio.h>
#include <allegro.h>
#include <fcntl.h>
#include <math.h>
#include <unistd.h>
#include <conio.h>
#include <go32.h>
#include <sys/stat.h>
#include <sys/movedata.h>
#include <sys/segments.h>

typedef unsigned char byte;
typedef unsigned short word;
typedef byte RGBA[4];

typedef struct pcx {
  byte Manufacturer;
  byte Version;
  byte Encoding;
  byte BitsPerPixel;
  word XMin,YMin,XMax,YMax;
  word Hdpi;
  word Vdpi;
  byte Colormap[48];
  byte Reserved;
  byte NPlanes;
  word BytesPerLine;
  word PaletteInfo;
  word HScreenSize;
  word VScreenSize;
  byte Filler[54];
} PCX_header;

typedef struct {
  PCX_header header;
  RGBA *buffer;
} PCX_image;

typedef struct {
  int xmax,ymax;
  int size;
  byte *buffer;
  int app[256];
  double entropy;
} image_t;

typedef struct {
  byte root[3];
  byte *buffer[3];
  int xmax,ymax;
  int size;
  int app[256][3];
  int bits[3];
  int mask[3];
  double entropy[3];
} split_image_t;

int fullinfo=0;

byte uniformRGB (byte r, byte g, byte b) {
  return ((b&0xc0)>>6)+((g&0xe0)>>3)+(r&0xe0);
}

PCX_image *read_pcx (char *name) {
  int file;
  PCX_image *image;
  int rx,ry;
  struct stat sbuf;
  int tempsize;
  byte *tempbuffer;
  byte **colorbuffer;
  int i,j,k,l;
  byte *pbuffer,*pfile;
  byte *pbufr,*pbufg,*pbufb;
  RGBA *pimage;
  byte value,value2;
  int normal=0,compressed=0;

  image=(PCX_image *) malloc (sizeof (PCX_image));
  stat (name,&sbuf);
  file=open (name,O_BINARY|O_RDONLY);
  read (file,&(image->header),sizeof (PCX_header));
  rx=image->header.XMax+1;
  ry=image->header.YMax+1;
  image->buffer=(RGBA *) malloc (rx*ry*sizeof (RGBA));
  tempsize=sbuf.st_size-sizeof (PCX_header);
  tempbuffer=(byte *) malloc (tempsize);
  read (file,tempbuffer,tempsize);
  close (file);
  colorbuffer=(byte **) malloc (image->header.NPlanes);
  for (i=0; i<image->header.NPlanes; i++)
    colorbuffer[i]=(byte *) malloc (image->header.BytesPerLine);
  pfile=tempbuffer;
  pimage=image->buffer;
  for (j=0; j<=image->header.YMax; j++) {
    for (k=0; k<image->header.NPlanes; k++) {
      pbuffer=colorbuffer[k];
      for (i=0; i<image->header.BytesPerLine;) {
        value=*pfile++;
        if (value>0xc0) {
          value2=*pfile++;
          compressed++;
          for (l=0; l<value-0xc0; l++) {
            *pbuffer++=value2;
            i++;
          }
        }
        else {
          *pbuffer++=value;
          i++;
          normal++;
        }
      }
    }
    pbufr=colorbuffer[0];
    pbufg=colorbuffer[1];
    pbufb=colorbuffer[2];
    for (i=0; i<=image->header.XMax; i++) {
      (*pimage)[0]=*pbufr++;
      (*pimage)[1]=*pbufg++;
      (*pimage++)[2]=*pbufb++;
    }
  }
  return image;
}

image_t *quantize_pcx (PCX_image *pcx) {
  image_t *image;
  int i;  
  byte *p;
  RGBA *prgb;
  
  image=(image_t *) malloc (sizeof (image_t));
  image->xmax=pcx->header.XMax+1;
  image->ymax=pcx->header.YMax+1;
  image->size=image->xmax*image->ymax;
  image->buffer=(byte *) malloc (image->size);
  p=image->buffer;
  prgb=pcx->buffer;
  for (i=0; i<image->size; i++) {
    *p++=uniformRGB ((*prgb)[0],(*prgb)[1],(*prgb)[2]);
    prgb++;
  }
  return image;
}

void display (image_t *image) {
  RGB rgb[256];
  int i;

  for (i=0; i<256; i++) {
    rgb[i].r=(i&0xe0)>>2;
    rgb[i].g=(i&0x1c)<<1;
    rgb[i].b=(i&0x03)<<4;
  }
  set_gfx_mode (GFX_VGA,320,200,320,200);
  set_palette (rgb);
  for (i=0; i<image->ymax; i++) {
    movedata (_my_ds(),(int)(image->buffer+i*image->xmax),
              _dos_ds,0xa0000+i*320,image->xmax);
  }
  getch ();
  set_gfx_mode (GFX_TEXT,80,25,80,25);
}

void stats (image_t *image) {
  int i;
  byte *p;
  double prob,accprob;

  printf ("uncompressed size=%d\n",image->size);
  p=image->buffer;
  for (i=0; i<256; i++) 
    image->app[i]=0;
  for (i=0; i<image->size; i++) 
    image->app[*p++]++;
  image->entropy=0.0;
  accprob=0.0;
  for (i=0; i<256; i++) {
    prob=(double)image->app[i]/(double)image->size;
    accprob+=prob;
    if (prob>0.0) 
      image->entropy+=prob*log(prob);
  }
  image->entropy/=-log(2.0)*8.0;
  printf ("entropy = %f\n",image->entropy);
  printf ("accumulated probability=%f\n",accprob);
  printf ("minimum size after ideal compression = %d\n",
          (int)(image->entropy*image->size));
}

split_image_t *split_image (image_t *image) {
  split_image_t *split;  
  int i;  

  split=(split_image_t *) malloc (sizeof (split_image_t));
  split->xmax=image->xmax;
  split->ymax=image->ymax;
  split->size=image->size;
  split->bits[0]=split->bits[1]=3;
  split->bits[2]=2;
  split->mask[0]=split->mask[1]=7;
  split->mask[2]=3;
  for (i=0; i<3; i++)
    split->buffer[i]=(byte *) malloc (image->size);
  for (i=0; i<image->size; i++) {
    split->buffer[0][i]=(image->buffer[i]&0x1c)>>2;
    split->buffer[1][i]=(image->buffer[i]&0xe0)>>5;
    split->buffer[2][i]=(image->buffer[i]&0x03);
  }
  return split;
}

void linear_dpcm (split_image_t *split) {
  int i,j;
  byte value,last;

  for (j=0; j<3; j++) {
    split->root[j]=split->buffer[j][0];
    value=split->root[j];
    for (i=0; i<split->size; i++) {
      last=value;
      value=split->buffer[j][i];
      split->buffer[j][i]=(split->buffer[j][i]-last)&split->mask[j];
    }
  }
}

void blocked_dpcm (split_image_t *split, int bsize) {
  int channel;
  int i,j,bi,bj;
  byte value,last;
  int offset;
  
  for (channel=0; channel<3; channel++) {
    split->root[channel]=split->buffer[channel][0];
    value=split->root[channel];
    for (j=0; j<split->ymax/bsize; j++) {
      for (i=0; i<split->xmax/bsize; i++) {
        for (bj=0; bj<bsize; bj++) {
          for (bi=0; bi<bsize; bi++) {
            last=value;
            offset=bi+i*bsize+j*split->xmax*bsize+bj*split->xmax;
            value=split->buffer[channel][offset];
            split->buffer[channel][offset]=
              (split->buffer[channel][offset]-last)&split->mask[channel];
          }
        }
      }
    }
  }
}

void stats_split (split_image_t *image, int wsize) {
  int i,j,k;
  byte *p;
  double prob,accprob;
  int *hits;
  int tsize;
  int shift;
  int offset;
  int total=0;

  printf ("uncompressed size=%d\n",image->size);
  tsize=1;
  for (i=0; i<wsize; i++)
    tsize*=8;
  hits=(int *) malloc (sizeof (int)*tsize);
  for (j=0; j<3; j++) {
    p=image->buffer[j];
    printf ("channel %d ",j);
    for (i=0; i<tsize; i++) 
      hits[i]=0;
    for (i=0; i<image->size; i+=wsize)  {
      shift=1;
      offset=0;
      for (k=0; k<wsize; k++)  {
        offset+=*p++*shift;
        shift*=8;
      }
      hits[offset]++;
    }
    image->entropy[j]=0.0;
    accprob=0.0;
    for (i=0; i<tsize; i++) {
      prob=(double)hits[i]/(double)image->size*wsize;
      if (fullinfo) printf ("%d %d %f\n",j,i,prob);
      accprob+=prob;
      if (prob>0.0) 
        image->entropy[j]+=prob*log(prob);
    }
    image->entropy[j]/=-log(2.0)*(double)image->bits[j]*wsize;
    printf ("entropy = %f\n",image->entropy[j]);
    if (fullinfo) {
      printf ("accumulated probability=%f\n",accprob);
      printf ("minimum size after ideal compression = %d\n",
              (int)(image->entropy[j]*image->size*image->bits[j]/8.0));
    }
    total+=(int)(image->entropy[j]*image->size*image->bits[j]/8.0);
  }
  printf ("total compressed size = %d\n",total);
  free (hits);
}

void oddeven_dpcm (split_image_t *split) {
  int i,j;
  byte value,last;

  for (j=0; j<3; j++) {
    split->root[j]=split->buffer[j][0];
    value=split->root[j];
    for (i=0; i<split->size; i+=2) {
      last=value;
      value=split->buffer[j][i];
      split->buffer[j][i]=(split->buffer[j][i]-last)&split->mask[j];
    }
    value=split->root[j];
    for (i=1; i<split->size; i+=2) {
      last=value;
      value=split->buffer[j][i];
      split->buffer[j][i]=(split->buffer[j][i]-last)&split->mask[j];
    }
  }
}

void linear_xpcm (split_image_t *split) {
  int i,j;
  byte value,last;

  for (j=0; j<3; j++) {
    split->root[j]=split->buffer[j][0];
    value=split->root[j];
    for (i=0; i<split->size; i++) {
      last=value;
      value=split->buffer[j][i];
      split->buffer[j][i]=(split->buffer[j][i]^last)&split->mask[j];
    }
  }
}

void oddeven_xpcm (split_image_t *split) {
  int i,j;
  byte value,last;

  for (j=0; j<3; j++) {
    split->root[j]=split->buffer[j][0];
    value=split->root[j];
    for (i=0; i<split->size; i+=2) {
      last=value;
      value=split->buffer[j][i];
      split->buffer[j][i]=(split->buffer[j][i]^last)&split->mask[j];
    }
    value=split->root[j];
    for (i=1; i<split->size; i+=2) {
      last=value;
      value=split->buffer[j][i];
      split->buffer[j][i]=(split->buffer[j][i]^last)&split->mask[j];
    }
  }
}

void linear2_dpcm (split_image_t *split) {
  int i,j;
  byte value,last;

  for (j=0; j<3; j++) {
    split->root[j]=split->buffer[j][0];
    value=split->root[j];
    for (i=0; i<split->size; i++) {
      last=value;
      value=split->buffer[j][i];
      split->buffer[j][i]=(split->buffer[j][i]-last)&split->mask[j];
    }
  }
  for (j=0; j<3; j++) {
    split->root[j]=split->buffer[j][0];
    value=split->root[j];
    for (i=0; i<split->size; i++) {
      last=value;
      value=split->buffer[j][i];
      split->buffer[j][i]=(split->buffer[j][i]-last)&split->mask[j];
    }
  }
}

void single_xpcm (image_t *split) {
  int i,j;
  byte value,last;

  for (j=0; j<3; j++) {
    value=split->buffer[0];
    for (i=0; i<split->size; i++) {
      last=value;
      value=split->buffer[i];
      split->buffer[i]=(split->buffer[i]^last);
    }
  }
}

void main (int argc, char **argv) {
  PCX_image *image;    
  image_t *quantized,*singlex;
  split_image_t *split,*blocked,*oddeven,*linearx,*oddevenx,*linear2;
  int disp=0;
  
  if (argc<2) {
    printf ("missing argument\n");
    exit (1);
  }
  if (argc>2 && !strcmp (argv[2],"full")) 
    fullinfo=1;
  if (argc>2 && !strcmp (argv[2],"display")) 
    disp=1;
  allegro_init ();
  image=read_pcx (argv[1]);
  printf ("-- Quantized image\n");
  quantized=quantize_pcx (image);
  if (disp) display (quantized);
  stats (quantized);  
  printf ("-- Split image\n");
  split=split_image (quantized);
  stats_split (split,1);
  printf ("-- blocked DPCM image (block size=4)\n");
  blocked=split_image (quantized);
  blocked_dpcm (blocked,4);
  stats_split (blocked,1);
  printf ("-- blocked DPCM image (block size=8)\n");
  blocked=split_image (quantized);
  blocked_dpcm (blocked,8);
  stats_split (blocked,1);
  printf ("-- blocked DPCM image (block size=16)\n");
  blocked=split_image (quantized);
  blocked_dpcm (blocked,16);
  stats_split (blocked,1);
  printf ("-- linear DPCM image (word size=1) \n");
  linear_dpcm (split);
  stats_split (split,1);
  printf ("-- linear DPCM image (word size=2) \n");
  stats_split (split,2);
  printf ("-- linear DPCM image (word size=3) \n");
  stats_split (split,3);
  printf ("-- linear DPCM image (word size=4) \n");
  stats_split (split,4);
  printf ("-- odd/even DPCM image (word size=1) \n");
  oddeven=split_image (quantized);
  oddeven_dpcm (oddeven);
  stats_split (oddeven,1);
  printf ("-- linear XPCM image (word size=1) \n");
  linearx=split_image (quantized);
  linear_xpcm (linearx);
  stats_split (linearx,1);
  printf ("-- odd/even XPCM image (word size=1) \n");
  oddevenx=split_image (quantized);
  oddeven_xpcm (oddevenx);
  stats_split (oddevenx,1);
  printf ("-- odd/even XPCM image (word size=2) \n");
  stats_split (oddevenx,2);
  printf ("-- second order DPCM image (word size=1) \n");
  linear2=split_image (quantized);
  linear2_dpcm (linear2);
  stats_split (linear2,1);
  printf ("-- second order DPCM image (word size=2) \n");
  stats_split (linear2,2);
  printf ("-- single XPCM image (word size=1) \n");
  singlex=quantize_pcx (image);
  single_xpcm (singlex);
  stats (singlex);
  allegro_exit ();
}

