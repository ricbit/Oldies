        .386p
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc

public  _kbhand, _ksstat
public  _init_kb, _reset_kb, _getch, _reset_hand

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
_kbhand         dd      ?
kbword  label word
kbbyte          db      ?
_ksstat         db      ?       ; bits: 0-shift, 1-alt, 2-ctrl, 3-key hit
kbpausec        db      ?
kbxtbl          db      0,14,'1234567890-=',16,15,'qwertyuiop[]',13,0
                db      'asdfghjkl;''`',0,'\zxcvbnm,./',0,'*',0,32,0
                db      1,2,3,4,5,6,7,8,9,10,0,0,19,25,21,'-',23,'5'
                db      24,'+',20,26,22,17,18,0,0,0,11,12

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
waitforkb:                              ; Wait for keyboard ready
        mov ecx,20000h
waitforkbl:
        in al,64h
        test al,2
        loopnz waitforkbl
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
setkb:                                  ; Set KB, LOCKS=BL
        mov al,0edh
        call outtokb
        mov al,bl
        call outtokb
        mov al,0f4h
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
outtokb:
        mov ah,al
        mov bh,3
outtokbl0:
        call waitforkb
        mov al,ah
        out 60h,al
        mov ecx,4000h
outtokbl1:
        in al,61h
        test al,10h
        jz $-4
        in al,61h
        test al,10h
        jnz $-4
        in al,64h
        test al,1
        loopz outtokbl1
        in al,60h
        cmp al,0fah
        je _ret
        dec bh
        jnz outtokbl0
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
kbirq:                                  ; Primary keyboard IRQ
        pushad
        push ds
        push es
        mov ax,ss
        mov ds,ax
        mov es,ax
        call waitforkb
        mov al,0adh
        out 64h,al
        call waitforkb
        in al,60h
        mov bl,al
        call waitforkb
        mov al,0aeh
        out 64h,al
        call waitforkb
        cmp kbpausec,0
        jne kbirqpc
        mov al,bl
        cmp al,0e0h
        je kbirqd
        cmp al,0e1h
        je kbirqp
        call _kbhand
kbirqd:
        pop es
        pop ds
        mov al,20h
        out 20h,al
        popad
        iretd
kbirqp:
        mov kbpausec,5
        jmp kbirqd
kbirqpc:
        dec kbpausec
        jmp kbirqd

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
kbhand:                                 ; Default keyboard handler
        test al,80h                     ;  Break code???
        jnz short kbbreak
        mov ah,1                        ;  KB make code, or value of shift
        cmp al,2ah                      ;  == left shift?
        jb short kbmakecc
        je short kbmakes
        cmp al,36h                      ;  == right shift?
        jb short kbmake
        je short kbmakes
        cmp al,38h                      ;  == alt?
        jne short kbmake
        mov ah,2                        ;  or in alt
kbmakes:
        or _ksstat,ah
        ret
kbmakecc:
        mov ah,4
        cmp al,1dh                      ;  == ctrl?
        je kbmakes
kbmake:                                 ;  not a shift state make code
        movzx eax,al
        mov al,kbxtbl[eax]
        or al,al
        jz short kbhandd
        or _ksstat,8
        mov kbbyte,al
        ret
kbbreak:                                ;  KB break code
        mov ah,0ffh
        cmp al,0aah                     ;  == left shift?
        jb short kbbreakcc
        je short kbbreaks
        cmp al,0b6h                     ;  == right shift?
        jb short kbbreakd
        je short kbbreaks
        cmp al,0b8h                     ;  == alt?
        jne short kbbreakd
        mov ah,0fdh                     ;  and out alt
        jmp short kbbreakd
kbbreakcc:
        cmp al,9dh                      ;  == ctrl?
        jne kbbreakd
        mov ah,0fbh                     ;  and out ctrl
        jmp kbbreakd
kbbreaks:                               ;  and out shift
        mov ah,0feh
kbbreakd:
        and _ksstat,ah
kbhandd:
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Initialize primary keyboard IRQ and secondary handler
; In:
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_init_kb:
        pushf
        cli
        push eax
        push bx
        push ecx
        mov bl,21h
        mov eax,offset kbirq
        call _setvect
        xor bl,bl
        call setkb
        in al,21h
        and al,0fdh
        out 21h,al
        call _reset_hand
        pop ecx
        pop bx
        pop eax
        popf
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Reset KB and uninstall handlers
; In:
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_reset_kb:
        pushf
        cli
        push eax
        push bx
        push ecx
        push es
        mov ax,18h
        mov es,ax
        mov bl,es:[417h]
        shr bl,4
        and bl,0fh
        call setkb
        in al,21h
        or al,2
        out 21h,al
        pop es
        pop ecx
        pop bx
        pop eax
        popf
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Reset to default KB handler
; In:
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_reset_hand:
        mov _ksstat,0
        mov _kbhand,offset kbhand
        mov kbpausec,0
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Get keystroke or wait for 1 (on default 2nd handler)
; In:
;   None
; Out:
;   AL - ASCII key or special code
;   AH - bits: 0 - Shift
;              1 - Alt
;              2 - Ctrl
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_getch:
        btr word ptr _ksstat,3
        jnc _getch
        mov ax,kbword
        ret


code32  ends
        end

