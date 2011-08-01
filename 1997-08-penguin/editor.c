#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <allegro.h>

typedef unsigned char byte;

typedef struct shapelink {
  BITMAP *image;
  int number;
  struct shapelink *next;
} shapelink;

typedef struct stagelink {
  RLE_SPRITE *image;
  int number;
  int x,y;
  struct stagelink *next;
} stagelink;

BITMAP *currentimage;           
RGB pal[256];
stagelink *plane[7];
shapelink *shapebuffer=NULL;
int actualnumber=0;
int globaloffset=0;

void readimage (void) {
  char name[200];

  printf ("name: ");
  scanf ("%s",name);
  currentimage=load_bitmap (name,pal);
  if (currentimage==NULL) {
    printf ("error reading file\n");
  }
  set_gfx_mode (GFX_VGA,320,200,320,200);
  set_palette (pal);
  blit (currentimage,screen,0,0,0,0,320,200);
  getch ();
  set_gfx_mode (GFX_TEXT,80,24,80,24);
}

shapelink *insert_bitmap (shapelink *root, BITMAP *bitmap) {
  shapelink *p;

  if (root==NULL) {
    root=(shapelink *) malloc (sizeof (shapelink));
    p=root;
  }
  else {
    p=root;
    while (p->next!=NULL) 
      p=p->next;
    p->next=(shapelink *) malloc (sizeof (shapelink));
    p=p->next;
  }
  p->image=bitmap;
  p->next=NULL;
  p->number=actualnumber++;
  return root;
}

void removegrid (BITMAP *shape) {
  int i;
  int size;

  size=shape->w*shape->h;
  for (i=0; i<size; i++)
    if (((byte *)shape->dat)[i]<128)
      ((byte *)shape->dat)[i]=0;
}

void get_shape (void) {
  int x1,y1,x2,y2,lx,ly;
  BITMAP *thisone;
  
  set_gfx_mode (GFX_VGA,320,200,320,200);
  set_palette (pal);
  blit (currentimage,screen,0,0,0,0,320,200);
  show_mouse (screen);
  while (mouse_b&1);
  while (!(mouse_b&1));
  x1=mouse_x&(0xfff8);
  y1=mouse_y&(0xfff8);
  while (mouse_b&1);
  lx=x1; ly=y1;
  while (!(mouse_b&1)) {
    x2=(mouse_x&0xfff8)|7;
    y2=(mouse_y&0xfff8)|7;
    if (x2!=lx || y2!=ly) {
      show_mouse (NULL);
      blit (currentimage,screen,0,0,0,0,320,200);
      xor_mode (TRUE);
      rect (screen,x1,y1,x2,y2,255);
      xor_mode (FALSE);
      lx=x2; ly=y2;
      show_mouse (screen);
    }
  }
  show_mouse (NULL);
  blit (currentimage,screen,0,0,0,0,320,200);
  thisone=create_bitmap (x2-x1+1,y2-y1+1);
  blit (screen,thisone,x1,y1,0,0,x2-x1+1,y2-y1+1);
  removegrid (thisone);
  shapebuffer=insert_bitmap (shapebuffer,thisone);
  set_gfx_mode (GFX_TEXT,80,24,80,24);
}

void view_shapes (void) {
  shapelink *p=shapebuffer;

  set_gfx_mode (GFX_VGA,320,200,320,200);
  set_palette (pal);
  do {
    clear_to_color (screen,0);
    blit (p->image,screen,0,0,0,0,p->image->w,p->image->h);
    getch ();
    p=p->next;
  } while (p!=NULL);
  set_gfx_mode (GFX_TEXT,80,24,80,24);
}

void save_all (void) {
  shapelink *p=shapebuffer;  
  stagelink *s;
  char name[200];
  int i;
  FILE *file;
  
  while (p!=NULL) {
    sprintf (name,"shape%03d.pcx",p->number);
    printf ("\nwriting %s...",name);
    save_pcx (name,p->image,pal);
    p=p->next;
  }
  file=fopen ("scene.txt","w");
  for (i=0; i<7; i++) {
    s=plane[i];
    while (s!=NULL) {
      fprintf (file,"%d\n%d %d\n",s->number,s->x,s->y);
      s=s->next;
    }
    fprintf (file,"-1\n");
  }
  fclose (file);
}

BITMAP *retrieveshape (int number) {
  shapelink *p=shapebuffer;

  while (p!=NULL && p->number!=number) {
    p=p->next;
  }
  if (p!=NULL)
    return p->image;
  else
    return NULL;
}

void read_all (void) {
  FILE *file;
  int i;
  int shape,x,y;

  file=fopen ("scene.txt","r");
  for (i=0; i<7;) {
    fscanf (file,"%d",&shape);
    if (shape==-1)
      i++;
    else {
      fscanf (file,"%d %d",&x,&y);        

    }
  }
}

void draw_plane (int planenumber) {
  stagelink *p;

  if (plane[planenumber]==NULL)
    return;
  p=plane[planenumber];
  while (p!=NULL) {
    draw_rle_sprite (screen,p->image,p->x,p->y);
    p=p->next;
  }
}

void insert_screl (int planenumber, int shapenumber, int x, int y) {
  stagelink *p;
  BITMAP *shape;

  if (plane[planenumber]==NULL) {
    plane[planenumber]=(stagelink *) malloc (sizeof (stagelink));
    p=plane[planenumber];
  }
  else {
    p=plane[planenumber];
    while (p->next!=NULL)
      p=p->next;
    p->next=(stagelink *) malloc (sizeof (stagelink));
    p=p->next;
  }
  shape=retrieveshape (shapenumber);
  p->image=get_rle_sprite (shape);
  p->number=shapenumber;
  p->x=x;
  p->y=y;
  p->next=NULL;
}

void drawgrid (void) {
  int x,y;

  for (y=0; y<200; y++)
    for (x=0; x<320; x++)
      if (((x/8)+(y/8))%2)
        putpixel (screen,x,y,1);
      else
        putpixel (screen,x,y,2);
}

void put_shape (void) {
  int shape=0;
  BITMAP *image;
  char c;
  int planenumber;
  int x,y;
  int i;  
  int planescape[7];

  printf ("select a plane: ");
  scanf ("%d",&planenumber);
  set_gfx_mode (GFX_VGA,320,200,320,200);
  set_palette (pal);
  do {
    clear_to_color (screen,0);
    image=retrieveshape (shape);
    blit (image,screen,0,0,0,0,image->w,image->h);
    c=getch ();
    if (!c) {
      switch (getch ()) {
        case KEY_RIGHT:
          shape++;
          if (shape==actualnumber) 
            shape=0;
          break;
        case KEY_LEFT:
          shape--;
          if (shape<0) 
            shape=actualnumber-1;
          break;
      }
    }
  } while (c!=27 && c!=13);
  for (i=0; i<=planenumber; i++)
    planescape[i]=1;
  if (c==13) {
    drawgrid ();
    for (i=0; i<=planenumber; i++)
      if (planescape[i])
        draw_plane (i);
    while (mouse_b&1);
    set_mouse_sprite (image);
    show_mouse (screen);
    while (!(mouse_b&1)&&!(mouse_b&2)) {
      if (kbhit()) {
        switch (c=getch ()) {
          case '1':
          case '2':
          case '3':
          case '4':
          case '5':
          case '6':
          case '7':
            planescape[c-'1']^=1;
        }
        show_mouse (NULL);
        drawgrid ();
        for (i=0; i<=planenumber; i++)
          if (planescape[i])
            draw_plane (i);
        show_mouse (screen);
      }
    }
    if (mouse_b&2) {
      x=0; y=0;
    }
    else {
      x=mouse_x-1; y=mouse_y-1;
    }
    show_mouse (NULL);
    set_mouse_sprite (NULL);
    insert_screl (planenumber,shape,x,y);
  }
  set_gfx_mode (GFX_TEXT,80,24,80,24);
}

void view_level (void) {
  int i;

  set_gfx_mode (GFX_VGA,320,200,320,200);
  set_palette (pal);
  clear_to_color (screen,0);
  for (i=0; i<7; i++) 
    draw_plane (i);
  getch ();
  set_gfx_mode (GFX_TEXT,80,24,80,24);
}

void mainloop (void) {
  int exitnow=0;
  int option;

  do {
    clrscr ();
    printf ("scenario editor 1.0\n\n");
    printf ("\n");
    printf ("1 - read image from disk\n");
    printf ("2 - view current level\n");
    printf ("3 - get new shape\n");
    printf ("4 - view shapes\n");
    printf ("5 - save all\n");
    printf ("6 - put shape\n");
    printf ("7 - load all\n");
    printf ("0 - exit\n");
    printf ("\nSelect: ");
    scanf ("%d",&option);
    switch (option) {
      case 1:
        readimage ();
        break;
      case 2:
        view_level ();
        break;
      case 3:
        get_shape ();
        break;
      case 4:
        view_shapes ();
        break;
      case 5:
        save_all ();
        break;
      case 6:
        put_shape ();
        break;
      case 7:
        read_all ();
        break;
      case 0:
        exitnow=1;
        break;
    }
  } while (!exitnow);
}

void stageinit (void) {
  int i;

  for (i=0; i<7; i++)
    plane[i]=NULL;
}

void main (void) {
  allegro_init ();
  install_timer ();
  install_mouse ();
  stageinit ();
  mainloop ();
  allegro_exit ();
}

