#include <stdio.h>
#include <stdlib.h>

#define B(i,j) (((i)>=0 && (i)<=7 && (j)>=0 && (j)<=7)?board[(j)*8+(i)]:0)
#define M(i,j) (board[(j)*8+(i)])

#define ATTR 200
#define SIZE 16

typedef struct {
  double attr[ATTR];
  int wins;
  int life;
} player;

player ps[SIZE];

void reset_board (char *board) {
  int i,j;

  for (i=0; i<64; i++)
    board[i]=32;

  for (j=0; j<8; j++) {
    for (i=0; i<8; i++)
      if ((i+j)%2) {
        if (j<3)
          board[j*8+i]='x';
        else if (j>4) 
          board[j*8+i]='o';
        else 
          board[j*8+i]='.';
      }
  }

}

void print_board (char *board) {
  int i,j;

  for (j=0; j<8; j++)  {
    for (i=0; i<8; i++)
      printf ("%c",board[j*8+i]);
    printf ("\n");
  }
  printf ("--------\n\n");
}

double eval_board (char *board, double *p1) {
  double total=0.0;
  int i,j;

  /* absolute position */
/*  for (i=0; i<64; i++) {
    if (board[i]=='o' || board[i]=='O')
      total+=p1[i];
    if (board[i]=='x' || board[i]=='X')
      total+=p1[i+64];
  }*/

  /* pure random */
  //total+=((double)rand()/(double)RAND_MAX)*p1[128];

  /* number of queens */
  for (j=0; j<8; j++) 
    for (i=0; i<8; i++) {
      if (B(i,j)=='O')
        total+=p1[129];
      if (B(i,j)=='X')
        total+=p1[130];
    }

  /* degrees of freedom */
  for (j=0; j<8; j++) 
    for (i=0; i<8; i++) {
      if (B(i,j)=='o' && B(i-1,j-1)=='.')
        total+=p1[131];
      if (B(i,j)=='o' && B(i+1,j-1)=='.')
        total+=p1[132];

      if (B(i,j)=='O' && B(i-1,j-1)=='.')
        total+=p1[133];
      if (B(i,j)=='O' && B(i+1,j-1)=='.')
        total+=p1[134];
      if (B(i,j)=='O' && B(i-1,j+1)=='.')
        total+=p1[135];
      if (B(i,j)=='O' && B(i+1,j+1)=='.')
        total+=p1[136];

      if (B(i,j)=='x' && B(i-1,j+1)=='.')
        total+=p1[137];
      if (B(i,j)=='x' && B(i+1,j+1)=='.')
        total+=p1[138];

      if (B(i,j)=='X' && B(i-1,j-1)=='.')
        total+=p1[139];
      if (B(i,j)=='X' && B(i+1,j-1)=='.')
        total+=p1[140];
      if (B(i,j)=='X' && B(i-1,j+1)=='.')
        total+=p1[141];
      if (B(i,j)=='X' && B(i+1,j+1)=='.')
        total+=p1[142];

      if (B(i,j)=='o' && B(i-1,j-1)=='.' && (B(i-2,j-2)=='x'||B(i-2,j-2)=='X'))
        total+=p1[143];
      if (B(i,j)=='o' && B(i+1,j-1)=='.' && (B(i+2,j-2)=='x'||B(i+2,j-2)=='X'))
        total+=p1[144];

      if (B(i,j)=='O' && B(i-1,j-1)=='.' && (B(i-2,j-2)=='x'||B(i-2,j-2)=='X'))
        total+=p1[145];
      if (B(i,j)=='O' && B(i+1,j-1)=='.' && (B(i+2,j-2)=='x'||B(i+2,j-2)=='X'))
        total+=p1[146];
      if (B(i,j)=='O' && B(i-1,j+1)=='.' && (B(i-2,j+2)=='x'||B(i-2,j+2)=='X'))
        total+=p1[147];
      if (B(i,j)=='O' && B(i+1,j+1)=='.' && (B(i+2,j+2)=='x'||B(i+2,j+2)=='X'))
        total+=p1[148];
    }

  /* number of pieces */
  for (j=0; j<8; j++) 
    for (i=0; i<8; i++) {
      if (B(i,j)=='o')
        total+=p1[149];
      if (B(i,j)=='x')
        total+=p1[150];
    }

  return total;
}


int check_movements (char *board, double *player) {
  int i,j,p1,p2,x1,y1,x2,y2;
  char temp,temp2;
  int moves[256],total;
  double points[256];
  int kmoves[256],ktotal;
  double kpoints[256];


  total=0;
  ktotal=0;
  for (j=0; j<8; j++)  {
    for (i=0; i<8; i++) {
      if ((B(i,j)=='o'||B(i,j)=='O') && B(i-1,j-1)=='.') {
        temp=M(i,j);
        M(i,j)='.';
        M(i-1,j-1)=temp;
        if (j-1==0)
          M(i-1,j-1)='O';
        points[total]=eval_board (board,player);
        moves[total++]=((j-1)*8+(i-1))*64+(j*8+i);
        M(i,j)=temp;
        M(i-1,j-1)='.';
      }
      if (B(i,j)=='O' && B(i-1,j+1)=='.') {
        temp=M(i,j);
        M(i,j)='.';
        M(i-1,j+1)=temp;
        points[total]=eval_board (board,player);
        moves[total++]=((j+1)*8+(i-1))*64+(j*8+i);
        M(i,j)=temp;
        M(i-1,j+1)='.';
      }
      if ((B(i,j)=='o'||B(i,j)=='O') && B(i+1,j-1)=='.') {
        temp=M(i,j);
        M(i,j)='.';
        M(i+1,j-1)=temp;
        if (j-1==0)
          M(i+1,j-1)='O';
        points[total]=eval_board (board,player);
        moves[total++]=((j-1)*8+(i+1))*64+(j*8+i);
        M(i,j)=temp;
        M(i+1,j-1)='.';
      }
      if (B(i,j)=='O' && B(i+1,j+1)=='.') {
        temp=M(i,j);
        M(i,j)='.';
        M(i+1,j+1)=temp;
        points[total]=eval_board (board,player);
        moves[total++]=((j+1)*8+(i+1))*64+(j*8+i);
        M(i,j)=temp;
        M(i+1,j+1)='.';
      }
      if ((B(i,j)=='o'||B(i,j)=='O') && (B(i-1,j-1)=='x'||B(i-1,j-1)=='X') && B(i-2,j-2)=='.' ) {
        temp=M(i,j);
        temp2=M(i-1,j-1);
        M(i,j)='.';
        M(i-1,j-1)='.';
        M(i-2,j-2)=temp;
        if (j-2==0)
          M(i-2,j-2)='O';
        kpoints[ktotal]=eval_board (board,player);
        kmoves[ktotal++]=((j-2)*8+(i-2))*64+(j*8+i);
        M(i,j)=temp;
        M(i-1,j-1)=temp2;
        M(i-2,j-2)='.';
      }
      if (B(i,j)=='O' && (B(i-1,j+1)=='x'||B(i-1,j+1)=='X') && B(i-2,j+2)=='.' ) {
        temp=M(i,j);
        temp2=M(i-1,j+1);
        M(i,j)='.';
        M(i-1,j+1)='.';
        M(i-2,j+2)=temp;
        kpoints[ktotal]=eval_board (board,player);
        kmoves[ktotal++]=((j+2)*8+(i-2))*64+(j*8+i);
        M(i,j)=temp;
        M(i-1,j+1)=temp2;
        M(i-2,j+2)='.';
      }
      if ((B(i,j)=='o'||B(i,j)=='O') && (B(i+1,j-1)=='x'||B(i+1,j-1)=='X') && B(i+2,j-2)=='.' ) {
        temp=M(i,j);
        temp2=M(i+1,j-1);
        M(i,j)='.';
        M(i+1,j-1)='.';
        M(i+2,j-2)=temp;
        if (j-2==0)
          M(i+2,j-2)='O';
        kpoints[ktotal]=eval_board (board,player);
        kmoves[ktotal++]=((j-2)*8+(i+2))*64+(j*8+i);
        M(i,j)=temp;
        M(i+1,j-1)=temp2;
        M(i+2,j-2)='.';
      }
      if (B(i,j)=='O' && (B(i+1,j+1)=='x'||B(i+1,j+1)=='X') && B(i+2,j+2)=='.' ) {
        temp=M(i,j);
        temp2=M(i+1,j+1);
        M(i,j)='.';
        M(i+1,j+1)='.';
        M(i+2,j+2)=temp;
        kpoints[ktotal]=eval_board (board,player);
        kmoves[ktotal++]=((j+2)*8+(i+2))*64+(j*8+i);
        M(i,j)=temp;
        M(i+1,j+1)=temp2;
        M(i+2,j+2)='.';
      }
    }
  }

  if (total==0 && ktotal==0)
    return 0;

  if (ktotal==0) {
    int max,k,index;
    max=points[0];
    index=0;
    for (k=0; k<total; k++)
      if (max<points[k]) {
        max=points[k];
        index=k;
      }
    i=index;
    //i=(int)((double)rand()/(double)RAND_MAX*(double)total);
    p1=moves[i]%64;
    p2=moves[i]/64;
    temp=board[p1];
    board[p1]=board[p2];
    board[p2]=temp;
    if (p2/8==0)
      board[p2]='O';
  } else {
    int max,k,index;
    max=kpoints[0];
    index=0;
    for (k=0; k<ktotal; k++)
      if (max<kpoints[k]) {
        max=kpoints[k];
        index=k;
      }
    i=index;
    //i=(int)((double)rand()/(double)RAND_MAX*(double)ktotal);
    p1=kmoves[i]%64;
    p2=kmoves[i]/64;
    temp=board[p1];
    board[p1]=board[p2];
    board[p2]=temp;
    if (p2/8==0)
      board[p2]='O';
    x1=p1%8; y1=p1/8;
    x2=p2%8; y2=p2/8;
    board[((x1+x2)/2)+8*((y1+y2)/2)]='.';
  }
  return 1;
}

void swap_board (char *board) {
  char b[64];
  int i;

  for (i=0; i<64; i++)
    b[i]=board[i];
  for (i=0; i<64; i++)
    board[i]=b[63-i];
  for (i=0; i<64; i++)
    if (board[i]=='x')
      board[i]='o';
    else if (board[i]=='o')
      board[i]='x';
    else if (board[i]=='O')
      board[i]='X';
    else if (board[i]=='X')
      board[i]='O';
}


int play (double *p1, double *p2) {
  char board[64];
  int i;
  int winner;

  reset_board (board);

  i=0;
  do {
    if (!check_movements (board,p1)) {
      winner=2;
      break;
    }
//    print_board (board);
    swap_board (board);

    if (!check_movements (board,p2)) {
      winner=1;
      break;
    }
    swap_board (board);
//    print_board (board);
    i++;
    winner=0;
  } while (i<64);
 
  return winner;
}

void round (player *ps) {
  int i,j,win;

  for (j=0; j<SIZE; j++)
    for (i=0; i<SIZE; i++)
      if (i!=j) {
        //printf ("# %d against %d\n",i,j);
        win=play (ps[i].attr,ps[j].attr);
        if (win==1)
          ps[i].wins++,ps[j].wins--;
        if (win==2)
          ps[j].wins++,ps[i].wins--;
      }

}

int comp (const void *e1, const void *e2) {
  if (((player *)e1)->wins < ((player *)e2)->wins)
    return 1;
  else
    return -1;
}

int main (void) {
  int i,j,k,try;

  for (j=0; j<SIZE; j++) 
    for (i=0; i<ATTR; i++) 
      ps[j].attr[i]=((double)rand()/(double)RAND_MAX);

  for (j=0; j<SIZE; j++)
    ps[j].life=0;

  for (k=0; k<256; k++) {
    fprintf (stderr,"# begin round %d\n",k); 

  for (j=0; j<SIZE; j++)
    ps[j].wins=0;

//  for (try=0; try<10; try++)
    round (ps);

  qsort (ps,SIZE,sizeof (player),comp);

  for (j=0; j<SIZE; j++)
    printf ("%d: %d %d\n",j,ps[j].wins,ps[j].life);

  for (i=0; i<SIZE/2; i++)
    for (j=0; j<ATTR; j++) {
      if ((double)rand()/(double)RAND_MAX>0.8)
        ps[i+SIZE/2].attr[j]=ps[i].attr[j]+(0.2*(double)rand()/(double)RAND_MAX-0.1);
      if (ps[i+SIZE/2].attr[j]>1.0)
        ps[i+SIZE/2].attr[j]=1.0;
      if (ps[i+SIZE/2].attr[j]<0.0)
        ps[i+SIZE/2].attr[j]=0.0;
    }

/*  for (j=SIZE/4*3; j<SIZE; j++) 
    for (i=0; i<ATTR; i++) 
      ps[j].attr[i]=((double)rand()/(double)RAND_MAX);*/

  for (j=0; j<SIZE/2; j++)
    ps[j].life++;
  for (j=SIZE/2; j<SIZE; j++)
    ps[j].life=0;

  printf ("--\n");
  for (j=0; j<ATTR; j++) {
    printf ("%02d ",(int)(ps[0].attr[j]*100.0));
    if (j%8==7) printf ("\n");
  }
  for (j=129; j<151; j++) {
    fprintf (stderr,"%02d ",(int)(ps[0].attr[j]*100.0));
  }
  fprintf (stderr,"\n");
  printf ("\n--\n");

  }

  return 0;
}
