        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc

public  _putdosstr,_putdecimal,newline,whitespace

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

dectable        dd      1000000000,100000000,10000000,1000000,100000
                dd      10000,1000,100,10,1
decbuffer       db      0h,0h
negsign         db      '-',0h
newline         db      0Dh,0Ah,0h
whitespace      db      ' ',0h

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Print ASCIIZ string to DOS
; In:
;   EDX -> ASCIIZ string in low mem
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_putdosstr:
        push eax
        push ecx
        push edi
        mov ecx,0ffffffffh
        xor al,al
        mov edi,edx
        repnz scasb
        dec edi
        mov byte ptr [edi],'$'
        mov ecx,_code32a
        add ecx,edx
        mov eax,ecx
        and ax,0fh
        shr ecx,4
        mov v86r_ds,cx
        mov v86r_dx,ax
        mov v86r_ah,9
        mov al,21h
        int 30h
        mov byte ptr [edi],0
        pop edi
        pop ecx
        pop eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Print a decimal number 
; In:
;   EAX -> number to be printed
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

_putdecimal:
        pushad
        cmp     eax,0
        jge     _putdecimal3
        neg     eax
        mov     edx,offset negsign
        call    _putdosstr
_putdecimal3:
        mov     esi,offset dectable
        mov     ecx,10
        mov     edi,offset decbuffer
        mov     bh,0
_putdecimal0:
        cdq
        div     dword ptr [esi]
        mov     bl,al
        cmp     bl,0
        jne     _putdecimal1
        cmp     bh,0
        je      _putdecimal2     
_putdecimal1:
        mov     bh,1
        add     bl,'0'
        mov     [edi],bl
        push    edx
        mov     edx,edi
        call    _putdosstr
        pop     edx
_putdecimal2:
        mov     eax,edx
        add     esi,4
        loop    _putdecimal0
        cmp     bh,0
        jne     _putdecimal4
        mov     byte ptr [edi],'0'
        mov     edx,edi
        call    _putdosstr
_putdecimal4:
        popad
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
code32  ends
        end

