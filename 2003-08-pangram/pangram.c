#include <stdio.h>
#include <malloc.h>
#include <string.h>
#include <conio.h>

#define MEM 2000

char *unidade[10]={"nenhuma","uma","duas","tres","quatro","cinco",
                   "seis","sete","oito","nove"};

char *dez[10]={"dez","onze","doze","treze","quatorze","quinze",
               "dezesseis","dezessete","dezoito","dezenove"};

char *dezena[10]={"dez","vinte","trinta","quarenta","cinquenta",
                  "sessenta","setenta","oitenta","noventa"};

int hist[26];
int *last;
char str[3000];

void print_number (int i) {
  if (i<10) {
    strcat (str,unidade[i]);
    return;
  }
  if (i<20) {
    strcat (str,dez[i-10]);
    return;
  }
  if (i<100) {
    strcat (str,dezena[i/10-1]);
    if (i%10) {
      strcat (str," e ");
      strcat (str,unidade[i%10]);
    }
    return;
  }
  strcat (str,"out of range");
  return;
}

void gera_str (void) {
  char tmp[500];
  int i;

  strcpy (str," Ricardo criou esta sentenca com ");

  for (i=0; i<26; i++) {
    print_number (hist[i]);
    sprintf (tmp," letra%s %c, ",hist[i]<2?"":"s",'A'+i);
    strcat (str,tmp);
  }

  strcat (str," .");
}

void count_hist (void) {
  int i,j;

  for (i=0; i<26; i++)
    hist[i]=0;

  for (i=0; i<strlen (str); i++) 
    for (j=0; j<26; j++)
      if (toupper (str[i])=='A'+j) 
        hist[j]++;
}

int main (void) {
  int i,j,do_it_again,last_pos=0,line;

  last=(int *) malloc (MEM*26*sizeof(int));
  for (i=0; i<MEM*26; i++)
    last[i]=1000;

  do {
    gera_str ();
    for (i=0; i<26; i++) {
      last[last_pos*26+i]=hist[i];
      printf ("%x ",hist[i]);
    }
    last_pos++;
    last_pos%=MEM;
    printf ("\n");
    count_hist ();
    do_it_again=0;
    for (j=0; j<MEM; j++) {
      line=1;
      for (i=0; i<26; i++)
        if (last[j*26+i]!=hist[i])
          line=0;
      if (line)
        do_it_again=j+1;
    }
  } while (!do_it_again && !kbhit ());
  printf ("%d %d\n",do_it_again,last_pos);
    for (i=0; i<26; i++) 
      printf ("%x ",hist[i]);
    printf ("\n");
  printf ("%s\n",str);
}

