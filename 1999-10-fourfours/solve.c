/* Solve the four fours problem (and generalizes to the n n problem).
   Ricardo Bittencourt */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define P_PLUS 1
#define P_MINUS 3
#define P_TIMES 10
#define P_DIV 30
#define P_FATORIAL 100
#define P_POT 250
#define P_SQRT 500
#define P_BINOMIAL 750
#define P_FALLING 3000
#define P_RISING 3000
#define P_FLOOR 10000

typedef struct radical_list {
  char *str;
  double value;
  int point;
  char pure;
  char number;
  struct radical_list *next;
} radical_list;

radical_list *radical,*bottom;

int pool=0,comb;

void *my_malloc (int n) {
  int q;

  q=n<64?64:n;
  pool+=q;
  return malloc (q);
}

int integer (double x) {
  return x==floor(x);
}

double fatorial (double x) {
  if (x==0.0)
    return 1.0;
  else
    return x*fatorial (x-1.0);
}

double pot (double a, double b) {
  int i;
  double n=1.0;

  if (integer (b)) {
    for (i=0; i<(int)b; i++)
      n*=a;
    return n;
  }
  else
    return exp(b*log(a));
}

double binomial (double a, double b) {
  return fatorial (a)/fatorial(a-b)/fatorial(b);
}

double falling (double a, double b) {
  return fatorial (a)/fatorial(a-b);
}

double rising (double a, double b) {
  return fatorial (a+b-1)/fatorial(a-1);
}

radical_list *insert 
  (radical_list *base, radical_list *last, char *str, double value,
   int point, int number, int pure) 
{ 
  radical_list *p;

  if (value<0.0)
    return last;

  for (p=radical; p!=NULL; p=p->next) 
    if (p->value==value && number==p->number && pure==p->pure) 
      if (point<p->point)
        {
          free (p->str); 
          p->str=(char *) my_malloc (strlen (str)+1);
          strcpy (p->str,str);
          p->point=point;
          return last;
        }
      else return last;

  for (p=base; p!=NULL; p=p->next) 
    if (p->value==value && number==p->number && pure==p->pure) 
      if (point<p->point)
        {
          free (p->str); 
          p->str=(char *) my_malloc (strlen (str)+1);
          strcpy (p->str,str);
          p->point=point;
          return last;
        }
      else return last;

  last->next=(radical_list *) my_malloc (sizeof (radical_list));
  last=last->next;
  last->str=(char *) my_malloc (strlen (str)+1);
  strcpy (last->str,str);
  last->value=value;
  last->number=number;
  last->point=point;
  last->pure=pure;
  last->next=NULL;

  return last;

}

void solve (void) {
  radical_list *p,*new,*q,*p2;
  char temp_str[5000];
  int temp_point,temp_number,temp_pure;
  double temp_value;

  new=(radical_list *) my_malloc (sizeof (radical_list));
  memcpy (new,radical,sizeof (radical_list));
  new->next=NULL;
  q=new;

  for (p=radical; p!=NULL; p=p->next) {

    /* fatorial */
    if (integer (p->value) && p->value<7.0 ) {
      if (p->pure)
        sprintf (temp_str,"%s!",p->str);
      else
        sprintf (temp_str,"(%s)!",p->str);
      temp_value=fatorial (p->value);
      temp_point=p->point+P_FATORIAL;
      temp_number=p->number;
      temp_pure=0;
      q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);
    }

    /* sqrt */  
    sprintf (temp_str,"sqrt(%s)",p->str);
    temp_value=sqrt (p->value);
    temp_point=p->point+P_SQRT;
    temp_number=p->number;
    temp_pure=0;
    q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);

    /* floor */  
    sprintf (temp_str,"floor(%s)",p->str);
    temp_value=floor (p->value);
    temp_point=p->point+P_FLOOR;
    temp_number=p->number;
    temp_pure=0;
    q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);

    /* ceil */  
    sprintf (temp_str,"ceil(%s)",p->str);
    temp_value=ceil (p->value);
    temp_point=p->point+P_FLOOR;
    temp_number=p->number;
    temp_pure=0;
    q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);

  }

  for (p=radical; p!=NULL; p=p->next) 
    for (p2=radical; p2!=NULL; p2=p2->next) 
      if (p->number+p2->number<=comb) {
        
        /* plus */  
        sprintf (temp_str,"(%s+%s)",p->str,p2->str);
        temp_value=p->value+p2->value;
        temp_point=p->point+p2->point+P_PLUS;
        temp_number=p->number+p2->number;
        temp_pure=0;
        q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);
      
        /* minus */
        sprintf (temp_str,"(%s-%s)",p->str,p2->str);
        temp_value=p->value-p2->value;
        temp_point=p->point+p2->point+P_MINUS;
        temp_number=p->number+p2->number;
        temp_pure=0;
        q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);
      
        /* times */
        sprintf (temp_str,"(%s*%s)",p->str,p2->str);
        temp_value=p->value*p2->value;
        temp_point=p->point+p2->point+P_TIMES;
        temp_number=p->number+p2->number;
        temp_pure=0;
        q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);
      
        /* div */
        if (p2->value!=0.0) {
          sprintf (temp_str,"(%s/%s)",p->str,p2->str);
          temp_value=p->value/p2->value;
          temp_point=p->point+p2->point+P_DIV;
          temp_number=p->number+p2->number;
          temp_pure=0;
          q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);
        }
        
        /* exp */
        if (p->value>0.0 && p2->value>0.0 && p->value<100.0 && p2->value<10.0) {
          sprintf (temp_str,"(%s^%s)",p->str,p2->str);
          temp_value=pot(p->value,p2->value);
          temp_point=p->point+p2->point+P_POT;
          temp_number=p->number+p2->number;
          temp_pure=0;
          q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);
        }
        
        /* binomial */
        if (p->value>0.0 && p2->value>0.0 && p->value<20.0 && p2->value<20.0 && integer (p->value) && integer (p2->value) && p->value>p2->value) {
          sprintf (temp_str,"binomial(%s,%s)",p->str,p2->str);
          temp_value=binomial(p->value,p2->value);
          temp_point=p->point+p2->point+P_BINOMIAL;
          temp_number=p->number+p2->number;
          temp_pure=0;
          q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);
        }
        
        /* falling */
        if (p->value>0.0 && p2->value>0.0 && p->value<20.0 && p2->value<20.0 && integer (p->value) && integer (p2->value) && p->value>p2->value) {
          sprintf (temp_str,"falling(%s,%s)",p->str,p2->str);
          temp_value=falling(p->value,p2->value);
          temp_point=p->point+p2->point+P_FALLING;
          temp_number=p->number+p2->number;
          temp_pure=0;
          q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);
        }
        
        /* rising */
        if (p->value>0.0 && p2->value>0.0 && p->value<15.0 && p2->value<10.0 && integer (p->value) && integer (p2->value)) {
          sprintf (temp_str,"rising(%s,%s)",p->str,p2->str);
          temp_value=rising(p->value,p2->value);
          temp_point=p->point+p2->point+P_RISING;
          temp_number=p->number+p2->number;
          temp_pure=0;
          q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);
        }
        
        /* concat */
        if (p->pure && p2->pure && p2->value<10.0) {
          sprintf (temp_str,"%s%s",p->str,p2->str);
          temp_value=p->value*10+p2->value;
          temp_point=p->point+p2->point;
          temp_number=p->number+p2->number;
          temp_pure=1;
          q=insert (new,q,temp_str,temp_value,temp_point,temp_number,temp_pure);
        }
      }

  bottom->next=new;
  bottom=q;
 
}

void print_table (void) {
  radical_list *p;
  int point;
  double i;
  char *str;

  for (i=0.0; i<=100.0; i+=1.0) {
    point=1e6;
    str=NULL;
    for (p=radical; p!=NULL; p=p->next) 
      if (i==p->value && p->point<point && p->number==comb) {
        str=p->str;
        point=p->point;
      }
    if (str!=NULL)
      printf ("%3d = %s\n",(int)i,str);
  }
}

void print_table_full (void) {
  radical_list *p;

  for (p=radical; p!=NULL; p=p->next) 
    printf ("%d = %s\n",(int)p->value,p->str);
}

int main (int argc, char **argv) {
  int i;

  printf ("Solve - by Ricardo Bittencourt \n\n");

  comb=atoi (argv[1]);

  radical=(radical_list *) my_malloc (sizeof (radical_list));
  radical->str=(char *) my_malloc (50);
  sprintf (radical->str,"%d",atoi(argv[2]));
  radical->value=(double) atoi(argv[2]);
  radical->point=0;
  radical->pure=1;
  radical->number=1;
  radical->next=NULL;
  bottom=radical;

  printf ("solving...\n");

  for (i=0; i<comb; i++) {
    solve ();
    printf ("pool: %d\n",pool);
  }
  
  printf ("printing...\n");

  print_table ();
  
  return 0;
}
