// Demetrio 1.0
// Parser.h

#ifndef __PARSER_H
#define __PARSER_H

#include <iostream.h>
#include <string.h>
#include <malloc.h>
#include <ctype.h>
#include <stdlib.h>
#include <math.h>

#define DELIMITADOR 	1
#define VARIAVEL 	2
#define NUMERO 		3
#define FUNCAO          4

class Parser {
public:
  // Constructor que recebe a expressao inicial
  Parser (char *c="");
  // Recebe uma string apos o constructor
  void Receive (char *c);
  // Calcula o valor da expressao para as variaveis atuais
  double Evaluate (void);
  // Altera o valor da variavel n, fazendo vars[n]=k
  void Let (int n, double k);
private:
  char *expression;             // Expressao
  char *prog;                   // Expressao temporaria
  char token[80];               // Tokens
  char tok_type;                // Tipo de token
  int tok_number;               // Numero do token
  double vars[26];              // 26 variaveis do usuario

  void eval_exp (double *answer);
  void eval_exp1 (double *answer);
  void eval_exp2 (double *answer);
  void eval_exp3 (double *answer);
  void eval_exp4 (double *answer);
  void eval_exp5 (double *answer);
  void eval_exp6 (double *answer);
  void atom (double *answer);
  void get_token (void);
  void putback (void);
  void unary (char o, double *r);
  void serror (int error);
  double find_var (char *s);
  int isdelim (char c);
  int isfunction (char *s);
};

#endif