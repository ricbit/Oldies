%{

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include "wise_gen.h"
#include "wise_grp.h"
#include "wise_rle.h"
#include "font6x8.h"
#include "font8x8.h"
#include "fontcode.h"

#define VERSION 9

#define SCREEN_SIZE (256-8)
#define BAR_SIZE (192-23)
#define TEXT_SIZE (24)

#define FONT_NOTHING    0
#define FONT_COLOR      1
#define FONT_SIZE       2

#define HEX_DIGIT(c) \
  (('0'<=(c)&&(c)<='9')?(c)-'0':('A'<=(c)&&(c)<='F')?(c)-'A'+10:\
   'a'<=(c)&&(c)<='f'?(c)-'a'+10:0)

#define ENCODE_HEX(string) \
   (ENCODE_RGB ( \
     HEX_DIGIT(string[1])*16+HEX_DIGIT(string[2]), \
     HEX_DIGIT(string[3])*16+HEX_DIGIT(string[4]), \
     HEX_DIGIT(string[5])*16+HEX_DIGIT(string[6]))) 

typedef struct {
  int value;
  int size;
} hist_type;

typedef struct {
  int type;
  int color;
  int size;
} font_elem;

typedef struct {
  char name[1000];
  char value[1000];
} attribute_list;

extern FILE *yyin;

FILE *yyout;
hist_type hist[256];
font_elem font_stack[256];
int building_histogram=1;

char coded[2000];
char upper_coded[2000];
int code_flag=1;
int line_length=0;
int previous_size=0xFF;
int actual_size=0xFF;
int total_lines=0;
int need_space=0;
int font_size=3;
int font_pos=0;
char *current_font=CHAR_6X8_TABLE;

char *link_name[256];
int max_links=0,actual_link;

attribute_list *base_attr;
int current_attr=0;

int bgcolor=0xF;
int textcolor=0x1;
int textunder=0x1;
int linkcolor=0x5;
int linkunder=0x4;

int title=0;
int underline=0;
int color=0;
int center=0;
int bold=0;
int large=0;
int italic=0;
int has_large=0;
int font_code=0;
int font_color=0;
int current_color=0x1;
int list_level=0;
int list_status=0;
int pre_formatted=0;
int begin_line=1;
int doing_graphics=0;

int yyerror (char *error);
int yylex ();
void insert_hist (char *word);
void insert_word (char *word);
void insert_char (int c);
int eval_size (char *word);
void check_tag (char *word);
void check_link (char *word);
void check_space (char *string);
void clear_coded (void);

%}

%union {
  char *str;
}

%token TOK_OPEN_TAG
%token TOK_CLOSE_TAG
%token TOK_EQUAL
%token <str> TOK_SPACE
%token <str> TOK_WORD

%%

source:
  item
  | source item
  ;

item:
  TOK_WORD {
    if (building_histogram)
      insert_hist ($1);
    else 
      insert_word ($1);
    free ($1);
  }
  | TOK_SPACE {
    if (!building_histogram)
      check_space ($1);
    free ($1);
  }
  | TOK_CLOSE_TAG
  | tag
  ;

tag:
  TOK_OPEN_TAG TOK_WORD parameters TOK_CLOSE_TAG {
    if (!building_histogram) 
      check_tag ($2);
    else
      check_link ($2);
    current_attr=0;
    free ($2);
  }
  ;

parameters:
  | listpar
  ;

listpar:
  element
  | listpar element
  ;

element:
  TOK_EQUAL TOK_WORD {
    /*if (!building_histogram) */
      strcpy (base_attr[current_attr-1].value,$2);
    free ($2);
  }
  | TOK_WORD {
    /*if (!building_histogram) */{
      strcpy (base_attr[current_attr].name,$1);
      my_strupr (base_attr[current_attr].name);
      strcpy (base_attr[current_attr++].value,"");
    }
    free ($1);
  }
  ;

%%

void insert_hist (char *word) {
  unsigned char *p;

  for (p=word; *p; p++)
    hist[*p].size++;
}

int sort_histogram (const void *e1, const void *e2) {
  return ((hist_type *)e2)->size - ((hist_type *)e1)->size;
}

void eval_histogram (char *name) {
  int i;

  building_histogram=1;
  
  base_attr=(attribute_list *) safe_malloc (32*sizeof (attribute_list));
  
  for (i=0; i<256; i++) {         
    hist[i].value=i;
    hist[i].size=0;
    link_name[i]=NULL;
  }

  yyin=fopen (name,"rb");
  yyparse ();
  fclose (yyin);

  qsort (hist,256,sizeof (hist_type),sort_histogram);

  for (i=0; i<7; i++) {
    /*
    printf ("[%05d] %03d %c\n",hist[i].size,hist[i].value,
            hist[i].value>=32&&hist[i].value<128?hist[i].value:32);
    */
    fputc (hist[i].value,yyout);
  }
  
  /* DDA factor */
  fputc (0,yyout);
  fputc (0,yyout);
  fputc (0,yyout);
  fputc (0,yyout);

  /* default colors */
  fputc (0,yyout);
  fputc (0,yyout);
  fputc (0,yyout);
  fputc (0,yyout);

  for (i=0; i<max_links; i++) {
    /*printf ("\nlink %02d: %s",i,link_name[i]);*/
    fputc (strlen (link_name[i]),yyout);
    fputs (link_name[i],yyout);
  }
  
  fputc (0,yyout);
}

int eval_size (char *word) {
  unsigned char *p;
  int size=0;

  for (p=word; *p; p++)
    size+=current_font[*p];

  return size;
}

void insert_code (int c) {
  if (code_flag) 
    coded[actual_size]=c<<4;
  else 
    coded[actual_size++]|=c;
  code_flag^=1;
}

void perform_center_calculation (void) {
  unsigned char temp[2000];

  memset (temp,0,2000);
  temp[0]=0x15;
  temp[1]=((256-line_length)/2)&0xF8;
  memcpy (temp+2,coded,1998);
  memcpy (coded,temp,2000);
  actual_size+=2;
}

void flush_line (void) {
  unsigned char size_id;
  int upper_actual_size;

  if (center)
    perform_center_calculation ();

  actual_size+=1-code_flag;

  if (has_large && !doing_graphics) {

    upper_actual_size=2;
    upper_coded[0]=0x01;
    upper_coded[1]=0x2E;
    size_id=upper_actual_size;
    
    fputc (previous_size,yyout);
    fputc (size_id,yyout);
    fwrite (upper_coded,1,upper_actual_size,yyout);
    previous_size=size_id;
    total_lines++;
    has_large=0;
  }

  if (actual_size<64) {
    size_id=actual_size;
  }
  else if (actual_size<64+64*2) {
    actual_size=(actual_size+1)&0xFFFFFFFE;
    size_id=64+(actual_size-64)/2;
  }
  else if (actual_size<64+64*2+127*4) {
    actual_size=(actual_size+3)&0xFFFFFFFC;
    size_id=128+(actual_size-64-64*2)/4;
  }
  else {
    printf ("error: internal buffer overflow\n");
    exit (1);
  }

  fputc (previous_size,yyout);
  fputc (size_id,yyout);
  if (actual_size)
    fwrite (coded,1,actual_size,yyout);
  actual_size=size_id;
  clear_coded ();
  total_lines++;
}

void insert_space (void) {
  if (line_length+need_space>SCREEN_SIZE)
    flush_line ();
  else
    if (need_space && !begin_line) {
      insert_char (32);
      line_length+=need_space;
      need_space=0;
    }
}

void insert_align (void) {
  if (line_length%8) {
    line_length=(line_length+7)&0xFFFFFFF8;
    if (line_length>=SCREEN_SIZE)
      flush_line ();
    else {
      insert_code (0x1);  
      insert_code (0x4);  
    }
  }
}

void check_align (void) {
  if (need_space) {
    if (line_length/8 == (line_length+need_space)/8) {
      if (line_length%8)
        insert_align ();
      else
        insert_space ();
    }
    else 
      insert_space ();
    need_space=0;
  }
  else
    insert_align ();
}

void check_space (char *string) {      
  char *space;

  space=(char *) safe_malloc (2);
  strcpy (space," ");
  if (pre_formatted) {
    char *p;

    for (p=string; *p; p++) 
      switch (*p) {
        case 32:
          insert_word (space);
          break;
        case 10:
          flush_line ();
          break;
      }
  }
  else
    need_space=eval_size (space);
  free (space);
}

void insert_bold (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0x4);  
  current_font=CHAR_8X8_TABLE;
}

void insert_no_bold (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0x5);  
  current_font=CHAR_6X8_TABLE;
}

void insert_italic (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0xA);  
}

void insert_no_italic (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0xB);  
}

void insert_large (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0x8);  
  large=1;
  has_large=1;
}

void insert_no_large (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0x9); 
  large=0;
}

void insert_font_code (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0x6);  
  font_code=1;
  current_font=CHAR_CODE_TABLE;
}

void insert_no_font_code (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0x7);  
  font_code=0;
  current_font=CHAR_6X8_TABLE;
}

void insert_underline (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0x0);  
  underline=1;
}

void insert_no_underline (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0x1);  
  underline=0;
}

void insert_color_link (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0x2);  
  insert_code (((actual_link+1)>>4)&0xF);  
  insert_code ((actual_link+1)&0xF);  
  color=1;
}

void insert_color_normal (void) {
  insert_code (0x1);  
  insert_code (0x2);  
  insert_code (0x3);  
  color=0;
}

void insert_arbitrary_color (int color) {
  insert_code (0x1);
  insert_code (0x2);
  insert_code (0xF);
  insert_code (color);
}

void insert_char (int c) {
  int i;

  if (c==32)
    insert_code (0xF);
  else {
    for (i=0; i<7; i++)
      if (c==hist[i].value) {
        insert_code (i+0x8);
        return;
      }
    if (c>=32 && c<128) {
      insert_code (c>>4);
      insert_code (c & 0xF);
    }
    else {
      insert_code (0x1);
      insert_code (c>>4);
      insert_code (c & 0xF);
    }
  }
}

void split_word (char *word) {  
  char *try,*complement;
  int i,j;

  try=(char *) safe_malloc (1000);
  complement=(char *) safe_malloc (1000);
  memset (try,0,1000);

  for (i=0; i<strlen (word); i++) {
    try[i]=word[i];
    try[i+1]=0;
    if (eval_size(try)>SCREEN_SIZE-line_length) {
      try[i]=0;
      for (j=0; j<strlen (word)-i; j++)
        complement[j]=word[i+j];
      complement[j]=0;
      insert_word (try);
      insert_word (complement);
      break;
    }
  }

  free (try);
  free (complement);
}


void insert_word (char *word) {
  unsigned char *p;

  if (title)
    return;

  if (line_length+need_space+eval_size (word)>SCREEN_SIZE)
    flush_line ();

  insert_space ();

  if (begin_line && eval_size (word)>SCREEN_SIZE-line_length) 
    split_word (word);
  else {
    for (p=word; *p; p++) 
      insert_char (*p);
    line_length+=eval_size (word);
  }
  
  begin_line=0;
}

void insert_white_blocks (int blocks) {
  if (blocks) {
    insert_code (0x1);
    insert_code (0x5);
    insert_code ((blocks*8)>>4);
    insert_code ((blocks*8)&0xF);
    line_length+=blocks*8;
  }
}

void change_font_size (int new_size) {
  if (font_size==4 && !bold)
    insert_no_bold ();
  if (font_size>=5)
    insert_no_large ();

  if (new_size==4)
    insert_bold ();
  if (new_size>=5)
    insert_large ();

  font_size=new_size;
}

void clear_coded (void) {
  memset (coded,0,2000);
  previous_size=actual_size;
  actual_size=0;
  line_length=0;
  code_flag=1;
  need_space=0;
  begin_line=1;

  if (underline)
    insert_underline ();
  
  if (color)
    insert_color_link ();
  
  if (bold)
    insert_bold ();

  if (italic)
    insert_italic ();

  change_font_size (font_size);

  if (font_color)
    insert_arbitrary_color (current_color);

  if (font_code)
    insert_font_code ();

  insert_white_blocks 
    ((list_level?(list_level-1)*2:0)+((list_status==2||list_status==4)?2:0));
  
  if (list_status==3) {
    insert_char (0);
    line_length+=8;
    insert_white_blocks (1);
    list_status=4;
  }

  if (!list_level)
    list_status=0;
}

void close_coded (void) {
  if (line_length)
    flush_line ();
  flush_line ();
  fputc (previous_size,yyout);
  fputc (0xFF,yyout);
}

void build_text (char *name) {
  unsigned int dda_factor;

  building_histogram=0;
  clear_coded ();
  yyin=fopen (name,"rb");
  yyparse ();
  close_coded ();
  fclose (yyin);

  /*
  printf ("total lines: %d\n",total_lines);
  */
  if (total_lines-(TEXT_SIZE-1)-1)
    dda_factor=(unsigned int) 
      BAR_SIZE*0x1000000/(total_lines-(TEXT_SIZE-1)-1);
  else
    dda_factor=0;
  fseek (yyout,9,SEEK_SET);

  fputc ((dda_factor)&0xFF,yyout);
  fputc ((dda_factor>>8)&0xFF,yyout);
  fputc ((dda_factor>>16)&0xFF,yyout);
  fputc ((dda_factor>>24)&0xFF,yyout);

  fputc (textcolor*16+bgcolor,yyout);
  fputc (textunder*16+bgcolor,yyout);
  fputc (linkcolor*16+bgcolor,yyout);
  fputc (linkunder*16+bgcolor,yyout);

}

char *search_attr (char *word) {
  int i;

  for (i=0; i<current_attr; i++)
    if (!strcmp (word,base_attr[i].name))
      return base_attr[i].value;
  return NULL;
}

void insert_graphic_header (int blocks) {
  if (!code_flag)
    insert_code (0);
  insert_code (1);
  insert_code (6);
}

int insert_image (char *name) {
  screen2 *grp;
  compressed *pattern,*color;
  int i,j,x;

  if ((grp=open_screen2 (name,bgcolor))==NULL)
    return 0;

  flush_line ();
  doing_graphics=1;
  for (i=0; i<grp->blocks; i++) {
    x=grp->size>31?31:grp->size;
    insert_graphic_header (x);
    pattern=compress_line (grp->pattern+i*grp->size*8,x*8);
    for (j=0; j<pattern->size; j++) {
      insert_code (pattern->buffer[j]>>4);
      insert_code (pattern->buffer[j]&0xF);
    }
    color=compress_line (grp->color+i*grp->size*8,x*8);
    for (j=0; j<color->size; j++) {
      insert_code (color->buffer[j]>>4);
      insert_code (color->buffer[j]&0xF);
    }
    line_length+=x*8;
    flush_line ();
    free_compressed (pattern);
    free_compressed (color);
  }
  doing_graphics=0;
  free_screen2 (grp);
  return 1;
}

void push_font_color (int color) {      
  font_stack[font_pos].type=FONT_COLOR;
  font_stack[font_pos].color=current_color;
  font_pos++;
  check_align ();
  font_color=1;
  current_color=color;
  insert_arbitrary_color (color);
}

void push_font_color_size (int color, int size) {      
  font_stack[font_pos].type=FONT_COLOR|FONT_SIZE;
  font_stack[font_pos].color=current_color;
  font_stack[font_pos].size=font_size;
  font_pos++;
  check_align ();
  font_color=1;
  current_color=color;
  insert_arbitrary_color (color);
  change_font_size (/*font_size-size*/ size);
}

void push_font_size (int size) {      
  font_stack[font_pos].type=FONT_SIZE;
  font_stack[font_pos].size=font_size;
  font_pos++;
  change_font_size (/*font_size-size*/ size);
}

void pop_font (void) {
  if (!font_pos)
    return;

  switch (font_stack[--font_pos].type) {
    case FONT_COLOR:
      check_align ();
      insert_arbitrary_color (font_stack[font_pos].color);
      current_color=font_stack[font_pos].color;
      if (current_color==textcolor)
        font_color=0;
      break;
    case FONT_SIZE:
      change_font_size (font_stack[font_pos].size);
      break;
    case FONT_COLOR | FONT_SIZE:
      check_align ();
      insert_arbitrary_color (font_stack[font_pos].color);
      current_color=font_stack[font_pos].color;
      if (current_color==textcolor)
        font_color=0;
      change_font_size (font_stack[font_pos].size);
      break;
  }
}

void check_link (char *word) {
  my_strupr (word);
  
  if (!strcmp (word,"A")) 
    if (search_attr ("HREF")!=NULL) {
      link_name[max_links]=safe_malloc (1+strlen (search_attr ("HREF")));
      strcpy (link_name[max_links++],search_attr ("HREF"));
    }

}

void check_tag (char *word) {
  my_strupr (word);

  if (!strcmp (word,"BR")) {
    flush_line ();
  }
  
  if (!strcmp (word,"P")) {
    flush_line ();
    flush_line ();
  }

  if (!strcmp (word,"TITLE")) {
    title=1;
  }

  if (!strcmp (word,"/TITLE")) {
    title=0;
  }

  if (!strcmp (word,"HR")) {
    flush_line ();
    doing_graphics=1;
    insert_code (0x1);
    insert_code (0x3);
    line_length+=SCREEN_SIZE;
    flush_line ();
    doing_graphics=0;
  }
  
  if (!strcmp (word,"U")) 
    insert_underline ();
  
  if (!strcmp (word,"/U")) 
    insert_no_underline ();
  
  if (!strcmp (word,"A"))
    if (search_attr ("HREF")!=NULL) {
      for (actual_link=0; actual_link<max_links; actual_link++)
        if (!strcmp (search_attr ("HREF"),link_name[actual_link]))
          break;

      /*printf ("[%s],[%s]: %d\n",link_name[actual_link],
        search_attr ("HREF"),actual_link);*/
      check_align ();
      insert_underline ();
      insert_color_link ();
    }
  
  if (!strcmp (word,"/A")) {
    check_align ();
    insert_no_underline ();
    if (font_color)
      insert_arbitrary_color (current_color);
    else
      insert_color_normal ();
  }
  
  if (!strcmp (word,"CENTER")) {
    flush_line ();
    center=1;
  }
  
  if (!strcmp (word,"/CENTER")) {
    flush_line ();
    center=0;
  }
  
  if (!strcmp (word,"I")) {
    insert_italic ();
    italic=1;
  }
  
  if (!strcmp (word,"/I")) {
    insert_no_italic ();
    italic=0;
  }
  
  if (!strcmp (word,"B") && !font_code) {
    insert_bold ();
    bold=1;
  }
  
  if (!strcmp (word,"/B") && !font_code) {
    insert_no_bold ();
    bold=0;
  }
  
  if (!strcmp (word,"H1")) {
    flush_line ();
    change_font_size (6);
  }
  
  if (!strcmp (word,"H2")) {
    flush_line ();
    change_font_size (5);
  }
  
  if (!strcmp (word,"H3")) {
    flush_line ();
    change_font_size (4);
  }
  
  if (!strcmp (word,"H4")) {
    flush_line ();
    change_font_size (3);
  }
  
  if (!strcmp (word,"H5")) {
    flush_line ();
    change_font_size (2);
  }
  
  if (!strcmp (word,"H6")) {
    flush_line ();
    change_font_size (1);
  }
  
  if (!strcmp (word,"/H1")) {
    flush_line ();
    change_font_size (3);
  }
  
  if (!strcmp (word,"/H2")) {
    flush_line ();
    change_font_size (3);
  }
  
  if (!strcmp (word,"/H3")) {
    flush_line ();
    change_font_size (3);
  }
  
  if (!strcmp (word,"/H4")) {
    flush_line ();
    change_font_size (3);
  }
  
  if (!strcmp (word,"/H5")) {
    flush_line ();
    change_font_size (3);
  }
  
  if (!strcmp (word,"/H6")) {
    flush_line ();
    change_font_size (3);
  }
  
  if (!strcmp (word,"TD")) {
    flush_line ();
    center=0;
  }
  
  if (!strcmp (word,"IMG")) {
    char *string;
    int included=0;

    if (search_attr ("SRC")!=NULL) 
      included=insert_image (search_attr ("SRC"));

    if (search_attr ("ALT")!=NULL && !included) {
      if (strcmp (search_attr ("ALT"),"")) {
        string=(char *) safe_malloc (1000);
        strcpy (string,"[");
        strcat (string,search_attr ("ALT"));
        strcat (string,"]");
        insert_word (string);
      }
    }
  }
  
  if (!strcmp (word,"FONT")) {
    if (search_attr ("COLOR")!=NULL && search_attr ("SIZE")!=NULL) 
    {
        if (strstr (search_attr ("SIZE"),"+")!=NULL || 
            strstr (search_attr ("SIZE"),"-")!=NULL )
          push_font_color_size (
            match_color (ENCODE_HEX (search_attr ("COLOR"))),
            font_size+atoi (search_attr ("SIZE")));
        else
          push_font_color_size (
            match_color (ENCODE_HEX (search_attr ("COLOR"))),
            atoi (search_attr ("SIZE")));
    }
    else {
      if (search_attr ("COLOR")!=NULL) 
        push_font_color (match_color (ENCODE_HEX (search_attr ("COLOR"))));
      
      if (search_attr ("SIZE")!=NULL) {
        if (strstr (search_attr ("SIZE"),"+")!=NULL || 
            strstr (search_attr ("SIZE"),"-")!=NULL )
          push_font_size (font_size+atoi (search_attr ("SIZE")));
        else
          push_font_size (atoi (search_attr ("SIZE")));
      }
    }
  }
  
  if (!strcmp (word,"/FONT")) 
    pop_font ();
  
  if (!strcmp (word,"BODY")) {
    if (search_attr ("BGCOLOR")!=NULL) 
      bgcolor=match_color (ENCODE_HEX (search_attr ("BGCOLOR")));
    if (search_attr ("LINK")!=NULL) {
      linkcolor=match_color (ENCODE_HEX (search_attr ("LINK")));
      linkunder=match_color (ENCODE_HEX (search_attr ("LINK")));
    }
    if (search_attr ("TEXT")!=NULL) {
      textcolor=match_color (ENCODE_HEX (search_attr ("TEXT")));
      textunder=match_color (ENCODE_HEX (search_attr ("TEXT")));
    }
  }
  
  if (!strcmp (word,"DL")) 
    list_level++;
  
  if (!strcmp (word,"/DL")) {
    list_level--;  
    list_status=0;
    flush_line ();
  }

  if (!strcmp (word,"DT")) {
    list_status=1;
    flush_line ();
  }

  if (!strcmp (word,"DD")) {
    list_status=2;
    flush_line ();
  }

  if (!strcmp (word,"UL")) 
    list_level++;
  
  if (!strcmp (word,"/UL")) {
    list_level--;
    list_status=0;
    flush_line ();
  }

  if (!strcmp (word,"LI")) {
    list_status=3;
    flush_line ();
  }

  if (!strcmp (word,"TT")) {
    insert_space ();
    insert_font_code ();
  }
  
  if (!strcmp (word,"/TT")) 
    insert_no_font_code ();
  
  if (!strcmp (word,"CODE")) { 
    insert_space ();
    insert_font_code ();
  }
  
  if (!strcmp (word,"/CODE")) 
    insert_no_font_code ();
  
  if (!strcmp (word,"PRE")) {
    insert_space ();
    insert_font_code ();
    pre_formatted=1;
  }
  
  if (!strcmp (word,"/PRE")) {
    insert_no_font_code ();
    pre_formatted=0;
  }
  
}

void write_header (void) {
  unsigned char b;

  b=0xFB;
  fwrite (&b,1,1,yyout);
  b=VERSION;
  fwrite (&b,1,1,yyout);
}

int main (int argc, char **argv) {
  printf ("Web Intelligent Server 1.%d\n",VERSION);
  printf ("Copyright (C) 1999,2000 by Ricardo Bittencourt\n\n");

  if (argc<3) {
    printf ("Usage: wise input.htm output.htz\n");
    exit (1);
  }
  
  printf ("Converting %s to %s...",argv[1],argv[2]);
  fflush (stdout);
  
  yyout=fopen (argv[2],"wb");

  write_header ();
  eval_histogram (argv[1]);
  build_text (argv[1]);

  fclose (yyout);
  printf ("Done.\n");
  return 0;
}



