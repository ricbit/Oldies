; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: MOUSE.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include pmode.inc

public mousedriver
public mousex
public mousey
public mouseleft

public init_mouse
public read_mouse
public set_mouse_range

; DATA ---------------------------------------------------------------

mousedriver     dd      0
mousex          dd      0
mousey          dd      0
mouseleft       dd      0

; init_mouse ---------------------------------------------------------
; check for mouse driver

init_mouse:
                ; detect the mouse driver
                mov     v86r_ax,0
                mov     al,33h
                int     33h
                cmp     v86r_ax,0FFFFh
                jne     _ret
                mov     mousedriver,1

                ret

; read_mouse ---------------------------------------------------------
; get the current mouse position
; updates the global vars mousex and mousey

read_mouse:
                cmp     mousedriver,1
                jne     _ret

                mov     v86r_ax,3
                mov     al,33h
                int     33h
                movzx   ecx,v86r_cx                
                movzx   edx,v86r_dx
                movzx   ebx,v86r_bx
                mov     mousex,ecx
                mov     mousey,edx
                and     ebx,1
                mov     mouseleft,ebx
                ret

; set_mouse_range ----------------------------------------------------
; set the mouse range to the screen limits

set_mouse_range:
                
                cmp     mousedriver,1
                jne     _ret

                cmp     mouse_enabled,1
                je      _ret
                
                ; set the horizontal range from 8 to 256-63
                mov     v86r_ax,7
                mov     v86r_cx,0
                mov     v86r_dx,256-16
                mov     al,33h
                int     33h

                ; set the vertical range from 0 to 192-25
                mov     v86r_ax,8
                mov     v86r_cx,0
                mov     v86r_dx,192-8
                mov     al,33h
                int     33h

                ret


code32          ends
                end


