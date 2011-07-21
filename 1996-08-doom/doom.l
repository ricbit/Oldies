%{

#include <stdio.h>
#include <stdlib.h>
#include "doom.h"
#include "doom_tab.h"
                    
%}

%%

[ \n\t]+ 
":"     return TOK_SEPARATOR;
"|"     return TOK_START;
[0-9]+  {
          yylval.i=atoi (yytext);
          return TOK_INTEGER;
        }
([+-]?)([0-9])+"."([0-9])+ {
          yylval.r=atof (yytext);
          return TOK_REAL;
        }
"SVGA" return TOK_SVGA;
"VGA" return TOK_VGA;
"REDLINES" return TOK_REDLINES;

