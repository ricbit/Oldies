%{

#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include "pc.h"

%}

%union {
  char str[250];
  int number;
  statelist_t *state;
  machinelist_t *machine;
  bot_t *bot;
}

%token TOK_FRAME
%token TOK_BOT
%token TOK_TIMES
%token TOK_OPEN
%token TOK_CLOSE
%token TOK_ORIGIN
%token TOK_DIRECT
%token TOK_INVERSE
%token TOK_OPEN_SEQUENCE
%token TOK_CLOSE_SEQUENCE
%token TOK_NEXT
%token <str> TOK_STATE
%token <str> TOK_STRING
%token <str> TOK_NAME
%token <str> TOK_SEQUENCE
%token <number> TOK_NUMBER
%type <number> number
%type <number> orient
%type <bot> obotscope
%type <bot> botscope
%type <state> ostatedef
%type <state> statedef
%type <state> statelist
%type <machine> seqdef
%type <machine> oseqdef

%left TOK_TIMES

%%

start: 
  TOK_BOT TOK_STRING botscope {
    char nameh[100],namecc[100];
    FILE *file;

    strcpy (nameh,$2);
    strcat (nameh,".h");
    file=fopen (nameh,"w");
    fprintf (file,"/* auto-generated %s */\n",nameh);
    fprintf (file,"/* copyright 1997 by Ricardo Bittencourt*/\n\n");
    fprintf (file,"#include \"bot.h\"\n\n");    
    fprintf (file,"class %s: public bot {\npublic:\n\n",$2);
    flushframes ($3,file);
    flushstates ($3,file);
    flushmachine ($3,file);
    fprintf (file,"\n  void init (void);\n");
    fprintf (file,"};\n\n");
    fclose (file);
    strcpy (namecc,$2);
    strcat (namecc,".cc");
    file=fopen (namecc,"w");
    fprintf (file,"/* auto-generated %s */\n",namecc);
    fprintf (file,"/* copyright 1997 by Ricardo Bittencourt*/\n\n");
    fprintf (file,"#include \"%s\"\n",nameh);
    fprintf (file,"\nvoid %s::init (void) {\n",$2);
    fprintf (file,"  int file;\n");
    fprintf (file,"  byte *buffer;\n");
    fprintf (file,"\n  file=open (\"%s\",O_BINARY|O_RDONLY);\n",$3->origin);
    fprintf (file,"  buffer=new byte[64000];\n");
    fprintf (file,"  read (file,buffer,786);\n");
    fprintf (file,"  read (file,buffer,64000);\n");
    fprintf 
      (file,"  sprite=new sprite_t[%d];\n",getmaxframes ($3->framelist));
    flushreadframes ($3,file);
    flushanimation ($3,file);
    flushsequence ($3,file);
    fprintf (file,"}\n");
    fclose (file);
  }
  ;

botscope:
  obotscope TOK_CLOSE {
    $$=$1;
  }
  ;

obotscope:
  TOK_OPEN {
    $$=(bot_t *) malloc (sizeof (bot_t));
    $$->framelist=NULL;
    $$->statelist=NULL;
    $$->machinelist=NULL;
  }
  | obotscope TOK_ORIGIN TOK_STRING {
    $$=$1;
    $$->origin=(char *) malloc (strlen ($3)+1);
    strcpy ($$->origin,$3);
  }
  | obotscope TOK_FRAME TOK_NAME number number number number orient {
    $$=$1;
    insert_frame ($$,$3,$4,$5,$6,$7,$8);
  }
  | obotscope statedef {
    $$=$1;
    insert_state_on_bot ($$,$2);
  }
  | obotscope seqdef {
    $$=$1;
    insert_machine_on_bot ($$,$2);
  }
  ;

statedef:
  ostatedef TOK_CLOSE {
    $$=$1;
  }
  ;

ostatedef:
  TOK_STATE TOK_OPEN  {
    $$=insert_state ($1);
  }
  | ostatedef TOK_NAME {
    insert_frame_on_state ($1,$2);
  }
  ;

number:
  TOK_NUMBER {
    $$=$1;
  }
  | number TOK_TIMES number {
    $$=$1*$3;
  }
  ;

orient:
  TOK_DIRECT {
    $$=0;
  }
  | TOK_INVERSE {
    $$=1;
  }
  ;

seqdef:
  oseqdef TOK_CLOSE {
    $$=$1;
  }
  ;

oseqdef:
  TOK_SEQUENCE TOK_OPEN {
    $$=create_machine ($1);
  }
  | oseqdef TOK_OPEN_SEQUENCE statelist TOK_CLOSE_SEQUENCE
    TOK_NEXT TOK_NUMBER TOK_STATE 
  {
    $$=$1;
    insert_statelist_in_machine ($$,$3,$6,$7);
  }
  ;

statelist:
  TOK_STATE {
    $$=insert_state ($1);
  }
  | statelist TOK_STATE {
    $$=insert_one_more_state ($$,$2);
  }
  ;

%%

int main (void) {
  yyparse ();
  return 0;
}

void insert_frame 
  (bot_t *bot, char *name, int x, int y, int dx, int dy, int orient) 
{
  framelist_t *frame;  

  if (bot->framelist==NULL) {
    bot->framelist=(framelist_t *) malloc (sizeof (framelist_t));
    frame=bot->framelist;
  }
  else {
    frame=bot->framelist;
    while (frame->next!=NULL)
      frame=frame->next;
    frame->next=(framelist_t *) malloc (sizeof (framelist_t));
    frame=frame->next;
  }
  frame->name=(char *) malloc (strlen (name)+1);
  strcpy (frame->name,name);
  frame->x=x;
  frame->y=y;
  frame->dx=dx;
  frame->dy=dy;
  frame->orient=orient;
  frame->next=NULL;
}

void flushframes (bot_t *bot, FILE *file) {
  framelist_t *frame;  
  
  frame=bot->framelist;
  fprintf (file,"  enum {\n");
  while (frame!=NULL) {
    fprintf (file,"    %s",frame->name);
    if (frame->next!=NULL)
      fprintf (file,",\n");
    else 
      fprintf (file,"\n");
    frame=frame->next;
  }
  fprintf (file,"  } framename;\n");
}

void flushmachine (bot_t *bot, FILE *file) {
  machinelist_t *machine; 
  
  machine=bot->machinelist;
  fprintf (file,"\n  enum {\n");
  while (machine!=NULL) {
    fprintf (file,"    %s",machine->name);
    if (machine->next!=NULL)
      fprintf (file,",\n");
    else 
      fprintf (file,"\n");
    machine=machine->next;
  }
  fprintf (file,"  } machinename;\n");
}

int getmaxframes (framelist_t *frame) {
  int max=0;

  while (frame!=NULL) {
    max++;
    frame=frame->next;
  }

  return max;
}

void flushreadframes (bot_t *bot, FILE *file) {
  framelist_t *frame=bot->framelist;

  while (frame!=NULL) {
    if (frame->orient) 
      fprintf 
        (file,"  sprite[%s]=get_hflip_sprite (buffer,%d,%d,%d,%d);\n",
         frame->name,frame->x,frame->y,frame->dx,frame->dy);
    else
      fprintf 
        (file,"  sprite[%s]=get_sprite (buffer,%d,%d,%d,%d);\n",
         frame->name,frame->x,frame->y,frame->dx,frame->dy);
    frame=frame->next;
  }
}

statelist_t *insert_state (char *name) {
  statelist_t *state;

  state=(statelist_t *) malloc (sizeof (statelist_t));
  state->framelist=NULL;
  state->name=(char *) malloc (strlen (name)+1);
  strcpy (state->name,name);
  state->next=NULL;
  return state;
}

statelist_t *insert_one_more_state (statelist_t *root, char *name) {
  statelist_t *state;

  state=root;
  while (state->next!=NULL)
    state=state->next;
  state->next=(statelist_t *) malloc (sizeof (statelist_t));
  state=state->next;
  state->framelist=NULL;
  state->name=(char *) malloc (strlen (name)+1);
  strcpy (state->name,name);
  state->next=NULL;
  return root;
}

void insert_frame_on_state (statelist_t *state, char *name) {
  framelist_t *frame;

  if (state->framelist==NULL) {
    state->framelist=(framelist_t *) malloc (sizeof (framelist_t));
    frame=state->framelist;
  }
  else {
    frame=state->framelist;
    while (frame->next!=NULL) 
      frame=frame->next;
    frame->next=(framelist_t *) malloc (sizeof (framelist_t));
    frame=frame->next;
  }
  frame->name=(char *) malloc (strlen (name)+1);
  strcpy (frame->name,name);
  frame->next=NULL;
}

void insert_state_on_bot (bot_t *bot, statelist_t *new_state) {
  statelist_t *state;

  if (bot->statelist==NULL) 
    bot->statelist=new_state;
  else {
    state=bot->statelist;
    while (state->next!=NULL)
      state=state->next;
    state->next=new_state;
  }
}

void insert_machine_on_bot (bot_t *bot, machinelist_t *new_machine) {
  machinelist_t *machine;

  if (bot->machinelist==NULL) 
    bot->machinelist=new_machine;
  else {
    machine=bot->machinelist;
    while (machine->next!=NULL)
      machine=machine->next;
    machine->next=new_machine;
  }
}

void flushstates (bot_t *bot, FILE *file) {
  statelist_t *state;  

  fprintf (file,"\n  enum {\n");
  state=bot->statelist;
  while (state!=NULL) {
    fprintf (file,"    %s",state->name);
    if (state->next!=NULL)
      fprintf (file,",\n");
    else
      fprintf (file,"\n");
    state=state->next;
  }
  fprintf (file,"  } statename;\n");
}

int getmaxstates (statelist_t *state) {
  int max=0;

  while (state!=NULL) {
    max++;
    state=state->next;
  }
  return max;
}

void flushanimation (bot_t *bot, FILE *file) {
  statelist_t *state;  
  framelist_t *frame;
  int i;

  fprintf (file,"  max_states=%d;\n",getmaxstates (bot->statelist));
  fprintf (file,"  anim=new animation_t[max_states];\n");
  state=bot->statelist;
  while (state!=NULL) {
    fprintf 
      (file,"  anim[%s].total=%d;\n",
      state->name,getmaxframes (state->framelist));
    fprintf (file,"  anim[%s].mapping=new int[",state->name);
    fprintf (file,"anim[%s].total];\n",state->name);
    frame=state->framelist;
    i=0;
    while (frame!=NULL) {
      fprintf 
        (file,"  anim[%s].mapping[%d]=%s;\n",state->name,i,frame->name);
      i++;
      frame=frame->next;
    }
    state=state->next;
  }
}

machinelist_t *create_machine (char *name) {
  machinelist_t *machine;

  machine=(machinelist_t *) malloc (sizeof (machinelist_t));
  machine->next=NULL;
  machine->name=(char *) malloc (strlen (name)+1);
  strcpy (machine->name,name);
  machine->transition=NULL;
  return machine;
}
    
void insert_statelist_in_machine 
  (machinelist_t *machine, statelist_t *statelist, int time, char *state)
{
  transition_t *tran;

  if (machine->transition==NULL) {
    machine->transition=(transition_t *) malloc (sizeof (transition_t));
    tran=machine->transition;
  } 
  else {
    tran=machine->transition;  
    while (tran->next!=NULL)
      tran=tran->next;
    tran->next=(transition_t *) malloc (sizeof (transition_t));
    tran=tran->next;
  }
  tran->statelist=statelist;
  tran->time=time;
  tran->final=(char *) malloc (strlen (state)+1);
  strcpy (tran->final,state);
  tran->next=NULL;
}

int getmaxsequence (bot_t *bot) {
  int max=0;
  machinelist_t *machine=bot->machinelist;
  
  while (machine!=NULL) {
    max++;
    machine=machine->next;
  }
  return max;
}

int gettotal (transition_t *transition) {
  int max=0;
  transition_t *tran=transition;

  while (tran!=NULL) {
    max+=getmaxstates (tran->statelist);
    tran=tran->next;
  }
  return max;
}

void flushsequence (bot_t *bot, FILE *file) {
  machinelist_t *machine;
  transition_t *tran;
  statelist_t *state;

  fprintf (file,"  create_state_machine (%d,max_states);\n",
           getmaxsequence (bot));
  for (machine=bot->machinelist; machine!=NULL; machine=machine->next) {
    for (tran=machine->transition; tran!=NULL; tran=tran->next) {
      for (state=tran->statelist; state!=NULL; state=state->next) {
        fprintf (file,"  state_machine[%s].nextstate[%s]=%s;\n",
                 machine->name,state->name,tran->final);
        fprintf (file,"  state_machine[%s].time[%s]=%d;\n",
                 machine->name,state->name,tran->time);
      }
    }
  }
}
