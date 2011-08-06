; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: JOYSTICK.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include bit.inc

public joyenable
public joysens
public calibrate_joystick
public read_joystick
public snespad
public lptport

extrn gamegear: dword

; DATA ---------------------------------------------------------------

snespad         dd      0
lptport         dd      0378h

joyx            dd      0
joyy            dd      0
joyxmax         dd      0
joyxmin         dd      0
joyymax         dd      0
joyymin         dd      0
joyenable       dd      0
joycenter       dd      0
joybutton       db      0
joymsx          db      0
joysens         db      3
startnmi        db      1

; joystick_sample ----------------------------------------------------
; get a sample from the joystick

joystick_sample:
                mov     edx,201h
                mov     al,0

                ; start joystick polling
                cli
                
                in      al,dx
                and     al,00110000b
                mov     joybutton,al
                
                mov     ebx,0
                mov     ecx,0
                out     dx,al

joystick_sample_loop:
                in      al,dx

                mov     ah,al
                shr     ah,1
                adc     ebx,0
                shr     ah,1
                adc     ecx,0

                and     al,03h
                jnz     joystick_sample_loop

                mov     joyx,ebx
                mov     joyy,ecx

                sti
                ret

; calibrate_joystick -------------------------------------------------
; calibrate the joystick by making one sample

calibrate_joystick:
                call    joystick_sample

                mov     eax,joyx
                mov     joycenter,eax
                
                mov     eax,joyx
                mov     cl,joysens
                shr     eax,cl
                
                mov     ebx,joyx
                add     ebx,eax
                mov     joyxmax,ebx

                mov     ebx,joyx
                sub     ebx,eax
                mov     joyxmin,ebx

                mov     eax,joyy
                shr     eax,cl
                
                mov     ebx,joyy
                add     ebx,eax
                mov     joyymax,ebx

                mov     ebx,joyy
                sub     ebx,eax
                mov     joyymin,ebx

                ret

; read_joystick ------------------------------------------------------
; read the joystick and return one byte in MSX-joy format
; output: al=joybyte

read_joystick:
                cmp     snespad,1
                je      read_snespad
                
                pushad
                call    joystick_sample

                cmp     pad_enabled,1
                je      read_joystick_paddle

                mov     bl,00001111b

                ; left
                mov     eax,joyx
                cmp     eax,joyxmin
                jae     read_joystick_no_left
                and     bl,NBIT_2
read_joystick_no_left:
                
                ; right
                cmp     eax,joyxmax
                jbe     read_joystick_no_right
                and     bl,NBIT_3
read_joystick_no_right:
                
                ; down
                mov     eax,joyy
                cmp     eax,joyymin
                jae     read_joystick_no_down
                and     bl,NBIT_0
read_joystick_no_down:
                
                cmp     eax,joyymax
                jbe     read_joystick_no_up
                and     bl,NBIT_1
read_joystick_no_up:

                mov     joymsx,bl
                popad
                mov     al,joymsx
                or      al,joybutton
                ret

read_joystick_paddle:
                mov     edx,0
                mov     eax,joyx
                mov     ebx,joycenter
                shr     ebx,3
                div     ebx
                cmp     eax,15
                jbe     read_joystick_paddle_ok
                mov     eax,15
read_joystick_paddle_ok:
                mov     padstatus,al
                popad
                mov     al,joybutton
                ret


; read_snespad -------------------------------------------------------
; read the status of a SNES pad connected on LPT1

read_snespad:
                pushad
                mov     bl,0FFh

                ; B 
                mov     al,0FAh
                call    read_snes_byte

                ; Y
                mov     al,0F9h
                call    read_snes_byte
                rol     al,4
                and     bl,al
                
                ; Select
                mov     al,0F9h
                call    read_snes_byte
                
                ; Start
                mov     al,0F9h
                call    read_snes_byte
                cmp     gamegear,1
                je      read_snespad_gamegear

                movzx   ecx,al
                and     ecx,1
                xor     ecx,1
                and     cl,startnmi
                mov     nmi,ecx
                mov     startnmi,al
                jmp     read_snespad_continue

read_snespad_gamegear:
                or      byte ptr [offset smsjoya+2],BIT_7
                rol     al,7
                and     byte ptr [offset smsjoya+2],al

read_snespad_continue:

                ; Up
                mov     al,0F9h
                call    read_snes_byte
                and     bl,al
                
                ; Down
                mov     al,0F9h
                call    read_snes_byte
                rol     al,1
                and     bl,al
                
                ; Left
                mov     al,0F9h
                call    read_snes_byte
                rol     al,2
                and     bl,al
                
                ; Right
                mov     al,0F9h
                call    read_snes_byte
                rol     al,3
                and     bl,al
                
                ; A
                mov     al,0F9h
                call    read_snes_byte
                
                ; X
                mov     al,0F9h
                call    read_snes_byte
                rol     al,5
                and     bl,al
                
                rept    2
                mov     al,0F9h
                call    read_snes_byte
                endm

                mov     joymsx,bl
                popad
                mov     al,joymsx

                ret

read_snes_byte:
                mov     edx,lptport ;0378h
                out     dx,al

                mov     al,0F8h
                out     dx,al

                inc     dx
                in      al,dx
                and     al,040h
                shr     al,6
                or      al,0FEh

                ret

code32          ends
                end


