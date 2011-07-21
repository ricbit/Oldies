%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "rbrt.h"
#include "vector.h"
#include "object.h"
#include "sphere.h"
#include "plane.h"
#include "circle.h"
#include "poliedra.h"
#include "cylinder.h"
#include "light.h"
#include "rbrt_tab.h"

%}

%%

[+-]?[0-9]+("."[0-9]+)? {
  yylval.number=atof (yytext);  
  return TOK_NUMBER;
}

","             return TOK_COMMA;
"("             return TOK_OPEN;
")"             return TOK_CLOSE;
"{"             return TOK_OPEN_SCOPE;
"}"             return TOK_CLOSE_SCOPE;

"sphere"        return TOK_SPHERE;
"center"        return TOK_CENTER;
"radius"        return TOK_RADIUS;
"plane"         return TOK_PLANE;
"dirU"          return TOK_DIRU;
"dirV"          return TOK_DIRV;
"punctual"      return TOK_PUNCTUAL;
"position"      return TOK_POSITION;
"threshold"     return TOK_THRESHOLD;               
"interp"        return TOK_INTERP;
"color"         return TOK_COLOR;
"circle"        return TOK_CIRCLE;
"cylinder"      return TOK_CYLINDER;
"axis"          return TOK_AXIS;
"length"        return TOK_LENGTH;
"surface"       return TOK_SURFACE;
"ka"            return TOK_KA;
"kd"            return TOK_KD;
"ks"            return TOK_KS;
"reflection"    return TOK_REFLECTION;
"poliedra"      return TOK_POLIEDRA;
"vertex"        return TOK_VERTEX;
"face"          return TOK_FACE;

[ \t\n]
.               yyerror ("Syntax error");

%%
