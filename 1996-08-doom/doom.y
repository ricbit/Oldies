%{

#include <stdio.h>
#include <allegro.h>
#include "doom.h"

int GFXMODE,RESX,RESY;
int redlines_enabled=0;

%}

%union {
  double r;
  int i;
  vector v;
  poly p;
}

%token TOK_SEPARATOR
%token TOK_REDLINES
%token TOK_START
%token TOK_VGA
%token TOK_SVGA
%token <r> TOK_REAL
%token <i> TOK_INTEGER

%type <v> vector
%type <p> poly

%start scene

%%

scene:  /* empty */
        | scene cmd
        ;

vector: TOK_REAL TOK_REAL TOK_REAL {
          $$.dx=$1;
          $$.dy=$2;
          $$.dz=$3;
        }
        ;

poly:   TOK_INTEGER TOK_INTEGER TOK_INTEGER {
          $$.a=$1;
          $$.b=$2;
          $$.c=$3;
        }
        ;

cmd:    TOK_INTEGER TOK_SEPARATOR vector {        
          insert_vertex ($3);
        }
        | TOK_VGA TOK_INTEGER TOK_INTEGER {
          GFXMODE=GFX_VGA;
          RESX=$2;
          RESY=$3;
        }
        | TOK_REDLINES {
          redlines_enabled=1;
        }
        | TOK_SVGA TOK_INTEGER TOK_INTEGER {
          GFXMODE=GFX_VESA1;
          RESX=$2;
          RESY=$3;
        }
        | poly {
          insert_poly ($1);          
        }
        | TOK_START {
          convert_vertex ();
        }
        ;

%%

int yyerror (char *s) {
  printf ("error: %s",s);
  return 0;
}
