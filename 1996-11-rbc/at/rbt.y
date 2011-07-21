%{

/* RBC version 1.4 */
/* by Ricardo Bittencourt */

#include <stdio.h>
#include "rbatmain.h"

extern FILE *yyout;

%}

%union {
  char *str;
  arglist *arg;
}

%token TOK_COMMA
%token TOK_ENTER
%token <str> TOK_ID
%type <arg> args

%%

top:
  command
  | top command
  ;

command:
  opcode
  | TOK_ENTER {
    fprintf (yyout,"\n");
  }
  ;

opcode:
  TOK_ID args TOK_ENTER {
    flush_opcode ($1,$2);
  }
  | TOK_ID TOK_ENTER {
    flush_opcode ($1,NULL);
  }
  ;

args:
  TOK_ID {
    $$=insert_argument ($1,NULL);
  }
  | args TOK_COMMA TOK_ID {
    $$=insert_argument ($3,$1);
  }
  ;

%%


