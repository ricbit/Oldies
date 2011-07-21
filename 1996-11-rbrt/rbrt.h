#ifndef __RBRT_H
#define __RBRT_H

#ifdef __cplsuplus
extern "C" {
#endif

int yyerror (char *error);
int yylex ();
int yyparse ();

#ifdef __cplsuplus
}
#endif

#endif
