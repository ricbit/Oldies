%{ 

#include <stdio.h>
#include <string.h>
#include "rblo.h"
#include "rblo_tab.h"

%}

%x string

%%

"'"             BEGIN (string);
<string>[^']+   {
                  char str[500];
                  strcpy (str,"'");
                  strcat (str,yytext);
                  strcat (str,"'");
                  yylval.str=(char *) malloc (strlen (str)+1);
                  strcpy (yylval.str,str);
                  return TOK_ARGUMENT;
                }
<string>"'"     BEGIN (INITIAL);
"pushpi"        return TOK_PUSHPI;
"popsi"         return TOK_POPSI;
"comment"       return TOK_COMMENT;
"extern"        return TOK_EXTERN;
"startup"       return TOK_STARTUP;
"label"         return TOK_LABEL;
"defs"          return TOK_DEFS;
"vari"          return TOK_VARI;
"enter"         return TOK_ENTER;
"leaipp"        return TOK_LEAIPP;
"pushpp"        return TOK_PUSHPP;
"ldipi"         return TOK_LDIPI;
"popsp"         return TOK_POPSP;
"ldpisp"        return TOK_LDPISP;
"ldpppi"        return TOK_LDPPPI;
"addsipi"       return TOK_ADDSIPI;
"callpp"        return TOK_CALLPP;
"restore"       return TOK_RESTORE;
"exit"          return TOK_EXIT;
"endcode"       return TOK_ENDCODE;
"savepi"        return TOK_SAVEPI;
"@begin"        return TOK_BEGIN;
"@end"          return TOK_END;
"ldsipp"        return TOK_LDSIPP;
"leafppp"       return TOK_LEAFPPP;
"jp"            return TOK_JP;
"jpzi"          return TOK_JPZI;
"jpli"          return TOK_JPLI;
"divsipi"       return TOK_DIVSIPI;
"mulsipi"       return TOK_MULSIPI;
"ldpptp"        return TOK_LDPPTP;
"ldtppi"        return TOK_LDTPPI;
"ldpitp"        return TOK_LDPITP;
"jpnzi"         return TOK_JPNZI;
"modsipi"       return TOK_MODSIPI;
"inctpi"        return TOK_INCTPI;
"endf"          return TOK_ENDF;

[a-zA-Z0-9,$_#]+       {
                          yylval.str=(char *) malloc (strlen (yytext)+1);
                          strcpy (yylval.str,yytext);
                          return TOK_ARGUMENT;
                        }
[ \n\t]

%%

int yyerror (char *error) {
  printf ("LO error: %s\n",error);
  exit (1);
}

