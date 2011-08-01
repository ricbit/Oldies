#include "bot.h"

void bot::change_state (int new_state) {
  if (state!=new_state) {
    state=new_state;
    frame=0;
    ticks=0;
  }
}

void bot::update_state (int machine) {
  if (ticks>=state_machine[machine].time[state]) 
    change_state (state_machine[machine].nextstate[state]);
}

void bot::adjust_timer (int delta) {
  delay-=delta;
  while (delay<0) {
    delay+=max_delay;
    ticks++;
    if (++frame==anim[state].total) 
      frame=0;
  }
}

void bot::show (byte *screen) {
  put_sprite (screen,sprite[anim[state].mapping[frame]],x,y);
}
  
void bot::create_state_machine (int machines, int states) {
  int i,j;

  state_machine=new state_machine_t[machines];
  for (i=0; i<machines; i++) {
    state_machine[i].total=states;
    state_machine[i].time=new int[states];
    state_machine[i].nextstate=new int[states];
    for (j=0; j<states; j++) {
      state_machine[i].time[j]=0;
      state_machine[i].nextstate[j]=j;
    }
  }
}

sprite_t get_sprite (byte *buffer, int x, int y, int dx, int dy) {
  sprite_t s;
  int i,j;

  s.dx=dx; s.dy=dy;
  s.data=(byte *) malloc (s.dx*s.dy);
  for (j=0; j<dy; j++) 
    for (i=0; i<dx; i++)
      if (buffer[i+x+(j+y)*320]>128)
        s.data[i+j*dx]=buffer[i+x+(j+y)*320];
      else
        s.data[i+j*dx]=0;
  return s;
}

sprite_t get_hflip_sprite (byte *buffer, int x, int y, int dx, int dy) {
  sprite_t s;
  int i,j;

  s.dx=dx; s.dy=dy;
  s.data=(byte *) malloc (s.dx*s.dy);
  for (j=0; j<dy; j++) 
    for (i=0; i<dx; i++)
      if (buffer[(dx-i-1)+x+(j+y)*320]>128)
        s.data[i+j*dx]=buffer[(dx-i-1)+x+(j+y)*320];
      else
        s.data[i+j*dx]=0;
  return s;
}

void put_sprite (byte *screen, sprite_t sprite, int x, int y) {
  int i,j;

  for (j=0; j<sprite.dy; j++)
    for (i=0; i<sprite.dx; i++)
      if (sprite.data[i+j*sprite.dx])
        screen[x+i+(j+y)*320]=sprite.data[i+j*sprite.dx];
}

