#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define half 16
#define tm half*2

void main (void) {
  FILE *f;
  int a[tm][tm],i,j,x1,y1,x2,y2,tot;
  char c;
  f=fopen ("mapa.txt","r");
  i=j=0;
  while (!feof (f)) {
    fscanf (f,"%c",&c);
    if (c=='.') {
      a[i][j]=0;
      i++;
      if (i==tm) {
        i=0;
        j++;
      }
    }
    if (c=='x') {
      a[i][j]=1;
      i++;
      if (i==tm) {
        i=0;
        j++;
      }
    }
    printf ("%c",c);
  }
  fclose (f);
  for (i=0; i<tm; i++) {
    for (j=0; j<tm; j++)
      printf ("%d",a[i][j]);
    printf ("\n");
  }
  tot=0;
  for (j=0; j<tm; j++)
    for (i=0; i<tm-1; i++)
      if (a[i][j]!=a[i+1][j])
        tot++;
  for (i=0; i<tm; i++)
    for (j=0; j<tm-1; j++)
      if (a[i][j]!=a[i][j+1])
        tot++;
  f=fopen ("walls.txt","w");
  printf ("Total de paredes: %d\n",tot);
  fprintf (f,"%d\n",tot);
  printf ("Atravessando na direcao de i:\n");
  for (j=0; j<tm; j++)
    for (i=0; i<tm-1; i++)
      if (a[i][j]!=a[i+1][j]) {
        printf ("Parede found: %d %d ",i,j);
        printf ("[(%d,%d)-(%d,%d)]\n",i-half,j-half,i-half,j-half-1);
        x1=(i-half)*2;
        y1=(j-half)*2;
        x2=(i-half)*2;
        y2=(j-half-1)*2;
        fprintf (f,"%d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 ",x1,-1,y1,x2,-1,y2,x2,1,y2,x1,1,y1);
        if (a[i][j]==0)
          fprintf (f,"-1.0 0.0 0.0 %d.0\n",x1);
        else
          fprintf (f,"1.0 0.0 0.0 %d.0\n",-x1);
      }
  printf ("Atravessando na direcao de j:\n");
  for (i=0; i<tm; i++)
    for (j=0; j<tm-1; j++)
      if (a[i][j]!=a[i][j+1]) {
        printf ("Parede found: %d %d ",i,j);
        printf ("[(%d,%d)-(%d,%d)]\n",i-4,j-4,i-4-1,j-4);
        x1=(i-half)*2;
        y1=(j-half)*2;
        x2=(i-half-1)*2;
        y2=(j-half)*2;
        fprintf (f,"%d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 %d.0 ",x1,-1,y1,x2,-1,y2,x2,1,y2,x1,1,y1);
        if (a[i][j]==0)
          fprintf (f,"0.0 0.0 -1.0 %d.0\n",y1);
        else
          fprintf (f,"0.0 0.0 1.0 %d.0\n",-y1);
      }
  fclose (f);
}