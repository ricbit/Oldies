%{

/* RBC version 1.4 */
/* by Ricardo Bittencourt */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "rbatmain.h"
#include "rbat_tab.h"

%}

%x definition

%%

"base"          return TOK_BASE;
"int"           return TOK_INT;
"char"          return TOK_CHAR;
"pointer"       return TOK_POINTER;
"("             return TOK_OPEN;
")"             return TOK_CLOSE;
","             return TOK_COMMA;

"#"[a-z]+       {
                  yylval.str=(char *) malloc (strlen (yytext)+1);
                  strcpy (yylval.str,yytext);
                  return TOK_STACK;
                }

[a-z]+          {
                  yylval.str=(char *) malloc (strlen (yytext)+1);
                  strcpy (yylval.str,yytext);
                  return TOK_ID;
                }

"{"             BEGIN (definition);

<definition>([^}]+)?"}" {
                  yylval.str=(char *) malloc (strlen (yytext)+1);
                  strcpy (yylval.str,yytext);
                  yylval.str[strlen(yytext)-1]=0;
                  BEGIN (INITIAL);
                  return TOK_OPCODE;
                }


[0-9]+          {
                  yylval.number=atoi (yytext);
                  return TOK_NUMBER;
                }

[ \n\t]


%%

void yyerror (char *error) {
  printf ("AT error: %s\n",error);
  exit (1);
}
