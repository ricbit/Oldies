#include <stdio.h>
#include <dos.h>
#include <unistd.h>
#include <fcntl.h>
#include <malloc.h>
#include <allegro.h>
#include "bot.h"
#include "timer.h"
#include "pengbot.h"

BITMAP *work;                           /* work bitmap */
pengbot penguin;                        /* penguin bot */
int realtimer;                          /* incs every 1/60 sec */
int total_frames;                       /* total frames */
BITMAP *scenario[7];
int xposition=0;

void read_scenario (void) {
  int file;  
  int i;
  char name[200];
  char buffer[1000];
  int j;

  for (i=0; i<7; i++) {
    sprintf (name,"rola-0%d.tga",i+1);
    file=open (name,O_BINARY|O_RDONLY);
    scenario[i]=create_bitmap (320,200);
    read (file,buffer,786);
    read (file,scenario[i]->dat,64000);
    for (j=0; j<64000; j++)
      if (((byte *)scenario[i]->dat)[j]<128)
        ((byte*)scenario[i]->dat)[j]=0;
    close (file);
  }
}

void create_palette (void) {
  RGB pal[256];  
  int i;
  
  for (i=0; i<=192; i++) {
    pal[i].r=pal[i].g=pal[i].b=0;
  }
  for (i=1; i<64; i++) {
    pal[i+192].r=(((i&0x30)<<2)+0x3f)>>2;
    pal[i+192].g=(((i&0x0c)<<4)+0x3f)>>2;
    pal[i+192].b=(((i&0x03)<<6)+0x3f)>>2;
  }
  set_pallete (pal);
}

void draw_scenario (int plane, int ymin, int ymax, int xpos) {
  int y;  
  byte *fastsi,*fastdi,*fastsiend,*fastsiorig;

  fastdi=((byte*)(work->dat))+ymin*320;
  fastsiorig=((byte*)(scenario[plane]->dat))+ymin*320;
  for (y=ymin; y<=ymax; y++) {
    fastsi=fastsiorig+xpos;
    fastsiend=fastsi+319-xpos;
    for (; fastsi<=fastsiend; ) {
      if (*fastsi)
        *fastdi=*fastsi;
      fastdi++; fastsi++;
    }
    fastsi=fastsiorig;
    fastsiend=fastsi+xpos;
    for (; fastsi<fastsiend; ) {
      if (*fastsi)
        *fastdi=*fastsi;
      fastdi++; fastsi++;
    }
    fastsiorig+=320;
  }
}

#define CROP(x) (((x)%320)<0?320+((x)%320):((x)%320))

void render (void) {
  draw_scenario (0,0,100,0);
  draw_scenario (1,32,101,CROP(xposition/5));
  draw_scenario (2,0,111,CROP(xposition/3));
  draw_scenario (3,62,131,CROP(xposition/2));
  draw_scenario (4,92,159,CROP(xposition));
  penguin.show ((byte *)work->dat);
  draw_scenario (5,122,159,CROP(xposition*2));
  draw_scenario (6,0,159,CROP(xposition*4));
  draw_scenario (0,160,199,0);
  vsync ();
  blit (work,screen,0,0,0,0,320,200);
}

void init_penguin (void) {
  penguin.init ();
  penguin.y=98;
  penguin.x=140;
  penguin.frame=0;
  penguin.state=penguin.STATE_STANDING_RIGHT;
  penguin.max_delay=10;
  penguin.delay=1;
  penguin.ticks=0;
}

void main_loop (void) {
  int before,delta;
  
  init_penguin ();
  realtimer=0;
  total_frames=0;
  do {
    before=realtimer;
    render ();
    total_frames++;
    delta=realtimer-before;
    penguin.adjust_timer (delta);
    if (key[KEY_RIGHT]) {
      penguin.update_state (penguin.SEQUENCE_RIGHT);
      if (penguin.state==penguin.STATE_STARTING_WALK_RIGHT ||
          penguin.state==penguin.STATE_WALKING_RIGHT) 
      {
        xposition+=delta;
      }
    } else
    if (key[KEY_LEFT]) {
      penguin.update_state (penguin.SEQUENCE_LEFT);
      if (penguin.state==penguin.STATE_STARTING_WALK_LEFT ||
          penguin.state==penguin.STATE_WALKING_LEFT) 
      {
        xposition-=delta;
      }
    } else
    if (key[KEY_DOWN]) {
      penguin.update_state (penguin.SEQUENCE_DOWN);
    }
    else {
      penguin.update_state (penguin.SEQUENCE_ALONE);
    }
  } while (!key[KEY_ESC]);
}

int main (void) {
  printf ("Penguin 1.0\n");
  printf ("by Ricardo Bittencourt and Raul Tabajara\n");
  allegro_init ();
  set_gfx_mode (GFX_VGA,320,200,320,200);
  create_palette ();
  work=create_bitmap (320,200);
  read_scenario ();
  install_keyboard ();
  timer_on ();
  main_loop ();
  remove_timer ();
  remove_keyboard ();
  allegro_exit ();
  printf ("fps: %.3f\n",(double)total_frames*60.0/(double)realtimer);
  return 0;
}

