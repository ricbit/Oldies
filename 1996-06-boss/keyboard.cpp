// BOSS 1.0
// by Ricardo Bittencourt 1996
// module KEYBOARD

#define __KEYBOARD_CPP

#include <dos.h>
#include <stdlib.h>
#include <stdio.h>
#include "general.h"
#include "keyboard.h"

void interrupt (*OldKeyboardHandler) (...);

void interrupt NewKeyboardHandler (...) {
  byte key;

  key=inportb (0x60);
  if (key<128) {
    Keyboard[key]=1;
  }
  else {
    Keyboard[key-128]=0;
  }
  outportb (0x20,0x20);
}

void InstallKeyboard (void) {
  int i;

  for (i=0; i<128; i++)
    Keyboard[i]=0;
  KeyboardInstalled=1;
  atexit (RemoveKeyboard);
  OldKeyboardHandler=getvect (0x09);
  setvect (0x09,NewKeyboardHandler);
}

void RemoveKeyboard (void) {
  if (KeyboardInstalled) {
    setvect (0x09,OldKeyboardHandler);
    KeyboardInstalled=0;
  }
}

void WaitForKey (byte key) {
  while (!Keyboard[key]);
}

char GetKey (void) {
  int i,keypressed,sum;

  i=0;
  do {
    sum=0;
    for (i=1; i<=88; i++)
      sum+=Keyboard[i];
  } while (sum!=0);
  do {
    i++;
    if (i>88) i=1;
  } while (!Keyboard[i]);

  switch (i) {
    case KEY_A:   return ('A');
    case KEY_R:   return ('R');
    case KEY_I:   return ('I');
  }
  return (KEY_ENTER);
}

char GetKeyE (void) {
  char c;

  c=GetKey ();
  printf ("%c\n",c);
  return c;
}

void KeyboardStartUp (void) {
  KeyboardInstalled=0;
}
#pragma startup KeyboardStartUp 255

