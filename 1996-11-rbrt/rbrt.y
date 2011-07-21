%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "rbrt.h"
#include "vector.h"
#include "object.h"
#include "sphere.h"
#include "plane.h"
#include "light.h"
#include "render.h"
#include "circle.h"
#include "poliedra.h"
#include "cylinder.h"
#include "surface.h"

extern ObjectList *global;
extern LightList *lightlist;
extern int BoardType;
extern int ResX,ResY;
extern double threshold;
extern int interpolation;
extern double reflection;

%}

%union {
  double number;
  Vector *vector;
  Object *object;
  ObjectList *objlist;
  Surface *surface;
  Sphere *sphere;
  Plane *plane;
  Circle *circle;
  Poliedra *poliedra;
  Cylinder *cylinder;
  PunctualLight *punctual;
  Light *light;
  int integer;
}

%token <number> TOK_NUMBER
%token TOK_COMMA
%token TOK_OPEN
%token TOK_CLOSE
%token TOK_OPEN_SCOPE
%token TOK_CLOSE_SCOPE
%token TOK_SPHERE
%token TOK_CENTER
%token TOK_RADIUS
%token TOK_PLANE
%token TOK_DIRU
%token TOK_DIRV
%token TOK_POSITION
%token TOK_PUNCTUAL
%token TOK_THRESHOLD
%token TOK_COLOR
%token TOK_INTERP
%token TOK_CIRCLE
%token TOK_CYLINDER
%token TOK_AXIS
%token TOK_LENGTH
%token TOK_SURFACE
%token TOK_KA
%token TOK_KD
%token TOK_KS
%token TOK_REFLECTION
%token TOK_POLIEDRA
%token TOK_FACE
%token TOK_VERTEX

%type <vector> vector 
%type <number> number
%type <object> object
%type <sphere> sphere
%type <sphere> _sphere
%type <plane> plane
%type <plane> _plane
%type <circle> circle
%type <circle> _circle
%type <cylinder> cylinder
%type <cylinder> _cylinder
%type <punctual> punctual
%type <punctual> _punctual
%type <surface> surface
%type <surface> _surface
%type <poliedra> poliedra
%type <poliedra> _poliedra
%type <light> light

%%

source: 
  component
  | source component
  ;

component:
  object {
    $1->Init ();
    global->Insert ($1);
  }
  | light {
    lightlist->Insert ($1); 
  }
  | TOK_THRESHOLD number {
    threshold=$2;
  }
  | TOK_REFLECTION number {
    reflection=$2;
  }
  | TOK_INTERP {
    interpolation=1;
  }
  ;

light:
  punctual {
    $$=$1;
  }
  ;

punctual: 
  _punctual TOK_CLOSE_SCOPE {
    $$=$1;
  }
  ;

_punctual:
  TOK_PUNCTUAL TOK_OPEN_SCOPE {
    $$=new PunctualLight;
  }
  | _punctual TOK_POSITION vector {
    $$=$1;
    $$->SetPosition (*$3);
  }
  | _punctual TOK_COLOR vector {
    $$=$1;
    $$->SetColor (*$3);
  }
  ;

object:
  sphere {
    $$=$1;
  }
  | plane {
    $$=$1;
  }
  | circle {
    $$=$1;
  }
  | cylinder {
    $$=$1;
  }
  | poliedra {
    $$=$1;
  }
  ;

surface:
  _surface TOK_CLOSE_SCOPE {
    $$=$1;
  }
  ;

_surface:
  TOK_SURFACE TOK_OPEN_SCOPE {
    $$=new Surface;
  }
  | _surface TOK_COLOR vector {
    $$=$1;
    $$->SetColor (*$3);
  }
  | _surface TOK_KA number {
    $$=$1;
    $$->SetKa ($3);
  }
  | _surface TOK_KD number {
    $$=$1;
    $$->SetKd ($3);
  }
  | _surface TOK_KS number {
    $$=$1;
    $$->SetKs ($3);
  }
  ;

sphere:
  _sphere TOK_CLOSE_SCOPE {
    $$=$1;
  }
  ;

_sphere:
  TOK_SPHERE TOK_OPEN_SCOPE {
    $$=new Sphere;
  }
  | _sphere TOK_CENTER vector {
    $$=$1;
    $$->SetCenter (*$3);
  }
  | _sphere TOK_RADIUS number {
    $$=$1;
    $$->SetRadius ($3);
  }
  | _sphere surface {
    $$=$1;
    $$->surface=$2;
  }
  ;

cylinder:
  _cylinder TOK_CLOSE_SCOPE {
    $$=$1;
  }
  ;

_cylinder:
  TOK_CYLINDER TOK_OPEN_SCOPE {
    $$=new Cylinder;
  }
  | _cylinder TOK_CENTER vector {
    $$=$1;
    $$->SetCenter (*$3);
  }
  | _cylinder TOK_RADIUS number {
    $$=$1;
    $$->SetRadius ($3);
  }
  | _cylinder surface {
    $$=$1;
    $$->surface=$2;
  }
  | _cylinder TOK_AXIS vector {
    $$=$1;
    $$->SetAxis (*$3);
  }
  | _cylinder TOK_LENGTH number {
    $$=$1;
    $$->SetLength ($3);
  }
  ;

plane:
  _plane TOK_CLOSE_SCOPE {
    $$=$1;
  }
  ;

_plane:
  TOK_PLANE TOK_OPEN_SCOPE {
    $$=new Plane;
  }
  | _plane TOK_CENTER vector {
    $$=$1;
    $$->SetCenter (*$3);
  }
  | _plane TOK_DIRU vector {
    $$=$1;
    $$->SetdirU (*$3);
  }
  | _plane TOK_DIRV vector {
    $$=$1;
    $$->SetdirV (*$3);
  }
  | _plane surface {
    $$=$1;
    $$->surface=$2;
  }
  ;

circle:
  _circle TOK_CLOSE_SCOPE {
    $$=$1;
  }
  ;

_circle:
  TOK_CIRCLE TOK_OPEN_SCOPE {
    $$=new Circle;
  }
  | _circle TOK_CENTER vector {
    $$=$1;
    $$->SetCenter (*$3);
  }
  | _circle TOK_DIRU vector {
    $$=$1;
    $$->SetdirU (*$3);
  }
  | _circle TOK_DIRV vector {
    $$=$1;
    $$->SetdirV (*$3);
  }
  | _circle surface {
    $$=$1;
    $$->surface=$2;
  }
  | _circle TOK_RADIUS number {
    $$=$1;
    $$->SetRadius ($3);
  }
  ;

poliedra:
  _poliedra TOK_CLOSE_SCOPE {
    $$=$1;
  }
  ;

_poliedra:
  TOK_POLIEDRA TOK_OPEN_SCOPE {
    $$=new Poliedra;
  }
  | _poliedra TOK_VERTEX TOK_NUMBER vector {
    $$=$1;
    $$->SetVertex (int($3),*$4);
  }
  | _poliedra TOK_FACE vector {
    $$=$1;
    $$->SetFace (*$3);
  }
  | _poliedra TOK_CENTER vector {
    $$=$1;
    $$->SetCenter (*$3);
  }
  | _poliedra TOK_RADIUS number {
    $$=$1;
    $$->SetRadius ($3);
  }
  | _poliedra surface {
    $$=$1;
    $$->surface=$2;
  }
  ;

vector:
  TOK_OPEN number TOK_COMMA number TOK_COMMA number TOK_CLOSE {
    $$=new Vector ($2,$4,$6);
  }
  ;

number:
  TOK_NUMBER {
    $$=$1;
  }
  ;

%%

int yyerror (char *error) {
  printf ("Error: %s\n",error);
  exit (1);
}
