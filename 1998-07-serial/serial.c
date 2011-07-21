/* Example of serial communication functions.
   This program implements a simple terminal between two computers.
   Use DJGPP 2.0 to compile this program.
   Copyright 1998 by Ricardo Bittencourt */

#include <stdio.h>
#include <stdlib.h>
#include <pc.h>
#include <conio.h>

/* return 0 if no UART is present, else
   1: 8250, 2: 16450, 3: 16550, 4:16550A */

int detect_UART(unsigned baseaddr)
{
   
   int x,olddata;

   olddata=inportb(baseaddr+4);
   outportb(baseaddr+4,0x10);
   if ((inportb(baseaddr+6)&0xf0)) return 0;
   outportb(baseaddr+4,0x1f);
   if ((inportb(baseaddr+6)&0xf0)!=0xf0) return 0;
   outportb(baseaddr+4,olddata);
   olddata=inportb(baseaddr+7);
   outportb(baseaddr+7,0x55);
   if (inportb(baseaddr+7)!=0x55) return 1;
   outportb(baseaddr+7,0xAA);
   if (inportb(baseaddr+7)!=0xAA) return 1;
   outportb(baseaddr+7,olddata); 
   outportb(baseaddr+2,1);
   x=inportb(baseaddr+2);
   outportb(baseaddr+2,0x0);
   if ((x&0x80)==0) return 2;
   if ((x&0x40)==0) return 3;
   return 4;
}

/* return -1 if no intlevel is found, else intlevel 0-15 */

int detect_IRQ(unsigned base)
{
  char ier,mcr,imrm,imrs,maskm,masks,irqm,irqs;

  asm ("cli");            
  ier = inportb(base+1);  
  outportb(base+1,0);     
  while (!(inportb(base+5)&0x20));  
  mcr = inportb(base+4);   
  outportb(base+4,0x0F);   
  imrm = inportb(0x21);    
  imrs = inportb(0xA1);    
  outportb(0xA0,0x0A);     
  outportb(0x20,0x0A);     
  outportb(base+1,2);      
  maskm = inportb(0x20);   
  masks = inportb(0xA0);   
  outportb(base+1,0);      
  maskm &= ~inportb(0x20); 
  masks &= ~inportb(0xA0); 
  outportb(base+1,2);      
  maskm &= inportb(0x20);  
  masks &= inportb(0xA0);  
  outportb(0xA1,~masks);   
  outportb(0x21,~maskm);
  outportb(0xA0,0x0C);     
  outportb(0x20,0x0C);     
  irqs = inportb(0xA0);    
  irqm = inportb(0x20);
  inportb(base+2);         
  outportb(base+4,mcr);    
  outportb(base+1,ier);    
  if (masks) 
    outportb(0xA0,0x20);  
  if (maskm) 
    outportb(0x20,0x20);  
  outportb(0x21,imrm);     
  outportb(0xA1,imrs);
  asm ("sti");
  if (irqs&0x80)       
    return (irqs&0x07)+8;
  if (irqm&0x80)       
    return irqm&0x07;
  return -1;
}
  
#define UART_BAUDRATE 12  /* divisor to select frequency */
#define UART_LCRVAL 0x1b  /* value to be written in LCR */

void UART_init(int addr)
{
   outportb(addr+3,0x80);
   outportw(addr,UART_BAUDRATE);
   outportb(addr+3,UART_LCRVAL);
   outportb(addr+4,0);
}


void UART_send(int addr, char character)
{
   while ((inportb(addr+5)&0x20)==0);
   outportb(addr,(int)character);
}

unsigned UART_get_char(int addr)
{
   unsigned x;
   x = (inportb(addr+5) & 0x9f) << 8;
   if (x&0x100) x|=((unsigned)inportb(addr))&0xff;
   return x;
}


void UART_watch_rxd(int addr)
{
   union {
      unsigned val;
      char character;
      } x;
   while (!kbhit()) {
      x.val=UART_get_char(addr);
      if (!x.val) continue;  
      if (x.val&0x100) {
        printf ("%c",x.character);  
        fflush (stdout);
      }
      if (!(x.val&0xe00)) continue; 
      if (x.val&0x200) printf("Overrun Error");
      if (x.val&0x400) printf("Parity Error");
      if (x.val&0x800) printf("Framing Error");
      }
}

void terminal(int addr)
{
   int key;
   while (1)
      {
      UART_watch_rxd(addr);
      key=getch();
      if (key==27) break;
      UART_send(addr,(char)key);
      }
}

void main (int argc, char **argv) {
  int addr;
  
  switch (atoi (argv[1])) {  
    case 1: 
      addr=0x3F8;
      break;
    case 2: 
      addr=0x2F8;
      break;
    case 3: 
      addr=0x3E8;
      break;
    case 4: 
      addr=0x2E8;
      break;
  }
  printf ("UART-type of COM%d: %d\n",atoi(argv[1]),detect_UART(addr));
  printf ("int used by COM%d: %d\n",atoi(argv[1]),detect_IRQ(addr));
  UART_init (addr);
  terminal (addr);
}
