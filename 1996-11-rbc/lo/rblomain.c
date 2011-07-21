#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include "rblo.h"

extern FILE *yyin;
FILE *yyout;

code_t *append_single (char *string, code_t *old) {
  code_t *p;

  p=(code_t *) malloc (sizeof (code_t));
  p->value=(char *) malloc (strlen (string)+1);
  strcpy (p->value,string);
  p->next=old;
  p->isconst=0;
  p->isaction=0;
  p->isalternate=0;
  return p;
}

code_t *append_double (char *string1, char *string2, code_t *old) {
  code_t *p;

  p=(code_t *) malloc (sizeof (code_t));
  p->value=(char *) malloc (strlen (string1)+strlen (string2)+1);
  strcpy (p->value,string1);
  strcat (p->value,string2);
  p->next=old;
  p->isconst=0;
  p->isaction=0;
  p->isalternate=0;
  return p;
}

code_t *append_code (code_t *code, code_t *old) {
  code_t *p;

  if (code!=NULL) {
    p=code;
    while (p->next!=NULL)
      p=p->next;
    p->next=old;
    return code;
  }
  else 
    return old;
}

void flush_code (code_t *code) {
  code_t *p;

  while (code!=NULL) {
    if (code->next==NULL) {
      fprintf (yyout,"%s\n",code->value);
      free (code);
      code=NULL;
    }
    else {
      p=code;
      while (p->next->next!=NULL) 
        p=p->next;
      fprintf (yyout,"%s\n",p->next->value);
      free (p->next);
      p->next=NULL;
    }
  }
}

code_t *append_known (char *string, int type, char *arg, code_t *old) {
  code_t *p;

  p=(code_t *) malloc (sizeof (code_t));
  p->value=(char *) malloc (strlen (string)+strlen (arg)+1);
  strcpy (p->value,string);
  strcat (p->value,arg);
  p->next=old;
  p->isconst=1;
  p->isaction=0;
  p->isalternate=0;
  p->type=type;
  p->argument=(char *) malloc (strlen (arg)+1);
  strcpy (p->argument,arg);
  return p;
}

code_t *append_action (char *string1, char *string2, code_t *old) {
  code_t *p;

  p=(code_t *) malloc (sizeof (code_t));
  p->next=old;
  p->value=(char *) malloc (strlen (string1)+1);
  strcpy (p->value,string1);
  p->alternate=(char *) malloc (strlen (string2)+1);
  strcpy (p->alternate,string2);
  p->isconst=0;
  p->isaction=1;
  p->isalternate=0;
  return p;
}

code_t *append_alternate (char *string1, char *string2, code_t *old) {
  code_t *p;

  p=(code_t *) malloc (sizeof (code_t));
  p->next=old;
  p->value=(char *) malloc (strlen (string1)+1);
  strcpy (p->value,string1);
  p->alternate=(char *) malloc (strlen (string2)+1);
  strcpy (p->alternate,string2);
  p->isconst=0;
  p->isaction=0;
  p->isalternate=1;
  return p;
}

void main (int argc, char **argv) {
  printf ("RBLO 1.3.3\n");  
  printf ("Copyright 1997 by Ricardo Bittencourt\n");
  if (strcmp (argv[1],"interactive"))
    yyin=fopen (argv[1],"rt");
  yyout=fopen (argv[2],"wt");
  yyparse ();
  fclose (yyin);
  fclose (yyout);
}
