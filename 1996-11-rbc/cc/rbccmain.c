/* RBCC 1.4 */
/* module RBCCMAIN.C */
/* by Ricardo Bittencourt */

#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include "rbcc.h"

extern int line_number;
function_list_t *function_list=NULL;
variable_t *global_vars=NULL;
string_list_t *string_list=NULL;

void add_function (char *c, type_t *type, code_t *code, argument_t *arg) {
  function_list_t *p;

  if (function_list==NULL) {
    function_list=(function_list_t *) malloc (sizeof (function_list_t));
    p=function_list;
    p->next=NULL;
  }
  else {
    p=function_list;
    while (p->next!=NULL && strcmp (p->name,c)) 
      p=p->next;
    if (strcmp (p->name,c))  {
      p->next=(function_list_t *) malloc (sizeof (function_list_t));
      p=p->next;
      p->next=NULL;
    } 
  }
  p->name=(char *) malloc (strlen (c)+1);
  strcpy (p->name,c);
  p->type=type;
  p->code=code;
  p->used=0;
  p->argument=arg;
}

void flush_functions () {
  function_list_t *p;
  code_t *code;

  p=function_list;
  while (p!=NULL) {
    if (p->code!=NULL) {
      fprintf (yyout,"\n");
      fprintf (yyout,"label _%s\n",p->name);
      code=p->code;      
      while (code!=NULL) {
        fprintf (yyout,"%s",code->line);
        code=code->next;
      }
      fprintf (yyout,"endf \n");
    }
    p=p->next;
  }
}

void flush_externs () {
  function_list_t *p;
  code_t *code;

  p=function_list;
  while (p!=NULL) {
    if (p->code==NULL && p->used) 
      fprintf (yyout,"extern _%s \n",p->name);
    p=p->next;
  }
}

function_list_t *isfunction (char *s) {
  function_list_t *p=function_list;

  while (p!=NULL) {
    if (!strcmp (p->name,s)) return p;
    p=p->next;
  }
  return NULL;
}

type_t *function_type (char *s) {
  function_list_t *p=function_list;
  type_t *type;

  while (p!=NULL) {
    if (!strcmp (p->name,s)) {
      type=(type_t *) malloc (sizeof (type_t));
      *type=*(p->type);
      return type;
    }
    p=p->next;
  }
  yyerror ("internal error: function not found");
  exit (1);
}

void function_used (char *name) {
  function_list_t *p=function_list;

  while (p!=NULL) {
    if (!strcmp (p->name,name)) {
      p->used=1;
      return;
    }
    p=p->next;
  }
  yyerror ("internal error: function not found");
  return;
}

argument_t *isargument (char *s) {
  argument_t *p=local_args;

  while (p!=NULL) {
    if (!strcmp (p->name,s)) 
      return p;
    p=p->next;
  }
  return NULL;
}

code_t *append_line (char *s, code_t *code) {
  code_t *p;

  if (code==NULL) 
    p=(code_t *) malloc (sizeof (code_t));
  else {
    p=code;
    while (p->next!=NULL) {
      p=p->next;
    }
    p->next=(code_t *) malloc (sizeof (code_t));
    p=p->next;
  }
  p->line=(char *) malloc (strlen (s)+1);
  strcpy (p->line,s);
  p->next=NULL;
  if (code==NULL)
    return p;
  else
    return code;
}

code_t *append_code (code_t *c, code_t *code) {
  code_t *p;

  if (code==NULL) 
    return c;
  else {
    p=code;
    while (p->next!=NULL)
      p=p->next;
    p->next=c;
    return code;
  }
}

int main (int argc, char **argv) {
  printf ("RBCC 1.4\n");
  printf ("Copyright 1996,1997 by Ricardo Bittencourt\n");
  if (argc<3) {
    printf ("usage: rbcc in.c out.asm\n");
    exit (1);
  }
  yyin=fopen (argv[1],"r");
  yyout=fopen (argv[2],"wt");
  if (yyout==NULL)  {
    printf ("deu pau\n");
    exit (1);
    }
  add_string ("Compiled by RBC Copyright 1996,97 by Ricardo Bittencourt");
  yyparse ();
  return 0;
}

void add_global (type_t *type, char *name, int value) {
  variable_t *p=global_vars;

  if (p==NULL) {
    global_vars=(variable_t *) malloc (sizeof (variable_t));
    p=global_vars;
  }
  else {
    while (p->next) 
      p=p->next;
    p->next=(variable_t *) malloc (sizeof (variable_t));
    p=p->next;
  }
  p->type=type;
  p->name=(char *) malloc (strlen (name)+1);
  strcpy (p->name,name);
  p->value=value;
  p->next=NULL;
}

void flush_variables () {
  variable_t *p=global_vars;

  while (p!=NULL) {
    switch (p->type->type) {
      case INT_ID:
        fprintf (yyout,"vari _%s,%d \n",p->name,p->value);
        break;
      case CHAR_ID:
        fprintf (yyout,"varc _%s,%d \n",p->name,p->value);
        break;
      case POINTER_ID:
        if (p->type->string)
          fprintf (yyout,"varp _%s,$string%d \n",p->name,p->value);
        else
          fprintf (yyout,"varp _%s,%d \n",p->name,p->value);
        break;
      default:
        yyerror ("type of %s is not implemented",p->name);
        break;
    }
    p=p->next;
  }
}

int isvariable (char *s) {
  variable_t *p=global_vars;

  while (p!=NULL) {
    if (!strcmp (p->name,s)) return 1;
    p=p->next;
  }
  return 0;
}

type_t *variable_type (char *s){
  variable_t *p=global_vars;
  type_t *type;

  while (p!=NULL) {
    if (!strcmp (p->name,s)) {
      type=(type_t *) malloc (sizeof (type_t));
      *type=*(p->type);
      return type;
    }
    p=p->next;
  }
  yyerror ("internal error: variable not found");
  exit (1);
}

void check_type (lvalue_t *lval1, lvalue_t *lval2) {
  char str[MAX_STRING];

  switch (lval1->type->type) {
    case NUMBER_ID:
      switch (lval2->type->type) {
        case NUMBER_ID:
          break;
        case INT_ID:
          sprintf (str,"ldipi %d \n",lval1->value);
          lval1->code=append_line (str,lval1->code);
          lval1->type=lval2->type;
          break;
        case CHAR_ID:
          sprintf (str,"ldipc %d \n",lval1->value);
          lval1->code=append_line (str,lval1->code);
          lval1->type=lval2->type;
          break;
      }
      break;
    case INT_ID:
      switch (lval2->type->type) {
        case NUMBER_ID:
          sprintf (str,"ldipi %d \n",lval2->value);
          lval2->code=append_line (str,lval2->code);
          lval2->type=lval1->type;
          break;
        case INT_ID:
          break;
        case CHAR_ID:
          lval2->code=append_line ("castci \n",lval2->code);
          lval2->type=lval1->type;
          break;
      }
      break;
    case CHAR_ID:
      switch (lval2->type->type) {
        case NUMBER_ID:
          sprintf (str,"ldipc %d \n",lval2->value);
          lval2->code=append_line (str,lval2->code);
          lval2->type=lval1->type;
          break;
        case INT_ID:
          lval1->code=append_line ("castci \n",lval1->code);
          lval1->type=lval2->type;
          break;
        case CHAR_ID:
          break;
      }
      break;
    case POINTER_ID:
      switch (lval2->type->type) {
        case NUMBER_ID:
          sprintf (str,"ldipi %d \n",lval2->value);
          lval2->code=append_line (str,lval2->code);
          lval2->type->type=INT_ID;
          break;
        case INT_ID:
          break;
        case CHAR_ID:
          lval2->code=append_line ("castci \n",lval2->code);
          lval2->type->type=INT_ID;
          break;
        case POINTER_ID:
          break;
        default:
          yyerror ("cast not implemented");
          break;
      }
      break;
  }
}

void force_cast (type_t *type, lvalue_t *lval) {
  char str[MAX_STRING];
  
  switch (type->type) {
    case INT_ID: 
      switch (lval->type->type) {
        case CHAR_ID:
          lval->code=append_line ("castci \n",lval->code);
          lval->type=type;
          break;
        case NUMBER_ID:
          sprintf (str,"ldipi %d \n",lval->value);
          lval->code=append_line (str,lval->code);
          lval->type=type;
          break;
        case INT_ID:
          break;
        case POINTER_ID:
          lval->code=append_line ("castpi \n",lval->code);
          lval->type=type;
          break;
        default:
          yyerror ("cast not implemented");
          break;
      }
      break;
    case CHAR_ID:
      switch (lval->type->type) {
        case INT_ID:
          lval->code=append_line ("castic \n",lval->code);
          lval->type=type;
          printf ("warning: possible loss of precision\n");
          break;
        case NUMBER_ID:
          sprintf (str,"ldipc %d \n",lval->value);
          lval->code=append_line (str,lval->code);
          lval->type=type;
          break;
        case CHAR_ID:
          break;
        default:
          yyerror ("cast not implemented");
          break;
      }
      break;
    case POINTER_ID:
      switch (lval->type->type) {
        case INT_ID:
          lval->code=append_line ("castpi \n",lval->code);
          lval->type=type;
          break;
        case NUMBER_ID:
          sprintf (str,"ldipp %d \n",lval->value);
          lval->code=append_line (str,lval->code);
          lval->type=type;
          break;
        case CHAR_ID:
          lval->code=append_line ("castpc \n",lval->code);
          lval->type=type;
          break;
        case POINTER_ID:
          break;
        default:
          yyerror ("cast not implemented");
          break;
      }
      break;
  }
}

int add_string (char *str) {
  string_list_t *p;
  int a=0;

  if (string_list==NULL) {
    string_list=(string_list_t *) malloc (sizeof (string_list_t));
    p=string_list;
  }
  else {
    p=string_list;
    while (p->next!=NULL) {
      p=p->next;
      a++;
    }
    a++;
    p->next=(string_list_t *) malloc (sizeof (string_list_t));
    p=p->next;
  }
  p->string=(char *) malloc (strlen (str)+1);
  strcpy (p->string,str);
  p->next=NULL;
  return a;
}

void flush_strings () {
  string_list_t *p=string_list;
  int a=0,i;
  char *pos;

  while (p!=NULL) {
    fprintf (yyout,"label $string%d \ndefs '",a++);
    pos=p->string;
    i=0;
    while (*pos!=0) {
      fprintf (yyout,"%d",(unsigned char)*pos++);
      if (++i==8) {
        fprintf (yyout,"'\ndefs '");
        i=0;
      }
      else
        fprintf (yyout,",");
    }
    fprintf (yyout,"0'\n\n");
    p=p->next;
  }
}
