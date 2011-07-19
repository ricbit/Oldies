; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: WINSOCK.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include io.inc
include pmode.inc

public winsock

; DATA ---------------------------------------------------------------

; --------------------------------------------------------------------


winsock:
                mov     v86r_ax,1684h
                mov     v86r_bx,03eh
                mov     v86r_es,0
                mov     v86r_di,0
                mov     al,02fh
                int     33h
                mov     bp,v86r_es
                and     ebp,0FFFFh
                mov     eax,v86r_edi
                and     eax,0FFFFh
                call    printdecimal
                call    crlf
                mov     eax,ebp
                call    printdecimal
                call    crlf
                ret

code32          ends
                end


