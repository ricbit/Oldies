/* RBC version 1.4 */
/* by Ricardo Bittencourt */

#include <stdio.h>

#define MAX_STRING 200

#define VOID_ID 0
#define INT_ID 1
#define DOUBLE_ID 2
#define CHAR_ID 3
#define NUMBER_ID 4
#define POINTER_ID 5
#define FUNCTION_ID 6

typedef struct type_t { 
  int type;
  int string;
  char *name;
  struct type_t *pointed;
} type_t;

typedef struct code_t {
  char *line;
  struct code_t *next;
} code_t;

typedef struct argument_t {
  type_t *type;
  char *name;
  char *offset;
  struct argument_t *next;
} argument_t;

typedef struct function_list_t {
  char *name;
  type_t *type;
  code_t *code;
  int used;
  argument_t *argument;
  struct function_list_t *next;
} function_list_t;

typedef struct lvalue_t {
  type_t *type;
  code_t *code;
  int value;
} lvalue_t;

typedef struct lvalue_list_t {
  lvalue_t *lvalue;
  struct lvalue_list_t *next;
} lvalue_list_t;

typedef struct variable_t {
  type_t *type;
  char *name;
  int value;
  struct variable_t *next;
} variable_t;

typedef struct function_name_t {
  type_t *type;
  char *name;
} function_name_t;

typedef struct string_list_t {
  char *string;
  struct string_list_t *next;
} string_list_t;

extern function_list_t *function_list;
extern argument_t *local_args;
extern variable_t *global_vars;
extern FILE *yyin,*yyout;

void add_function (char *s, type_t *type, code_t *code, argument_t *arg);
void flush_functions ();
function_list_t *isfunction (char *s);
argument_t *isargument (char *s);
code_t *append_line (char *s, code_t *code);
code_t *append_code (code_t *c, code_t *code);
void add_global (type_t *type, char *name, int value);
void flush_variables ();
int isvariable (char *s);
void check_type (lvalue_t *lval1, lvalue_t *lval2);
type_t *variable_type (char *s);
type_t *function_type (char *s);
void force_cast (type_t *type, lvalue_t *lval);
void flush_externs ();
void function_used (char *name);
int add_string (char *str);
void flush_strings ();
