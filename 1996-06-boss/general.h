// BOSS 1.0
// by Ricardo Bittencourt 1996
// header GENERAL

#ifndef __GENERAL_H
#define __GENERAL_H

#ifdef __SCANEDIT_CPP
#define _GENERALEXT
#else
#define _GENERALEXT extern
#endif

#define epsilon         1e-5
#define PI              3.1415926535897

typedef unsigned char        byte;
typedef unsigned int         word;
typedef unsigned long int    dword;
typedef byte                *pbyte;
typedef double               real;

#endif
