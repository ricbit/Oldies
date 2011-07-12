// Demetrio 1.0
// Parser.cpp

#include "Parser.h"

void Parser::Receive (char *c) {
  expression=(char *) realloc (expression,sizeof (char)*(strlen (c)+1));
  strcpy (expression,c);
}

Parser::Parser (char *c) {
  expression=(char *) malloc (sizeof (char)*(strlen (c)+1));
  Receive (c);
}

double Parser::Evaluate (void) {
  double k;

  prog=expression;
  eval_exp (&k);
  return k;
}

void Parser::Let (int n, double k) {
  vars[n]=k;
}

/* Ponto de entrada do analisador */
void Parser::eval_exp(double *answer) {
  get_token();
  if (!*token) {
    serror(2);
    return;
  }
  eval_exp1(answer);
}

/* Processa uma atribuicao */
void Parser::eval_exp1(double *answer) {
  int slot;
  char ttok_type;
  char temp_token[80];

  if (tok_type == VARIAVEL) {
    /* salva token antigo */
    strcpy(temp_token, token);
    ttok_type = tok_type;

    /* calcula o indice da variavel */
    slot = toupper(*token)-'A';

    get_token();
    if (*token != '=') {
      putback(); /* devolve token atual */
      /* restaura token antigo - nenhuma atribuicao */
      strcpy(token, temp_token);
      tok_type = ttok_type;
    }
    else {
      get_token(); /* pega a proxima parte da expressao */
      eval_exp2(answer);
      vars[slot] = *answer;
      return;
    }
  }
  eval_exp2(answer);
}


/* Soma ou subtrai dois termos */
void Parser::eval_exp2(double *answer) {
  register char op;
  double temp;

  eval_exp3(answer);
  while((op = *token) == '+' || op == '-') {
    get_token();
    eval_exp3(&temp);
    switch(op) {
      case '-':
	*answer = *answer - temp;
	break;
      case '+':
	*answer = *answer + temp;
	break;
    }
  }
}

/* Multiplica ou divide dois fatores */
void Parser::eval_exp3(double *answer) {
  register char op;
  double temp;

  eval_exp4(answer);
  while ((op = *token) == '*' || op == '/' || op == '%') {
    get_token();
    eval_exp4(&temp);
    switch(op) {
      case '*':
	*answer = *answer * temp;
	break;
      case '/':
	*answer = *answer / temp;
	break;
      case '%':
	*answer = (int)*answer % (int)temp;
	break;
    }
  }
}

/* Processa um expoente */
void Parser::eval_exp4(double *answer) {
  double temp, ex;
  register int t;

  eval_exp5(answer);
  if (*token=='^') {
    get_token();
    eval_exp4(&temp);
    ex = *answer;
    if (temp == 0.0) {
      *answer = 1.0;
      return;
    }
    *answer = pow (ex,double (temp));
  }
}

/* Avalia um + ou - unario */
void Parser::eval_exp5(double *answer) {
  char op=0;
  int nfuncao=0;
  int toksave;

  toksave=tok_type;
  if ((tok_type == DELIMITADOR) && (*token == '+' || *token == '-')) {
    op = *token;
    get_token ();
  }
  else if (tok_type == FUNCAO) {
    nfuncao=tok_number;
    get_token ();
  }
  eval_exp6(answer);
  if (op=='-') {
    *answer = -(*answer);
    return;
  }
  if (toksave!= FUNCAO) return;
  switch (nfuncao) {
    case 0: *answer=sin (*answer); break;
    case 1: *answer=cos (*answer); break;
    case 2: *answer=tan (*answer); break;
    case 3: *answer=exp (*answer); break;
    case 4: *answer=log (*answer); break;
    case 5: *answer=log10 (*answer); break;
    case 6: *answer=asin (*answer); break;
    case 7: *answer=acos (*answer); break;
    case 8: *answer=atan (*answer); break;
  }
}

/* Processa uma expressao entre parenteses */
void Parser::eval_exp6(double *answer) {
  if ((*token == '(')) {
    get_token();
    eval_exp2(answer);
    if (*token != ')')
      serror(1);
    get_token();
  }
  else
    atom(answer);
}

/* Obtem o valor real de um numero */
void Parser::atom(double *answer) {
  switch (tok_type) {
    case VARIAVEL:
      *answer = find_var(token);
      get_token();
      return;
    case NUMERO:
      *answer = atof(token);
      get_token();
      return;
    default:
      serror(0);
  }
}

/* Devolve um token ao seu lugar de origem */
void Parser::putback(void) {
  char *t;

  t = token;
  for (; *t; t++) prog--;
}

/* Apresenta um erro de sintaxe */
void Parser::serror(int error) {
  static char *e[] = {
    "erro de sintaxe",
    "falta parenteses",
    "nenhuma expressao presente"
  };

  cerr << e[error];
}

/* Devolve o proximo token */
void Parser::get_token (void) {
  register char *temp;

  tok_type = 0;
  temp = token;
  *temp = '\0';

  if (!*prog) return;  /* final da expressao */
  while (isspace(*prog)) ++prog;  /* ignora espacos em branco */

  if (strchr("+-*/%^=()", *prog)) {
    tok_type = DELIMITADOR;
    /* avanca para o proximo char */
    *temp++ = *prog++;
  }
  else if (isalpha(*prog)) {
    while(!isdelim(*prog)) *temp++ = toupper (*prog++);
    *temp = '\0';
    if (isfunction (token))
      tok_type = FUNCAO;
    else
      tok_type = VARIAVEL;
  }
  else if (isdigit(*prog)) {
    while(!isdelim(*prog)) *temp++ = *prog++;
    tok_type = NUMERO;
  }

  *temp = '\0';
}

/* Devolve se c e um delimitador */
int Parser::isdelim(char c) {
  if (strchr("+-*/%^=() ", c) || c==9 || c=='\r' || c==0)
    return 1;

  return 0;
}


double Parser::find_var(char *s) {
  if (!isalpha(*s)) {
    serror(1);
    return 0.0;
  }
  return vars[toupper(*token)-'A'];
}

int Parser::isfunction (char *c) {
  int i=0;
  static char *fnames[]= {      // Nomes das funcoes
         "SIN",
         "COS",
         "TAN",
         "EXP",
         "LN",
         "LOG",
         "ARCSIN",
         "ARCCOS",
         "ARCTAN",
         ""
  };

  while (fnames[i][0]!='\0') {
    if (!strcmp (c,fnames[i])) {
      tok_number=i;
      return 1;
    }
    i++;
  }
  return 0;
}