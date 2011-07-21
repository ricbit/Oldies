/* RBC version 1.4 */
/* by Ricardo Bittencourt */

#ifndef __RBATMAIN_H
#define __RBATMAIN_H

typedef struct arglist {
  char *value;
  struct arglist *next;
} arglist;

#define BASE_ID 0
#define INT_ID 1
#define CHAR_ID 2
#define POINTER_ID 3
#define MAX_TYPES 4

void insert_opcode (char *name, int args, char *value);
void list_opcodes (void);
void flush_opcode (char *name, arglist *argument);
arglist *insert_argument (char *value, arglist *argument);
char *convert_stack (char *stack);
char *convert_frame (char *stack);

#endif

