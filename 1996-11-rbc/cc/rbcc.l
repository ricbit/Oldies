%{

/* RBC version 1.4 */
/* by Ricardo Bittencourt */

#include <string.h>
#include <stdlib.h>
#include "rbcc.h"
#include "rbcc_tab.h"

int line_number;

%}

ID              [a-zA-Z_][a-zA-Z0-9_]*
NUMBER          [0-9]+|"0"[xX][0-9a-fA-F]+

%x string

%%

"#line "[0-9]+  line_number=atoi (yytext+6);
"#source <"[^>]*">"
"int"           return TOK_INT;
"double"        return TOK_DOUBLE;
"char"          return TOK_CHAR;
"void"          return TOK_VOID;
"if"            return TOK_IF;
"while"         return TOK_WHILE;
"return"        return TOK_RETURN;
"for"           return TOK_FOR;
"do"            return TOK_DO;
{ID}            {
                  strcpy (yylval.strval,yytext);
                  return TOK_ID;
                }
{NUMBER}        {
                  yylval.number=strtol (yytext,NULL,0);
                  return TOK_NUMBER;
                }
["]             BEGIN (string);
<string>[^"]+   {
                  strcpy (yylval.strval,yytext);
                  return TOK_STRING;
                }
<string>["]     BEGIN (INITIAL);
"{"             return TOK_OPEN_SCOPE;
"}"             return TOK_CLOSE_SCOPE;
"("             return TOK_OPEN;
")"             return TOK_CLOSE;
"["             return TOK_OPEN_ARRAY;
"]"             return TOK_CLOSE_ARRAY;
";"             return TOK_END;
","             return TOK_COMMA;
"+="            return TOK_PLUSEQ;
"-="            return TOK_MINUSEQ;
"++"            return TOK_PLUS2;
"+"             return TOK_PLUS;
"&"             return TOK_BINARYAND;
"<<"            return TOK_SHL;
">>"            return TOK_SHR;
"<="            return TOK_LET;
"=="            return TOK_EQUAL2;
"!="            return TOK_NOTEQUAL;
"*="            return TOK_TIMESEQ;
"%="            return TOK_MODEQ;
"/="            return TOK_DIVEQ;
"="             return TOK_EQUAL;
"*"             return TOK_TIMES;
"<"             return TOK_LT;
">"             return TOK_GT;
"--"            return TOK_MINUS2;
"-"             return TOK_MINUS;
"/"             return TOK_DIV;
"%"             return TOK_MOD;
"!"             return TOK_NOT;
"?"             return TOK_QUESTION;
":"             return TOK_DOT2;
"'\\"[ntr]"'"    {
                  switch (yytext[2]) {
                    case 'n': yylval.number=10; break;
                    case 't': yylval.number=9; break;
                    case 'r': yylval.number=13; break;
                  }
                  return TOK_NUMBER;
                }
"'"[^']"'"      {
                  yylval.number=yytext[1];
                  return TOK_NUMBER;
                }
[ \n\t]+        

%%

