#ifndef __BOT_H
#define __BOT_H

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <malloc.h>

typedef unsigned char byte;

typedef struct {
  byte *data;
  int dx,dy;
} sprite_t;

typedef struct {
  int *mapping;
  int total;
} animation_t;

typedef struct {
  int *nextstate;
  int *time;
  int total;
} state_machine_t;

class bot {
public:
  int x,y;
  int frame;
  int ticks;
  int state,max_states;
  int delay,max_delay;
  animation_t *anim;
  state_machine_t *state_machine;
  sprite_t *sprite;

  void update_state (int machine);
  void change_state (int new_state);
  void adjust_timer (int delta);
  void show (byte *screen);
  void create_state_machine (int machines, int states);
};
  
sprite_t get_sprite (byte *buffer, int x, int y, int dx, int dy);
sprite_t get_hflip_sprite (byte *buffer, int x, int y, int dx, int dy);
void put_sprite (byte *screen, sprite_t sprite, int x, int y);

#endif
