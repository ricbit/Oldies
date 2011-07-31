%{

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <io.h>
#include "wise_gen.h"
#include "wise_tab.h"

#define SUBST(string,hexa) \
      if (strstr (s,string)==s) { \
        *d++=(hexa); \
        s+=strlen (string); \
        swapped=1; \
      }        

char *tag_string;

%}

%option nounput

%x TAG
%x STRING

%%

[^< \t\12\15]+ {
  char *s,*d,*temp,number[6];
  int swapped,i;

  yylval.str=(char *) safe_malloc (yyleng+1);
  temp=(char *) safe_malloc (yyleng+1);
  strcpy (temp,yytext);

  for (s=temp,d=yylval.str; *s;) {
    if (*s=='&') {
      swapped=0;
      SUBST ("&quot;",34);
      SUBST ("&amp;",38);
      SUBST ("&lt;",60);
      SUBST ("&gt;",62);
      SUBST ("&nbsp;",0xA0);
      SUBST ("&iexcl;",0xA1);
      SUBST ("&cent;",0xA2);
      SUBST ("&pound;",0xA3);
      SUBST ("&curren;",0xA4);
      SUBST ("&yen;",0xA5);
      SUBST ("&brvbar;",0xA6);
      SUBST ("&sect;",0xA7);
      SUBST ("&uml;",0xA8);
      SUBST ("&copy;",0xA9);
      SUBST ("&ordf;",0xAA);
      SUBST ("&laquo;",0xAB);
      SUBST ("&not;",0xAC);
      SUBST ("&shy;",0xAD);
      SUBST ("&reg;",0xAE);
      SUBST ("&macr;",0xAF);
      SUBST ("&deg;",0xB0);
      SUBST ("&plusmn;",0xB1);
      SUBST ("&sup2;",0xB2);
      SUBST ("&sup3;",0xB3);
      SUBST ("&acute;",0xB4);
      SUBST ("&micro;",0xB5);
      SUBST ("&para;",0xB6);
      SUBST ("&middot;",0xB7);
      SUBST ("&cedil;",0xB8);
      SUBST ("&sup1;",0xB9);
      SUBST ("&ordm;",0xBA);
      SUBST ("&raquo;",0xBB);
      SUBST ("&frac14;",0xBC);
      SUBST ("&frac12;",0xBD);
      SUBST ("&frac34;",0xBE);
      SUBST ("&iquest;",0xBF);
      SUBST ("&Agrave;",0xC0);
      SUBST ("&Aacute;",0xC1);
      SUBST ("&Acirc;", 0xC2);
      SUBST ("&Atilde;",0xC3);
      SUBST ("&Auml;",0xC4);
      SUBST ("&Aring;",0xC5);
      SUBST ("&AElig;",0xC6);
      SUBST ("&Ccedil;",0xC7);
      SUBST ("&Egrave;",0xC8);
      SUBST ("&Eacute;",0xC9);
      SUBST ("&Ecirc;", 0xCA);
      SUBST ("&Euml;", 0xCB);
      SUBST ("&Igrave;",0xCC);
      SUBST ("&Iacute;",0xCD);
      SUBST ("&Icirc;",0xCE);
      SUBST ("&Iuml;",0xCF);
      SUBST ("&ETH;",0xD0);
      SUBST ("&Ntilde;",0xD1);
      SUBST ("&Ograve;",0xD2);
      SUBST ("&Oacute;",0xD3);
      SUBST ("&Ocirc;", 0xD4);
      SUBST ("&Otilde;",0xD5);
      SUBST ("&Ouml;",0xD6);
      SUBST ("&times;",0xD7);
      SUBST ("&Oslash;",0xD8);
      SUBST ("&Ugrave;",0xD9);
      SUBST ("&Uacute;",0xDA);
      SUBST ("&Ucirc;",0xDB);
      SUBST ("&Uuml;",0xDC);
      SUBST ("&Yacute;",0xDD);
      SUBST ("&THORN;",0xDE);
      SUBST ("&szlig;",0xDF);
      SUBST ("&agrave;",0xE0);
      SUBST ("&aacute;",0xE1);
      SUBST ("&acirc;", 0xE2);
      SUBST ("&atilde;",0xE3);
      SUBST ("&auml;",0xE4);
      SUBST ("&aring;",0xE5);
      SUBST ("&aelig;",0xE6);
      SUBST ("&ccedil;",0xE7);
      SUBST ("&egrave;",0xE8);
      SUBST ("&eacute;",0xE9);
      SUBST ("&ecirc;", 0xEA);
      SUBST ("&euml;", 0xEB);
      SUBST ("&igrave;",0xEC);
      SUBST ("&iacute;",0xED);
      SUBST ("&icirc;",0xEE);
      SUBST ("&iuml;",0xEF);
      SUBST ("&eth;",0xF0);
      SUBST ("&ntilde;",0xF1);
      SUBST ("&ograve;",0xF2);
      SUBST ("&oacute;",0xF3);
      SUBST ("&ocirc;", 0xF4);
      SUBST ("&otilde;",0xF5);
      SUBST ("&ouml;",0xF6);
      SUBST ("&divide;",0xF7);
      SUBST ("&oslash;",0xF8);
      SUBST ("&ugrave;",0xF9);
      SUBST ("&uacute;",0xFA);
      SUBST ("&ucirc;",0xFB);
      SUBST ("&uuml;",0xFC);
      SUBST ("&yacute;",0xFD);
      SUBST ("&thorn;",0xFE);
      SUBST ("&yuml;",0xFF);

      if (s[1]=='#' && strstr (s,";")!=NULL && (strstr (s,";")-s)<6 ) {
        for (i=2; i<(strstr (s,";")-s); i++)
          number[i-2]=s[i];
        number[i-2]=0;
        *d++=atoi (number);
        s=strstr (s,";")+1;
        swapped=1;
      }  

      if (!swapped)
        *d++=*s++;
    }
    else
      *d++=*s++;
  }        
  *d=0;
  free (temp);

  return TOK_WORD;
}

[ \t\12\15]+ {
  yylval.str=(char *) safe_malloc (yyleng+1);
  strcpy (yylval.str,yytext);
  return TOK_SPACE;
}

"<" {
  BEGIN (TAG);
  return TOK_OPEN_TAG;
}

<TAG>">" { 
  BEGIN (INITIAL);
  return TOK_CLOSE_TAG;
}

<TAG>[^>\"= \t\12\15]+ {
  yylval.str=(char *) safe_malloc (yyleng+1);
  strcpy (yylval.str,yytext);
  return TOK_WORD;
}

<TAG>"=" return TOK_EQUAL;

<TAG>[ \t\12\15]+

<TAG>"\"" {
  tag_string=(char *) calloc (1000,1);
  BEGIN (STRING);
}
<STRING>[^\"\\]+ {
  strcat (tag_string,yytext);
}
<STRING>"\\\\" {
  strcat (tag_string,"\\");
}
<STRING>"\\"[^\\] {
  tag_string[strlen (tag_string)]=yytext[1];
}
<STRING>"\"" {
  yylval.str=(char *) safe_malloc (yyleng+1);
  strcpy (yylval.str,tag_string);
  free (tag_string);
  BEGIN (TAG);
  return TOK_WORD;
}

%%

int yyerror (char *error) {
  printf ("error: %s\n",error);
  exit (1);
}

