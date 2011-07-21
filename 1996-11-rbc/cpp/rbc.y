/* RBCPP 1.4 by Ricardo Bittencourt */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "rbc.h"

%}
 
%union {
  char str[MAX_STRING];
  arg_list *al;
  define_list *def;
  tok_list *tok;
  int arg;
}

%token TOK_NEWLINE
%token TOK_DEFINE
%token TOK_IFDEF
%token TOK_IFNDEF
%token TOK_ENDIF
%token <str> TOK_ID
%token <str> TOK_STUFF
%token <str> TOK_STRING
%token <str> TOK_WHITESPACE
%token <str> TOK_OPEN
%token <str> TOK_CLOSE  
%token <str> TOK_COMMA
%token <def> TOK_IDARGS
%token <def> TOK_IDNOARGS
%token <arg> TOK_ARG

%type <str> define
%type <str> deftok
%type <tok> deflist
%type <al> arglist

%type <str> text
%type <str> texttok
%type <str> cmd

%type <def> stmacro
%type <str> macro
%type <al> list

%type <str> single
%type <str> singlelist

%expect 1

%start source

%%

source:   
        | source TOK_DEFINE TOK_ID TOK_OPEN arglist TOK_CLOSE {
          actual=$5;
        } deflist {
          if (!invalid_nest) {
            insert_item ($3,$8,$5);
          }
          actual=NULL;
        }
        | source TOK_DEFINE TOK_ID deflist {
          if (!invalid_nest) {
            insert_item ($3,$4,NULL);
          }
        }
        | source TOK_IFDEF define endofline {
          if (invalid_nest) 
            invalid_nest++;
          else 
            if (is_defined ($3)!=NULL) 
              valid_nest++;
            else 
              invalid_nest++;
        }
        | source TOK_IFNDEF define endofline {
          if (invalid_nest) 
            invalid_nest++;
          else 
            if (is_defined ($3)==NULL) 
              valid_nest++;
            else 
              invalid_nest++;
        }
        | source TOK_ENDIF {
          if (invalid_nest) 
            invalid_nest--;
          else {
            if (valid_nest)           
              valid_nest--;
            else 
              report_error ("#endif without #ifdef",RBC_WARNING);
          }
        } endofline
        | source text TOK_NEWLINE {
          if (!invalid_nest) {
            fprintf (yyout,"#line %d\n",line_number);
            fprintf (yyout,"%s\n",$2);
          }
        }
        | source TOK_NEWLINE {
          if (!invalid_nest)
            fprintf (yyout,"\n");
        }
        | error endofline 
       ;

deftok: TOK_ID {
          strcpy ($$,$1);
        }
        | TOK_OPEN {
          strcpy ($$,$1);
        }
        | TOK_CLOSE {
          strcpy ($$,$1);
        }
        | TOK_STUFF {
          strcpy ($$,$1);
        }
        | TOK_STRING {
          strcpy ($$,$1);
        }
        | TOK_WHITESPACE {
          strcpy ($$,$1);
        }
        | TOK_COMMA {
          strcpy ($$,$1);
        }
        | TOK_IDARGS {
          strcpy ($$,$1->name);
        }
        | TOK_IDNOARGS {
          strcpy ($$,$1->name);
        }
        ;

deflist: TOK_NEWLINE {
           $$=NULL;
         }
         | deftok deflist {
           $$=(tok_list *) malloc (sizeof (tok_list));
           $$->type=0;
           $$->value=(char *) malloc (strlen ($1)+1);
           strcpy ($$->value,$1);
           $$->next=$2;
         }
         | TOK_ARG deflist {
           $$=(tok_list *) malloc (sizeof (tok_list));
           $$->type=$1;
           $$->value=NULL;
           $$->next=$2;
         }
         ;

arglist: TOK_ID { 
           $$=(arg_list *) malloc (sizeof (arg_list));
           $$->name=(char *) malloc (strlen ($1)+1);
           strcpy ($$->name,$1);
           $$->next=NULL;
         }
         | arglist TOK_COMMA TOK_ID { 
           arg_list *p;
           p=$$=$1;
           while (p->next!=NULL) p=p->next;
           p->next=(arg_list *) malloc (sizeof (arg_list));
           p->next->name=(char *) malloc (strlen ($3)+1);
           strcpy (p->next->name,$3);
           p->next->next=NULL;
         }
         ;

define: TOK_ID {
          strcpy ($$,$1);
        }
        | TOK_IDARGS {
          strcpy ($$,$1->name);
        }
        | TOK_IDNOARGS {
          strcpy ($$,$1->name);
        }
        ;

endofline: TOK_NEWLINE 
           | TOK_WHITESPACE TOK_NEWLINE {}
           ;

stmacro: TOK_IDARGS {
           $$=$1;
         }
         | TOK_IDARGS TOK_WHITESPACE {
           $$=$1;
         }
         ;

cmd: TOK_ID {
       strcpy ($$,$1); 
     }
     | TOK_WHITESPACE {
       strcpy ($$,$1);
     }
     | TOK_STUFF {
       strcpy ($$,$1);
     }
     | TOK_STRING {
       strcpy ($$,$1);
     }
     ;

texttok: cmd {
           strcpy ($$,$1);
         }
         | macro {
           strcpy ($$,$1);
         }
         | single {
           strcpy ($$,$1);
         }
         ;

text:   texttok {
          strcpy ($$,$1);
        }
        | text texttok {
          strcpy ($$,$1);
          strcat ($$,$2);
        }
        ;

list: text TOK_CLOSE {
        $$=(arg_list *) malloc (sizeof (arg_list));
        $$->name=(char *) malloc (strlen ($1)+1);
        strcpy ($$->name,$1);
        $$->next=NULL;
      }
      | text TOK_COMMA list {
        $$=(arg_list *) malloc (sizeof (arg_list));        
        $$->name=(char *) malloc (strlen ($1)+1);
        strcpy ($$->name,$1);
        $$->next=$3;
      }
      ;

macro: stmacro TOK_OPEN list {
         arg_list *p,*l;
         strcpy ($$,expand_macro ($1->tok,$3));
         p=$3;
         while (p!=NULL) {
           l=p;           
           p=p->next;
           free (l->name);
           free (l);
         }
       }
       | TOK_IDNOARGS {
         tok_list *t=$1->tok;
         strcpy ($$,"");
         while (t!=NULL) {
           strcat ($$,t->value);
           t=t->next;
         }
       }
       ;

single: TOK_OPEN singlelist {
          strcpy ($$,$1);
          strcat ($$,$2);
        }
        | TOK_OPEN TOK_CLOSE {
          strcpy ($$,$1);
          strcat ($$,$2);
        }
        ;

singlelist: text TOK_CLOSE {
              strcpy ($$,$1);
              strcat ($$,$2);
            }
            |
            text TOK_COMMA singlelist {
              strcpy ($$,$1);
              strcat ($$,$2);
              strcat ($$,$3);
            }
            ;

%%

