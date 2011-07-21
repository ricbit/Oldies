%{

/* RBC version 1.4 */
/* by Ricardo Bittencourt */

#include <stdio.h>
#include "rbatmain.h"

int size[2][MAX_TYPES];

%}

%union {
  char *str;
  int number;
}

%token TOK_STACK
%token TOK_BASE
%token TOK_INT
%token TOK_CHAR
%token TOK_POINTER
%token TOK_OPEN
%token TOK_CLOSE
%token TOK_COMMA
%token <number> TOK_NUMBER
%token <str> TOK_ID
%token <str> TOK_OPCODE

%%

top: 
  feature
  | top feature
  ;

feature:
  opcode
  | TOK_BASE TOK_OPEN TOK_NUMBER TOK_CLOSE {
    size[0][BASE_ID]=$3;
  }
  | TOK_INT TOK_OPEN TOK_NUMBER TOK_COMMA TOK_NUMBER TOK_CLOSE {
    size[0][INT_ID]=$3;
    size[1][INT_ID]=$5;
  }
  | TOK_CHAR TOK_OPEN TOK_NUMBER TOK_COMMA TOK_NUMBER TOK_CLOSE {
    size[0][CHAR_ID]=$3;
    size[1][CHAR_ID]=$5;
  }
  | TOK_POINTER TOK_OPEN TOK_NUMBER TOK_COMMA TOK_NUMBER TOK_CLOSE {
    size[0][POINTER_ID]=$3;
    size[1][POINTER_ID]=$5;
  }
  ;

opcode:
  TOK_ID TOK_NUMBER TOK_OPCODE {
    insert_opcode ($1,$2,$3);
  }
  ;

%%

