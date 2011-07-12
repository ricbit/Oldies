        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc

upcode          equ     048h
downcode        equ     050h
leftcode        equ     04Bh
rightcode       equ     04Dh
altcode         equ     038h
esccode         equ     001h
acode           equ     01Eh
zcode           equ     02Ch
released        equ     080h

public KeyboardHandler,esckey,leftkey,rightkey,upkey,downkey
public akey,zkey,altkey 

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

align 4
upkey           dd      0
downkey         dd      0
leftkey         dd      0
rightkey        dd      0
esckey          dd      0
altkey          dd      0
akey            dd      0       
zkey            dd      0

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;-----------------------------------------------------------------------------
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Keyboard handler for run loop
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

KeyboardHandler:
        cmp     al,esccode
        jne     KeyboardHandler0
        mov     esckey,1
        ret

KeyboardHandler0:
        cmp     al,esccode+released
        jne     KeyboardHandler1
        mov     esckey,0
        ret

KeyboardHandler1:
        cmp     al,upcode
        jne     KeyboardHandler2
        mov     upkey,1
        ret

KeyboardHandler2:
        cmp     al,upcode+released
        jne     KeyboardHandler3
        mov     upkey,0
        ret

KeyboardHandler3:
        cmp     al,downcode
        jne     KeyboardHandler4
        mov     downkey,1
        ret

KeyboardHandler4:
        cmp     al,downcode+released
        jne     KeyboardHandler5
        mov     downkey,0
        ret

KeyboardHandler5:
        cmp     al,leftcode
        jne     KeyboardHandler6
        mov     leftkey,1
        ret

KeyboardHandler6:
        cmp     al,leftcode+released
        jne     KeyboardHandler7
        mov     leftkey,0
        ret

KeyboardHandler7:
        cmp     al,rightcode
        jne     KeyboardHandler8
        mov     rightkey,1
        ret

KeyboardHandler8:
        cmp     al,rightcode+released
        jne     KeyboardHandler9
        mov     rightkey,0
        ret

KeyboardHandler9:
        cmp     al,acode
        jne     KeyboardHandler10
        mov     akey,1
        ret

KeyboardHandler10:
        cmp     al,acode+released
        jne     KeyboardHandler11
        mov     akey,0
        ret

KeyboardHandler11:
        cmp     al,zcode
        jne     KeyboardHandler12
        mov     zkey,1
        ret

KeyboardHandler12:
        cmp     al,zcode+released
        jne     KeyboardHandler13
        mov     zkey,0
        ret

KeyboardHandler13:
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
code32  ends
        end

