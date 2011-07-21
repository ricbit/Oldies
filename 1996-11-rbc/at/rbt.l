%{

/* RBC version 1.4 */
/* by Ricardo Bittencourt */

#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include "rbatmain.h"
#include "rbt_tab.h"

%}

%option noyywrap
%option nounput

%x string

%%

[$_a-zA-Z0-9]+    {
                  zzlval.str=(char *) malloc (strlen (zztext)+1);
                  strcpy (zzlval.str,zztext);
                  return TOK_ID;
                }

[a-z]"#"[a-z]*  {
                  zzlval.str=convert_frame (zztext);
                  return TOK_ID;
                }

"#"[a-z]+       {
                  zzlval.str=convert_stack (zztext);
                  return TOK_ID;
                }

"@"[a-z]+([ \t]+)?("\n")?

"'"             BEGIN (string);

<string>([^']+)?"'"     {
                          zzlval.str=(char *) malloc (strlen (zztext)+1);
                          strcpy (zzlval.str,zztext);
                          zzlval.str[strlen (zztext)-1]=0;
                          BEGIN (INITIAL);
                          return TOK_ID;
                        }

","             return TOK_COMMA;
"\n"            return TOK_ENTER;

[ \t]+
.

%%

int zzerror (char *error) {
  printf ("error %s\n",error);
  exit (1);
}
