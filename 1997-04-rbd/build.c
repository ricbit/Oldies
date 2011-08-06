#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys\stat.h>

typedef struct {
  double x,y,z,u,v;
} vertex;

typedef struct {
  int a,b,c;
} triangle;

vertex *vertexmap;
triangle *trianglemap;
int maxvertex,maxtriangle;

void init_vertices (int total) {
  vertexmap=(vertex *) malloc (total*sizeof (vertex));
  printf ("Initial vertices: %d\n",total);
  maxvertex=total;
}

void init_triangles (int total) {
  trianglemap=(triangle *) malloc (total*sizeof (triangle));
  printf ("Initial triangles: %d\n",total);
  maxtriangle=total;
}

void insert_triangle (int number, int a, int b, int c) {
  trianglemap[number].a=a;
  trianglemap[number].b=b;
  trianglemap[number].c=c;
}

void insert_vertex 
  (int number, double x, double y, double z, double u, double v) 
{
  vertexmap[number].x=x;
  vertexmap[number].y=y;
  vertexmap[number].z=z;
  vertexmap[number].u=u;
  vertexmap[number].v=v;
}

void save (char *name) {
  int file;
  int i;

  file=open (name,O_BINARY|O_CREAT|O_WRONLY,S_IRUSR|S_IWUSR);
  write (file,&maxvertex,sizeof (int));
  for (i=0; i<maxvertex; i++)
    write (file,vertexmap+i,sizeof (vertex));
  write (file,&maxtriangle,sizeof (int));
  for (i=0; i<maxtriangle; i++)
    write (file,trianglemap+i,sizeof (triangle));
  close (file);
}

void main (int argc, char **argv) {
  extern FILE *yyin;

  printf ("Build 1.0 \n");
  printf ("by Ricardo Bittencourt \n\n");
  yyin=fopen (argv[1],"r");
  if (yyin==NULL) {
    printf ("This file doesn't exist. \n");
    exit (1);
  }
  yyparse ();
  save (argv[2]);
}

