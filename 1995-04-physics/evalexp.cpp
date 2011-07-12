#include <iostream.h>
#include <process.h>
#include <strclass.h>
#include "Parser.h"

void main (int argc, char **argv) {
  String s;
  int i;
  if (argc<2) {
    cout << "Usage: Parser <expression>\n";
    exit (1);
  }
  for (i=1; i<argc; i++) s+=argv[i];
  Parser P(s);
  cout << "Result: " << P.Evaluate () << "\n";
}