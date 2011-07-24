#include <math.h>
#include "fudebug_window.h"
#include "scanline_window.h"
#include "brmsx_main.h"
#include "brmsx_z80.h"
#include "brmsx_vdp.h"
#include "runvdp.h"
#include "timer.h"
#include "tvborder.h"

// interface with assembly code
int line;
unsigned int drawbuffer;
unsigned int windowcolor;
unsigned int drawpitch;
unsigned int scanline_intensity;

// interface with external windows
volatile unsigned int scanline_value=0x40;
volatile unsigned int tvborder_value=1;
volatile unsigned int bright_value=100;

// scanline cache manager
volatile unsigned int first_black_frame=0;
volatile unsigned int draw_black_now=0;
volatile unsigned int dont_draw_anymore=0;


//---------------------------------------------------------------------------

unsigned char readmem (unsigned short addr) {
  _ESI=0;
  _EBX=0;
  _ECX=addr;
  readmem_asm();
  return _AL;
}

//---------------------------------------------------------------------------

void draw_border
  (unsigned int *drawbuffer, unsigned int drawpitch,
   unsigned int *bordercolor)
{
    int len,val,pos=0;
    int r,g,b;
    int rr,gg,bb;
    int alpha;
    int i,j;
    unsigned int windowcolor,*pixel;

    r=ColorToRGB(clBtnFace)&0xFF;
    g=(ColorToRGB(clBtnFace)&0xFF00)>>8;
    b=(ColorToRGB(clBtnFace)&0xFF0000)>>16;
    windowcolor=(r<<16)+(g<<8)+b;
    i=0; j=0;
    do {
      val=tvborder[pos++];
      len=tvborder[pos++];
      switch (val) {
        case 128:
          pixel=drawbuffer+i+j*drawpitch;
          for (;len;len--) {
            *pixel=windowcolor;
            pixel++; i++;
            if (i==592) {
              i=0; j++; pixel+=drawpitch-592;
            }
          }
          break;
        case 0:
          i+=len;
          j+=i>=592;
          i%=592;
          break;
        default:
          do {
            alpha=bordercolor[j];
            rr=(alpha>>16)&0xFF;
            gg=(alpha>>8)&0xFF;
            bb=(alpha>>0)&0xFF;
            rr=(r*val+rr*(128-val))>>7;
            gg=(g*val+gg*(128-val))>>7;
            bb=(b*val+bb*(128-val))>>7;
            drawbuffer[i+j*drawpitch]=(rr<<16)+(gg<<8)+bb;
            i++;
            if (i==592) { i=0; j++; }
            len--;
          } while (len);
          break;
      }
    } while (j<480);
}

//---------------------------------------------------------------------------

void draw_border16
  (unsigned short *drawbuffer, unsigned int drawpitch,
   unsigned int *bordercolor)
{
    int len,val,pos=0;
    int r,g,b;
    int rr,gg,bb;
    int alpha;
    int i,j;
    unsigned short windowcolor,*pixel;

    r=ColorToRGB(clBtnFace)&0xFF;
    g=(ColorToRGB(clBtnFace)&0xFF00)>>8;
    b=(ColorToRGB(clBtnFace)&0xFF0000)>>16;
    windowcolor=((r>>3)<<11)+((g>>2)<<5)+(b>>3);
    i=0; j=0;
    do {
      val=tvborder[pos++];
      len=tvborder[pos++];
      switch (val) {
        case 128:
          pixel=drawbuffer+i+j*drawpitch;
          for (;len;len--) {
            *pixel=windowcolor;
            pixel++; i++;
            if (i==592) {
              i=0; j++; pixel+=drawpitch-592;
            }
          }
          break;
        case 0:
          i+=len;
          j+=i>=592;
          i%=592;
          break;
        default:
          do {
            alpha=bordercolor[j]>>16;
            rr=(alpha>>8)&0xF8;
            gg=(alpha>>3)&0xFC;
            bb=(alpha<<3)&0xF8;
            rr=(r*val+rr*(128-val))>>7;
            gg=(g*val+gg*(128-val))>>7;
            bb=(b*val+bb*(128-val))>>7;
            drawbuffer[i+j*drawpitch]=((rr>>3)<<11)+((gg>>2)<<5)+(bb>>3);
            i++;
            if (i==592) { i=0; j++; }
            len--;
          } while (len);
          break;
      }
    } while (j<480);
}

//---------------------------------------------------------------------------

void run_msx (unsigned int *z80time,unsigned int *vdptime,
              unsigned int *bordertime)
{
  int ret,outline,fakeline;
  DDSURFACEDESC2 ddsd;
  int start,end,luma;
  unsigned int bordercolor[480];

  memset (&ddsd,0,sizeof(ddsd));
  ddsd.dwSize  = sizeof(ddsd);
  ret=blitbuffer->Lock(NULL,&ddsd,DDLOCK_WAIT|DDLOCK_SURFACEMEMORYPTR,NULL);

  if (ret==DD_OK) {
    // 124 clocks/line
    drawbuffer=(unsigned int)ddsd.lpSurface;

    if (draw_black_now) {
      dont_draw_anymore=1;
      draw_black_now=0;
    }

    if (first_black_frame) {
      draw_black_now=1;
      first_black_frame=0;
    }

    for (outline=0; outline<480; outline++) {
      start=rdtsc();
      runZ80();
      end=rdtsc();
      *z80time+=(end-start);

      if (stopped) {
        time_enabled=0;
        breakpoint=0x10000;
        Fudebug->Invalidate();
        break;
      }

      line=outline-48;
      if (line<0)
        line+=(480-48);
      line>>=1;

      if (line==191 && outline%2==1) {
        vdpstatus|=0x80;
        if ((vdpstatus&0x80) && (vdpreg[1]&32) && iff1) {
          z80_interrupt();
        }
      }

      if (outline%2)
        luma=scanline_value*bright_value/100;
      else
        luma=0x80*bright_value/100;
      scanline_intensity=0x01010101*luma;        

      start=rdtsc();
      if (outline%2) {
        if (!dont_draw_anymore) {
          render_lastline();
          bordercolor[outline]=*(unsigned int *)drawbuffer;
        } else {
          bordercolor[outline]=0;
        }
      } else {
        runVDP();
        bordercolor[outline]=*(unsigned int *)drawbuffer;
      }

      end=rdtsc();
      *vdptime+=(end-start);

      drawbuffer+=ddsd.lPitch;

      Application->ProcessMessages();
    }

    start=rdtsc();
    if (tvborder_value) {
      if (bitdepth==16)
        draw_border16
          ((unsigned short *)ddsd.lpSurface,
           (unsigned int)ddsd.lPitch/2,bordercolor);
      else
        draw_border
          ((unsigned int *)ddsd.lpSurface,
           (unsigned int)ddsd.lPitch/4,bordercolor);
    }
    end=rdtsc();
    *bordertime+=(end-start);

    blitbuffer->Unlock(NULL);
  }

}


