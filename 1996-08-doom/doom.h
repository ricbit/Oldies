/* doom.h */

typedef struct {
  double dx,dy,dz;
} vector;

typedef struct {
  int x,y;
} point;

typedef struct {
  int a,b,c;
  vector normal;
  double pa,pb,pc,pd;
} poly;

typedef struct vertex_list {
  vector vertex;
  struct vertex_list *next;
} vertex_list;

typedef struct poly_list {
  poly t;
  struct poly_list *front,*back;
} poly_list;

extern vertex_list *vlist;
extern poly_list *plist;
extern int GFXMODE,RESX,RESY;
extern int redlines_enabled;

int yyparse (void);
int yyerror (char *s);
int yylex (void);
void insert_vertex (vector vertex);
void insert_poly (poly t);
void convert_vertex (void);
