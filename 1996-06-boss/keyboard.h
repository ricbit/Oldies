// BOSS 1.0
// by Ricardo Bittencourt 1996
// header KEYBOARD

#ifndef __KEYBOARD_H
#define __KEYBOARD_H

#ifdef __KEYBOARD_CPP
#define _KEYBOARDEXT
#else
#define _KEYBOARDEXT extern
#endif

#define KEY_ESC         1
#define KEY_ENTER       28
#define KEY_A           30
#define KEY_I           23
#define KEY_R           19

_KEYBOARDEXT int Keyboard[128];
_KEYBOARDEXT int KeyboardInstalled;

void InstallKeyboard (void);
void RemoveKeyboard (void);
void WaitForKey (byte key);
char GetKey (void);
char GetKeyE (void);

#endif

