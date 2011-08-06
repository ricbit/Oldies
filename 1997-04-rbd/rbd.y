%{

#include <stdio.h>
#include <stdlib.h>
#include "rbd_gram.h"
#include "build.h"

%}

%union {
  double real;
  int integer;
}

%token TOK_A
%token TOK_B
%token TOK_C
%token TOK_X
%token TOK_Y
%token TOK_Z
%token TOK_U
%token TOK_V
%token TOK_AB
%token TOK_BC
%token TOK_CA
%token TOK_DOT2
%token TOK_LIST
%token TOK_VERTICES
%token TOK_FACES
%token TOK_VERTEX
%token TOK_FACE
%token <real> TOK_REAL
%token <integer> TOK_INTEGER

%type <real> number

%%

source : 
  elem
  | source elem
  ;

elem:
  triangle
  | vertex
  | TOK_REAL {}
  | TOK_INTEGER {}
  | TOK_DOT2
  | TOK_FACE TOK_LIST 
  | TOK_VERTEX TOK_LIST
  | TOK_AB TOK_INTEGER
  | TOK_BC TOK_INTEGER
  | TOK_CA TOK_INTEGER
  | TOK_VERTICES TOK_INTEGER {
    init_vertices ($2);
  }
  | TOK_FACES TOK_INTEGER {
    init_triangles ($2);
  }
  ;

triangle :
  TOK_FACE TOK_INTEGER TOK_DOT2 
  TOK_A TOK_INTEGER
  TOK_B TOK_INTEGER
  TOK_C TOK_INTEGER
  {
    insert_triangle ($2,$9,$7,$5);
  }
  ;

number:
  TOK_REAL {
    $$=$1;
  }
  | TOK_INTEGER {
    $$=(double) $1;
  }
  ;

vertex :
  TOK_VERTEX TOK_INTEGER TOK_DOT2
  TOK_X number
  TOK_Y number
  TOK_Z number
  TOK_U number
  TOK_V number
  {
    insert_vertex ($2,$5,$7,$9,$11,$13);
  }
  | TOK_VERTEX TOK_INTEGER TOK_DOT2
  TOK_X number
  TOK_Y number
  TOK_Z number
  {
    insert_vertex ($2,$5,$7,$9,0.0,0.0);
  }
  ;

%%

int yyerror (char *error) {
  printf ("error: %s\n",error);
  exit (1);
}
