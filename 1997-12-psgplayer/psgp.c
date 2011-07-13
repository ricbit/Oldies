/* PSG Player 2.1 */
/* by Ricardo Bittencourt */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <io.h>
#include <fcntl.h>
#include <conio.h>
#include <pc.h>
#include <string.h>
#include <dir.h>
#include <dos.h>
#include <go32.h>
#include <dpmi.h>
#include <math.h>
#include <allegro.h>
#include <sys\stat.h>
#include <sys\farptr.h>
#include <sys\movedata.h>
#include "slide.h"
#include "psgp.h"

#define MAXSTRING 250
#define SAMPLE_RATE 45455
#define IRQSTACK 1
#define CONV_FACTOR ((int)(65536.0*((233722.0)/(double)(SAMPLE_RATE))))
#define NOISE_MAX 16384

typedef unsigned char byte;

byte *music;                    /* Music is stored here */
byte *mpos;                     /* Position of music pointer */
byte *noise_table;              /* Random numbers look up table */
byte VolumeBar[17][32];         /* Stores the graphics for bars */
byte psg[16];                   /* Contents of PSG registers */
int dma_buffer_seg;             /* Double buffer for DMA */
int dma_buffer_sel;             /* Double buffer for DMA */
byte *fast_buffer;              /* Fast access buffer in high memory */
int dma_buffer_size;            /* Size of each DMA buffer */
int PSGcounter[4];              /* PSG internal counter */
int PSGstate[4];                /* PSG internal state */
int ActualPos;                  /* Number of music pointer */
int TotalSize;                  /* Size of music in bytes */
int TotalInts;                  /* Number of interrupts on music */
int Period;                     /* Period of each interrupt */
int ActiveChannel[3];           /* 1=Channel active */
int InterruptFreq=60;           /* Frequency of interrupts */
int SBIRQ;                      /* Sound Blaster IRQ */
int SBBAddr;                    /* Sound Blaster base address */
int SBDMA;                      /* Sound Blaster DMA */
int TimerTicks;                 /* Clock control variable */      
int TimerSeconds;
int TimerMinutes;
int IntsAccum;                  /* Bar control variables */
int ActualStep;
int IntsPerStep;
int DSP_RESET=0x6;              /* Sound Blaster I/O ports */
int DSP_READ_DATA=0xa;
int DSP_WRITE_DATA=0xc;
int DSP_WRITE_STATUS=0xc;
int DSP_DATA_AVAIL=0xe;
static _go32_dpmi_seginfo sb_oldirq;    /* IRQ handlers for Sound Blaster */
static _go32_dpmi_seginfo sb_newirq;
static byte sb_default_pic1;            /* PIC mask flags */
static byte sb_default_pic2;
int dsp_time_cte;                       /* time constant for dsp */
int ready_to_go=0;                      /* you can eval the new bitstream */

void ReadFile (char *name) {
  int file;  
  byte *pos,*end;  

  file=open (name,O_BINARY|O_RDONLY);
  if (file<0) {
    printf ("Cannot open file <%s>\n",name);
    exit (1);
  }
  printf ("Reading <%s>\n",name);
  TotalSize=filelength (file);
  music=(byte *) malloc (TotalSize);
  read (file,music,TotalSize);
  close (file);
  pos=music;
  end=music+TotalSize;
  TotalInts=0;
  do {
    if (*pos!=0xff && *pos>15) {
      printf ("File <%s> is corrupt\n",name);
      exit (1);
    }
    if (*pos==0xff) {
      TotalInts++;
      pos++;
    }
    else {
      pos+=6;
    }
  } while (pos<end);
  IntsPerStep=TotalInts/78;
}

void InitScreen (char *FileName) {
  char drive[MAXDRIVE],dir[MAXDIR],file[MAXFILE],ext[MAXEXT];
  int i;

  for (i=0; i<17; i++) 
    memcpy (VolumeBar[i],(SlideScreen+i*160),32);
  ScreenUpdate (MainScreen);
  _setcursortype (_NOCURSOR);
  textcolor (LIGHTGRAY);
  textbackground (BLACK);
  gotoxy (62,4);
  cprintf ("%8d",TotalSize);
  gotoxy (71,5);
  cprintf ("%2d:%02d",TotalInts/3600,(TotalInts/60)%60);
  fnsplit (FileName,drive,dir,file,ext);
  gotoxy (64,3);
  strupr (file);
  strupr (ext);
  cprintf ("%8s%s",file,ext);
  gotoxy (55,1);
  textcolor (CYAN);
  textbackground (BLUE);
  cprintf ("%8s%s",file,ext);
  gotoxy (75,1);
  cprintf ("%2d:%02d",TotalInts/3600,(TotalInts/60)%60);
}

inline static void InitMusic (void) {
  TimerTicks=0;
  TimerSeconds=0;
  TimerMinutes=0;
  IntsAccum=0;
  ActualStep=0;
  ActualPos=0;
  mpos=music;
}

void InitPSG (void) {
  int i;

  for (i=0; i<16; i++)
    psg[i]=0;
  for (i=0; i<3; i++) {
    ActiveChannel[i]=1;
    PSGcounter[i]=0;
    PSGstate[i]=0;
  }
  PSGcounter[3]=0x46326231;
  PSGstate[3]=0;
}

void Interrupt (void) {
  byte command,argument;
  static char str[MAXSTRING];

  /* Parse the PSG string */
  do {
    if (*mpos!=0xff) {
      command=*mpos;
      argument=*(++mpos);
      psg[command]=argument;
      sprintf (str,"%02X",argument);
      _farpokeb (_dos_ds,0xb8000+12*2+(8+command)*160,str[0]);
      _farpokeb (_dos_ds,0xb8000+13*2+(8+command)*160,str[1]);
      ActualPos+=6;
      mpos+=5;
      switch (command) {
        case 6:
          if (psg[6]==0) psg[6]=1;
        case 8: /* Volume of channel 0 */
          if (ActiveChannel[0])
            dosmemput (VolumeBar[argument&0xf],32,0xb8000+13*2+2*160);
          break;
        case 9: /* Volume of channel 1 */ 
          if (ActiveChannel[1])
            dosmemput (VolumeBar[argument&0xf],32,0xb8000+13*2+3*160);
          break;
        case 10: /* Volume of channel 2 */
          if (ActiveChannel[2])
            dosmemput (VolumeBar[argument&0xf],32,0xb8000+13*2+4*160);
          break;
      }
    }
    else {
      ActualPos++;
      mpos++;
    }
  } while (ActualPos<TotalSize && *mpos!=0xff);
  if (ActualPos>=TotalSize)
    InitMusic ();

  /* Actualize the bar */
  IntsAccum++;
  if (IntsAccum>=IntsPerStep) {
    IntsAccum=0;
    ActualStep++;
    _farpokeb (_dos_ds,0xb8000+ActualStep*2+1+6*160,(BLUE<<4)+YELLOW);
  }

  /* Actualize the clock */
  TimerTicks++;
  if (TimerTicks==InterruptFreq) {
    gotoxy (69,1);
    textcolor (CYAN);
    textbackground (BLUE);
    TimerTicks=0;
    TimerSeconds++;
    if (TimerSeconds==60) {
      TimerSeconds=0;
      TimerMinutes++;
    }
    cprintf ("%2d:%02d",TimerMinutes,TimerSeconds);
  }
}

void read_blaster_var (void) {
  char *blaster,*bp;
  
  blaster=getenv ("BLASTER");
  if (blaster==NULL) {
    printf ("BLASTER environment variable not found.\n");
    exit (1);
  }
  while (*blaster) {
    switch (*blaster) {
      case 'I':
        SBIRQ=strtol (blaster+1,&bp,10);
        break;
      case 'A':
        SBBAddr=strtol (blaster+1,&bp,16);
        break;
      case 'D':
        SBDMA=strtol (blaster+1,&bp,10);
        break;
    }
    blaster++;
  }
  printf ("Sound Blaster set at 0x%x, IRQ %d, DMA %d\n",SBBAddr,SBIRQ,SBDMA);
  DSP_RESET+=SBBAddr;
  DSP_READ_DATA+=SBBAddr;
  DSP_WRITE_DATA+=SBBAddr;
  DSP_WRITE_STATUS+=SBBAddr;
  DSP_DATA_AVAIL+=SBBAddr;
  dsp_time_cte=256-(1000000/SAMPLE_RATE);
  printf ("DSP time constant=%d\n",dsp_time_cte);
}

void alloc_dma_memory (int *segment, int *selector) {

  dma_buffer_size=(SAMPLE_RATE/60)*IRQSTACK;
  do {
    *segment=__dpmi_allocate_dos_memory (dma_buffer_size,selector);
  } while (((*segment<<4)>>16)!=(((*segment<<4)+dma_buffer_size)>>16));
  printf ("DMA buffer size=%d\n",dma_buffer_size);
}

void reset_dsp (void) {
  outportb (DSP_RESET,1);
  delay (10);
  outportb (DSP_RESET,0);
  delay (10);
  if ((inportb (DSP_DATA_AVAIL)&0x80)==0x80 && inportb (DSP_READ_DATA)==0xaa)
    printf ("Sound Blaster reseted sucessfully\n");
  else {
    printf ("Cannot reset Sound Blaster\n");
    exit (1);
  }
}

void write_dsp (byte value) {
  while ((inportb (DSP_WRITE_STATUS)&0x80));
  outportb (DSP_WRITE_DATA,value);
}

static void play (int segment) {
  int linear,page;

  linear=segment<<4;
  page=linear>>16;
  outportb (0xa,5);
  outportb (0xc,0);
  outportb (0xb,0x49|0x10);
  outportb (0x2,linear&0xff);
  outportb (0x2,(linear>>8)&0xff);
  outportb (0x83,page);
  outportb (0x3,(dma_buffer_size-1)&0xff);
  outportb (0x3,((dma_buffer_size-1)>>8)&0xff);
  outportb (0xa,1);

  write_dsp (0x40);
  write_dsp (dsp_time_cte);

  write_dsp (0x48);
  write_dsp ((dma_buffer_size-1)&0xff);
  write_dsp (((dma_buffer_size-1)>>8)&0xff);
  write_dsp (0x90);
}

static void eval_new_bitstream (void) {
  int start_counter[4];
  int noise_pos=0;
  int i,j,k;
  int pos;
  int bitm,bitr;

  pos=0;
  for (k=0; k<IRQSTACK; k++) {
    Interrupt ();
    start_counter[0]=(psg[0]+(psg[1]<<8))<<16;
    start_counter[1]=(psg[2]+(psg[3]<<8))<<16;
    start_counter[2]=(psg[4]+(psg[5]<<8))<<16;
    start_counter[3]=(psg[6]&0x1f)<<(16+1);
    if (start_counter[3]==0) start_counter[3]=1<<(16+1);
    for (i=0; i<dma_buffer_size/IRQSTACK; i++,pos++) {
      for (j=0; j<3; j++) {
        PSGcounter[j]+=CONV_FACTOR;
        if (PSGcounter[j]>start_counter[j]) {
          if (start_counter[j]) {
            PSGcounter[j]-=start_counter[j];
            if (PSGstate[j])
              PSGstate[j]=0;
            else
              PSGstate[j]=1; 
          }
          else {
            PSGcounter[j]=0;
            PSGstate[j]=1;
          }
        }
      }
      /* noise emulation */
      
      PSGcounter[3]+=(CONV_FACTOR);
      if (PSGcounter[3]>start_counter[3] || psg[6]<3) {
        PSGstate[3]=rand()>(RAND_MAX/2);
        PSGcounter[3]-=start_counter[3];
      }
      noise_pos=(noise_pos+1)%NOISE_MAX;
      
      fast_buffer[pos]=0;
      bitm=(psg[7]&1)>1;
      bitr=(psg[7]&8)>1;
      fast_buffer[pos]+=((bitm|PSGstate[0])&(bitr|PSGstate[3]))*(psg[8]&0xf);
      bitm=(psg[7]&2)>1;
      bitr=(psg[7]&16)>1;
      fast_buffer[pos]+=((bitm|PSGstate[1])&(bitr|PSGstate[3]))*(psg[9]&0xf);
      bitm=(psg[7]&4)>1;
      bitr=(psg[7]&32)>1;
      fast_buffer[pos]+=((bitm|PSGstate[2])&(bitr|PSGstate[3]))*(psg[10]&0xf);
    }
  }
}

static void sb_interrupt (void) {
  asm ("cli");
  inportb (DSP_DATA_AVAIL);
  movedata (_my_ds(),(int)fast_buffer,dma_buffer_sel,0,dma_buffer_size);
  ready_to_go=1;
  outportb (0x20,0x20);
  outportb (0xa0,0x20);
  asm ("sti");
}

void install_irq_handler (void) {
  sb_newirq.pm_offset=(unsigned long) sb_interrupt;  
  sb_newirq.pm_selector=_my_cs ();

  _go32_dpmi_allocate_iret_wrapper (&sb_newirq);
  _go32_dpmi_get_protected_mode_interrupt_vector (SBIRQ+8,&sb_oldirq);
  _go32_dpmi_set_protected_mode_interrupt_vector (SBIRQ+8,&sb_newirq);

  sb_default_pic1=inportb (0x21);
  sb_default_pic2=inportb (0xa1);

  outportb (0x21,sb_default_pic1 & (~(1<<SBIRQ)));
}

void init_dma_buffer (void) {
  int i;

  fast_buffer=(byte *) malloc (dma_buffer_size);
  for (i=0; i<dma_buffer_size; i++)
    fast_buffer[i]=0;
  movedata (_my_ds(),(int)fast_buffer,dma_buffer_sel,0,dma_buffer_size);
}

void turn_off_sb (void) {  
  write_dsp (0xd3);
  outportb (0xa,5);
  _go32_dpmi_set_protected_mode_interrupt_vector (SBIRQ+8,&sb_oldirq);
  reset_dsp ();
  outportb (0x21,sb_default_pic1);
  outportb (0xA1,sb_default_pic1);
}

void init_noise (void) {
  int i;

  noise_table=(byte *) malloc (NOISE_MAX);
  for (i=0; i<NOISE_MAX; i++)
    noise_table[i]=rand()>RAND_MAX/2;
}

int main (int argc, char **argv) {
  char FileName[MAXSTRING];
  int i;
  char c;

  printf ("PSG Player 2.1\n");  
  printf ("Copyright (C) 1997,1998 by Ricardo Bittencourt\n\n");
  for (i=1; i<argc; i++) {
    if (argv[i][0]=='-') {
      if (!strcmp (argv[i],"-ifreq")) 
        InterruptFreq=atoi (argv[++i]);
    }
    else 
      strcpy (FileName,argv[i]);
  }
  read_blaster_var ();
  alloc_dma_memory (&(dma_buffer_seg),&(dma_buffer_sel));
  init_dma_buffer ();
  reset_dsp ();
  ReadFile (FileName);
  printf ("SC: %d\n",CONV_FACTOR);
  printf ("Okay, press enter to start\n");
  getch ();
  InitScreen (FileName);
  InitPSG ();
  InitMusic ();
  init_noise ();
  install_irq_handler ();
  play (dma_buffer_seg);
  c=0;
  do {
    if (kbhit()) {
      switch (c=getch ()) {
        case '1':
          if (ActiveChannel[0]) {
            ActiveChannel[0]=0;
            dosmemput (VolumeBar[16],32,0xb8000+13*2+2*160);
          }
          else {
            ActiveChannel[0]=1;
            dosmemput (VolumeBar[psg[8]&0xf],32,0xb8000+13*2+2*160);
          }
          break;
        case '2':
          if (ActiveChannel[1]) {
            ActiveChannel[1]=0;
            dosmemput (VolumeBar[16],32,0xb8000+13*2+3*160);
          }
          else {
            ActiveChannel[1]=1;
            dosmemput (VolumeBar[psg[9]&0xf],32,0xb8000+13*2+3*160);
          }
          break;
        case '3':
          if (ActiveChannel[2]) {
            ActiveChannel[2]=0;
            dosmemput (VolumeBar[16],32,0xb8000+13*2+4*160);
          }  
          else {
            ActiveChannel[2]=1;
            dosmemput (VolumeBar[psg[10]&0xf],32,0xb8000+13*2+4*160);
          }
          break;
      }
    }
    if (ready_to_go) {
      ready_to_go=0;
      eval_new_bitstream ();
    }
  } while (c!=27);
  textcolor (LIGHTGRAY);
  textbackground (BLACK);
  _setcursortype (_NORMALCURSOR);
  turn_off_sb ();
  clrscr ();
  return 0;
}
