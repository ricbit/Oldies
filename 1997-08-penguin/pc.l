%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pc.h"
#include "pc_tab.h"

int yyerror (char *s);

%}

%option nounput
%x string
%x comment

%%

"bot"   return TOK_BOT;
"frame" return TOK_FRAME;
["]     BEGIN (string);
"origin" return TOK_ORIGIN;
<string>[^"]+ {
               strcpy (yylval.str,yytext);
               return TOK_STRING;
             }
<string>["] BEGIN (INITIAL);
"/*" BEGIN (comment);
<comment>[^*]+"*/" BEGIN (INITIAL);
<comment>[^*]+"*"+
"D"     return TOK_DIRECT;
"I"     return TOK_INVERSE;
"SEQUENCE_"[A-Z_0-9]+ {
  strcpy (yylval.str,yytext);
  return TOK_SEQUENCE;
}
"=>" return TOK_NEXT;
"[" return TOK_OPEN_SEQUENCE;
"]" return TOK_CLOSE_SEQUENCE;
"STATE_"[A-Z_0-9]+ {
  strcpy (yylval.str,yytext);
  return TOK_STATE;
}
[A-Z][A-Z0-9_]+ {
          strcpy (yylval.str,yytext);
          return TOK_NAME;
        }
[ \t\n]+
[0-9]+ {
         yylval.number=atoi (yytext);
         return TOK_NUMBER;
       }
"*"     return TOK_TIMES;
"{"     return TOK_OPEN;
"}"     return TOK_CLOSE;
.       yyerror ("bug");

%%

int yyerror (char *s) {
  printf ("error: %s\n",s);
  exit (1);
}
