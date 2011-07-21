/* Super Otimizador versao 1.0 */
/* Copyright (c) 2003 by Ricardo Bittencourt */

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <time.h>

#define ARGS 1
#define MAXLEVEL 4
#define nCARRYSOL
#define CONST0 0
#define CONST1 1
#define CONST2 255
#define START_ARG 0
#define END_ARG 255
#define TRY_NUMBER 5
#define RANDSAMP 16
int measure_type=2;

unsigned char final (unsigned char input) {
/*  return input+1; */
/*  return ~input;  */
/*  return -input; */
/*  return input<255?input+1:255;*/
/* return ((input&7)==7)||((input&7)==0);*/
/*  return input==3?4:input;*/
/*  return input?input:128;  */
/*  return input!=255?0:255;*/
/*  return input*23;*/
/*  return (input&3)==0;*/
/*  return 0; */
/*  return 1; */
/*  return input==0;*/
/*return input<32?input+1:input;*/
/*return input>32?input-1:input;*/
/*return input>32?input-1:input<32?input-1:input;*/
return (input==1)||(input==3)||(input==7)||(input==15)||(input==31)
        ||(input==63)||(input==127)||(input==255);
/*  return (signed char)input>=0;*/
/*  return input/2;*/
/*  return (signed char)input<0?-input:input;*/
/*  return (signed char)input*3;*/
/*  return (signed char)input<0?-1:input==0?0:1;*/
}

unsigned char final2 (unsigned char a, unsigned char h) {
/*  return a+h;*/
/*  return h-a;*/
/*  return a&&h;*/
/*  return h?a:0;*/
/*  return a<h?a+1:h; */
/*  return a?h:-h;*/
  return a<=h?h:a; /*max*/
/*  return (signed char)a<(signed char)h;  */
/*  return (a&3)==0?h+1:h;*/
/*  return (signed char)a<(signed char)h;*/
/*  return a&128?a*2+h:a*2;*/
}

typedef struct stack {
  unsigned long long prog;
  struct stack *next;
} stack;

unsigned char regs[8],carry;
stack *base;
int current;

int eval (unsigned long long prog) {
  switch (measure_type) {
    case 1:
      if (prog<0x10)
        return prog==2?2:prog==9?2:1;
      if (prog<0xA0)
        return prog%8<5?1:2;
      if (prog<0xB0)
        return 2;
      if (prog<0xC0)
        return 1;
      return prog%8<5?1:2;
    case 2:
      if (prog<0x10)
        return prog==2?10:prog==9?17:5;
      if (prog<0xA0)
        return prog%8<5?5:8;
      if (prog<0xB0)
        return 10;
      if (prog<0xC0)
        return 5;
      return prog%8<5?5:8;
    case -1:
      return 0;
    default:
      return 1;
  }
}

int measure (unsigned long long prog) {
  int n;

  /* number of instructions */
  n=0;         
  while (prog) {
    n+=eval(prog&255);
    prog>>=8;
  }
  return n;

}

void init_regs (int i) {
  regs[0]=i;
  regs[1]=(unsigned char)(rand()&0xFF);
  regs[2]=(unsigned char)(rand()&0xFF);
  carry=(unsigned char)(rand()&0x1);
}

void init_regs2 (int i, int j) {
  regs[0]=i;
  regs[1]=j;
  regs[2]=(unsigned char)(rand()&0xFF);
  carry=(unsigned char)(rand()&0x1);
}
/*
mapping:
0       nop
1       cpl
2       neg
3       ccf
4       scf
5       rlca
6       rrca
7       rla
8       rra
9       sbc hl,hl
10-17   add a,x 2
18-1F   and x   3
20-27   xor x   4
28-2F   adc a,x 5
30-37   sub a   6
38-3F   sbc a,x 7
40-47   cp  x   8
48-4F   or  x   9
A0-A7   sra y
A8-AF   srl y
B0-B7   inc y
B8-BF   dec y
C0-FF   ld  y,x
*/

#define A_IN 1
#define H_IN 2
#define L_IN 4
#define CARRY_IN 8
#define A_OUT 256*1
#define H_OUT 256*2
#define L_OUT 256*4
#define CARRY_OUT 256*8

unsigned int dataio (unsigned long long prog) {
  unsigned int temp=0;

  if (prog<10) {
    switch (prog) {
      case 0: return 0;
      case 1: return A_IN+A_OUT;
      case 2: return A_IN+A_OUT+CARRY_OUT;
      case 3: return CARRY_IN+CARRY_OUT;
      case 4: return CARRY_OUT;
      case 5: return A_IN+A_OUT+CARRY_OUT;
      case 6: return A_IN+A_OUT+CARRY_OUT;
      case 7: return A_IN+CARRY_IN+A_OUT+CARRY_OUT;
      case 8: return A_IN+CARRY_IN+A_OUT+CARRY_OUT;
      case 9: return CARRY_IN+CARRY_OUT+H_OUT+L_OUT;
    }
  }

  if (prog>=0x10 && prog<0x50) {
    temp=A_OUT+CARRY_OUT;
    switch (prog>>3) {
      case 2: temp+=A_IN; break;
      case 3: temp+=A_IN; break;
      case 4: temp+=A_IN; break;
      case 5: temp+=A_IN+CARRY_IN; break;
      case 6: temp+=A_IN; break;
      case 7: temp+=A_IN+CARRY_IN; break;
      case 8: temp+=A_IN; break;
      case 9: temp+=A_IN; break;
    }
    switch (prog%8) {
      case 0: temp|=A_IN; break;
      case 1: temp|=H_IN; break;
      case 2: temp|=L_IN; break;
    }
    return temp;
  }

  if (prog>=0xA0 && prog<0xC0) {
    switch (prog%8) {
      case 0: temp=A_IN+A_OUT; break;
      case 1: temp=H_IN+H_OUT; break;
      case 2: temp=L_IN+L_OUT; break;
    }
    switch (prog>>3) {
      case 20: return temp+CARRY_OUT;
      case 21: return temp+CARRY_OUT;
      case 22: return temp;
      case 23: return temp;
    }
  }

  if (prog>=0xC0) {
    switch (prog%8) {
      case 0: temp=A_IN;
      case 1: temp=H_IN;
      case 2: temp=L_IN;
      default: temp=0;
    }
    switch ((prog>>3)%8) {
      case 0: return temp+A_OUT;
      case 1: return temp+H_OUT;
      case 2: return temp+L_OUT;
    }
  }

  return 0;
}

void eval_fun (unsigned long long prog) {
  unsigned int arg,val,src;

  if (prog>0 && prog<10) {
    switch (prog) {
      case 1: regs[0]=regs[0]^255; break;
      case 2: carry=regs[0]!=0; regs[0]=(-regs[0])&0xFF; break;
      case 3: carry=carry^1; break;
      case 4: carry=1; break;
      case 5:
        regs[0]=((regs[0]<<1)&0xFF)|(regs[0]>>7);
        carry=regs[0]&1;
        break;
      case 6:
        regs[0]=((regs[0]>>1)&0x7F)|((regs[0]<<7)&128);
        carry=(regs[0]&128)>>7;
        break;
      case 7:
        arg=(regs[0]<<1)|carry;
        carry=arg>>8;
        regs[0]=arg&0xFF;
        break;
      case 8:
        arg=regs[0]|(carry<<8);
        carry=arg&1;
        regs[0]=arg>>1;
        break;
      case 9:
        arg=regs[1]*256+regs[2]; src=regs[1]*256+regs[2];
        val=src-arg-carry; carry=(src^arg^val)>>16;
        regs[1]=val>>8; regs[2]=val&0xFF; break;
      default: return;
    }
  }
  if (prog>=0x10 && prog<0x50) {
    switch (prog%8) {
      case 0: arg=regs[0]; break;
      case 1: arg=regs[1]; break;
      case 2: arg=regs[2]; break;
      case 5: arg=CONST0; break;
      case 6: arg=CONST1; break;
      case 7: arg=CONST2; break;
      default: return;
    }
    src=regs[0];
    switch (prog/8) {
      case 2:
        val=src+arg; carry=(src^arg^val)>>8; break;
      case 3:
        val=src&arg; carry=0; break;
      case 4:
        val=src^arg; carry=0; break;
      case 5:
        val=src+arg+carry; carry=(src^arg^val)>>8; break;
      case 6:
        val=src-arg; carry=(src^arg^val)>>8; break;
      case 7:
        val=src-arg-carry; carry=(src^arg^val)>>8; break;
      case 8:
        val=src-arg; carry=(src^arg^val)>>8; val=regs[0]; break;
      case 9:
        val=src|arg; carry=0; break;
      default:
        return;
    }
    regs[0]=val&0xFF;
    carry&=1;
  }

  if (prog>=0xA0 && prog<0xC0) {
    switch (prog%8) {
      case 0: arg=regs[0]; break;
      case 1: arg=regs[1]; break;
      case 2: arg=regs[2]; break;
      default: return;
    }
    switch (prog>>3) {
      case 20: carry=(arg&1); val=(arg>>1)|(arg&128); break;
      case 21: carry=(arg&1); val=(arg>>1); break;
      case 22: val=(arg+1)&255; break;
      case 23: val=(arg-1)&255; break;
      default: return;
    }
    switch (prog%8) {
      case 0: regs[0]=val; break;
      case 1: regs[1]=val; break;
      case 2: regs[2]=val; break;
      default: return;
    }
  }

  if (prog>=0xC0) {
    switch (prog%8) {
      case 0: arg=regs[0]; break;
      case 1: arg=regs[1]; break;
      case 2: arg=regs[2]; break;
      case 5: arg=CONST0; break;
      case 6: arg=CONST1; break;
      case 7: arg=CONST2; break;
      default: return;
    }
    switch ((prog>>3)%8) {
      case 0: regs[0]=arg; break;
      case 1: regs[1]=arg; break;
      case 2: regs[2]=arg; break;
      default: return;
    }
  }
}

void printbin (unsigned long long prog) {
  int i;

  for (i=0; i<16; i++) {
    printf ("%c",'0'+(prog&1));
    prog>>=1;
  }
  printf (" ");
}

void print_fun (unsigned long long prog) {
  if (prog>0 && prog<10) {
    switch (prog) {
      case 1: printf ("CPL"); break;
      case 2: printf ("NEG"); break;
      case 3: printf ("CCF"); break;
      case 4: printf ("SCF"); break;
      case 5: printf ("RLCA"); break;
      case 6: printf ("RRCA"); break;
      case 7: printf ("RLA"); break;
      case 8: printf ("RRA"); break;
      case 9: printf ("SBC HL,HL"); break;
      default: return;
    }
    printf ("\n");
    return;
  }

  if (prog>=0x10 && prog<0x50) {
    switch (prog/8) {
      case 2: printf ("ADD A,"); break;
      case 3: printf ("AND "); break;
      case 4: printf ("XOR "); break;
      case 5: printf ("ADC A,"); break;
      case 6: printf ("SUB "); break;
      case 7: printf ("SBC A,"); break;
      case 8: printf ("CP  "); break;
      case 9: printf ("OR  "); break;
      default: return;
    }
    switch (prog%8) {
      case 0: printf ("A"); break;
      case 1: printf ("H"); break;
      case 2: printf ("L"); break;
      case 5: printf ("%d",CONST0); break;
      case 6: printf ("%d",CONST1); break;
      case 7: printf ("%d",CONST2); break;
      default: return;
    }
    printf ("\n");
  }

  if (prog>=0xA0 && prog<0xC0) {
    switch (prog>>3) {
      case 20: printf ("SRA "); break;
      case 21: printf ("SRL "); break;
      case 22: printf ("INC "); break;
      case 23: printf ("DEC "); break;
      default: return;
    }
    switch (prog%8) {
      case 0: printf ("A"); break;
      case 1: printf ("H"); break;
      case 2: printf ("L"); break;
      default: return;
    }
    printf ("\n");
  }

  if (prog>0xC0) {
    switch ((prog>>3)%8) {
      case 0: printf ("LD  A,"); break;
      case 1: printf ("LD  H,"); break;
      case 2: printf ("LD  L,"); break;
      default: return;
    }
    switch (prog%8) {
      case 0: printf ("A"); break;
      case 1: printf ("H"); break;
      case 2: printf ("L"); break;
      case 5: printf ("%d",CONST0); break;
      case 6: printf ("%d",CONST1); break;
      case 7: printf ("%d",CONST2); break;
      default: return;
    }
    printf ("\n");
  }
}

int dataflow (unsigned long long prog) {
#if ARGS==1
  unsigned char data=A_IN;
#else
  unsigned char data=A_IN|H_IN;
#endif
  unsigned int opcode;

  while (prog) {
    opcode=dataio(prog&0xFF);
    prog>>=8;
    if ((opcode&data)!=(opcode&0xFF))
      return 0;
    data|=(opcode>>8);
  }
  return 1;

}

void print_prog (unsigned long long prog) {
  printf ("----- %d \n",measure(prog));
  while (prog) {
    print_fun (prog&0xFF);
    prog>>=8;
  }
}

int eval_prog (unsigned long long prog) {
  while (prog) {
    eval_fun (prog&0xFF);
    prog>>=8;
  }
#ifdef CARRYSOL
  return carry;
#else
  return regs[0];
#endif
}

int valid (unsigned long long prog) {
  unsigned int tail;

  tail=prog&0xFF;

  if (tail>0 && tail<10) {
    if ((prog>>8)==0)
      return 1;
    return (valid(prog>>8));        
  }

  if (tail>=0x10 && tail<0x50) {
    if (tail%8==3 || tail%8==4)
      return 0;
    if ((prog>>8)==0)
      return 1;
    return (valid(prog>>8));    
  }

  if (tail>=0xA0 && tail<0xC0) {
    if (tail%8>2)
      return 0;
    if ((prog>>8)==0)
      return 1;
    return (valid(prog>>8));    
  }

  if (tail>=0xC0) {
    if (tail%8==3 || tail%8==4)
      return 0;
    if (((tail>>3)%8)>2)
      return 0;
    if ((prog>>8)==0)
      return 1;
    return (valid(prog>>8));    
  }
  return 0;
}

int check_fun (unsigned long long prog) {
  int i;

#if ARGS==1
  for (i=0; i<RANDSAMP; i++) {
    int a;
    a=random()&255;
    init_regs (a);
    if (eval_prog (prog)!=final (a))
      return 0;
  }
  for (i=START_ARG; i<=END_ARG; i++) {
    init_regs (i);
    if (eval_prog (prog)!=final (i))
      return 0;
  }
#else
  for (i=0; i<RANDSAMP; i++) {
    int a,b;
    a=random()&255;
    b=random()&255;
    init_regs2 (a,b);
    if (eval_prog (prog)!=final2 (a,b))
      return 0;
  }
  for (i=0; i<65536; i++) {
    init_regs2 (i>>8,i&255);
    if (eval_prog (prog)!=final2 (i>>8,i&255))
      return 0;
  }
#endif

  return 1;
}

int check_fun_ok (unsigned long long prog) {
  int i;

#if ARGS==1
  for (i=0; i<TRY_NUMBER; i++) {
    if (!check_fun (prog))
      return 0;
  }
  return 1;
#else
  return check_fun (prog);
#endif
}

void push (unsigned long long prog) {
  stack *p;

  p=(stack *) malloc (sizeof (stack));
  p->prog=prog;
  p->next=base;
  base=p;
}

void check_top (unsigned long long  level, int goal, unsigned long long prev) {
  unsigned long long i,prog;

  for (i=0; i<=0xFF; i++) {
    if (level==0)
      printf ("%c%d",13,i);

    prog=(prev)|(i<<(level*8));

    if (!valid (prog))
      continue;
    if (!dataflow (prog))
      continue;
    if (measure(prog)>current)
      continue;

    if (level==goal) {
    
      if (check_fun_ok (prog)) {
        if (measure(prog)<current) {
          base=NULL;
          current=measure(prog);
          print_prog (prog);
        }
        push (prog);
      }

    } else {

      check_top (level+1,goal,prog);
      
    }
  }
}

int main (int argc, char **argv) {
  stack *p;

  srand (time (0));
  base=NULL;
  current=1e6;

  check_top (0,MAXLEVEL,0);

  printf ("\n");
  for (p=base; p!=NULL; p=p->next)
    print_prog (p->prog);

  return 0;
}
