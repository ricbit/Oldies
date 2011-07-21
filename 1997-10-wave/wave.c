#include <stdio.h>
#include <pc.h>
#include <dos.h>
#include <dpmi.h>
#include <sys/movedata.h>

#define DSP_RESET 0x226
#define DSP_READ_DATA 0x22A
#define DSP_WRITE_DATA 0x22C
#define DSP_WRITE_STATUS 0x22C
#define DSP_DATA_AVAIL 0x22E
#define BUFSIZE 16384

typedef unsigned char byte;

int selector,segment;

static _go32_dpmi_seginfo sb_oldirq;      /* original IRQ routine */
static _go32_dpmi_seginfo sb_ourirq;      /* our IRQ handler */

static unsigned char sb_default_pic1;     /* PIC mask flags to restore */
static unsigned char sb_default_pic2;


void alloc_dma_memory (void) {
  int total=BUFSIZE;
  
  do {
    segment=__dpmi_allocate_dos_memory (total,&selector);
    printf (".");
  } while (((segment<<4)>>16)!=(((segment<<4)+total)>>16));
  printf ("/\n");
}

void resetdsp (void) {
  outportb (DSP_RESET,1);
  delay (10);
  outportb (DSP_RESET,0);
  delay (10);
  if ((inportb (DSP_DATA_AVAIL)&0x80)==0x80 && inportb (DSP_READ_DATA)==0xAA)
    printf ("reset ok\n");
  else
    printf ("bug\n");
}

void fill_440 (void) {
  int i,flip=0,state=0;
  byte memo[BUFSIZE];

  for (i=0; i<BUFSIZE; i++) {
    memo[i]=state;
    if (flip++>15) {
      flip=0;
      state=(!state)*50;
    }
  }
  movedata (_my_ds(),(int)memo,selector,0,BUFSIZE);
  printf ("transf ok\n");
}

void writedsp (byte value) {
  while ((inportb (DSP_WRITE_STATUS)&0x80)!=0);
  outportb (DSP_WRITE_DATA,value);
}

static void play (void) {
  int linear,page,size=BUFSIZE-1;  
  
  /* setupdma */
  linear=segment<<4;
  page=(linear)>>16;
  outportb (0xa,5);
  outportb (0xc,0);
  outportb (0xb,0x49|0x10);
  outportb (0x2,linear&0xff);
  outportb (0x2,(linear>>8)&0xff);
  outportb (0x3,size&0xff);
  outportb (0x3,(size>>8)&0xff);
  outportb (0x83,page);
  outportb (0xc,0);
  outportb (0xa,1);

/*  writedsp (0x14);*/
  writedsp (0x48);
  writedsp (size&0xff);
  writedsp ((size>>8)&0xff);
  writedsp (0x90);

}

static void sb_interrupt () {
  asm ("cli");
  /*play ();*/
  inportb (DSP_DATA_AVAIL);
  outportb (0x20,0x20);
  outportb (0xa0,0x20);
  asm ("sti");
}

static void sb_install_interrupts()
{
   printf ("installed\n");
   sb_ourirq.pm_offset = (unsigned long)sb_interrupt;
   sb_ourirq.pm_selector = _my_cs();

   _go32_dpmi_allocate_iret_wrapper(&sb_ourirq);
   _go32_dpmi_get_protected_mode_interrupt_vector(5+8, &sb_oldirq);
   _go32_dpmi_set_protected_mode_interrupt_vector(5+8, &sb_ourirq);

   sb_default_pic1 = inportb(0x21);
   sb_default_pic2 = inportb(0xA1);

   outportb(0x21, sb_default_pic1 & (~(1<<5)));

}



void main (void) {
  int timec;

  printf ("test sb-wave\n");
  resetdsp ();
  alloc_dma_memory ();
  fill_440 ();
  sb_install_interrupts ();
  /* speaker on */
  writedsp (0xd1);
  
  timec=256-(1000000/44100);
  writedsp (0x40);
  writedsp (timec);
  

  play ();
  while (!kbhit());
}
