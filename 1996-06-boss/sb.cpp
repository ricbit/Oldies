// BOSS 1.0
// by Ricardo Bittencourt 1996
// module MEMORY

#include <dos.h>

#include <general.h>
#include <sb.h>

int BaseAddr;

void SetRegister (byte number, byte value) {
  asm {
    pushf
    cli
    mov dx,BaseAddr
    mov al,number
    out dx,al
    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx
    inc dx
    mov al,value
    out dx,al
    popf
    dec dx

    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx

    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx

    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx

    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx

    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx

    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx

    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx
    in  al,dx
  }
}

void ResetSoundBlaster (void) {
  byte i;

  for (i=0; i<=0xF5; i++)
    SetRegister (i,0);
}

void InitSoundBlaster (int BaseAddress) {
  byte i;

  BaseAddr=BaseAddress;
  for (i=0; i<=0xF5; i++)
    SetRegister (i,0);
}
