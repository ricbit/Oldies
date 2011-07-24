/*---------------------------------------------------------------------------------

  Graphos DS v1.0 
  Copyright (C) 2005 by Ricardo Bittencourt
  start date: 2005.11.23
  last update: 2005.12.28
  
---------------------------------------------------------------------------------*/

#include <nds.h>
#include <nds/arm9/console.h>
#include "graphos_jpg_bin.h"
#include "jpeg/gba-jpeg-decode.h"

#define NULL ((void*)0)

typedef struct {
  u8 pattern[0x1800];
  u8 color[0x1800];
} vdp_screen_type;

static uint32 msx1palette[16] = {
    0x000000, 0x000000, 0x21c842, 0x5edc78, 0x5455ed, 0x7d76fc, 0xd4524d, 0x42ebf5,
    0xfc5554, 0xff7978, 0xd4c154, 0xe6ce80, 0x21b03b, 0xc95bba, 0xcccccc, 0xffffff
};

//---------------------------------------------------------------------------------

SpriteEntry *sprites_sub=(SpriteEntry *)OAM_SUB;
SpriteRotation *spriteRotations_sub=(SpriteRotation *)OAM_SUB;
SpriteEntry *sprites=(SpriteEntry *)OAM;
SpriteRotation *spriteRotations=(SpriteRotation *)OAM;
u16 *name_table=(u16*)SCREEN_BASE_BLOCK_SUB(31);

//---------------------------------------------------------------------------------

typedef enum {
	STATE_COVER,
	STATE_DRAW,
	STATE_PREVIEW
} possible_states;

possible_states global_state=STATE_COVER;

vdp_screen_type screen;
int touchx,touchy; 
int blockx=10,blocky=10;
int current_color=6;

u8 preview_screen[3*256*192];
u8 temp_screen[65536];
u16 opening[256*192];

//---------------------------------------------------------------------------------

#define TOUCH_BUFFER 8

uint32 msx_color (int i) {
  return RGB15((msx1palette[i]>>16)>>3, ((msx1palette[i]>>8)&0xFF)>>3, (msx1palette[i]&0xFF)>>3);
}

void put_sprite_sub (int x, int y, int layer, int pattern) {
	sprites_sub[layer].attribute[0] = ATTR0_SQUARE | ATTR0_COLOR_256 | ATTR0_ROTSCALE_DOUBLE | ((y-8)&255);
	sprites_sub[layer].attribute[1] = ATTR1_SIZE_16 | ((x-8)&511); 
	sprites_sub[layer].attribute[2] = pattern;
}

void put_sprite (int x, int y, int layer, int pattern) {
	sprites[layer].attribute[0] = ATTR0_SQUARE | ATTR0_COLOR_256 | ATTR0_ROTSCALE_DOUBLE | ((y-8)&255);
	sprites[layer].attribute[1] = ATTR1_SIZE_16 | ((x-8)&511); 
	sprites[layer].attribute[2] = pattern;
}

void erase_sprite_sub (int layer) {
	sprites_sub[layer].attribute[0] = ATTR0_DISABLED;
}

void erase_sprite (int layer) {
	sprites[layer].attribute[0] = ATTR0_DISABLED;
}

void draw_square (int x, int y, uint32 front, uint32 border) {
  int i,j;
  
  for (j=1; j<12; j++) {
    BG_GFX_SUB[(y+1)*256+x+j]=border+(1<<15);
    BG_GFX_SUB[(y+11)*256+x+j]=border+(1<<15);
    BG_GFX_SUB[(y+j)*256+x+1]=border+(1<<15);
    BG_GFX_SUB[(y+j)*256+x+11]=border+(1<<15);
  }
  
  for (j=2; j<11; j++)
    for (i=2; i<11; i++)
      BG_GFX_SUB[(y+j)*256+x+i]=front+(1<<15);
}

int update_stylus(void) {
  touchPosition touchXY;
  int i,mx,my,nx,ny,nc=0;
  static int stylusx[TOUCH_BUFFER],stylusy[TOUCH_BUFFER];
  static int total=0;
  
  if (keysHeld()&KEY_TOUCH) {
    mx=my=0;
    
    touchXY=touchReadXY();
    if (total<TOUCH_BUFFER) {
      stylusx[total]=touchXY.px;
      stylusy[total]=touchXY.py;
      for (i=0; i<=total; i++) {
        mx+=stylusx[i];
        my+=stylusy[i];
      }
      total++;
      mx/=total;
      my/=total;
    } else {
      for (i=0; i<TOUCH_BUFFER-1; i++) {
        mx+=(stylusx[i]=stylusx[i+1]);
        my+=(stylusy[i]=stylusy[i+1]);        
      }
      mx+=(stylusx[TOUCH_BUFFER-1]=touchXY.px);
      my+=(stylusy[TOUCH_BUFFER-1]=touchXY.py);   
      mx/=TOUCH_BUFFER; my/=TOUCH_BUFFER;
    }
    
    nx=ny=0;
    for (i=0; i<total; i++) {
      if (stylusx[i]>mx-8 && stylusx[i]<mx+8 && stylusy[i]>my-8 && stylusy[i]<my+8) {
        nx+=stylusx[i];
        ny+=stylusy[i];
        nc++;
      }
    }
  } else total=0;
  
  if (nc>4) {
    touchx=nx/nc; 
    touchy=ny/nc; 
    return 1;
  }
  
  return 0;
} 

int get_screen_color (int x, int y) {
  int i,j,ii,jj;
  int color;
  
  i=x>>3; ii=x&7;
  j=y>>3; jj=y&7;
  if (screen.pattern[j*32*8+jj+i*8]&(1<<(7-ii)))
    color=msx_color(screen.color[j*32*8+jj+i*8]>>4);
  else  
    color=msx_color(screen.color[j*32*8+jj+i*8]&0xF);
  return color;
}

void update_all_squares(void) {
	int i,j;
	
  for (i=0; i<16; i++)
    for (j=0; j<16; j++)
       draw_square (i*12+32,j*12,get_screen_color(blockx*8+i,blocky*8+j),0);
}       

void init_sub_screen(void) {
  int i;
  
  for (i=0; i<256*192; i++)
    BG_GFX_SUB[i]=RGB15(31,31,31)+(1<<15);
 
  update_all_squares(); 
  
  for (i=1; i<16; i++)
    draw_square (256-12-4,i*12,msx_color(i),0);
     
  for (i=32; i<32+12*16+1; i++) {
  	BG_GFX_SUB[i+0*256]=RGB15(31,0,0)+(1<<15);
  	BG_GFX_SUB[i+12*8*256]=RGB15(31,0,0)+(1<<15);
  }
  for (i=0; i<256; i++) {
  	BG_GFX_SUB[32+i*256]=RGB15(31,0,0)+(1<<15);
  	BG_GFX_SUB[32+12*16+i*256]=RGB15(31,0,0)+(1<<15);
  	BG_GFX_SUB[32+12*8+i*256]=RGB15(31,0,0)+(1<<15);
  }
}

void init_main_screen(void) {
  int i,j,ii,jj;
  
  for (j=0; j<24; j++)
    for (jj=0; jj<8; jj++)
      for (i=0; i<32; i++)
        for (ii=0; ii<8; ii++)
          if (screen.pattern[j*32*8+jj+i*8]&(1<<(7-ii)))
             BG_GFX[(j*8+jj)*256+(i*8+ii)]=msx_color(screen.color[j*32*8+jj+i*8]>>4)|(1<<15);
          else  
             BG_GFX[(j*8+jj)*256+(i*8+ii)]=msx_color(screen.color[j*32*8+jj+i*8]&0xF)|(1<<15);
}

void set_screen_color (int x, int y, int color) {
  int i,j,ii,jj;
  
  i=x>>3; ii=x&7;
  j=y>>3; jj=y&7;
  
  if ((screen.color[j*32*8+jj+i*8]>>4)==(screen.color[j*32*8+jj+i*8]&0xF)) {
  	screen.color[j*32*8+jj+i*8]=(screen.color[j*32*8+jj+i*8]&0xF)+(color<<4);
  	screen.pattern[j*32*8+jj+i*8]=1<<(7-ii);
  	return;
  }
  
  if (screen.pattern[j*32*8+jj+i*8]==0) {
  	screen.color[j*32*8+jj+i*8]=(screen.color[j*32*8+jj+i*8]&0xF)+(color<<4);
  	screen.pattern[j*32*8+jj+i*8]=1<<(7-ii);
  	return;
  }
  
  if (screen.pattern[j*32*8+jj+i*8]==0xFF) {
  	screen.color[j*32*8+jj+i*8]=(screen.color[j*32*8+jj+i*8]>>4)+(color<<4);
  	screen.pattern[j*32*8+jj+i*8]=1<<(7-ii);
  	return;
  }
  
  if (screen.color[j*32*8+jj+i*8]>>4==color)
    screen.pattern[j*32*8+jj+i*8]|=1<<(7-ii);
  else if ((screen.color[j*32*8+jj+i*8]&0xF)==color)
    screen.pattern[j*32*8+jj+i*8]&=~(1<<(7-ii));
  else {
    if (screen.pattern[j*32*8+jj+i*8]&(1<<(7-ii)))
      screen.color[j*32*8+jj+i*8]=((screen.color[j*32*8+jj+i*8])&0x0F)|(color<<4);
    else   
      screen.color[j*32*8+jj+i*8]=((screen.color[j*32*8+jj+i*8])&0xF0)|color;
  }  
}

void change_screen_color (int x, int y, int color) {
  int i,j,ii,jj;
  
  i=x>>3; ii=x&7;
  j=y>>3; jj=y&7;
  
  if ((screen.color[j*32*8+jj+i*8]>>4)==(screen.color[j*32*8+jj+i*8]&0xF)) 
  	screen.pattern[j*32*8+jj+i*8]=0;
  	
  if (screen.pattern[j*32*8+jj+i*8]&(1<<(7-ii)))
    screen.color[j*32*8+jj+i*8]=((screen.color[j*32*8+jj+i*8])&0x0F)|(color<<4);
  else   
    screen.color[j*32*8+jj+i*8]=((screen.color[j*32*8+jj+i*8])&0xF0)|color;
}

void update_octet (int x, int y) {
	int i;
	
	for (i=0; i<8; i++) {
    BG_GFX[(blocky*8+y)*256+(blockx*8+(x&~7)+i)]=get_screen_color(blockx*8+(x&~7)+i,blocky*8+y)|(1<<15);
    draw_square (((x&~7)+i)*12+32,y*12,get_screen_color(blockx*8+(x&~7)+i,blocky*8+y),RGB15(0,0,0));
  }  
}


void stylus_action(void) {
  int x,y;

  // check for color change
  if (touchx>256-20 && touchy>12) {
  	current_color=touchy/12;
  	return;
  }
  
  // set grid color
  x=(touchx-32)/12;
  y=touchy/12;
  
  if (x<0 || x>=16)
    return;

  if (keysHeld()&KEY_L) 
    change_screen_color(blockx*8+x,blocky*8+y,current_color);
  else  
    set_screen_color(blockx*8+x,blocky*8+y,current_color);

  update_octet(x,y);
  put_sprite_sub (32+x*12+1,y*12+1,0,0);
}

int key_repeat (int time) {
	if (time==0) return 1;
	if (time<30) return 0;
	return !(time&7);
}

void keyboard_action (void) {
	static int time=0;
	int moved=0,pressed=0;
	
	if (keysHeld()&KEY_UP) {
		pressed=1;
	  if (blocky>0 && key_repeat(time)) {
	    blocky--;
	    moved=1;
	  }  
	}
	
	if (keysHeld()&KEY_DOWN) {
		pressed=1;
	  if (blocky<22 && key_repeat(time)) {
	    blocky++;
	    moved=1;
	  }
	}
	
	if (keysHeld()&KEY_LEFT) {
		pressed=1;
	  if (blockx>0 && key_repeat(time)) {
	    blockx--;
  	  moved=1;
  	}
	}
	
	if (keysHeld()&KEY_RIGHT) {
		pressed=1;
	  if (blockx<30 && key_repeat(time)) {
	    blockx++;
	    moved=1;
	  }
	}
  
	if (moved) 
	  update_all_squares();
	  
	time=pressed?time+1:0;  
}

void preview_sub_screen() {
  dmaCopy(preview_screen,BG_GFX_SUB,256*192*2);
}

void init_sprites(void)
{
  int i,j,ii,jj;
  char sq[16][16];
  
  for(i = 0; i < 128; i++) {
     sprites_sub[i].attribute[0] = ATTR0_DISABLED;
     sprites_sub[i].attribute[1] = 0;
     sprites_sub[i].attribute[2] = 0;
     sprites_sub[i].attribute[3] = 0;
  }

	spriteRotations_sub[0].hdx=256;
	spriteRotations_sub[0].hdy=0;
	spriteRotations_sub[0].vdx=0;
	spriteRotations_sub[0].vdy=256;
 	SPRITE_PALETTE_SUB[1]=RGB15(31,31,0);

  for(i = 0; i < 128; i++) {
     sprites[i].attribute[0] = ATTR0_DISABLED;
     sprites[i].attribute[1] = 0;
     sprites[i].attribute[2] = 0;
     sprites[i].attribute[3] = 0;
  }

	spriteRotations[0].hdx=256;
	spriteRotations[0].hdy=0;
	spriteRotations[0].vdx=0;
	spriteRotations[0].vdy=256;
 	SPRITE_PALETTE[1]=RGB15(31,31,0);

  // draw 10x10 box for sub cursor
  // 16x16, each pixel is a byte, each word is 2 bytes
  // 256 pixels -> 128 words  
  for (i=0; i<16; i++)
    for (j=0; j<16; j++)
      sq[i][j]=0;
      
  for (i=0; i<11; i++) {
  	sq[0][i]=1;
  	sq[10][i]=1;
  	sq[i][0]=1;
  	sq[i][10]=1;
  }
      
  for (j=0; j<2; j++)
    for (i=0; i<2; i++)
      for (jj=0; jj<8; jj++) 
        for (ii=0; ii<4; ii++) {
        	SPRITE_GFX_SUB[jj*4+i*4*8+j*4*8*2+ii]=(sq[i*8+ii*2+1][j*8+jj]<<8)+sq[i*8+ii*2+0][j*8+jj];
        }  

  // draw 16x16 box for main cursor
  for (i=0; i<16; i++)
    for (j=0; j<16; j++)
      sq[i][j]=0;
      
  for (i=0; i<16; i++) {
  	sq[0][i]=1;
  	sq[15][i]=1;
  	sq[i][0]=1;
  	sq[i][15]=1;
  }
      
  for (j=0; j<2; j++)
    for (i=0; i<2; i++)
      for (jj=0; jj<8; jj++) 
        for (ii=0; ii<4; ii++) 
        	SPRITE_GFX[jj*4+i*4*8+j*4*8*2+ii]=(sq[i*8+ii*2+1][j*8+jj]<<8)+sq[i*8+ii*2+0][j*8+jj];
}

void init_video_bitmap (void) {
  /* enable top screen MODE 5 => BG0,BG1=tiled screens, BG2,BG3=extended rotation bitmaps */
  /* only the BG3 will be used */
  videoSetMode(MODE_5_2D | DISPLAY_BG3_ACTIVE | DISPLAY_SPR_ACTIVE | DISPLAY_SPR_1D); 

  /* enable bottom screen MODE 5 */
  videoSetModeSub(MODE_5_2D | DISPLAY_BG3_ACTIVE | DISPLAY_SPR_ACTIVE | DISPLAY_SPR_1D); 

  /* vram is divided into 4 128kb banks */
  /* I'm going to use banks 1 and 2 in the top screen, */
  /* bank 3 for background in bottom screen, bank 4 for sprites in bottom screen */
  vramSetMainBanks
    (VRAM_A_MAIN_BG_0x6000000, VRAM_B_MAIN_SPRITE,
     VRAM_C_SUB_BG_0x6200000 , VRAM_D_SUB_SPRITE);

  /* enable 16-bit bitmap mode on both screens */
  BG3_CR = BG_BMP16_256x256 | BG_WRAP_ON;
  SUB_BG3_CR = BG_BMP16_256x256  | BG_WRAP_ON;

  /* init the scroll position = top of rotation bitmap */
  /* this is a fixed point number in 1.23.8 format */
  BG3_XDX = 1 << 8;
  BG3_XDY = 0;
  BG3_YDX = 0;
  BG3_YDY = 1 << 8;
  BG3_CX = 0;
  BG3_CY = 0;

  SUB_BG3_XDX = 1 << 8;
  SUB_BG3_XDY = 0;
  SUB_BG3_YDX = 0;
  SUB_BG3_YDY = 1 << 8;
  SUB_BG3_CX = 0;
  SUB_BG3_CY = 0;
  
  init_sprites();
}

void init_video_tiled (void) {
  /* enable top screen MODE 5 => BG0,BG1=tiled screens, BG2,BG3=extended rotation bitmaps */
  /* only the BG3 will be used */
  videoSetMode(MODE_5_2D | DISPLAY_BG3_ACTIVE ); 

  /* enable bottom screen MODE 0, tiled */
  videoSetModeSub(MODE_0_2D | DISPLAY_BG0_ACTIVE ); 

  /* vram is divided into 4 128kb banks */
  /* I'm going to use banks 1 and 2 in the top screen, */
  /* bank 3 for background in bottom screen, bank 4 for sprites in bottom screen */
  vramSetMainBanks
    (VRAM_A_MAIN_BG_0x6000000, VRAM_B_MAIN_SPRITE,
     VRAM_C_SUB_BG_0x6200000 , VRAM_D_SUB_SPRITE);

  BG3_CR = BG_BMP16_256x256 | BG_WRAP_ON;
	SUB_BG0_CR = BG_MAP_BASE(31);
	consoleInitDefault((u16*)SCREEN_BASE_BLOCK_SUB(31), (u16*)CHAR_BASE_BLOCK_SUB(0), 16);

	BG_PALETTE_SUB[255] = RGB15(31,31,31);	
	BG_PALETTE_SUB[254] = RGB15(31,31,10);	

  /* init the scroll position = top of rotation bitmap */
  /* this is a fixed point number in 1.23.8 format */
  BG3_XDX = 1 << 8;
  BG3_XDY = 0;
  BG3_YDX = 0;
  BG3_YDY = 1 << 8;
  BG3_CX = 0;
  BG3_CY = 0;

  SUB_BG0_X0 = 0;
  SUB_BG0_Y0 = 0;
}

void save_sram (void) {
	int i;
	
  for (i=0; i<0x1800; i++)
    SRAM[4+i]=screen.pattern[i];
  for (i=0; i<0x1800; i++)
    SRAM[4+i+0x2000]=screen.color[i];
}


void irq_handler(void) {
  if(REG_IF & IRQ_VBLANK) {
    scanKeys();
    
    switch (global_state) {
    	case STATE_COVER:
        if (keysUp()&KEY_TOUCH) {
        	init_video_bitmap();
        	init_main_screen();
        	init_sub_screen();
  				global_state=STATE_DRAW;    	
  		  }
    	  break;
    	case STATE_DRAW:
        if (update_stylus())
          stylus_action();
        else  
          erase_sprite_sub(0);
        
        keyboard_action();  
      
        if (keysDown()&KEY_START) 
          save_sram();
          
        // main screen sprite
        put_sprite(blockx*8,blocky*8,0,0);    
        // sub screen color select sprite
        put_sprite_sub (256-12-4+1,1+current_color*12,1,0);

        if (keysDown()&KEY_R) {
        	preview_sub_screen();
          erase_sprite_sub(0);
          erase_sprite_sub(1);
          erase_sprite(0);
        	global_state=STATE_PREVIEW;
        }  
        
				break;
				
    	case STATE_PREVIEW:
    	  if (keysUp()&KEY_R) {
    		  init_sub_screen();
    		  global_state=STATE_DRAW;
    	  }
    	  break;
    }
          
    // Tell the DS we handled the VBLANK interrupt
    VBLANK_INTR_WAIT_FLAGS |= IRQ_VBLANK;
    REG_IF |= IRQ_VBLANK;
  }
  else {
    // Ignore all other interrupts
    REG_IF = REG_IF;
  }
}

void initIRQ (void) {
  REG_IME = 0;
  IRQ_HANDLER = irq_handler;
  REG_IE = 0;
  REG_IF = ~0;
  DISP_SR = DISP_VBLANK_IRQ;
  REG_IME = 1;
}

void enable_virq(void) {
  REG_IE |= IRQ_VBLANK;
}

void disable_virq(void) {
  REG_IE &= ~IRQ_VBLANK;
}

void iprintf();

void init_menu_screen(void) {
  JPEG_DecompressImage(graphos_jpg_bin, opening, 256, 192);
  dmaCopy(opening,BG_GFX,256*192*2);
  iprintf ("Graphos DS\n\n");
}

void halt(void) {
	while(1);
}

void init_sram (void) {
  int i;
  
  WAIT_CR &= ~0x80;
  
  iprintf ("Valid SRAM... ");
  if (SRAM[0]!='G' || SRAM[1]!='D' || SRAM[2]!='S') {
  	iprintf ("failed.");
  	halt();
  }
  iprintf ("ok.\n");    
  
  iprintf ("Main picture... ");
  for (i=0; i<0x1800; i++)
    screen.pattern[i]=SRAM[4+i];
  for (i=0; i<0x1800; i++)
    screen.color[i]=SRAM[4+i+0x2000];
  iprintf ("ok.\n");    
    
  iprintf ("Reference picture... ");    
  for (i=0; i<65536-4-16384; i++)
    temp_screen[i]=SRAM[4+16384+i];
  if (!JPEG_DecompressImage(temp_screen, (u16*)preview_screen, 256, 192)) {
  	iprintf ("failed.");
  	halt();
  }
  iprintf ("ok.\n");    
    
  iprintf ("\nPress the touchscreen to start");
}

int main(void) {
  initIRQ();
  keysInit();
  init_video_tiled();
  init_menu_screen();
  init_sram();
  enable_virq();
  
  while(1) swiWaitForVBlank();

  return 0;
}
