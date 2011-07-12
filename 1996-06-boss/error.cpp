// BOSS 1.0
// by Ricardo Bittencourt 1996
// module ERROR

#include <stdlib.h>
#include <stdio.h>
#include <conio.h>
#include <ctype.h>
#include "dos.h"
#include "error.h"
#include "vesa.h"
#include "keyboard.h"

void InstallErrorHandler (void) {
}

actiontype ReportError (errortype id, char *error) {
  char c;

  switch (id) {
    case ERROR_FATAL:
      printf ("\nFATAL ERROR: %s\n",error);
      _setcursortype (_NORMALCURSOR);
      exit (1);
    case ERROR_RETRY:
      do {
        printf ("\nError: %s\n",error);
        printf ("[A]bort, [R]etry, [I]gnore ");
        if (KeyboardInstalled) {
          c=GetKeyE ();
        }
        else {
          c=toupper (getche ());
          printf ("\n");
        }
      } while (c!='R' && c!='A' && c!='I');
      switch (c) {
        case 'A': exit (1);
        case 'I': return ACTION_IGNORE;
        case 'R': return ACTION_RETRY;
      }
  }
}



