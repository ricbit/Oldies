#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>

#define RESX 576
#define RESY 400
#define MAX (RESX*RESY/64)

#define SQR(x) ((x)<0?-(x):(x))
#define IABS(x) ((x)<0?-(x):(x))

unsigned char *b2;

int eval_mean (unsigned char *buffer, int i, int j) {
  int x,y;
  int mean=0;

  for (x=0; x<8; x++)
    for (y=0; y<8; y++)
      mean+=buffer[(i*8+x)+(j*8+y)*RESX];

  return mean;
}

int eval_mean_2 (unsigned char *buffer, int i, int j) {
  int x,y;
  int mean=0;

  for (x=0; x<8; x++)
    for (y=0; y<8; y++)
      mean+=buffer[(i*8+x)+(j*8+y)*RESX/2];

  return mean;
}

int mean_table[3600],mean_table_2[3600/4];
int diff_t[64],diff_y[64],diff_x[64],diff_b[64],diff_f[64],*pdiff;
int diff_fy[64],diff_fx[64],diff_fb[64];

int eval_diff (unsigned char *buffer, int i, int j, int ii, int jj)
{
  int x,y,c=0;
  int diff=0;
  int code1,code2;

  code1=j*RESX/8+i;
  code2=jj*RESX/16+ii;
  for (y=0; y<8; y++)
    for (x=0; x<8; x++) {
      diff_t[c]=
        buffer[i*8+x+(j*8+y)*RESX]-
        b2[ii*8+x+(jj*8+y)*RESX/2]*mean_table[code1]/mean_table_2[code2];
      diff+=SQR(diff_t[c]);
      c++;
    }

  return diff;
}

int eval_diff_y (unsigned char *buffer, int i, int j, int ii, int jj)
{
  int x,y,c=0;
  int diff=0;
  int code1,code2;

  code1=j*RESX/8+i;
  code2=jj*RESX/16+ii;
  for (y=0; y<8; y++)
    for (x=0; x<8; x++) {
      diff_y[c]=
        buffer[i*8+x+(j*8+7-y)*RESX]-
        b2[ii*8+x+(jj*8+y)*RESX/2]*mean_table[code1]/mean_table_2[code2];
      diff+=SQR(diff_y[c]);
      c++;
    }

  return diff;
}

int eval_diff_x (unsigned char *buffer, int i, int j, int ii, int jj)
{
  int x,y,c=0;
  int diff=0;
  int code1,code2;

  code1=j*RESX/8+i;
  code2=jj*RESX/16+ii;
  for (y=0; y<8; y++)
    for (x=0; x<8; x++) {
      diff_x[c]=
        buffer[i*8+7-x+(j*8+y)*RESX]-
        b2[ii*8+x+(jj*8+y)*RESX/2]*mean_table[code1]/mean_table_2[code2];
      diff+=SQR(diff_x[c]);
      c++;
    }

  return diff;
}

int eval_diff_b (unsigned char *buffer, int i, int j, int ii, int jj)
{
  int x,y,c=0;
  int diff=0;
  int code1,code2;

  code1=j*RESX/8+i;
  code2=jj*RESX/16+ii;
  for (y=0; y<8; y++)
    for (x=0; x<8; x++) {
      diff_b[c]=
        buffer[i*8+7-x+(j*8+7-y)*RESX]-
        b2[ii*8+x+(jj*8+y)*RESX/2]*mean_table[code1]/mean_table_2[code2];
      diff+=SQR(diff_b[c]);
      c++;
    }

  return diff;
}

int eval_diff_f (unsigned char *buffer, int i, int j, int ii, int jj)
{
  int x,y,c=0;
  int diff=0;
  int code1,code2;

  code1=j*RESX/8+i;
  code2=jj*RESX/16+ii;
  for (y=0; y<8; y++)
    for (x=0; x<8; x++) {
      diff_f[c]=
        buffer[i*8+y+(j*8+x)*RESX]-
        b2[ii*8+x+(jj*8+y)*RESX/2]*mean_table[code1]/mean_table_2[code2];
      diff+=SQR(diff_f[c]);
      c++;
    }

  return diff;
}

int eval_diff_fx (unsigned char *buffer, int i, int j, int ii, int jj)
{
  int x,y,c=0;
  int diff=0;
  int code1,code2;

  code1=j*RESX/8+i;
  code2=jj*RESX/16+ii;
  for (y=0; y<8; y++)
    for (x=0; x<8; x++) {
      diff_fx[c]=
        buffer[i*8+7-y+(j*8+x)*RESX]-
        b2[ii*8+x+(jj*8+y)*RESX/2]*mean_table[code1]/mean_table_2[code2];
      diff+=SQR(diff_fx[c]);
      c++;
    }

  return diff;
}

int eval_diff_fy (unsigned char *buffer, int i, int j, int ii, int jj)
{
  int x,y,c=0;
  int diff=0;
  int code1,code2;

  code1=j*RESX/8+i;
  code2=jj*RESX/16+ii;
  for (y=0; y<8; y++)
    for (x=0; x<8; x++) {
      diff_fy[c]=
        buffer[i*8+y+(j*8+7-x)*RESX]-
        b2[ii*8+x+(jj*8+y)*RESX/2]*mean_table[code1]/mean_table_2[code2];
      diff+=SQR(diff_fy[c]);
      c++;
    }

  return diff;
}

int eval_diff_fb (unsigned char *buffer, int i, int j, int ii, int jj)
{
  int x,y,c=0;
  int diff=0;
  int code1,code2;

  code1=j*RESX/8+i;
  code2=jj*RESX/16+ii;
  for (y=0; y<8; y++)
    for (x=0; x<8; x++) {
      diff_fb[c]=
        buffer[i*8+7-y+(j*8+7-x)*RESX]-
        b2[ii*8+x+(jj*8+y)*RESX/2]*mean_table[code1]/mean_table_2[code2];
      diff+=SQR(diff_fb[c]);
      c++;
    }

  return diff;
}

void encode (unsigned char *buffer) {
  int i,j,ii,jj;
  int selected,diff,diff2,absel;
  int code1;

  for (j=0; j<RESY/8; j++)
    for (i=0; i<RESX/8; i++) 
      mean_table[j*RESX/8+i]=eval_mean(buffer,i,j);

  for (j=0; j<RESY/16; j++)
    for (i=0; i<RESX/16; i++) 
      mean_table_2[j*RESX/16+i]=eval_mean_2(b2,i,j);

  for (j=0; j<RESY/8; j++)
    for (i=0; i<RESX/8; i++) {
      selected=0;
      absel=0;
      diff=eval_diff (buffer,i,j,0,0);
      code1=j*RESX/8+i;
      for (jj=0; jj<RESY/16; jj++)
        for (ii=0; ii<RESX/16; ii++) {
          diff2=eval_diff (buffer,i,j,ii,jj);
          if (diff2<diff) {
            selected=jj*RESX/16+ii;
            absel=jj*RESX/16+ii;
            diff=diff2;
            pdiff=diff_t;
          }
          diff2=eval_diff_x (buffer,i,j,ii,jj);
          if (diff2<diff) {
            selected=10000+(jj*RESX/16+ii);
            absel=jj*RESX/16+ii;
            diff=diff2;
            pdiff=diff_x;
          }
          diff2=eval_diff_y (buffer,i,j,ii,jj);
          if (diff2<diff) {
            selected=20000+(jj*RESX/16+ii);
            absel=jj*RESX/16+ii;
            diff=diff2;
            pdiff=diff_y;
          }
          diff2=eval_diff_b (buffer,i,j,ii,jj);
          if (diff2<diff) {
            selected=30000+(jj*RESX/16+ii);
            absel=jj*RESX/16+ii;
            diff=diff2;
            pdiff=diff_b;
          }
          diff2=eval_diff_f (buffer,i,j,ii,jj);
          if (diff2<diff) {
            selected=40000+(jj*RESX/16+ii);
            absel=jj*RESX/16+ii;
            diff=diff2;
            pdiff=diff_f;
          }
          diff2=eval_diff_fx (buffer,i,j,ii,jj);
          if (diff2<diff) {
            selected=50000+(jj*RESX/16+ii);
            absel=jj*RESX/16+ii;
            diff=diff2;
            pdiff=diff_fx;
          }
          diff2=eval_diff_fy (buffer,i,j,ii,jj);
          if (diff2<diff) {
            selected=60000+(jj*RESX/16+ii);
            absel=jj*RESX/16+ii;
            diff=diff2;
            pdiff=diff_fy;
          }
          diff2=eval_diff_fb (buffer,i,j,ii,jj);
          if (diff2<diff) {
            selected=70000+(jj*RESX/16+ii);
            absel=jj*RESX/16+ii;
            diff=diff2;
            pdiff=diff_fb;
          }
        }
      printf ("%d\t%d\t%d\n",selected,mean_table[code1],
              mean_table_2[absel]);
    }
}

int main (void) {
  FILE *f;
  unsigned char *buffer;
  int i,j;

  buffer=(unsigned char *) malloc (RESX*RESY);
  b2=(unsigned char *) malloc (RESX*RESY/4);
  f=fopen ("teste.gry","rb");
  fread (buffer,1,RESX*RESY,f);
  fclose (f);
  for (i=0; i<RESX/2; i++)
    for (j=0; j<RESY/2; j++)
      b2[j*RESX/2+i]=(buffer[(j*2+0)*RESX+(i*2+0)]
                     +buffer[(j*2+1)*RESX+(i*2+0)]
                     +buffer[(j*2+0)*RESX+(i*2+1)]
                     +buffer[(j*2+1)*RESX+(i*2+1)])/4;
  encode (buffer);

  return 0;
}
