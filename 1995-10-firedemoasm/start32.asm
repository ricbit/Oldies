; 386 Protected mode control program header.
; By Tran.
; Feel free to use this code in your own programs.

        .386p

LOWMIN  equ     0               ; minimum low memory needed to run (in K)
EXTMIN  equ     0               ; minimum extended memory needed to run (in K)
TSTAK   equ     400h            ; total stack size (in bytes)
ISTAK   equ     80h             ; hardware IRQ safe stack size (in bytes)

desc    struc
lml     dw      0
bsl     dw      0
bsm     db      0
acc     db      0
lmh     db      0
bsh     db      0
desc    ends

task    struc
back            dd      0
esp0            dd      0
sp0             dd      10h
esp1            dd      0
sp1             dd      0
esp2            dd      0
sp2             dd      0
ocr3            dd      0
oeip            dd      0
oeflags         dd      0
oeax            dd      0
oecx            dd      0
oedx            dd      0
oebx            dd      0
oesp            dd      0
oebp            dd      0
oesi            dd      0
oedi            dd      0
oes             dd      0
ocs             dd      0
oss             dd      0
ods             dd      0
ofs             dd      0
ogs             dd      0
oldtr           dd      0
iomap           dd      104 shl 16
task    ends

code16  segment para stack use16 'stack'
code16  ends
code32  segment para public use32
code32  ends
codeend segment para public use32
codeend ends


code16  segment para stack use16 'stack'
        assume cs:code16, ds:code16, ss:code16
        org 0

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16 bit basic system data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
stak16  db      100h dup(?)
stak16e label   near
oldint1b        dd      ?
nullint         db      0cfh
errmsg0         db      'You must have a 386 or better to run this program!!!',7,'$'
errmsg1         db      'This system is already in V86 mode!!!',7,'$'
errmsg2         db      'You must have 640k low memory to run this program!!!',7,'$'
errmsg3         db      'Not enough extended memory to run this program!!!',7,'$'
errmsg4         db      'You must have VGA to run this program!!!',7,'$'
errmsg5         db      'Not enough low memory to run this program!!!',7,'$'
defidt          dw      3ffh, 0,0

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16 bit basic system code
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
chek_VGA:                               ; Detect VGA or MCGA card
        xor bx,bx
        mov ax,01a00h
        int 10h
        cmp bl,7
        jb short detectvgano
        cmp bl,0ch
        ja short detectvgano
        ret
detectvgano:
        mov dx,offset errmsg4
        jmp exit16err
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
chek_processor:                         ; Detect if current processor 386
        pushf
        xor ah,ah
        push ax
        popf
        pushf
        pop ax
        and ah,0f0h
        cmp ah,0f0h
        je short detectno386
        mov ah,0f0h
        push ax
        popf
        pushf
        pop ax
        and ah,0f0h
        jz short detectno386
        popf
        ret
detectno386:
        mov dx,offset errmsg0
        jmp short exit16err
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
chek_virtual:                           ; Chek if already running in V86 mode
        smsw ax
        test al,1
        jnz short detected_virtual86
        ret
detected_virtual86:
        mov dx,offset errmsg1
        jmp short exit16err
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
chek_memory:                            ; Chek and get info on memory
        int 12h
        cmp ax,638
        jb short notenoughlowmem
        movzx eax,ax
        shl eax,10
        sub eax,ds:_code32a
        mov ds:_lomemtop,eax
        sub eax,ds:_lomembase
        shr eax,10
        cmp eax,LOWMIN
        jb short notenoughlowmem2
        mov ah,88h
        int 15h
        cmp ax,EXTMIN
        jb short notenoughhighmem
        mov ds:_totalextmem,ax
        movzx eax,ax
        shl eax,10
        add eax,ds:_himembase
        mov ds:_himemtop,eax
        ret
notenoughlowmem:
        mov dx,offset errmsg2
        jmp short exit16err
notenoughlowmem2:
        mov dx,offset errmsg5
        jmp short exit16err
notenoughhighmem:
        mov dx,offset errmsg3
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
exit16err:                              ; Exit program with message
        mov ah,9
        int 21h
        mov ax,4cffh
        int 21h
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
start16:                                ; Program begins here
        cli
        mov sp,offset stak16e
        mov ax,cs
        mov ds,ax
        call chek_VGA
        call chek_processor
        call chek_virtual

        mov eax,code16                  ; Calc misc memory pointers
        shl eax,4
        mov ds:_code16a,eax
        mov eax,code32
        shl eax,4
        mov ds:_code32a,eax
        mov ebx,codeend
        shl ebx,4
        sub ebx,eax
        add ds:v86task.esp0,ebx
        add ebx,TSTAK
        mov ds:_lomembase,ebx
        mov ebx,100000h
        sub ebx,eax
        mov ds:_himembase,ebx
        call chek_memory

        xor ax,ax                       ; Disable CTRL+BREAK
        mov es,ax
        mov eax,es:[1bh*4]
        mov oldint1b,eax
        mov word ptr es:[1bh*4],offset nullint
        mov word ptr es:[1bh*4+2],cs

        mov eax,ds:_code32a             ; Set up protected mode adresses
        add dword ptr ds:gdt32a[2],eax
        add dword ptr ds:idt32a[2],eax
        mov ds:code32dsc.bsl,ax
        mov ds:data32dsc.bsl,ax
        add ds:v86taskdsc.bsl,ax
        shr eax,8
        mov ds:code32dsc.bsm,ah
        mov ds:data32dsc.bsm,ah
        add ds:v86taskdsc.bsm,ah
        mov eax,ds:_code16a
        mov ds:retrealc.bsl,ax
        mov ds:retreald.bsl,ax
        shr eax,8
        mov ds:retrealc.bsm,ah
        mov ds:retreald.bsm,ah

        lgdt fword ptr ds:gdt32a        ; Init protected mode
        mov eax,cr0
        or al,1
        mov cr0,eax
        db 0eah
        dw start32,8

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
v86sys:                                 ; V86 interrupt
        xor eax,eax
        xor ebx,ebx
        xor ecx,ecx
        xor edx,edx
        xor esi,esi
        xor edi,edi
        xor ebp,ebp
        mov ax,cs:v86r_ax
        mov bx,cs:v86r_bx
        mov cx,cs:v86r_cx
        mov dx,cs:v86r_dx
        mov si,cs:v86r_si
        mov di,cs:v86r_di
        mov bp,cs:v86r_bp
        db 0cdh
v86sysintnum    db      ?
        mov cs:v86r_ax,ax
        mov cs:v86r_bx,bx
        mov cs:v86r_cx,cx
        mov cs:v86r_dx,dx
        mov cs:v86r_si,si
        mov cs:v86r_di,di
        mov cs:v86r_bp,bp
        mov cs:v86r_ds,ds
        mov cs:v86r_es,es
        pushf
        pop ax
        mov cs:v86r_flags,ax
        int 0fdh

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
prerealmode:                            ; 16 bit protected mode to real mode
        lidt fword ptr defidt
        mov eax,cr0
        and al,0feh
        mov cr0,eax
        db 0eah
        dw realmode,code16
realmode:                               ; Back in real mode
        xor ax,ax                       ; Reenable CTRL+BREAK
        mov es,ax
        mov eax,cs:oldint1b
        mov es:[1bh*4],eax
        mov ax,cs                       ; Fix up regs and quit to DOS
        mov ds,ax
        mov es,ax
        mov ss,ax
        xor eax,eax
        mov fs,ax
        mov gs,ax
        xor ebx,ebx
        xor ecx,ecx
        xor edx,edx
        xor esi,esi
        xor edi,edi
        xor ebp,ebp
        mov esp,offset stak16e+200h
        mov ax,4c00h
        int 21h

        dw      ?,?,?
code16  ends


code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32
        org 0

extrn   _main:near

public  v86r_ax, v86r_bx, v86r_cx, v86r_dx, v86r_si, v86r_di, v86r_bp
public  v86r_ds, v86r_es, v86r_flags, v86r_ah, v86r_al, v86r_bh, v86r_bl
public  v86r_ch, v86r_cl, v86r_dh, v86r_dl
public  _totalextmem, _code16a, _code32a, _hextbl, _lomembase, _lomemtop
public  _himembase, _himemtop

public  _putdosmsg, _getvect, _setvect, _exit, _getmem, _getlomem, _gethimem
public  _lomemsize, _himemsize, _ret

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 32 bit basic system data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
gdt32           desc    <>
code32dsc       desc    <0ffffh, 0, 0, 10011010b, 11001111b, 0>
data32dsc       desc    <0ffffh, 0, 0, 10010010b, 11001111b, 0>
zerodsc         desc    <0ffffh, 0, 0, 10010010b, 11001111b, 0>
v86taskdsc      desc    <0ffffh, v86task, 0, 10001001b, 0, 0>
retrealc        desc    <0ffffh, 0, 0, 10011010b, 0, 0>
retreald        desc    <0ffffh, 0, 0, 10010010b, 0, 0>
idt32           dw      exc0, 8, 08e00h, 0
                dw      exc1, 8, 08e00h, 0
                dw      exc2, 8, 08e00h, 0
                dw      exc3, 8, 08e00h, 0
                dw      exc4, 8, 08e00h, 0
                dw      exc5, 8, 08e00h, 0
                dw      exc6, 8, 08e00h, 0
                dw      exc7, 8, 08e00h, 0
                dw      exc8, 8, 08e00h, 0
                dw      exc9, 8, 08e00h, 0
                dw      exca, 8, 08e00h, 0
                dw      excb, 8, 08e00h, 0
                dw      excc, 8, 08e00h, 0
                dw      v86gen, 8, 08e00h, 0
                dw      exce, 8, 08e00h, 0
                dw      17 dup(unexp, 8, 08e00h, 0)
                dw      irq0, 8, 08e00h, 0
                dw      irq1, 8, 08e00h, 0
                dw      irq2, 8, 08e00h, 0
                dw      irq3, 8, 08e00h, 0
                dw      irq4, 8, 08e00h, 0
                dw      irq5, 8, 08e00h, 0
                dw      irq6, 8, 08e00h, 0
                dw      irq7, 8, 08e00h, 0
                dw      irq8, 8, 08e00h, 0
                dw      irq9, 8, 08e00h, 0
                dw      irqa, 8, 08e00h, 0
                dw      irqb, 8, 08e00h, 0
                dw      irqc, 8, 08e00h, 0
                dw      irqd, 8, 08e00h, 0
                dw      irqe, 8, 08e00h, 0
                dw      irqf, 8, 08e00h, 0
                dw      callv86sys, 8, 8e00h, 0
gdt32a          dw      037h, gdt32,0
idt32a          dw      187h, idt32,0
v86task         task    <>
                db      2000h dup(0)

v86irqnum       db      ?               ; num of IRQ that ocurred in V86 mode
v86r_ax         label   word            ; Virtual regs for virtual ints
v86r_al         db      ?
v86r_ah         db      ?
v86r_bx         label   word
v86r_bl         db      ?
v86r_bh         db      ?
v86r_cx         label   word
v86r_cl         db      ?
v86r_ch         db      ?
v86r_dx         label   word
v86r_dl         db      ?
v86r_dh         db      ?
v86r_si         dw      ?
v86r_di         dw      ?
v86r_bp         dw      ?
v86r_ds         dw      ?
v86r_es         dw      ?
v86r_flags      dw      ?

oirqm21         db      ?               ; old low IRQ mask
oirqma1         db      ?               ; old high IRQ mask
_totalextmem    dw      ?               ; total extended memory present
_code16a        dd      ?               ; offset of start of program from 0
_code32a        dd      ?               ; offset of start of 32bit code from 0
_lomembase      dd      ?               ; low mem base for allocation
_lomemtop       dd      ?               ; top of low mem
_himembase      dd      ?               ; high mem base for allocation
_himemtop       dd      ?               ; top of high mem
_hextbl         db      '0123456789ABCDEF'

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 32 bit basic system code
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
callv86sys:                             ; V86 INT AL
        pushad
        push es
        push fs
        push gs
        mov bx,18h
        mov es,bx
        mov ebx,_code16a
        mov es:v86sysintnum[ebx],al
        push v86task.esp0
        mov ecx,esp
        sub esp,ISTAK
        mov v86task.esp0,esp
        xor eax,eax
        push eax
        push eax
        mov ax,v86r_ds
        push eax
        mov ax,v86r_es
        push eax
        mov eax,codeend
        push eax
        shl eax,4
        sub eax,_code32a
        sub ecx,eax
        push ecx
        pushfd
        pop eax
        or eax,20000h
        push eax
        mov eax,code16
        push eax
        mov eax,offset v86sys
        push eax
        iretd
retfromv86:
        mov ax,10h
        mov ds,ax
        mov esp,v86task.esp0
        add esp,ISTAK
        pop v86task.esp0
        pop gs
        pop fs
        pop es
        popad
        iretd
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
v86gen:                                 ; General protection violation handler
        test byte ptr [esp+14],2
        jnz short v86genv86
        pushad
        mov dl,13
        jmp exc
v86genv86:
        add esp,4
        pushad
        mov ax,18h
        mov ds,ax
        movzx ebx,word ptr [esp+36]
        shl ebx,4
        add ebx,[esp+32]
        inc word ptr [esp+32]
        mov al,[ebx]
        mov dl,3
        cmp al,0cch
        je short v86int
        cmp al,0ceh
        ja exc
        je short v86genv86ni
        inc word ptr [esp+32]
        mov dl,[ebx+1]
        cmp dl,0fdh
        jne short v86int
        jmp retfromv86
v86genv86ni:
        mov dl,4
v86int:                                 ; Do interrupt for V86 task
        mov ax,18h
        mov ds,ax
        movzx ebx,dl
        shl ebx,2
        movzx edx,word ptr [esp+48]
        shl edx,4
        sub word ptr [esp+44],6
        add edx,[esp+44]
        mov ax,[esp+40]
        mov [edx+4],ax
        mov ax,[esp+36]
        mov [edx+2],ax
        mov ax,[esp+32]
        mov [edx],ax
        and word ptr [esp+40],0fcffh
        mov eax,ds:[ebx]
        mov [esp+32],ax
        shr eax,16
        mov [esp+36],ax
        popad
        iretd

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
exc0:                                   ; Exceptions
	push ax
	mov al,0
	jmp irq
exc1:
	push ax
	mov al,1
        jmp irq
exc2:
	push ax
	mov al,2
        jmp irq
exc3:
	push ax
	mov al,3
        jmp irq
exc4:
	push ax
	mov al,4
        jmp irq
exc5:
	push ax
	mov al,5
        jmp irq
exc6:
        pushad
        mov dl,6
        jmp short exc
exc7:
	push ax
	mov al,7
        jmp irq
exc8:
        pushad
        mov dl,8
        jmp short exc
exc9:
        pushad
        mov dl,9
        jmp short exc
exca:
        pushad
        mov dl,10
        jmp short exc
excb:
        pushad
        mov dl,11
        jmp short exc
excc:
        pushad
        mov dl,12
        jmp short exc
exce:
        pushad
        mov dl,14
        jmp short exc
unexp:                                  ; Unexpected interrupt
        pushad
        mov dl,0ffh
exc:
        cld                             ; Dump data
        mov ax,10h
        mov ds,ax
        mov es,ax
        mov fs,ax
        mov ax,18h
        mov gs,ax
        mov al,0ffh
        out 21h,al
        out 0a1h,al
        mov al,10h
        mov v86r_ax,3
        int 30h
        mov edi,0b8000h+2*160
        sub edi,_code32a
        mov ebx,offset _hextbl
        mov ecx,2
        shl edx,24
        mov ah,0fh
        call excput
        add edi,152
        mov ah,0ah
        mov ebp,8
excl0:
        pop edx
        mov cl,8
        call excput
        dec ebp
        jnz excl0
        mov ebp,codeend
        shl ebp,4
        sub ebp,_code32a
        add ebp,TSTAK
excf0:
        mov ah,0ch
excl1:
        pop edx
        mov cl,8
        call excput
        cmp esp,ebp
        jbe excf0
        jmp _exit
excput:
        rol edx,4
        mov al,dl
        and al,0fh
        xlat
        stosw
        loop excput
        mov al,' '
        stosw
        stosw
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
irq0:                                   ; Do IRQs
        push ax
        mov al,8
        jmp short irq
irq1:
        push ax
        mov al,9
        jmp short irq
irq2:
        push ax
        mov al,0ah
        jmp short irq
irq3:
        push ax
        mov al,0bh
        jmp short irq
irq4:
        push ax
        mov al,0ch
        jmp short irq
irq5:
        push ax
        mov al,0dh
        jmp short irq
irq6:
        push ax
        mov al,0eh
        jmp short irq
irq7:
        push ax
        mov al,0fh
        jmp short irq
irq8:
        push ax
        mov al,70h
        jmp short irq
irq9:
        push ax
        mov al,71h
        jmp short irq
irqa:
        push ax
        mov al,72h
        jmp short irq
irqb:
        push ax
        mov al,73h
        jmp short irq
irqc:
        push ax
        mov al,74h
        jmp short irq
irqd:
        push ax
        mov al,75h
        jmp short irq
irqe:
        push ax
        mov al,76h
        jmp short irq
irqf:
        push ax
        mov al,77h
irq:
        test byte ptr [esp+12],2
        jnz short v86irq
        push ds                         ; A real mode IRQ in protected mode
        push ss
        pop ds
        int 30h
        pop ds
        pop ax
        iretd
v86irq:                                 ; An IRQ from V86 mode
        mov ss:v86irqnum,al
        pop ax
        pushad
        mov dl,ss:v86irqnum
        jmp v86int

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
set8529vektorz:                         ; Set new IRQ vektor numbers
        mov al,11h                      ;  BL - low vektor base #
        out 20h,al                      ;  BH - high vektor base #
        jmp short $+2
        mov al,bl
        out 21h,al
        jmp short $+2
        mov al,4h
        out 21h,al
        jmp short $+2
        mov al,1h
        out 21h,al
        jmp short $+2
        mov al,11h
        out 0a0h,al
        jmp short $+2
        mov al,bh
        out 0a1h,al
        jmp short $+2
        mov al,2h
        out 0a1h,al
        jmp short $+2
        mov al,1h
        out 0a1h,al
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
enableA20:                              ; Enable gate A20
        call enableA20o1
        jnz short enableA20done
        mov al,0d1h
        out 64h,al
        call enableA20o1
        jnz short enableA20done
        mov al,0dfh
        out 60h,al
enableA20o1:
        mov ecx,20000h
enableA20o1l:
        jmp short $+2
        in al,64h
        test al,2
        loopnz enableA20o1l
enableA20done:
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
start32:                                ; 32bit code begins here
        lidt fword ptr cs:idt32a
        mov ax,10h
        mov ds,ax
        mov es,ax
        mov fs,ax
        mov ss,ax
        mov ax,18h
        mov gs,ax
        mov esp,_lomembase
        mov ax,20h
        ltr ax
        pushfd
        pop eax
        or ah,30h
        and ah,not 40h
        push eax
        popfd
        in al,21h
        mov oirqm21,al
        or al,3
        out 21h,al
        in al,0a1h
        mov oirqma1,al
        mov bx,2820h
        call set8529vektorz
        call enableA20
        sti
        jmp _main

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; Some 'system' services
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Exit to real mode
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_exit:
        cli
        mov bx,7008h
        call set8529vektorz
        mov al,oirqm21
        out 21h,al
        mov al,oirqma1
        out 0a1h,al
        mov ax,30h
        mov ds,ax
        mov es,ax
        mov fs,ax
        mov gs,ax
        mov ss,ax
        db 0eah
        dw prerealmode,0,28h

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Get interrupt vektor (0-30h)
; In:
;   BL - interrupt number
; Out:
;   EAX - 32 bit offset in code
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_getvect:
        push ebx
        movzx ebx,bl
        mov ax,idt32[ebx*8+6]
        shl eax,16
        mov ax,idt32[ebx*8]
        pop ebx
_ret:                                   ; Generic RET for all procedures
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Set interrupt vektor (0-30h)
; In:
;   BL - interrupt number
;   EAX - 32 bit offset in code
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_setvect:
        pushf
        cli
        push eax
        push ebx
        movzx ebx,bl
        mov idt32[ebx*8],ax
        shr eax,16
        mov idt32[ebx*8+6],ax
        pop ebx
        pop eax
        popf
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Allocate any mem, (first cheks low, then high)
; In:
;   EAX - size requested
; Out:
;   CF=1  - not enough mem
;     EAX - ?
;   CF=0  - memory allocated
;     EAX - linear pointer to mem
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_getmem:
        push eax
        call _getlomem
        jnc short getmemd
        pop eax
        jmp short _gethimem
getmemd:
        add esp,4
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Allocate some low mem
; In:
;   EAX - size requested
; Out:
;   CF=1  - not enough mem
;     EAX - ?
;   CF=0  - memory allocated
;     EAX - linear pointer to mem
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_getlomem:
        add eax,_lomembase
        cmp eax,_lomemtop
        ja short getmemerr
        xchg eax,_lomembase
        clc
        ret
getmemerr:
        stc
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Allocate some high mem
; In:
;   EAX - size requested
; Out:
;   CF=1  - not enough mem
;     EAX - ?
;   CF=0  - memory allocated
;     EAX - linear pointer to mem
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_gethimem:
        add eax,_himembase
        cmp eax,_himemtop
        ja short getmemerr
        xchg eax,_himembase
        clc
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Get amount of free low mem
; Out:
;   EAX - number of bytes free
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_lomemsize:
        mov eax,_lomemtop
        sub eax,_lomembase
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Get amount of free high mem
; Out:
;   EAX - number of bytes free
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_himemsize:
        mov eax,_himemtop
        sub eax,_himembase
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Put '$' terminated message to DOS
; In:
;   EDX -> message in low mem
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_putdosmsg:
        push ax
        push edx
        add edx,_code32a
        mov al,dl
        and ax,0fh
        shr edx,4
        mov v86r_ds,dx
        mov v86r_dx,ax
        mov v86r_ah,9
        mov al,21h
        int 30h
        pop edx
        pop ax
        ret

code32  ends


codeend segment para public use32
        assume cs:codeend
stak32  label   near
codeend ends
        end     start16

