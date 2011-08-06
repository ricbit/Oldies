%{

#include <stdio.h>
#include <stdlib.h>
#include "rbd_gram.h"
#include "rbd_tab.h"

#define YY_NO_UNPUT

%}

%%

[+-]?[0-9]+"."[0-9]+ {
  yylval.real=atof (yytext);
  return TOK_REAL;
}

[0-9]+ {
  yylval.integer=atoi (yytext);
  return TOK_INTEGER;
}

"Vertices:"     return TOK_VERTICES;
"Faces:"        return TOK_FACES;
"Vertex"        return TOK_VERTEX;
"Face"          return TOK_FACE;
"list:"         return TOK_LIST;
"X:"            return TOK_X;
"Y:"            return TOK_Y;
"Z:"            return TOK_Z;
"A:"            return TOK_A;
"B:"            return TOK_B;
"C:"            return TOK_C;
"U:"            return TOK_U;
"V:"            return TOK_V;
"AB:"           return TOK_AB;
"BC:"           return TOK_BC;
"CA:"           return TOK_CA;
":"             return TOK_DOT2;

[ \t\n]
. 

%%
