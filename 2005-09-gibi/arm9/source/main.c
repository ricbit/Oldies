/*---------------------------------------------------------------------------------

  Gibi Reader v1.0 
  Copyright (C) 2005 by Ricardo Bittencourt
  start date: 2005.10.19  
  last update: 2005.10.19

---------------------------------------------------------------------------------*/

#include "nds.h"
#include "shaolin_bin.h"

SpriteEntry sprites[128];
pSpriteRotation spriteRotations = (pSpriteRotation)sprites;
    int sx=0,sy=0;

/* every other bottom screen symbol starts with SUB_, why not this one? */
#define SUB_BG_GFX BG_GFX_SUB

void display_image_line (const u8 *image, int source_line, int video_line) {
  int r,g,b,i;
  
  image+=source_line*512*3;
  video_line*=512;
  for (i=0; i<512; i++) {
    r=image[i*3+0];
    g=image[i*3+1];
    b=image[i*3+2];
    BG_GFX[video_line+i]=RGB15(r>>3,g>>3,b>>3) | (1<<15);
  }
}

void display_image_line_256 (const u8 *image, int source_line, int video_line) {
  int r,g,b,i;
  
  image+=source_line*1024*3;
  video_line*=256;
  for (i=0; i<256; i++) {
    r=image[2*i*3+0]+image[2*i*3+3]+image[2*i*3+0+512*3]+image[2*i*3+3+512*3];
    g=image[2*i*3+1]+image[2*i*3+4]+image[2*i*3+1+512*3]+image[2*i*3+4+512*3];
    b=image[2*i*3+2]+image[2*i*3+5]+image[2*i*3+2+512*3]+image[2*i*3+5+512*3];
    SUB_BG_GFX[video_line+i]=RGB15(r>>5,g>>5,b>>5) | (1<<15);
  }
}

void init_image (const u8 *image) {
  int j;
  
  for (j=0; j<256; j++)
    display_image_line (image,j,j);
  
  for (j=0; j<256; j++)
    display_image_line_256 (image,j,j);
}

void scroll_image_down (const u8 *image, int *scroll) {
  int i;
  int height=753;

  if (*scroll+8+192>height)
    return;
  
  BG3_CY=(*scroll+8)<<8;
  
  for (i=0; i<8; i++) 
    display_image_line (image,*scroll+256+i,(*scroll+i)%256);
  
  *scroll+=8;
}

void scroll_image_up (const u8 *image, int *scroll) {
  int i;

  if (*scroll-8<0)
    return;
  
  for (i=0; i<8; i++)
    display_image_line (image,*scroll+i-8,(*scroll+i-8)%256);

  BG3_CY=(*scroll-8)<<8;
    
  *scroll-=8;
}

//---------------------------------------------------------------------------------

/* turn off all the sprites */
void init_sprites(void)
{
  int i,j;
  
  for(i = 0; i < 128; i++) {
     sprites[i].attribute[0] = ATTR0_DISABLED;
     sprites[i].attribute[1] = 0;
     sprites[i].attribute[2] = 0;
     sprites[i].attribute[3] = 0;
  }

	sprites[0].attribute[0] = ATTR0_TALL | ATTR0_COLOR_256 | ATTR0_ROTSCALE_DOUBLE | 75;
	sprites[0].attribute[1] = ATTR1_SIZE_32 | 20; 
	sprites[0].attribute[2] = 64;

	spriteRotations[0].hdx=256;
	spriteRotations[0].hdy=0;
	spriteRotations[0].vdx=0;
	spriteRotations[0].vdy=256;
 	SPRITE_PALETTE_SUB[1]=RGB15(0,0,31);

  dmaCopy(sprites, OAM_SUB, 128*sizeof(SpriteEntry));

  // 32x32 -> 8=256 => x=192/256*8=6
	for(i=0; i<32*16; i++)
		SPRITE_GFX_SUB[i+64*16]=(1<<8)|1;

	for(j=0; j<6; j++)
	  for (i=0; i<4; i++)
		  SPRITE_GFX_SUB[i*8+j+64*16]=0;
}

//---------------------------------------------------------------------------------

void irq_handler(void) {
  if(REG_IF & IRQ_VBLANK) {
    scanKeys();
    u16 a=keysHeld();
    if (a & KEY_RIGHT) sx+=8*256;
    if (a & KEY_LEFT) sx-=8*256;
    if (a & KEY_UP) scroll_image_up(shaolin_bin, &sy);
    if (a & KEY_DOWN) scroll_image_down(shaolin_bin, &sy);
    sx=sx<0?0:sx>256*256?256*256:sx;
    BG3_CX=sx;

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

int main(void) {


  initIRQ();

  /* enable top screen MODE 5 => BG0,BG1=tiled screens, BG2,BG3=extended rotation bitmaps */
  /* only the BG3 will be used */
  videoSetMode(MODE_5_2D | DISPLAY_BG3_ACTIVE);

  /* enable bottom screen MODE 5 */
  videoSetModeSub(MODE_5_2D | DISPLAY_BG3_ACTIVE | DISPLAY_SPR_ACTIVE | DISPLAY_SPR_1D); 

  /* vram is divided into 4 128kb banks */
  /* I'm going to use banks 1 and 2 in the top screen, */
  /* bank 3 for background in bottom screen, bank 4 for sprites in bottom screen */
  vramSetMainBanks
    (VRAM_A_MAIN_BG_0x6000000, VRAM_B_MAIN_BG_0x6020000,
     VRAM_C_SUB_BG_0x6200000 , VRAM_D_SUB_SPRITE);

  /* enable 16-bit bitmap mode on both screens */
  BG3_CR = BG_BMP16_512x256 | BG_WRAP_ON;
  SUB_BG3_CR = BG_BMP16_256x256  | BG_WRAP_ON;

  /* init the rotation parameters for the extended rotation bitmaps */
  BG3_XDX = 1 << 8;
  BG3_XDY = 0;
  BG3_YDX = 0;
  BG3_YDY = 1 << 8;
  SUB_BG3_XDX = 1 << 8;
  SUB_BG3_XDY = 0;
  SUB_BG3_YDX = 0;
  SUB_BG3_YDY = 1 << 8;
    
  /* init the scroll position = top of rotation bitmap */
  /* this is a fixed point number in 1.23.8 format */
  BG3_CX = 0;
  BG3_CY = 0;
  SUB_BG3_CX = 0;
  SUB_BG3_CY = 0;

  init_image(shaolin_bin);
  init_sprites();
  enable_virq();
  
  while(1) {
  	swiWaitForVBlank();
  }

  return 0;
}
