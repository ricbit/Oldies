/* RBCPP 1.4 by Ricardo Bittencourt */

#include <stdio.h>
#include <malloc.h>
#include "rbc.h"

extern FILE *yyin;
FILE *yyout;
int valid_nest,invalid_nest;
char sourcename[MAX_STRING];
char includename[MAX_INCLUDE][MAX_STRING];
int include_line[MAX_INCLUDE];

define_list *list=NULL,*last=NULL;
arg_list *actual=NULL;

int main (int argc, char **argv) {
  printf ("RBCPP 1.4\n");
  printf ("Copyright 1996,1997 by Ricardo Bittencourt\n");
  if (argc<3) {
    printf ("usage: rbc input output\n");
    exit (1);
  }
  yyin=fopen (argv[1],"r");
  yyout=fopen (argv[2],"w");
  strcpy (sourcename,argv[1]);
  fprintf (yyout,"#source <%s>\n",sourcename);
  yyparse ();
  /* show_list ();*/
  return 0;
}

int yyerror (char *s) {
  report_error (s,RBC_ERROR);
  return 0;
}

void insert_item (char *name, tok_list *tok, arg_list *al) {
  arg_list *arg;
  tok_list *p;
  
  if (list==NULL) {
    list=(define_list *) malloc (sizeof (define_list));
    last=list;
  }
  else {
    last->next=(define_list *) malloc (sizeof (define_list));
    last=last->next;
  }
  last->next=NULL;
  last->name=(char *) malloc (strlen (name)+1);
  strcpy (last->name,name);
  last->tok=tok;
  last->list=al;
  if (al==NULL) 
    last->args=0;
  else {
    last->args=1;
    arg=al;
    while (arg->next!=NULL) {
      last->args++;
      arg=arg->next;
    }
  }
}

void show_list (void) {
  define_list *i;

  i=list;
  printf ("\nDefine list\n");
  while (i!=NULL) {
    tok_list *p;
    printf ("%d:%s",i->args,i->name);
    if (i->args>0) {
      int j;
      arg_list *p=i->list;
      printf ("(");
      for (j=0; j<i->args; j++,p=p->next) {
        printf ("%s",p->name);
        if (j!=i->args-1)
          printf (",");
        else
          printf (") ");
      }
    } 
    p=i->tok;        
    while (p!=NULL) {
      if (!(p->type)) 
        printf ("%s",p->value);
      else
        printf ("$%d",p->type);
      p=p->next;
    }
    printf ("\n");
    i=i->next;
  }
}

define_list *is_defined (char *s) {
  define_list *p;

  p=list;
  while (p!=NULL) {
    if (!strcmp (p->name,s)) 
      return p;
    p=p->next;
  }
  return p;
}

char *return_filename (int actual_file) {
  if (!actual_file) 
    return sourcename;  
  else
    return includename[actual_file-1];
}

void report_error (char *error, int type) {
  switch (type) {
    case RBC_FATAL_ERROR:
      printf ("%s:%d: fatal error: %s\n",
              return_filename(actual_include),line_number,error);
      exit (1);
    case RBC_ERROR:
      printf ("%s:%d: error: %s\n",
              return_filename(actual_include),line_number,error);
      break;
    case RBC_WARNING:
      printf ("%s:%d: warning: %s\n",
              return_filename(actual_include),line_number,error);
      break;
  }
}

int is_argument (char *value, arg_list *list) {
  arg_list *p;
  int i=1;

  p=list;
  while (p!=NULL) {
    if (!strcmp (p->name,value)) 
      return i;
    p=p->next;
    i++;
  }
  return 0;
}

char *expand_macro (tok_list *tok, arg_list *arg) {
  tok_list *t;
  arg_list *a;
  char *str;

  t=tok;
  str=(char *) malloc (MAX_STRING);
  strcpy (str,"");
  while (t!=NULL) {
    if (!(t->type))  {
      strcat (str,t->value);      
    }
    else {
      int i=1;
      a=arg; 
      while (i!=t->type) {
        i++;
        a=a->next;
      }
      strcat (str,a->name);
    }
    t=t->next;
  }
  return str;
}
