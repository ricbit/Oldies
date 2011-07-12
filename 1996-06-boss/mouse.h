// BOSS 1.0
// by Ricardo Bittencourt 1996
// header MOUSE

#ifndef __MOUSE_H
#define __MOUSE_H

#ifdef __MOUSE_CPP
#define _MOUSEEXT
#else
#define _MOUSEEXT extern
#endif

_MOUSEEXT volatile int     MouseX,MouseY;
_MOUSEEXT int              MouseMinX,MouseMinY;
_MOUSEEXT int              MouseMaxX,MouseMaxY;
_MOUSEEXT volatile int     LeftButton,RightButton;

void InstallMouseDriver (void);
void RemoveMouseDriver (void);

#endif
