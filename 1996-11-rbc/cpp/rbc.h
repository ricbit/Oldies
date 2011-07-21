/* RBCPP 1.4 by Ricardo Bittencourt */

#include <stdio.h>

#define MAX_STRING 250
#define MAX_INCLUDE 10

#define RBC_FATAL_ERROR 0
#define RBC_ERROR 1
#define RBC_WARNING 2

extern FILE *yyin;
extern FILE *yyout;
extern int valid_nest,invalid_nest;
extern line_number;
extern char sourcename[MAX_STRING];
extern char includename[MAX_INCLUDE][MAX_STRING];
extern int include_line[MAX_INCLUDE];
extern int actual_include;

typedef struct arg_list {
  char *name;
  struct arg_list *next;
} arg_list;

typedef struct tok_list {
  int type;
  char *value;
  struct tok_list *next;
} tok_list;

typedef struct define_list {
  char *name;
  tok_list *tok;
  int args;
  arg_list *list;
  struct define_list *next;
} define_list;

extern define_list *list,*last;
extern arg_list *actual;

void insert_item (char *name, tok_list *tok, arg_list *al);
define_list *is_defined (char *s);
void show_list (void);
char *return_filename (int actual_file);
void report_error (char *error, int type);
int is_argument (char *value, arg_list *list);
char *expand_macro (tok_list *tok, arg_list *arg);
