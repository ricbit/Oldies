%{

#include <stdio.h>
#include "rblo.h"

extern FILE *yyout;

%}

%token TOK_PUSHPI
%token TOK_POPSI
%token TOK_COMMENT
%token TOK_EXTERN
%token TOK_LABEL
%token TOK_DEFS
%token TOK_VARI
%token TOK_ENTER
%token TOK_LEAIPP
%token TOK_PUSHPP
%token TOK_LDIPI
%token TOK_POPSP
%token TOK_LDPISP
%token TOK_LDPPPI
%token TOK_ADDSIPI
%token TOK_CALLPP
%token TOK_RESTORE
%token TOK_EXIT
%token TOK_ENDCODE
%token TOK_STARTUP
%token TOK_SAVEPI
%token TOK_BEGIN
%token TOK_END
%token TOK_LDSIPP
%token TOK_LEAFPPP
%token TOK_JP
%token TOK_JPZI
%token TOK_JPLI
%token TOK_DIVSIPI
%token TOK_MULSIPI
%token TOK_LDPPTP
%token TOK_LDTPPI
%token TOK_LDPITP
%token TOK_JPNZI
%token TOK_MODSIPI
%token TOK_INCTPI
%token TOK_ENDF
%token <str> TOK_ARGUMENT

%type <code> source
%type <code> init_block
%type <code> init_command
%type <code> function
%type <code> scope
%type <code> command
%type <code> opcommand_list
%type <code> command_list
%type <code> expression
%type <code> action
%type <code> end

%union {
  char *str;
  code_t *code;
}

%expect 3

%%

source: 
  init end {
    flush_code ($2);
  }
  ;

init:
  init_block function {
    flush_code ($1);
    fprintf (yyout,"\n");
    flush_code ($2);
  }
  | init function {
    fprintf (yyout,"\n");
    flush_code ($2);
  }
  ;

init_block:
  init_command {
    $$=append_code ($1,NULL);
  }
  | init_block init_command {
    $$=append_code ($1,NULL);
    $$=append_code ($2,$$);
  }
  ;

init_command:
  TOK_STARTUP {
    $$=append_single ("startup",NULL);
  }
  | TOK_LABEL TOK_ARGUMENT {
    $$=append_double ("label ",$2,NULL);
  }
  | TOK_COMMENT TOK_ARGUMENT {
    $$=append_double ("comment ",$2,NULL);
  }
  | TOK_DEFS TOK_ARGUMENT {
    $$=append_double ("defs ",$2,NULL);
  }
  | TOK_VARI TOK_ARGUMENT {
    $$=append_double ("vari ",$2,NULL);
  }
  | TOK_EXTERN TOK_ARGUMENT {
    $$=append_double ("extern ",$2,NULL);
  }
  ;

function:
  TOK_LABEL TOK_ARGUMENT TOK_ENTER scope TOK_ENDF {
    $$=append_double ("label ",$2,NULL);
    $$=append_single ("enter",$$);
    $$=append_code ($4,$$);
    printf ("function processed\n");
  }
  ;

scope:
  command {
    $$=$1;
  }
  | scope command {
    $$=append_code ($1,NULL);
    $$=append_code ($2,$$);
  }
  ;

command:
  TOK_LEAIPP TOK_ARGUMENT {
    $$=append_double ("leaipp ",$2,NULL);
  }
  | TOK_LEAIPP TOK_ARGUMENT TOK_LDPPPI {
    $$=append_double ("ldvipi ",$2,NULL);
  }
  | TOK_LEAIPP TOK_ARGUMENT TOK_CALLPP {
    $$=append_double ("call ",$2,NULL);
  }
  | TOK_LEAFPPP TOK_ARGUMENT {
    $$=append_double ("leafppp ",$2,NULL);
  }
  | TOK_LEAFPPP TOK_ARGUMENT TOK_LDPPPI {
    $$=append_double ("ldfppi ",$2,NULL);
  }
  | TOK_PUSHPP {
    $$=append_single ("pushpp",NULL);
  }
  | TOK_INCTPI {
    $$=append_single ("inctpi",NULL);
  }
  | TOK_POPSP {
    $$=append_single ("popsp",NULL);
  }
  | TOK_EXIT {
    $$=append_single ("exit",NULL);
  }
  | TOK_SAVEPI {
    $$=append_single ("savepi",NULL);
  }
  | TOK_LDIPI TOK_ARGUMENT {
    $$=append_known ("ldipi ",INT_ID,$2,NULL);
  }
  | TOK_LABEL TOK_ARGUMENT {
    $$=append_double ("label ",$2,NULL);
  }
  | TOK_JP TOK_ARGUMENT {
    $$=append_double ("jp ",$2,NULL);
  }
  | TOK_JPZI TOK_ARGUMENT {
    $$=append_double ("jpzi ",$2,NULL);
  }
  | TOK_JPLI TOK_ARGUMENT {
    $$=append_double ("jpli ",$2,NULL);
  }
  | TOK_JPNZI TOK_ARGUMENT {
    $$=append_double ("jpnzi ",$2,NULL);
  }
  | TOK_LDPISP {
    $$=append_single ("ldpisp",NULL);
  }
  | TOK_LDPITP {
    $$=append_single ("ldpitp",NULL);
  }
  | TOK_LDTPPI {
    $$=append_single ("ldtppi",NULL);
  }
  | TOK_LDPPPI {
    $$=append_single ("ldpppi",NULL);
  }
  | TOK_CALLPP {
    $$=append_single ("callpp",NULL);
  }
  | TOK_RESTORE TOK_ARGUMENT {
    $$=append_double ("restore ",$2,NULL);
  }
  | TOK_BEGIN expression opcommand_list TOK_END {
    $$=append_code ($2,NULL);
    $$=append_code ($3,$$);
  }
  | TOK_BEGIN command_list TOK_END {
    $$=$2;
  }
  ;

opcommand_list: 
  /* null */ {
    $$=NULL;
  }
  | opcommand_list command {
    $$=append_code ($1,NULL);
    $$=append_code ($2,$$);
  }
  | opcommand_list TOK_PUSHPI {
    $$=append_code ($1,NULL);
    $$=append_single ("pushpi",$$);
  }
  | opcommand_list TOK_POPSI {
    $$=append_code ($1,NULL);
    $$=append_single ("popsi",$$);
  }
  | opcommand_list TOK_ADDSIPI {
    $$=append_code ($1,NULL);
    $$=append_single ("addsipi",$$);
  }
  | opcommand_list TOK_MULSIPI {
    $$=append_code ($1,NULL);
    $$=append_single ("mulsipi",$$);
  }
  | opcommand_list TOK_MODSIPI {
    $$=append_code ($1,NULL);
    $$=append_single ("modsipi",$$);
  }
  | opcommand_list TOK_DIVSIPI {
    $$=append_code ($1,NULL);
    $$=append_single ("divsipi",$$);
  }
  | opcommand_list TOK_LDPPTP {
    $$=append_code ($1,NULL);
    $$=append_single ("ldpptp",$$);
  }
  ;

command_list:
  command {
    $$=$1;
  }
  | command_list command {
    $$=append_code ($1,NULL);
    $$=append_code ($2,$$);
  }
  ;

expression:
  command_list TOK_PUSHPI command_list TOK_POPSI action {
    if ($1->isconst) {
      $$=append_code ($3,NULL);        
      $$=append_double ($5->alternate,$1->argument,$$);
    } 
    else {
      $$=append_code ($1,NULL);
      $$=append_single ("pushpi",$$);
      $$=append_code ($3,$$);
      $$=append_single ("popsi",$$);
      $$=append_code ($5,$$);
    }
  }
  | command_list TOK_PUSHPI command_list TOK_POPSI 
    TOK_LDPPTP TOK_LDTPPI action TOK_LDPITP {
    {
      $$=append_code ($1,NULL);
      $$=append_single ("pushpi",$$);
      $$=append_code ($3,$$);
      $$=append_single ("popsi",$$);
      $$=append_single ("ldpptp",$$);
      $$=append_single ("ldtppi",$$);
      $$=append_code ($7,$$);
      $$=append_single ("ldpitp",$$);
    }
  }
  | command_list TOK_LDPPTP TOK_LDTPPI TOK_INCTPI {
    $$=append_code ($1,NULL);
    $$=append_alternate ("ldpptp \nldtppi \ninctpi","incppi",$$);
  }
  | command_list TOK_PUSHPI command_list TOK_POPSI command {
    $$=append_code ($1,NULL);
    $$=append_single ("pushpi",$$);
    $$=append_code ($3,$$);
    $$=append_single ("popsi",$$);
    $$=append_code ($5,$$);
  }
  ;

action:
  TOK_ADDSIPI {
    $$=append_action ("addsipi","addipi ",NULL);
  }
  | TOK_LDSIPP {
    $$=append_action ("ldsipp","ldnipp ",NULL);
  }
  | TOK_DIVSIPI {
    $$=append_action ("divsipi","divipi ",NULL);
  }
  | TOK_MODSIPI {
    $$=append_action ("modsipi","modipi ",NULL);
  }
  | TOK_MULSIPI {
    $$=append_action ("mulsipi","mulipi ",NULL);
  }
  ;

end:
  TOK_ENDCODE {
    $$=append_single ("endcode",NULL);
  }
  ;

%%

