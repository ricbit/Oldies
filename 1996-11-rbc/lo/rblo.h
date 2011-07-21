#ifndef __RBLO_H
#define __RBLO_H

#define INT_ID 0
#define CHAR_ID 1
#define POINTER_ID 2

typedef struct code_t {
  char *value;
  struct code_t *next;
  int isconst;
  int type;
  char *argument;
  int isaction;
  char *alternate;
  int isalternate;
} code_t;

code_t *append_single (char *string, code_t *old);
code_t *append_double (char *string1, char *string2, code_t *old);
code_t *append_code (code_t *code, code_t *old);
code_t *append_known (char *string, int type, char *arg, code_t *old);
code_t *append_action (char *string1, char *string2, code_t *old);
code_t *append_alternate (char *string1, char *string2, code_t *old);
void flush_code (code_t *code);

#endif
