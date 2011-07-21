#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <conio.h>
#include <math.h>
#include <allegro.h>

#define MAX_AMEBA 300
#define MAX_PLANT 50

typedef struct ameba_type {
  double color;
  double x,y;
  double dir;
  double smell;
  double smell_force;
  double vfield;
  double energy;
  double max;
  double initial_energy;
  double child_threshold;
  double child_chance;
  double falloff;
  double speed;
  double mini[40][30];
  int item[40][30];
  int active;
  int generation;
} ameba_type;

typedef struct plant_type {
  double energy;
  double x,y;
  int type;
  int active;
} plant_type;

ameba_type ameba[MAX_AMEBA];
plant_type plant[MAX_PLANT];
int last_ameba,last_plant;
double energy_pool=0;
BITMAP *field;
RGB palette[256];
int iteration=0;

void insert_random_ameba (void) {
  int i,j;

  ameba[last_ameba].color=(double)(random()%64);
  ameba[last_ameba].x=random()%(640-20);
  ameba[last_ameba].y=random()%(480-20);
  ameba[last_ameba].dir=(double)(random()%64)/64.0*2.0*PI; 
  ameba[last_ameba].smell=50*50;
  ameba[last_ameba].smell_force=0.5;
  ameba[last_ameba].vfield=PI/16.0;
  ameba[last_ameba].energy=300.0;
  ameba[last_ameba].child_threshold=600.0;
  ameba[last_ameba].child_chance=10;
  ameba[last_ameba].initial_energy=300.0;
  ameba[last_ameba].falloff=0.0095941;
  ameba[last_ameba].speed=1.0;
  ameba[last_ameba].active=1;
  ameba[last_ameba].generation=1;
  for (i=0; i<40; i++)
    for (j=0; j<30; j++) {
      ameba[last_ameba].mini[i][j]=0.0;
      ameba[last_ameba].item[i][j]=0;
    }
  last_ameba++;
}

double rand10 (void) {
  double d;
  d=1.0+((double)((random()%10000)-5000)/5000.0/2.0);
  return d;
}

void ameba_son (int a) {
  int i,j,k=0;

  for (i=0; i<MAX_AMEBA; i++)
    if (!(ameba[i].active)) {
      k=i;
      break;
    }

  ameba[k].color=ameba[a].color+(rand10()-1.0)*8.0;
  ameba[k].color=
    ameba[k].color<1.0?1.0:ameba[k].color>63.0?63.0:ameba[k].color;
  ameba[k].x=ameba[a].x;
  ameba[k].y=ameba[a].y;
  ameba[k].dir=ameba[a].dir-PI; 
  ameba[k].smell=ameba[a].smell*rand10();
  ameba[k].speed=ameba[a].speed*rand10();
  ameba[k].smell_force=ameba[a].smell_force*rand10();
  ameba[k].vfield=ameba[a].vfield*rand10();
  ameba[k].vfield=ameba[k].vfield>PI/8.0?PI/8.0:ameba[k].vfield;
  ameba[k].child_threshold=ameba[a].child_threshold*rand10();
  ameba[k].child_chance=ameba[a].child_chance*rand10();
  ameba[k].initial_energy=ameba[a].initial_energy *rand10();
  ameba[k].generation=ameba[a].generation+1;
  if (ameba[k].initial_energy>ameba[a].energy) {
    ameba[k].initial_energy=ameba[a].energy;
    ameba[k].energy=ameba[k].initial_energy;
  }
  else {
    ameba[k].energy=ameba[k].initial_energy;
  }
  ameba[a].energy-=ameba[k].energy;
  ameba[k].falloff=ameba[a].falloff*rand10();
  ameba[k].active=1;
  for (i=0; i<40; i++)
    for (j=0; j<30; j++) {
      ameba[k].mini[i][j]=0.0;
      ameba[k].item[i][j]=0;
    }
}

void insert_random_plant (void) {
  plant[last_plant].x=random()%(640-20);
  plant[last_plant].y=random()%(480-20);
  plant[last_plant].energy=200.0;
  plant[last_plant].active=1;
  last_plant++;
}

void init_field (int max_ameba) {
  int i;

  field=create_bitmap (640,480);
  for (i=64; i<128; i++) {
    palette[i].r=(i-64);
    palette[i].g=0;
    palette[i].b=63-(i-64);
    palette[i+64].r=(i-64);
    palette[i+64].g=32;
    palette[i+64].b=63-(i-64);
    palette[i+64*2].r=(i-64)/2+32;
    palette[i+64*2].g=(i-64)/2+32;
    palette[i+64*2].b=(i-64)/2+32;
  }
  palette[0].r=palette[0].g=palette[0].b=0;
  palette[1].r=palette[1].g=palette[1].b=63;
  palette[2].r=palette[2].b=0; palette[2].g=32;
  set_palette (palette);

  last_ameba=0;
  last_plant=0;

  for (i=0; i<MAX_AMEBA; i++)
    ameba[i].active=0;

  for (i=0; i<max_ameba; i++)
    insert_random_ameba ();
  for (i=0; i<20; i++)
    insert_random_plant ();
}

void draw_field (void) {
  char str[200];
  int a,p;
  int vertices[8];
  int i,j,k=0;
  int maxgen=1,mingen=1e6;

  for (i=0; i<MAX_AMEBA; i++)
    if (ameba[i].active) {
      k=i;
      break;
    }
  
  for (i=0; i<MAX_AMEBA; i++) {
    if (ameba[i].active && ameba[i].generation<mingen)
      mingen=ameba[i].generation;
    if (ameba[i].active && ameba[i].generation>maxgen)
      maxgen=ameba[i].generation;
  }

  for (i=0; i<40; i++)
    for (j=0; j<30; j++)
      rectfill (field,i*16,j*16,i*16+15,j*16+15,
                (int)(ameba[k].mini[i][j]*63.0)+128+64);
  
  for (a=0; a<MAX_AMEBA; a++) 
  if (ameba[a].active)
  {
    vertices[0]=(int) (ameba[a].x+16.0*sqrt(2.0)*cos (ameba[a].dir+PI/4.0));
    vertices[1]=(int) (ameba[a].y+16.0*sqrt(2.0)*sin (ameba[a].dir+PI/4.0));
    vertices[2]=(int) (ameba[a].x+16.0*sqrt(2.0)*cos (ameba[a].dir+3.0*PI/4.0));
    vertices[3]=(int) (ameba[a].y+16.0*sqrt(2.0)*sin (ameba[a].dir+3.0*PI/4.0));
    vertices[4]=(int) (ameba[a].x+16.0*sqrt(2.0)*cos (ameba[a].dir+5.0*PI/4.0));
    vertices[5]=(int) (ameba[a].y+16.0*sqrt(2.0)*sin (ameba[a].dir+5.0*PI/4.0));
    vertices[6]=(int) (ameba[a].x+16.0*sqrt(2.0)*cos (ameba[a].dir+7.0*PI/4.0));
    vertices[7]=(int) (ameba[a].y+16.0*sqrt(2.0)*sin (ameba[a].dir+7.0*PI/4.0));
    polygon (field,4,vertices,(int)ameba[a].color+64);
    floodfill (field,(int)ameba[a].x,(int)ameba[a].y,(int)ameba[a].color+64);
    vertices[2]=(int) (ameba[a].x+16.0*cos (ameba[a].dir+PI));
    vertices[3]=(int) (ameba[a].y+16.0*sin (ameba[a].dir+PI));
    vertices[0]=(int) ((double)vertices[2]+32.0/cos(ameba[a].vfield)*cos (ameba[a].dir+ameba[a].vfield));
    vertices[1]=(int) ((double)vertices[3]+32.0/cos(ameba[a].vfield)*sin (ameba[a].dir+ameba[a].vfield));
    vertices[6]=(int) ((double)vertices[2]+32.0/cos(ameba[a].vfield)*cos (ameba[a].dir-ameba[a].vfield));
    vertices[7]=(int) ((double)vertices[3]+32.0/cos(ameba[a].vfield)*sin (ameba[a].dir-ameba[a].vfield));
    line (field,vertices[2],vertices[3],vertices[6],vertices[7],(int)ameba[a].color+128);
    line (field,vertices[2],vertices[3],vertices[0],vertices[1],(int)ameba[a].color+128);
    line (field,vertices[6],vertices[7],vertices[0],vertices[1],(int)ameba[a].color+128);
    floodfill (field,(int)ameba[a].x,(int)ameba[a].y,(int)ameba[a].color+128);
    sprintf (str,"%d",(int)ameba[a].energy);
    textout (field,font,str,(int)ameba[a].x-8-4,(int)ameba[a].y-4,1);
  }
  
  for (p=0; p<last_plant; p++) 
    if (plant[p].active)
      circlefill (field,(int)plant[p].x,(int)plant[p].y,8,2);
  
  sprintf (str,"%6d",iteration++);
  textout (field,font,str,640-6*8,480-8,1);
  sprintf (str,"gen [%4d,%4d]",mingen,maxgen);
  textout (field,font,str,0,480-8,1);
  blit (field,screen,0,0,0,0,640,480);
}

double eval_single_ameba (int a, double x, double y) {
  double total=0.0;
  double dx,dy,dist;
  int p;

  for (p=0; p<last_plant; p++) 
  if (plant[p].active)
  {
    dx=x-plant[p].x;
    dy=y-plant[p].y;
    dist=dx*dx+dy*dy+1e-6;
    if (ameba[a].energy*ameba[a].energy>dist)
      total+=ameba[a].mini[((int)plant[p].x)/16][((int)plant[p].y)/16]/dist;
  }
  return total;
}

void free_plant (int p) {
  plant[p].active=0;
  plant[p].x=random()%(640-20);
  plant[p].y=random()%(480-20);
}

void eval_field (void) {
  int a;
  int p;
  int i,j;
  double x,y;
  double d1,d2;
  double dx1,dy1,dx2,dy2;
  double pfront,p1,p2;
  double energy_spent;
  int eat;

  for (p=0; p<last_plant; p++)
    if (!plant[p].active && energy_pool>200.0) {
      plant[p].active=1;
      energy_pool-=200.0;
    }

  for (a=MAX_AMEBA-1; a>=0; a--) 
  if (ameba[a].active)
  {
    for (i=0; i<40; i++)
      for (j=0; j<30; j++) 
        ameba[a].mini[i][j]*=0.7;

    d1=ameba[a].dir+ameba[a].vfield*2.0;
    d2=ameba[a].dir-ameba[a].vfield*2.0;

    dx1=cos(d1-PI/2.0); dy1=sin(d1-PI/2.0);
    dx2=cos(d2+PI/2.0); dy2=sin(d2+PI/2.0);
    
    for (i=0; i<40; i++)
      for (j=0; j<30; j++) {
        x=(double)(i*16)- ameba[a].x;
        y=(double)(j*16)- ameba[a].y;
        if (x*dx1+y*dy1>0.0 && x*dx2+y*dy2>0.0)
          ameba[a].mini[i][j]+=exp(-ameba[a].falloff*(sqrt(x*x+y*y)));
      }
  
    for (i=0; i<40; i++)
      for (j=0; j<30; j++) {
        x=(double)(i*16)- ameba[a].x;
        y=(double)(j*16)- ameba[a].y;
        if (x*x+y*y<ameba[a].smell) {
          ameba[a].mini[i][j]+=ameba[a].smell_force;
        }
        ameba[a].mini[i][j]=ameba[a].mini[i][j]>1.0?1.0:ameba[a].mini[i][j];
      }
  
    eat=0;
    for (p=0; p<last_plant; p++) 
    if (plant[p].active)
    {
      x=ameba[a].x - plant[p].x;
      y=ameba[a].y - plant[p].y;
      if (x*x+y*y<16*16) {
        ameba[a].energy+=plant[p].energy;
        eat=1;
        free_plant (p);
        break;
      }
    }

    if (!eat) {
      dx1=cos (ameba[a].dir+PI/4.0/16.0);
      dy1=sin (ameba[a].dir+PI/4.0/16.0);
      dx2=cos (ameba[a].dir-PI/4.0/16.0);
      dy2=sin (ameba[a].dir-PI/4.0/16.0);
      pfront=eval_single_ameba (a,ameba[a].x,ameba[a].y);        
      p1=eval_single_ameba (a,ameba[a].x+dx1*10.0,ameba[a].y+dy1*10.0);        
      p2=eval_single_ameba (a,ameba[a].x+dx2*10.0,ameba[a].y+dy2*10.0);        
             
      if (pfront+p1+p2<1e-6) {
        ameba[a].dir+=PI/4.0/16.0;
        ameba[a].x+=ameba[a].speed*cos (ameba[a].dir);
        ameba[a].y+=ameba[a].speed*sin (ameba[a].dir);
        energy_spent=ameba[a].speed;
        ameba[a].energy-=energy_spent;
        energy_pool+=energy_spent;
      } else   
      
      if (pfront>p1 && pfront>p2) {
        ameba[a].x+=ameba[a].speed*cos (ameba[a].dir);
        ameba[a].y+=ameba[a].speed*sin (ameba[a].dir);
        ameba[a].max=pfront;
      } else if (p1>p2) {
        ameba[a].dir+=PI/4.0/16.0;
        ameba[a].x+=ameba[a].speed*cos (ameba[a].dir);
        ameba[a].y+=ameba[a].speed*sin (ameba[a].dir);
        ameba[a].max=p1;
      } else {
        ameba[a].dir-=PI/4.0/16.0;
        ameba[a].x+=ameba[a].speed*cos (ameba[a].dir);
        ameba[a].y+=ameba[a].speed*sin (ameba[a].dir);
        ameba[a].max=p2;
      }

      energy_spent=ameba[a].speed;
      ameba[a].energy-=energy_spent;
      energy_pool+=energy_spent;
      if (ameba[a].energy<0.0)
        ameba[a].active=0;

      if (ameba[a].energy>ameba[a].child_threshold && 
          (double)(random()%100)<ameba[a].child_chance)
        ameba_son (a);
    }  
  }
}

int main (int argc, char **argv) {
  int frame=0;

  allegro_init ();
  printf ("Criacao de Amebas v1.0\n");
  printf ("Copyright (C) 2000 por Ricardo Bittencourt\n\n");

  if (argc<2) {
    printf ("Uso:\tameba n\n\t(onde n = numero inicial de amebas)\n");
    exit (1);
  }
  
  srandom (time (NULL));

  printf ("Aperte enter para comecar...");
  fflush (stdout);
  getch ();

  set_gfx_mode (GFX_AUTODETECT,640,480,640,480);
  init_field (atoi (argv[1]));
  while (!kbhit ()) {
    eval_field ();
    if (!(frame++%5)) draw_field ();
  }

  allegro_exit ();
  return 0;
}
