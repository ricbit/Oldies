/* Exercicio-Programa 2
 * Este programa acha as reacoes normais nas barras de uma trelica
 * Nome: Ricardo Bittencourt Vidigal Leitao
 * Turma: Eletrica-C
 * Professor: Ronaldo
 * Computador: AT 286
 * Compilador: Turbo-C v:2.0 */

/* Bibliotecas */

#include <stdio.h>
#include <math.h>

/* Constantes */
#define maxvetor 100

/* Variaveis Globais */
int     maxno,          /* Quantidade de nos */
        maxba,          /* Quantidade de barras */
        bai [maxvetor], /* Inicio da barra */
        baf [maxvetor], /* Fim da barra */
        maxf,           /* Quantidade de forcas */
        fo [maxvetor],  /* No onde esta aplicada a forca */
        fd [maxvetor],  /* Numero de forcas desconhecidas entrando no no */
        br [maxvetor]   /* Barra resolvida ? */
        ;
double  nox [maxvetor], /* Posicao x do no */
        noy [maxvetor], /* Posicao y do no */
        fox [maxvetor], /* Componente x da forca externa */
        foy [maxvetor], /* Componente y da forca externa */
        bx [maxvetor],  /* Componente x da forca normal na barra */
        by [maxvetor],  /* Componente y da forca normal na barra */
        bar [maxvetor]  /* Forca na barra */
        ;

/* Le o arquivo do disco e inicializa as variaveis globais */
void LeArquivo (void) {
  FILE *arq;
  int i;
  arq=fopen ("EP2.DAT", "r");
  fscanf (arq,"%d",&maxno);
  for (i=0; i<maxno; i++) {
    fscanf (arq,"%lf",&nox [i]);
    fscanf (arq,"%lf",&noy [i]);
  }
  fscanf (arq,"%d",&maxba);
  for (i=0; i<maxba; i++) {
    fscanf (arq,"%d",&bai [i]);
    fscanf (arq,"%d",&baf [i]);
  }
  fscanf (arq,"%d",&maxf);
  for (i=0; i<maxf; i++) {
    fscanf (arq,"%d",&fo [i]);
    fscanf (arq,"%lf",&fox [i]);
    fscanf (arq,"%lf",&foy [i]);
  }
  fclose (arq);
  for (i=0; i<maxba; i++)
    br [i]=0;
}

/* Volta 0 se a trelica esta resolvida e 1 se nao esta */
/* Alem disso, atualiza o vetor fd */
int HaBarras (void) {
  int i,k;
  k=0;
  for (i=0; i<maxno; i++)
    fd [i]=0;
  for (i=0; i<maxba; i++)
    if (!br [i]) {
      fd [bai [i]]++;
      fd [baf [i]]++;
      k=1;
    }
  return (k);
}

/* Fornece a distancia entre dois pontos */
double dist (double xa,double ya,double xb,double yb) {
  return (sqrt ((yb-ya)*(yb-ya)+(xb-xa)*(xb-xa)));
}

/* Resolve o no n (desde que o no n tenha 2 incognitas) */
void ResolveDois (int n) {
  int i,ba,bb,noa,nob;
  double a,b,sena,senb,cosa,cosb,rx,ry;
  /* Localiza as barras nao resolvidas que incidem no no' */
  ba=-1;
  for (i=0; i<maxba; i++)
    if (((bai [i]==n) || (baf [i]==n))  && (!br [i])) {
      if (ba<0)
        ba=i;
      else
        bb=i;
    }
  /* Garante que a barra inicie no no' considerado */
  if (bai [ba]==n)
    noa=baf [ba];
  else
    noa=bai [ba];
  if (bai [bb]==n)
    nob=baf [bb];
  else
    nob=bai [bb];
  /* Calcula os senos e cossenos das barras */
  sena=(noy [noa]-noy [n])/dist (nox [n],noy [n],nox [noa], noy[noa]);
  cosa=(nox [noa]-nox [n])/dist (nox [n],noy [n],nox [noa], noy[noa]);
  senb=(noy [nob]-noy [n])/dist (nox [n],noy [n],nox [nob], noy[nob]);
  cosb=(nox [nob]-nox [n])/dist (nox [n],noy [n],nox [nob], noy[nob]);
  /* Calcula a resultante das forcas externas */
  rx=0;
  ry=0;
  for (i=0; i<maxf; i++)
    if (fo [i]==n) {
      rx=rx+fox [i];
      ry=ry+foy [i];
    }
  /* Soma com as forcas em barras ja resolvidas que incidem no no' */
  for (i=0; i<maxba; i++)
    if ((br [i]) && ((bai [i]==n) || (baf [i]==n))) {
      rx=rx-bx [i];
      ry=ry-by [i];
    }
  /* Acha as forcas nas barras, resolvendo um sistema linear */
  b=(rx*sena-ry*cosa)/(senb*cosa-cosb*sena);
  a=(ry*cosb-rx*senb)/(senb*cosa-cosb*sena);
  bx [ba]=a*cosa;
  by [ba]=a*sena;
  bx [bb]=b*cosb;
  by [bb]=b*senb;
  br [ba]=1;
  br [bb]=1;
  bar [ba]=a;
  bar [bb]=b;
}

/* Resolve o no n, no caso em que ha apenas uma incognita */
/* O funcionamento e' analogo a funcao anterior */
void ResolveUm (int n) {
  int i,ba,no;
  double rx,ry,sena,cosa;
  for (i=0; i<maxba; i++)
    if ((!br [i]) && ((bai [i]==n) || (baf [i]==n)))
      ba=i;
  if (bai [ba]==n)
    no=baf [ba];
  else
    no=bai [ba];
  sena=(noy [no]-noy [n])/dist (nox [n],noy [n],nox [no], noy[no]);
  cosa=(nox [no]-nox [n])/dist (nox [n],noy [n],nox [no], noy[no]);
  rx=0;
  ry=0;
  for (i=0; i<maxf; i++)
    if (fo [i]==n) {
      rx=rx+fox [i];
      ry=ry+foy [i];
    }
  for (i=0; i<maxba; i++)
    if ((br [i]) && ((bai [i]==n) || (baf [i]==n))) {
      rx=rx-bx [i];
      ry=ry-by [i];
    }
  /* Acha as forcas nas barras, resolvendo um sistema linear */
  bx [ba]=-rx;
  by [ba]=-ry;
  br [ba]=1;
  if (cosa==0)
    bar [ba]=by [ba]/sena;
  else
    bar [ba]=bx [ba]/cosa;
}

/* Mostra os resultados */
void MostraResultados (void) {
  int i;
  printf   ("Barra     Forcas\n");
  for (i=0; i<maxba; i++) {
    printf (" %3d     %10lf",i,fabs(bar [i]));
    if (bar[i]>=0)
      printf (" (Compressao)\n");
    else
      printf (" (Tracao)\n");
  }
}

void main (void) {
  int n;
  clrscr ();
  printf ("Forcas nas barras que compoe a trelica:\n\n");
  LeArquivo ();
  n=0;
  while ((HaBarras()>0) && (n<maxba)) {
    n=0;
    while (((fd [n]>2) || (fd[n]<1)) && n<maxba) n++;
    if (fd[n]==2)
      ResolvaDois (n);
    if (fd[n]==1)
      ResolvaUm (n);
  }
  if (n<maxba)
    MostraResultados ();
  else
    printf ("Nao e possivel resolver esta trelica\n");
}

