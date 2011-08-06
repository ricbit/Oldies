#include <stdio.h>

#define SIZE 31

typedef struct {
  int x1,y1,x2,y2;
} wall_type;

int maze[SIZE][SIZE];

int maxwall=0;
wall_type wall[SIZE*SIZE*4];

int test_line (int x, int y, int i, int j) {
  int ii,a;
  int x1,x2,x3,x4,y1,y2,y3,y4;

  a=0;
  for (ii=0; ii<maxwall; ii++) {
    if (i==wall[ii].x1 && j==wall[ii].y1)
      continue;
    if (i==wall[ii].x2 && j==wall[ii].y2)
      continue;

    x1=x; x2=i; x3=wall[ii].x1; x4=wall[ii].x2;
    y1=y; y2=j; y3=wall[ii].y1; y4=wall[ii].y2;
    if (((x4-x3)*(y1-y3)-(y4-y3)*(x1-x3))<0)
      continue;
    if (((x2-x1)*(y1-y3)-(y2-y1)*(x1-x3))<0)
      continue;
    if (((x4-x3)*(y1-y3)-(y4-y3)*(x1-x3))>((y4-y3)*(x2-x1)-(x4-x3)*(y2-y1)))
      continue;
    if (((x2-x1)*(y1-y3)-(y2-y1)*(x1-x3))>((y4-y3)*(x2-x1)-(x4-x3)*(y2-y1)))
      continue;
    a=1;
  }
  return a;
}

int test_point (int x, int y, int i, int j) {
  return 
    test_line (x,y,i,j)&
    test_line (x,y,i+1,j)&
    test_line (x,y,i,j+1)&
    test_line (x,y,i+1,j+1);
}

void vis (int x, int y) {
  int i,j,a;
  int m2[SIZE][SIZE];

  for (j=0; j<SIZE; j++)
    for (i=0; i<SIZE; i++) {
      m2[i][j]=0;

      if (maze[i][j]) 
        continue;

      if (i==x && j==y)
        continue;

      a=test_point (x,y,i,j);
      a&=test_point (x+1,y,i,j);
      a&=test_point (x,y+1,i,j);
      a&=test_point (x+1,y+1,i,j);
      m2[i][j]=a?0:2;
    }

  for (j=0; j<SIZE; j++) {
    for (i=0; i<SIZE; i++)
      printf (i==x&&j==y?"+":m2[i][j]==2?"-":maze[i][j]?"X":" ");
    printf ("\n");
  }
  printf ("\n");      
}

void insert_wall (int x1, int y1, int x2, int y2) {
  wall[maxwall].x1=x1;
  wall[maxwall].y1=y1;
  wall[maxwall].x2=x2;
  wall[maxwall].y2=y2;
  maxwall++;
}

void build_wall (void) {
  int i,j;

  for (j=1; j<SIZE-1; j++)
    for (i=1; i<SIZE-1; i++) {
      if (maze[i][j]==0 && maze[i][j-1]!=0)
        insert_wall (i,j,i+1,j);
      if (maze[i][j]==0 && maze[i+1][j]!=0)
        insert_wall (i+1,j,i+1,j+1);
      if (maze[i][j]==0 && maze[i][j+1]!=0)
        insert_wall (i+1,j+1,i,j+1);
      if (maze[i][j]==0 && maze[i-1][j]!=0)
        insert_wall (i,j+1,i,j);
    }
}

int main (int argc, char **argv) {
  FILE *f;
  int i,j;
  char temp[255],*s;

  f=fopen (argv[1],"rt");
  for (j=0; j<SIZE; j++) {
    s=fgets (temp,255,f);
    for (i=0; i<SIZE; i++)
      maze[i][j]=s[i]=='X';
  }
  fclose (f);

  for (j=0; j<SIZE; j++) {
    for (i=0; i<SIZE; i++)
      printf (maze[i][j]?"X":" ");
    printf ("\n");
  }

  build_wall();

  for (j=0; j<SIZE; j++) 
    for (i=0; i<SIZE; i++)
      if (!maze[i][j])
        vis (i,j);

  return 0;
}
