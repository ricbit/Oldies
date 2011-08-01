#include <stdio.h>
#include <stdlib.h>
#include <pc.h>

#ifdef __cplusplus
extern "C" {
#endif

int comaddr[4]={0x3f8,0x2f8,0x3e8,0x2e8};
int comport;

typedef struct {
  int f1,f2,f3,f4,f5;
  int raw,pitch;
} glove_data;

void set_com_base (int port) {
  comport=comaddr[port];
}

void UART_init (void) {
  outportb (comport+3,0x80);
  outportb (comport,6); /* baudrate */
  outportb (comport+3,0x3); /* 8n1 */
  outportb (comport+4,0);
}

int UART_receive (void) {
  while (!(inportb (comport+5)&1));
  return inportb (comport);
}

void UART_send (int value) {
  while (!(inportb (comport+5)&0x20));
  outportb (comport,value);
}

int glove_init (void) {
  UART_send (0x41);
  if (UART_receive()!=0x55) 
    return 0;
  else
    return 1;
}

void get_glove_data (glove_data *data) {
  int sy,cs;
  
  UART_send (0x43);
  sy=UART_receive ();
  data->f1=UART_receive ();
  data->f2=UART_receive ();
  data->f3=UART_receive ();
  data->f4=UART_receive ();
  data->f5=UART_receive ();
  data->pitch=UART_receive ();
  data->raw=UART_receive ();
  cs=UART_receive ();
  if (sy!=0x80) {
    /* error */
  }
}

#ifdef __cplusplus
}
#endif

