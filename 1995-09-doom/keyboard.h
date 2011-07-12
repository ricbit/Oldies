/* Multikey Keyboard Header File */
/* Ricardo Bittencourt (9/95) */

#ifndef __KEYBOARD_H
#define __KEYBOARD_H

#include <conio.h>
#include <dos.h>

#ifdef __cplusplus
extern "C" {
#endif

#define UP       72
#define DOWN     80
#define LEFT     75
#define RIGHT    77
#define ESC      1
#define RELEASED 128

#ifdef __KEYBOARD_CPP
void interrupt (*Old9Handler) (...);
unsigned char uk=0,rk=0,lk=0,dk=0,ek=0;
#elif
extern void interrupt (*Old9Handler) (...);
extern unsigned char uk,rk,lk,dk,ek;
#endif

void interrupt New9Handler (...);
void InitKeyboard (void);
void RestoreKeyboard (void);

#ifdef __cplusplus
extern "C" {
#endif

#endif