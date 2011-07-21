/* RBC version 1.4 */
/* by Ricardo Bittencourt */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "rbatmain.h"

typedef struct opcode {
  char *name;
  int args;
  char *value;
  struct opcode *next;
} opcode;

opcode *oplist=NULL;
extern FILE *yyin;
extern FILE *zzin;
FILE *yyout;
extern int size[2][MAX_TYPES];

int yyparse (void);
int zzparse (void);

void insert_opcode (char *name, int args, char *value) {
  opcode *op;
  
  if (oplist==NULL) {
    oplist=(opcode *) malloc (sizeof (opcode));
    op=oplist;
  }
  else {
    op=oplist;
    while (op->next!=NULL)
      op=op->next;
    op->next=(opcode *) malloc (sizeof (opcode));
    op=op->next;
  }
  op->args=args;
  op->name=(char *) malloc (strlen (name)+1);
  strcpy (op->name,name);
  op->value=(char *) malloc (strlen (value)+1);
  strcpy (op->value,value);
  op->next=NULL;
}

void list_opcodes (void) {
  opcode *op=oplist;

  while (op!=NULL) {
    printf ("[%s] %d\n",op->name,op->args);
    op=op->next;
  }
}

void flush_opcode (char *name, arglist *argument) {
  opcode *op=oplist;
  char *buffer;

  while (op!=NULL && strcmp (op->name,name))
    op=op->next;
  if (op==NULL) {
    printf ("bug! opcode not found: %s\n",name);
    exit (1);
  }
  buffer=(char *) malloc (strlen (op->value)+10);  
  sprintf (buffer,"\t\t%s\n",op->value);
  switch (op->args) {
    case 0:
      fprintf (yyout,buffer);
      break;
    case 1:
      fprintf (yyout,buffer,argument->value);
      break;
    case 2:
      fprintf (yyout,buffer,argument->value,argument->next->value);
      break;
  }
  free (buffer);
}

int main (int argc, char **argv) {
  printf ("RBAT 1.4 \n");
  printf ("Copyright 1997 by Ricardo Bittencourt \n");
  yyin=fopen (argv[1],"r");
  yyparse ();
  zzin=fopen (argv[2],"r");
  yyout=fopen (argv[3],"w");
  zzparse ();
  return 0;
}

arglist *insert_argument (char *value, arglist *argument) {
  arglist *root,*arg;  

  if (argument==NULL) {
    root=(arglist *) malloc (sizeof (arglist));
    arg=root;
  }
  else {
    root=arg=argument;
    while (arg->next!=NULL)
      arg=arg->next;
    arg->next=(arglist *) malloc (sizeof (arglist));
    arg=arg->next;
  }
  arg->value=(char *) malloc (strlen (value)+1);
  strcpy (arg->value,value);
  arg->next=NULL;
  return root;
}

char *convert_stack (char *stack) {
  int total=0;
  char *p;
  char *str;

  str=(char *) malloc (50);
  p=stack+1;
  while (*p) {
    switch (*p++) {
      case 'i':
        total+=size[0][INT_ID];
        break;
      case 'c':
        total+=size[0][CHAR_ID];
        break;
      case 'p':
        total+=size[0][POINTER_ID];
        break;
    }
  }
  sprintf (str,"%d",total);
  return str;
}

char *convert_frame (char *stack) {
  int total=size[0][0];
  char *p;
  char *str;

  str=(char *) malloc (50);
  p=stack+2;
  while (*p) {
    switch (*p++) {
      case 'i':
        total+=size[0][INT_ID];
        break;
      case 'c':
        total+=size[0][CHAR_ID];
        break;
      case 'p':
        total+=size[0][POINTER_ID];
        break;
    }
  }
  switch (*stack) {
    case 'i':
      total+=size[1][INT_ID];
      break;
    case 'c':
      total+=size[1][CHAR_ID];
      break;
    case 'p':
      total+=size[1][POINTER_ID];
      break;
  }
  sprintf (str,"%d",total);
  return str;
}
