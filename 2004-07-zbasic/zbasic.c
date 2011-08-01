#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <io.h>
#include <ctype.h>

#define SYNTAX(s) {printf("\n" s " (%02X)\n",buf[0]);exit(0);}

unsigned char *buf;
unsigned char *vars;

void optional_space(void) {
  if (buf[0]==0x20) {
    printf (" ");
    buf++;
    optional_space();
  }
}

void expect_line_number (void) {
  int line;

  if (buf[0]!=0xE)
    SYNTAX ("expecting 0xE line number id");
  buf++;

  line=buf[0]+buf[1]*256;
  printf ("%d",line);
  buf+=2;
}

int variable_name (void) {
  int varname;

  if (!isalpha(buf[0]))
    SYNTAX("wrong variable name");
  varname=buf[0];
  printf ("%c",buf[0]);
  buf++;

  if (isalnum(buf[0])) {
    varname+=buf[0]*256;
    printf ("%c",buf[0]);
    buf++;

    while(isalnum(buf[0])) {
      printf ("%c",buf[0]);
      buf++;
    }
  }

  if (vars[varname]<255)
    vars[varname]++;
  return varname;
}

void expression(void);

void function_single_parameters(void) {
  if (buf[0]!=0x28)
    SYNTAX("expecting (");
  printf("(");
  buf++;

  expression();

  if (buf[0]!=0x29)
    SYNTAX("expecting )");
  printf(")");
  buf++;
}

void expression_bracket(void) {
  if (buf[0]!=0x28)
    SYNTAX("expecting (");
  printf("(");
  buf++;

  expression();

  if (buf[0]!=0x29)
    SYNTAX("expecting )");
  printf(")");
  buf++;
}

void single_precision(void) {
  int exp,num,i;
  double d;

  if (buf[0]!=0x1D)
    SYNTAX ("expection single 1D");
  buf++;
  exp=buf[0];
  num=buf[1]>>4;
  num=num*10+(buf[1]&0xF);
  num=num*10+(buf[2]>>4);
  num=num*10+(buf[2]&0xF);
  num=num*10+(buf[3]>>4);
  num=num*10+(buf[3]&0xF);
  d=(double)num;
  if (exp&0x80)
    d=-d;
  if (!(exp&0x40))
    SYNTAX ("can't handle single exponent negative yet");
  d=d*0.000001;
  for (i=0; i<(exp&0x3F); i++) 
    d*=10;
  printf("%d!",(int)(d+1e-6));
  buf+=4;
}

void expression_element(void) {
  optional_space();

  /* unary - */
  if (buf[0]==0xF2) {
    printf("-");
    buf++;
    expression_element();
    return;
  }

  /* functions */
  if (buf[0]==0xFF) {
    buf++;
    switch (buf[0]) {
      case 0xA2:
        /* STICK */
        printf("STICK");
        buf++;
        function_single_parameters();
        break;
      case 0x86:
        /* ABS */
        printf("ABS");
        buf++;
        function_single_parameters();
        break;
      case 0x98:
        /* VPEEK */
        printf("VPEEK");
        buf++;
        function_single_parameters();
        break;
      case 0xA3:
        /* STRIG */
        printf("STRIG");
        buf++;
        function_single_parameters();
        break;
      default:
        SYNTAX("expecting function");
    }
    return;
  }

  /* integer 0-9 */
  if (buf[0]>=0x11 && buf[0]<=0x1A) {
    printf ("%d",buf[0]-0x11);
    buf++;
    return;
  }

  /* integer 10-255 */
  if (buf[0]==0xF) {    
    printf ("%d",buf[1]);
    buf+=2;
    return;
  }

  /* integer 256-32767 */
  if (buf[0]==0x1C) {    
    printf ("%d",buf[1]+buf[2]*256);
    buf+=3;
    return;
  }

  /* single precision */
  if (buf[0]==0x1D) {
    single_precision();
    return;
  }

  /* brackets */
  if (buf[0]==0x28) {
    expression_bracket();
    return;
  }

  /* variables */
  if (isalpha(buf[0])) {
    variable_name();
    return;
  }
    

  SYNTAX("expecting expression element");
}

void expression(void) {
  expression_element();
  optional_space();

  switch (buf[0]) {
    case 0xF7:
      /* OR */
      printf ("OR");
      buf++;
      expression();
      break;
    case 0xF6:
      /* AND */
      printf ("AND");
      buf++;
      expression();
      break;
    case 0xF0:
      /* < */
      printf ("<");
      buf++;
      if (buf[0]==0xEE) {
        printf (">");
        buf++;
      }
      expression();
      break;
    case 0xEF:
      /* = */
      printf ("=");
      buf++;
      expression();
      break;
    case 0xF1:
      /* + */
      printf ("+");
      buf++;
      expression();
      break;
    case 0xFC:
      /* \ */
      printf ("\\");
      buf++;
      expression();
      break;
    case 0xF3:
      /* * */
      printf ("*");
      buf++;
      expression();
      break;
    case 0xF2:
      /* - */
      printf ("-");
      buf++;
      expression();
      break;
    case 0xEE:
      /* > */
      printf (">");
      buf++;
      expression();
      break;
  }
}

void untyped_let(void) {
  int varname;

  varname=variable_name();
  if (buf[0]!=0xEF)
    SYNTAX("expect = token");
  printf("=");
  buf++;
  expression();
}

void line_number_list() {
  expect_line_number();
  if (buf[0]==',') {
    printf(",");
    buf++;
    line_number_list();
  }
}

void on_statement(void) {
  printf ("ON");
  buf++;
  if(isalpha(buf[0])) {
    variable_name();
    switch (buf[0]) {
      case 0x89:
        /* GOTO */
        printf ("GOTO");
        buf++;
        break;
      case 0x8D:
        /* GOSUB */
        printf ("GOSUB");
        buf++;
        break;
      default:
        SYNTAX("expect GOTO or GOSUB");
    }
    line_number_list();
  } else SYNTAX ("invalid ON statement");
}

void interval_statement(void) {
  if (buf[0]!=0xFF || buf[1]!=0x85 || buf[2]!=0x45 ||
      buf[3]!=0x52 || buf[4]!=0xFF || buf[5]!=0x94)
    SYNTAX("expecting INTERVAL");
  printf ("INTERVAL");
  buf+=6;
  if (buf[0]!=0xEB)
    SYNTAX("expecting OFF");
  printf ("OFF");
  buf++;
}


void expression_list(void) {
  expression();
  if (buf[0]==',') {
    printf (",");
    buf++;
    expression();
  }
}

void basic_statement (void) {
  optional_space();
  if (isalpha(buf[0]))
    untyped_let();
  else switch (buf[0]) {
    case 0xFF:
      /* INTERVAL */
      interval_statement();
      break;
    case 0x95:
      /* ON */
      on_statement();
      break;
    case 0xC6:
      /* VPOKE */
      printf ("VPOKE");
      buf++;
      expression_list();
      break;
    case 0x98:
      /* POKE */
      printf ("POKE");
      buf++;
      expression_list();
      break;
    case 0x89:
      /* GOTO */
      printf ("GOTO");
      buf++;
      expect_line_number();
      break;
    case 0x8D:
      /* GOSUB */
      printf ("GOSUB");
      buf++;
      expect_line_number();
      break;
    case 0x8B:
      /* IF */
      printf ("IF");
      buf++;
      expression();
      if (buf[0]!=0xDA)
        SYNTAX("expecting THEN");
      printf ("THEN");
      buf++;
      if (buf[0]==0xE)
        expect_line_number();
      else
        basic_statement();
      if (buf[0]==0x3A && buf[1]==0xA1) {
        printf ("ELSE");
        buf+=2;
        basic_statement();
      }
      break;

    default: SYNTAX("unknown basic statement");
  }

  if (buf[0]==0x3A && buf[1]!=0xA1) {
    printf (":");
    buf++;
    basic_statement();
  }
}

void parse_basic_line (void) {
  int addr,line;

  addr=buf[0]+buf[1]*256;
  line=buf[2]+buf[3]*256;
  printf ("%d ",line);
  buf+=4;

  while (1) {
    basic_statement ();
    if (buf[0]==0) {
      printf ("\n");
      buf++;
      break;
    } else SYNTAX("line not terminated");
  }
}

void parse (void) {
  if (buf[0]!=0xff)
    SYNTAX ("expecting FF");

  buf++;
  while (buf[0]!=0 && buf[1]!=0)
    parse_basic_line ();
}

void printvars(void) {
  int i;

  printf ("Variables used:\n");
  for (i=0; i<65536; i++) 
    if (vars[i]) 
      printf ("%c%c %d\n",i&0xFF,i>>8?i>>8:32,vars[i]);
}

int main (int argc, char **argv) {
  FILE *f;
  int len;

  f=fopen (argv[1],"rb");
  len=filelength (fileno (f));
  buf=(unsigned char *) malloc (len); 
  fread (buf,1,len,f);
  fclose (f);

  vars=(unsigned char *) calloc (256,256);
  /*atexit (printvars);*/
  parse();

  return 0;
}


