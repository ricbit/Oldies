/* RBCPP 1.4 by Ricardo Bittencourt */

%{
#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include "rbc.h"
#include "rbc_tab.h"
YY_BUFFER_STATE include_buffer[MAX_INCLUDE];
int actual_include=0;
int line_number=1;
char strbuf[MAX_STRING],*strp;
%}

%x name_state
%x comm_state
%x str_state

INCLUDE         "#include"[ \t]*"<"
DEFINE          "#define"[ \t]*
IFDEF           "#ifdef"[ \t]*
IFNDEF          "#ifndef"[ \t]*
ENDIF           "#endif"
NEWLINE         "\n"
ID              [a-zA-Z_][a-zA-Z0-9_]*

%%

{NEWLINE}       {
            line_number++;
            return TOK_NEWLINE;
        }
{INCLUDE}       {
                    BEGIN (name_state);
                }
{DEFINE}        {
                    return TOK_DEFINE; 
                }
{IFDEF}         {
                    return TOK_IFDEF;
                }
{IFNDEF}        {  
                    return TOK_IFNDEF;
                }
{ENDIF}         return TOK_ENDIF;
"/*"            BEGIN (comm_state);
<comm_state>[^*\n]+
<comm_state>"*"+[^*/\n]*
<comm_state>{NEWLINE} line_number++;
<comm_state>"*"+"/" BEGIN (INITIAL);
<name_state>[^>]+">" {
          char name[MAX_STRING];
          memcpy (name,yytext,(strlen (yytext))-1);
          name[strlen(yytext)-1]=0;
          strcpy (includename[actual_include],name);
          include_buffer[actual_include]=YY_CURRENT_BUFFER;
          include_line[actual_include]=line_number;          
          yyin=fopen (name,"r");
          if (!yyin) {
            char error[MAX_STRING];
            sprintf (error,"Cannot open <%s>",name);
            report_error (error,RBC_FATAL_ERROR);
          }
          yy_switch_to_buffer (yy_create_buffer (yyin,YY_BUF_SIZE));
          actual_include++;
          line_number=1;
          fprintf (yyout,"#source <%s>\n",name);
          BEGIN (INITIAL);
        }
<<EOF>> {
          if (!actual_include) {
            yyterminate ();
          }
          else {
            yy_delete_buffer (YY_CURRENT_BUFFER);
            yy_switch_to_buffer (include_buffer[--actual_include]);
            line_number=include_line[actual_include];
            fprintf (yyout,"#source <%s>\n",sourcename);
          }
        }
\" {
            strcpy (strbuf,yytext);
            strp=strbuf+1;
            BEGIN (str_state);
        }
<str_state>{NEWLINE} {
          *strp++=*yytext;
          line_number++;
        }
<str_state>[^\n"] *strp++=*yytext;
<str_state>\" {
          strcpy (strp,yytext);
          strcpy (yylval.str,strbuf);
          BEGIN (INITIAL);
          return TOK_STRING;
        }
{ID} {
          define_list *def=is_defined (yytext);
            if (actual!=NULL) {
              int i=is_argument (yytext,actual);
              if (i) {
                yylval.arg=i;
                return TOK_ARG;
              }
            }
            if (def==NULL) {
              strcpy (yylval.str,yytext);
              return TOK_ID;
            }
            else {
              yylval.def=def;
              if (!def->args)
                return TOK_IDNOARGS;
              else
                return TOK_IDARGS;
            }
          }
[ \t]+ {
            strcpy (yylval.str,yytext);
            return TOK_WHITESPACE;
        }
"(" {
            strcpy (yylval.str,yytext);
            return TOK_OPEN;
        }
")" {
            strcpy (yylval.str,yytext);
            return TOK_CLOSE;
        }
"," {
            strcpy (yylval.str,yytext);
            return TOK_COMMA;
        }
. { 
            strcpy (yylval.str,yytext);
            return TOK_STUFF;
        }

