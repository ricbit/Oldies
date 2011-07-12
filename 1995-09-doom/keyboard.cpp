#define __KEYBOARD_CPP

#include "keyboard.h"

void interrupt New9Handler (...) {
  int v;
  v=inp (0x60);
  switch (v) {
    case UP:                    uk=1; break;
    case DOWN:                  dk=1; break;
    case LEFT:                  lk=1; break;
    case RIGHT:                 rk=1; break;
    case ESC:                   ek=1; break;
    case RELEASED+UP:           uk=1; break;
    case RELEASED+DOWN:         dk=1; break;
    case RELEASED+LEFT:         lk=1; break;
    case RELEASED+RIGHT:        rk=1; break;
    case RELEASED+ESC:          ek=1; break;
  }
  Old9Handler ();
  if (kbhit ()) getch ();
}

void InitKeyboard (void) {
  Old9Handler=getvect (9);
  setvect (9,New9Handler);
}

void RestoreKeyboard (void) {
  setvect (9,Old9Handler);
}

