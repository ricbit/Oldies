; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: PATCH.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include bit.inc

extrn emulC9: near
extrn diskimage: dword
extrn tapeimage: dword
extrn msxram: dword

public emulEDFF
public tape_pos

; DATA ---------------------------------------------------------------

align 4

boot:           db      512 dup (0)
tape_pos        dd      0
saveslot        db      0


; --------------------------------------------------------------------

; emulEDFF -----------------------------------------------------------
; main patch selector
; select patch through the PC

emulEDFF:
                ; patch not found
                inc     edi
                sub     ebp,4
                ret

; --------------------------------------------------------------------

code32          ends
                end


