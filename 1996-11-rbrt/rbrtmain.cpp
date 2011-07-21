#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include "rbrt.h"
#include "object.h"
#include "render.h"
#include "light.h"

ObjectList *global;
LightList *lightlist;
extern FILE *yyin;

int main (int argc, char **argv) {

  if (argc<2) {
    printf ("usage: rbrt scene.rbs\n");
    exit (1);
  }
  yyin=fopen (argv[1],"r");
  global=new ObjectList;
  lightlist=new LightList;
  yyparse ();
  printf ("Parsed\n");
  global->Print ();
  lightlist->Print ();
  printf ("Vou renderizar\n");
  getch ();
  Render (global);
}
