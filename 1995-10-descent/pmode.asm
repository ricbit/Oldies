; PMODE v2.4 raw, DPMI, VCPI, & XMS compliant protected mode header.
; By Tran (a.k.a. Thomas Pytel).

        .386p

LOWMIN          = 64            ; minimum free low memory (in K)
EXTMIN          = 0             ; minimum free extended memory (in K)
SELECTORS       = 8             ; extra selectors for allocation
STAKMAIN        = 100h          ; main execution stream stack size (in para)
STAKRMODE       = 10h           ; real mode call stack size (in para)
STAKPMODE       = 20h           ; protected mode call stack size (in para)
MODENESTING     = 8             ; max number of nested mode switches

RMODENUM        = (MODENESTING+1) shr 1
PMODENUM        = MODENESTING shr 1
STAKSIZE        = STAKMAIN+(PMODENUM*STAKPMODE)+(RMODENUM*STAKRMODE)

.errnz STAKSIZE gt 0fffh        ; error if stack greater than 64k

code16  segment para public use16
code16  ends
code32  segment para public use32
code32  ends
codeend segment para stack use32 'stack'
codeend ends

;²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²
; Real mode and 16bit code
;²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²
code16  segment para public use16
        assume cs:code16, ds:code16
        org 0

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16 bit common system data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
errmsg0         db      '386 or better not detected!!!',7,'$'
errmsg1         db      'Not enough low memory!!!',7,'$'
errmsg2         db      'System is already in V86 mode, and no VCPI or DPMI found!!!',7,'$'
errmsg3         db      'Not enough extended memory!!!',7,'$'
errmsg4         db      'Couldn''t enable A20 gate!!!',7,'$'
errmsg5         db      'Extended memory allocation failure. (weird eh???)',7,'$'

nullint         db      0cfh            ; IRET instruction
exitrout        dw      exit            ; exit routine, modified if XMS, VCPI

savedstakoff    dw      ?               ; current saved stack offset
savedstakseg    dw      ?               ; current saved stack segment

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16 bit common system code
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
intreal:                                ; real mode int, load FS and GS here
        pushf
;-----------------------------------------------------------------------------
callreal:                               ; real mode call, load FS and GS here
        push cs
        push offset icreald
        mov fs,cs:v86r_fs
        mov gs,cs:v86r_gs
        mov eax,cs:v86r_eax
        mov ecx,cs:v86r_ecx
        mov edx,cs:v86r_edx
        mov ebx,cs:v86r_ebx
        mov esi,cs:v86r_esi
        mov edi,cs:v86r_edi
        mov ebp,cs:v86r_ebp
;-----------------------------------------------------------------------------
icreal:                                 ; real mode int, call, or IRQ
        db 66h,68h              ; PUSH destination addx
icrealm1        dd      ?       ;
icrealm0        db      ?       ; CLI or STI
        retf
;-----------------------------------------------------------------------------
icreald:                                ; done with real int or call
        cli
        pushf
        pop cs:v86r_flags
        mov cs:v86r_eax,eax
        mov cs:v86r_ecx,ecx
        mov cs:v86r_edx,edx
        mov cs:v86r_ebx,ebx
        mov cs:v86r_esi,esi
        mov cs:v86r_edi,edi
        mov cs:v86r_ebp,ebp
        mov cs:v86r_ds,ds
        mov cs:v86r_es,es
        mov cs:v86r_fs,fs
        mov cs:v86r_gs,gs
icreald2:
        mov ax,cs
        mov ds,ax
icrealm2        label word              ; return to pmode modifiable to JMP
;-----------------------------------------------------------------------------
        mov ebx,ds:cp_savedstakoff      ; DPMI return to pmode
        mov dx,ds:dp_savedstaksel
        mov edi,offset dp_int3_d
        mov si,ds:_selcode
        mov cx,dx
        mov ax,ds:_seldata
        jmp ds:d_switchaddx
;-----------------------------------------------------------------------------
VICREAL1D=(($-(icrealm2+2))shl 8)+0ebh
v_icreal1d:                             ; VCPI return to pmode from safe
        mov edi,offset cp_int3_d
;-----------------------------------------------------------------------------
; EDI=offset to jump to in code32
v_switchtopmode:                        ; VCPI switch to pmode
        mov ds:v_ss_dest,edi
        mov esi,offset v_ss_cr3
        add esi,ds:_code16a
        mov ax,0de0ch
        int 67h
;-----------------------------------------------------------------------------
CICREAL1D=(($-(icrealm2+2))shl 8)+0ebh
c_icreal1d:                             ; custom return to pmode from safe
	mov edi,offset cp_int3_d
;-----------------------------------------------------------------------------
; EDI=offset in pmode to jump to
c_retpmode:                             ; reenter 32bit pmode
        lgdt fword ptr c_gdt32addx      ; set up pmode GDT and IDT
	lidt fword ptr c_idt32addx
	mov ds:gdt32task[5],89h 	; set task as not busy
        mov eax,cr0                     ; switch to pmode
        or al,1
        mov cr0,eax
        db 0eah
        dw $+4,20h
        mov ax,30h                      ; load task register
        ltr ax
	jmp c_gotopmode
;-----------------------------------------------------------------------------
if ($-(icrealm2+2)) gt 127
  err
endif
CICREAL0D=(($-(icrealm2+2))shl 8)+0ebh
c_icreal0d:                             ; return to pmode from normal
        int 0ffh
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
int32:                                  ; real mode INT32: EDX=off
        pushad
        push ds es fs gs
        cli
        mov ax,cs
        mov ds,ax
        mov ds:p_cpmodem0,edx
        mov al,[esp+45]
        shr al,1
        and al,1
        add al,0fah
        mov ds:p_cpmodem1,al
        push savedstakoff
        push savedstakseg
        movzx ebx,ds:nextmodestack
        lea eax,[ebx-STAKPMODE*16]
        mov ds:nextmodestack,ax
        add ebx,ds:realstackbase
        mov savedstakseg,ss
int32m0         label   word            ; jump to pmode, modifiable
;-----------------------------------------------------------------------------
        sub sp,ds:dp_savelen
        mov savedstakoff,sp
        mov ax,ss                       ; DPMI jump to pmode
        mov es,ax
        mov di,sp
        xor al,al
        call d_saveaddx
        mov ax,ds:_seldata
        mov cx,ax
        mov dx,ax
        mov edi,offset p_cpmode
        mov si,ds:_selcode
        jmp ds:d_switchaddx
;-----------------------------------------------------------------------------
VINT32=(($-(int32m0+2))shl 8)+0ebh
v_int32:                                ; VCPI call pmode
        push ds:p_cpmodem2
        mov ds:p_cpmodem2,VCPMODED
        mov savedstakoff,sp
        mov edi,offset p_cpmode1
        jmp v_switchtopmode
;-----------------------------------------------------------------------------
if ($-(int32m0+2)) gt 127
  err
endif
CINT32=(($-(int32m0+2))shl 8)+0ebh
c_int32:                                ; raw/XMS call pmode
        push ds:p_cpmodem2
        mov ds:p_cpmodem2,CCPMODED
        mov savedstakoff,sp
        mov edi,offset p_cpmode1
        jmp c_retpmode
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
int32d0:                                ; DPMI done with pmode call
        mov di,sp
        mov al,1
        call d_saveaddx
        add sp,ds:dp_savelen
;-----------------------------------------------------------------------------
int32d2:                                ; done from all
        pop savedstakseg
        pop savedstakoff
        add ds:nextmodestack,STAKPMODE*16
        mov bx,ds:v86r_flags
        mov ax,[esp+44]
        and ax,not 8d5h
        and bx,8d5h
        or ax,bx
        mov [esp+44],ax
        pop gs fs es ds
        popad
        iret
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
int32d1:                                ; VCPI done with pmode call
        mov ss,savedstakseg
        pop ds:p_cpmodem2
        jmp int32d2
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
int32d3:                                ; raw/XMS done with pmode call
        mov c_retreal0m0,offset c_sicreal
        mov ax,cs
        mov ds,ax
        movzx esp,savedstakoff
        mov ss,savedstakseg
        pop ds:p_cpmodem2
        jmp int32d2
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
chek_VCPI:                              ; Chek for VCPI
        xor ax,ax
        mov gs,ax
        mov ax,gs:[67h*4]
        or ax,gs:[(67h*4)+2]
        jz short chekVCPIa
        mov ax,0de00h
        int 67h
        or ah,ah
        clc
        jz short chekVCPId
chekVCPIa:
        stc
chekVCPId:
        ret
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
chek_V86:                               ; Chek if already in V86 mode
        smsw ax
        test al,1
        mov dx,offset errmsg2
        jnz short exit16err
        ret
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
pregetlomem:                            ; Get low memory or abort
        add eax,ds:_lomembase
        mov ebx,ds:_lomemtop
        cmp eax,ebx
        ja short pregetlomema
        mov ecx,eax
        xchg eax,ds:_lomembase
        sub ebx,ecx
        cmp ebx,LOWMIN*1024
        jb short pregetlomema
        ret
pregetlomema:
        mov dx,offset errmsg1
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
exit16err:                              ; Exit program with message
        mov ah,9
        int 21h
        jmp exitrout
;-----------------------------------------------------------------------------
exit:                                   ; Guess what???
        mov ah,4ch
        mov al,ds:_exitcode
        int 21h
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
start16:                                ; Program begins here
        cli
        cld
        push cs
        pop ds

        call chek_processor             ; is it at least a 386¨

        mov ax,es                       ; set up a bunch of pointers
        movzx eax,ax
        shl eax,4
        mov ds:_pspa,eax
        mov eax,code16
        shl eax,4
        mov ds:_code16a,eax
        or dword ptr ds:gdt32code16[2],eax
        or dword ptr ds:gdt32data16[2],eax
        mov ebx,code32
        shl ebx,4
        mov ds:_code32a,ebx
        or dword ptr ds:gdt32code32[2],ebx
        or dword ptr ds:gdt32data32[2],ebx
        add dword ptr ds:c_gdt32addx[2],ebx
        mov eax,codeend
        shl eax,4
        sub eax,ebx
        mov ds:_lomembase,eax
        mov ds:realstackbase,eax
        movzx eax,word ptr es:[2]
        shl eax,4
        sub eax,ebx
        mov ds:_lomemtop,eax

        mov eax,STAKSIZE*16             ; get stack memory
        call pregetlomem

        push es                         ; save PSP seg (DPMI chek kills ES)
        pop fs

        mov ax,1687h                    ; chek for DPMI
        int 2fh
        or ax,ax
        jz d_start

        call chek_VCPI                  ; chek for VCPI
        jnc v_start

        call chek_V86                   ; chek for V86 mode

        mov ax,4300h                    ; chek for XMS
        int 2fh
        cmp al,80h
        je x_start

        jmp c_start                     ; custom system start
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
enableA20:                              ; hardware enable gate A20
        xor ax,ax
        mov fs,ax
        dec ax
        mov gs,ax
        call testA20
        je short enableA20done
        in al,92h                       ; PS/2 A20 enable
        or al,2
        jmp short $+2
        jmp short $+2
        jmp short $+2
        out 92h,al
        call testA20
        je short enableA20done
        call enableA20o1                ; AT A20 enable
        jnz short enableA20wait
        mov al,0d1h
        out 64h,al
        call enableA20o1
        jnz short enableA20wait
        mov al,0dfh
        out 60h,al
        push offset enableA20wait
enableA20o1:
        mov ecx,20000h
enableA20o1l:
        jmp short $+2
        jmp short $+2
        jmp short $+2
        in al,64h
        test al,2
        loopnz enableA20o1l
enableA20done:
        ret
;-----------------------------------------------------------------------------
enableA20wait:                          ; wait for A20
        mov al,36h
        out 43h,al
        xor al,al
        out 40h,al
        out 40h,al
        mov cx,800h
enableA20waitl0:
        call testA20
        je enableA20done
        in al,40h
        in al,40h
        mov ah,al
enableA20waitl1:
        in al,40h
        in al,40h
        cmp al,ah
        je enableA20waitl1
        loop enableA20waitl0
        mov dx,offset errmsg4
        jmp exit16err
;-----------------------------------------------------------------------------
testA20:                                ; Test for enabled A20
        mov al,fs:[0]
        mov ah,al
        not al
        mov gs:[10h],al
        cmp ah,fs:[0]
        mov fs:[0],ah
        ret
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; BL=low PIC val, BH=high PIC val
setintslots:                            ; set int nums in table to PIC vals
        mov edi,offset ds:intslottbl
        mov cl,8
setintslotsl0:
        mov [di],bl
        inc di
        inc bl
        dec cl
        jnz setintslotsl0
        mov cl,8
setintslotsl1:
        mov [di],bh
        inc di
        inc bh
        dec cl
        jnz setintslotsl1
        ret

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16 bit DPMI system data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
d_errmsg0       db      'DPMI host is not 32bit!!!',7,'$'
d_errmsg1       db      'Ran out of DPMI descriptors!!!',7,'$'
d_errmsg2       db      'Couldn''t set DPMI descriptors as needed!!!',7,'$'
d_errmsg3       db      'Couldn''t enter 32bit protected mode!!!',7,'$'

d_enterpmode    dw      ?,?             ; DPMI switch to pmode addx
d_pspsel        dw      ?               ; stupid PSP selector
d_oldenvsegsel  dw      ?               ; stupid selector we dont want

d_switchaddx    dd      ?               ; switch to pmode addx
d_saveaddx      dd      ?               ; save/restore state addx

d_nintoff       dd      offset dp_irq0,offset dp_irq1,offset dp_irq2,offset dp_irq3
                dd      offset dp_irq4,offset dp_irq5,offset dp_irq6,offset dp_irq7
                dd      offset dp_irq8,offset dp_irq9,offset dp_irqa,offset dp_irqb
                dd      offset dp_irqc,offset dp_irqd,offset dp_irqe,offset dp_irqf
                dd      offset dp_int33,offset dp_int32,offset dp_int33,offset dp_int32
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16 bit DPMI system code
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
d_retreal:                              ; Return to real mode
        mov ax,205h                     ; restore all int vektorz needed
        mov edi,19
d_retreall0:
        mov bl,ds:intslottbl[edi]
        lea ebp,[edi*2+edi]
        mov edx,dword ptr ds:dp_ointbuf[ebp*2]
        mov cx,word ptr ds:dp_ointbuf[ebp*2+4]
        int 31h
        sub di,1
        jnc d_retreall0
        jmp short d_exit
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
d_exit16err:                            ; DPMI Exit with error message
        mov ds:v86r_ds,code16
        mov ds:v86r_ah,9
        mov ax,300h
        mov bx,21h
        xor cx,cx
        mov edi,offset ds:v86r_edi
        push ds
        pop es
        int 31h
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
d_exit:                                 ; DPMI exit to real mode
        mov es,d_pspsel                 ; restore env selector
        mov ax,d_oldenvsegsel
        mov es:[2ch],ax
        jmp exit
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
d_start:                                ; Start in a crappy DPMI system
        or ds:_sysbyte0,3               ; set system type DPMI byte

        test bl,1                       ; must be 32bit DPMI
        mov dx,offset d_errmsg0
        jz exit16err

        mov d_enterpmode[0],di          ; store enter addx
        mov d_enterpmode[2],es
        push word ptr fs:[2ch]          ; preserve old env seg

        movzx eax,si                    ; get mem for DPMI blok
        shl eax,4
        call pregetlomem
        shr eax,4
        add ax,code32
        mov es,ax

        mov ax,1                        ; switch to pmode
        call dword ptr d_enterpmode
        cli                             ; I don't trust DPMI
        mov dx,offset d_errmsg3
        jc exit16err
        mov ds:v86r_dx,offset d_errmsg1 ; prepare for abort maybe
        pop ax                          ; swap old env seg with selector
        xchg ax,es:[2ch]
        mov d_oldenvsegsel,ax
        mov d_pspsel,es                 ; store stupid selectors
        mov ds:data16sel,ds
        mov ds:code16sel,cs
        mov ds:code16off,offset d_retreal       ; set return to real mode addx
        mov ds:_setirqvect,offset dp_setirqvect ; modify some crap
        mov ds:_getirqvect,offset dp_getirqvect
        mov ds:_setselector,offset dp_setselector

        push ds                         ; no more need for PSP
        pop es
        mov ax,3                        ; get selector increment value
        int 31h
        mov bx,ax
        xor ax,ax                       ; get needed selectors
        mov cx,3+SELECTORS
        int 31h
        jc d_exit16err

        mov si,ax                       ; set up descriptors
        mov ds:_selcode,ax
        lea ecx,[eax+ebx]
        mov ds:_seldata,cx
        lea ebp,[ecx+ebx]
        mov ds:_selzero,bp
        lea eax,[ebp+ebx]
if SELECTORS ne 0
        mov ds:selectorbase,ax
        mov ds:selectorinc,bx
endif
        mov ds:v86r_dx,offset d_errmsg2
        mov ax,0ch                      ; set descriptors from GDT
        mov bx,si
        mov edi,offset ds:gdt32code32
        or byte ptr [edi+5],60h
        int 31h
        jc d_exit16err
        mov bx,cx
        mov edi,offset ds:gdt32data32
        or byte ptr [edi+5],60h
        int 31h
        jc d_exit16err
        mov bx,bp
        mov edi,offset ds:gdt32zero32
        or byte ptr [edi+5],60h
        int 31h
        jc d_exit16err
if SELECTORS ne 0
        mov bx,ds:selectorbase          ; set up extra allocatable selectors
        mov dx,SELECTORS
d_startl1:
        int 31h
        jc d_exit16err
        add bx,ds:selectorinc
        dec dx
        jnz d_startl1
endif
        mov es,cx                       ; ES, FS, and GS what they should be
        mov fs,cx
        mov gs,bp

        mov edi,ds:_lomembase           ; chek and get extended memory
        mov eax,ds:_lomemtop
        sub eax,edi
        cmp eax,48
        mov ds:v86r_dx,offset errmsg1
        jb d_exit16err
        mov ax,500h
        int 31h
        mov eax,es:[edi+14h]
        cmp eax,-1
        jne short d_startf0
        mov eax,(EXTMIN+3) shr 2
d_startf0:
        shl eax,12
        mov edx,eax
        shr eax,10
        cmp eax,EXTMIN
        mov ds:v86r_dx,offset errmsg3
        jb d_exit16err
        or edx,edx
        jz short d_startf1
        mov cx,dx
        shld ebx,edx,16
        mov ax,501h
        int 31h
        mov ds:v86r_dx,offset errmsg5
        jc d_exit16err
        shl ebx,16
        mov bx,cx
        sub ebx,ds:_code32a
        mov ds:_himembase,ebx
        add ebx,edx
        mov ds:_himemtop,ebx
d_startf1:

        mov ax,305h                     ; get save/restore state addxs
        int 31h
        mov ds:dp_savelen,ax
        mov dword ptr ds:dp_saveaddx[0],edi
        mov word ptr ds:dp_saveaddx[4],si
        mov word ptr d_saveaddx[0],cx
        mov word ptr d_saveaddx[2],bx
        mov ax,306h                     ; get switch mode addxs
        int 31h
        mov dword ptr ds:dp_switchaddx[0],edi
        mov word ptr ds:dp_switchaddx[4],si
        mov word ptr d_switchaddx[0],cx
        mov word ptr d_switchaddx[2],bx

        mov ax,400h                     ; set IRQ handlers to PIC values
        int 31h
        xchg dl,dh
        mov bx,dx
        call setintslots

        mov ah,2                        ; backup and set all int vektorz
        mov si,ds:_selcode
        mov edi,19
d_startl0:
        mov bl,ds:intslottbl[edi]
        mov al,4
        int 31h
        lea ebp,[edi*2+edi]
        mov dword ptr ds:dp_ointbuf[ebp*2],edx
        mov word ptr ds:dp_ointbuf[ebp*2+4],cx
        mov al,5
        mov edx,d_nintoff[edi*4]
        mov cx,si
        int 31h
        sub di,1
        jnc d_startl0

        mov ax,es                       ; set up needed regs & go on to 32bit
        mov ss,ax
        add esp,ds:realstackbase
        mov ds,ax
        push dword ptr cs:_selcode
        push offset p_start
        db 66h,0cbh             ; 32bit RETF

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16bit VCPI system data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
v_errmsg0       db      'Incompatible VCPI PIC mappings!!!',7,'$'

v_pagedirseg    dw      ?               ; seg of page directory
v_pagebase      dw      0               ; first page of himem (*4)+1000h
v_pagetop       dw      0               ; top page of himem (*4)+1000h

v_ss_cr3        dd      ?               ; new CR3 for pmode (physical)
v_ss_gdtaddxptr dw      c_gdt32addx,0   ; ptr to GDT data for pmode
v_ss_idtaddxptr dw      c_idt32addx,0   ; ptr to IDT data for pmode
v_ss_ldtsel     dw      0               ; don't need no stinkin LDTs
v_ss_trsel      dw      30h             ; task state segment selector
v_ss_dest       dd      ?               ; start in pmode EIP
                dw      20h             ; start in pmode CS
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16bit VCPI system code
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
v_retreal:                              ; VCPI return to real mode
        movzx edi,exitrout
        mov esi,esp
        sub esi,ds:realstackbase
        mov cx,code16
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; EDI=offset to jump to, ESI=real mode stack ptr, CX=real mode DS
v_retreal0:                             ; VCPI go to real mode
        sub esp,8
        push ecx
        push dword ptr ds:v86r_es
        dw 06866h,codeend,0     ; PUSH dword codeend
        push esi
        pushfd
        dw 06866h,code16,0      ; PUSH dword code16
        push edi
        mov ax,gs
        mov ds,ax
        mov ax,0de0ch
        call cs:vp_vcpipmentry
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
v_exit:                                 ; VCPI exit (clean up pages)
        mov es,v_pagedirseg
        mov si,v_pagebase
        mov cx,v_pagetop
        sub cx,si
        jbe short v_exitf0
v_exitl0:
        mov edx,es:[si]
        and dx,0f000h
        mov ax,0de05h
        int 67h
        add si,4
        sub cx,4
        jnz v_exitl0
v_exitf0:
        jmp exit
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
v_exiterr1:                             ; VCPI not enough low mem exit
        mov dx,offset errmsg1
        jmp exit16err
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
v_start:                                ; start continues from VCPI
        or ds:_sysbyte0,2               ; set system type VCPI byte
        mov ds:code16off,offset v_retreal       ; VCPI return to real mode
        mov c_idt32handler[48h],offset vp_int33 ; VCPI safe int handlers
        mov c_idt32handler[4ch],offset vp_int32
        mov ds:cp_v86irqintr[4],offset vp_int33f0 ; VCPI IRQ safe int routine
        mov int32m0,VINT32              ; VCPI real INT32

        mov ax,0de0ah                   ; get PIC mappings
        int 67h
        mov bh,cl
        mov dx,offset v_errmsg0         ; chek for compatible PIC mapping
        cmp bl,bh
        je exit16err
        cmp bl,30h
        je exit16err
        cmp bh,30h
        je exit16err
        mov ax,70h                      ; compatible, get highest needed num
        cmp al,bl
        ja short v_startf1
        mov al,bl
v_startf1:
        cmp al,bh
        ja short v_startf2
        mov al,bh
v_startf2:
        add al,7
        mov c_numofintvects,al
        lea eax,[eax*8+7]               ; set limit of IDT
        mov c_idt32addx,ax
        call setintslots                ; set int slots needed
        movzx eax,ax
        add eax,2068h+1
        call pregetlomem                ; allocate TSS, IO bitmap, and IDT
        mov ds:cp_tssesp0ptr,eax
        mov eax,ds:_code16a             ; adjust mode switch structure
        add dword ptr v_ss_gdtaddxptr,eax
        add dword ptr v_ss_idtaddxptr,eax

        mov exitrout,offset v_exit      ; set VCPI cleanup exit

        mov eax,ds:_lomembase           ; align lomem base on a page
        mov ebx,ds:_code32a
        add ebx,eax
        lea ecx,[ebx+0fffh]
        and ecx,0fffff000h
        sub ebx,ecx
        sub eax,ebx
        mov ds:_lomembase,eax
        mov ebp,ds:_lomemtop            ; get available low memory
        sub ebp,eax
        sub ebp,LOWMIN*1024             ; die if not enough
        jc v_exiterr1
        cmp ebp,8192
        jb v_exiterr1

        shld eax,ecx,28                 ; get segment and clear all pages
        mov v_pagedirseg,ax
        mov es,ax
        xor di,di
        mov cx,2048
        xor eax,eax
        rep stos dword ptr es:[di]
        mov di,1000h                    ; get VCPI pmode interface
        mov esi,offset ds:gdt32vcpi
        mov ax,0de01h
        int 67h
        mov dword ptr ds:vp_vcpipmentry,ebx

        mov v_pagebase,di               ; set up and go through allocation
        mov v_pagetop,di
        movzx eax,di
        sub eax,1000h
        shl eax,10
        sub eax,ds:_code32a
        mov ds:_himembase,eax
        mov ebx,8192
v_startl2:
        mov ax,0de04h
        int 67h
        or ah,ah
        jnz short v_startl2d
        test di,0fffh
        jnz short v_startf4
        add ebx,4096
        cmp ebx,ebp
        jbe short v_startf4
        mov v_pagetop,di
        mov ax,0de05h
        int 67h
        jmp v_exiterr1
v_startf4:
        and dx,0f000h
        or dl,7
        mov es:[di],edx
        add di,4
        jnc v_startl2
v_startl2d:
        mov v_pagetop,di
        lea si,[di-1000h]
        movzx eax,si
        shl eax,10
        sub eax,ds:_code32a
        mov ds:_himemtop,eax
        sub di,v_pagebase
        cmp di,EXTMIN
        mov dx,offset errmsg3
        jb exit16err
        add ds:_lomembase,ebx

        movzx ebx,v_pagedirseg          ; set up physical addresses
        shr ebx,8
        mov eax,es:[ebx*4+1000h]
        mov v_ss_cr3,eax
        xor di,di
v_startl3:
        inc ebx
        mov eax,es:[ebx*4+1000h]
        and ax,0f000h
        or al,7
        stos dword ptr es:[di]
        sub si,1000h
        ja v_startl3

        mov edi,offset c_startf1        ; offset to jump to in pmode
        mov ebx,ds:cp_tssesp0ptr
        jmp v_switchtopmode             ; duh?

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16 bit XMS system data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
x_calladdx      dd      ?               ; XMS driver addx
x_handle        dw      0fedch          ; XMS handle of extended memory
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16 bit XMS system code
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
x_exit:                                 ; XMS exit (clean up allocation)
        mov ax,cs
        mov ds,ax
        mov dx,x_handle
        mov ah,0dh
        call x_calladdx
        mov ah,0ah
        call x_calladdx
        jmp exit
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
x_exiterr5:                             ; exit with error message 5
        mov dx,offset errmsg5
        jmp exit16err
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
x_start:                                ; start in an XMS system
        or ds:_sysbyte0,1               ; set system type XMS byte

        mov ax,4310h                    ; get XMS driver addx
        int 2fh
        mov word ptr x_calladdx[0],bx
        mov word ptr x_calladdx[2],es

        mov ah,3                        ; XMS enable A20
        call x_calladdx
        or ax,ax
        mov dx,offset errmsg4
        jz exit16err

        mov ah,8                        ; chek and get extended memory
        call x_calladdx
        sub ax,64
        jnc short x_startf0
        xor ax,ax
x_startf0:
        cmp ax,EXTMIN
        mov dx,offset errmsg3
        jb exit16err
        mov dx,ax
        movzx ecx,ax
        shl ecx,10
        mov ah,9
        call x_calladdx
        or ax,ax
        jz x_exiterr5
        mov x_handle,dx
        mov exitrout,offset x_exit
        mov ah,0ch
        call x_calladdx
        or ax,ax
        jz x_exiterr5
        shrd eax,edx,16
        mov ax,bx
        sub eax,ds:_code32a
        mov ds:_himembase,eax
        add eax,ecx
        mov ds:_himemtop,eax

        jmp c_startf0                   ; go on to custom start

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16 bit custom system data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
c_idt16addx     dw      3ffh, 0,0       ; default real mode IDT addx&limit
c_idt32addx     dw      3bfh, ?,?       ; 32bit IDT addx&limit
c_gdt32addx     dw      04fh+SELECTORS*8; 32bit GDT addx&limit
                dd      offset gdt32    ;

c_numofintvects db      77h             ; number of int vects needed -1
c_idt32handler  dd      offset cp_irq0,offset cp_irq1,offset cp_irq2,offset cp_irq3
                dd      offset cp_irq4,offset cp_irq5
                dd      offset cp_irq6,offset cp_irq7,offset cp_irq8,offset cp_irq9
                dd      offset cp_irqa,offset cp_irqb
                dd      offset cp_irqc,offset cp_irqd,offset cp_irqe,offset cp_irqf
                dd      offset cp_int35,offset cp_int34,offset cp_int33,offset cp_int32,offset cp_int31
                dd      offset cp_exc0,offset cp_exc1,offset cp_exc2,offset cp_exc3
                dd      offset cp_exc4,offset cp_exc5
                dd      offset cp_exc6,offset cp_exc7,offset cp_exc8,offset cp_exc9
                dd      offset cp_exca,offset cp_excb
                dd      offset cp_excc,offset cp_excd,offset cp_exce
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 16 bit custom system code
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
c_irqreal:                              ; real mode IRQ
        pushf
        push cs
        push offset icreald2
        jmp icreal
;-----------------------------------------------------------------------------
c_retreal1:                             ; load some real mode stuff & exit
        mov ax,codeend
        mov ss,ax
        mov esp,STAKSIZE*10h
        jmp exitrout
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
c_retreal0:                             ; load real mode IDT and set PE=0
        mov ax,28h
        mov ds,ax
        mov es,ax
        mov fs,ax
        mov gs,ax
        mov ss,ax
        lidt fword ptr c_idt16addx
        mov eax,cr0
        and al,0feh
        mov cr0,eax
        db 0eah                 ; JMP FAR PTR c_retreal0m0
c_retreal0m0    dw c_sicreal,code16
;-----------------------------------------------------------------------------
c_sicreal:                              ; safe real mode int or call
        mov ax,codeend
        mov ss,ax
        mov ds,cs:v86r_ds
        mov es,cs:v86r_es
        db 0eah                 ; JMP FAR PTR c_sicrealm0
c_sicrealm0     dw      ?,code16;
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
c_retreal:                              ; return to real mode
        mov c_retreal0m0,offset c_retreal1
        mov esp,STAKSIZE*10h
        jmp c_retreal0
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
c_start:                                ; custom only start
        call enableA20                  ; enable that stupid A20 thingy

        mov ah,88h                      ; chek and get extended mem
        int 15h
        cmp ax,EXTMIN
        mov dx,offset errmsg3
        jb exit16err
        movzx eax,ax
        shl eax,10
        mov ebx,100000h
        sub ebx,ds:_code32a
        mov ds:_himembase,ebx
        add eax,ebx
        mov ds:_himemtop,eax
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
c_startf0:                              ; start continues from custom or XMS
        mov int32m0,CINT32              ; raw/XMS real INT32
        mov eax,2428h                   ; allocate TSS, IO bitmap, and IDT
        call pregetlomem
        mov ebx,eax

        lgdt fword ptr c_gdt32addx      ; switch to pmode
        mov eax,cr0
        or al,1
        mov cr0,eax
        db 0eah
        dw $+4,20h
;-----------------------------------------------------------------------------
; EBX->TSS
c_startf1:                              ; in 16bit pmode
        mov ax,28h                      ; set up segregs
        mov ds,ax
        mov al,18h
        mov gs,ax
        mov al,10h
        mov es,ax
        mov fs,ax
        mov ss,ax
        mov esp,STAKSIZE*16
        add esp,ds:realstackbase

        mov word ptr v_ss_dest[4],8     ; VCPI enter 32bit pmode from now on
        lea eax,[ebx+4]                 ; addx of ESP0 in TSS
        mov ds:cp_tssesp0ptr,eax
        mov ebp,ds:_code32a             ; TSS location in mem to GDT
        lea eax,[ebx+ebp]
        mov ecx,offset ds:gdt32task     ; set up task
        or dword ptr ds:[ecx+2],eax
        mov byte ptr ds:[ecx+5],89h
        mov cx,30h
        ltr cx
        add eax,2068h                   ; set up IDT
        mov ecx,offset c_idt32addx
        mov dword ptr [ecx+2],eax
        lidt fword ptr [ecx]

        mov dword ptr es:[ebx+8],10h    ; set up TSS stuff (EBX->TSS)
        mov edi,104
        mov es:[ebx+102],di
        mov word ptr es:[ebx+100],0
        add edi,ebx                     ; fill IO bitmap with 0
        xor eax,eax
        mov ecx,800h
        rep stos dword ptr es:[edi]

        mov ds:cp_idt32ptr,edi          ; set up blank IDT entries
        movzx esi,c_numofintvects
c_startl0:
        mov dword ptr es:[edi+esi*8],80000h+offset cp_excf
        mov dword ptr es:[edi+esi*8+4],8e00h
        sub si,1
        jnc c_startl0
        mov si,23h                      ; necessary IDT entries
c_startl1:
        movzx ebp,ds:intslottbl[esi]
        mov eax,c_idt32handler[esi*4]
;       cmp bp,13
;       jne short c_startl1c
;       mov ds:cp_int13vect,eax
;       mov eax,offset cp_excd
c_startl1c:
        mov es:[edi+ebp*8],ax
        sub si,1
        jnc c_startl1

        mov edi,offset p_start          ; set up regs & go on to 32bit
	mov ax,10h
        mov ds,ax
;-----------------------------------------------------------------------------
c_gotopmode:				; jump to 32bit pmode
        pushfd                          ; set eflags: NT=0, IOPL=3
        pop eax
        and ah,0bfh
        or ah,30h
        push eax
        popfd
        dw 6866h,8,0            ; PUSH dword 8
	push edi
        db 66h,0cbh             ; 32bit RETF

code16  ends

;²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²
; 32bit pmode code
;²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²
code32  segment para public use32
        assume cs:code32, ds:code32
        org 0

extrn   _main:near

public  _exit, _ret, _getmem, _getlomem, _gethimem, _lomemsize, _himemsize
public  _getirqmask, _setirqmask, _getselector, _freeselector, _rmpmirqset
public  _rmpmirqfree

public  v86r_eax, v86r_ebx, v86r_ecx, v86r_edx, v86r_esi, v86r_edi, v86r_ebp
public  v86r_ax, v86r_bx, v86r_cx, v86r_dx, v86r_si, v86r_di, v86r_bp
public  v86r_al, v86r_ah, v86r_bl, v86r_bh, v86r_cl, v86r_ch, v86r_dl, v86r_dh
public  v86r_ds, v86r_es, v86r_fs, v86r_gs
public  _selcode, _seldata, _selzero, _lomembase, _lomemtop, _himembase
public  _himemtop, _pspa, _code16a, _code32a, _getirqvect, _setirqvect
public  _sysbyte0, _irqmode, _setselector, _exitcode
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 32 bit common system data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
_lomembase      dd      ?               ; low mem base for allocation
_lomemtop       dd      ?               ; top of low mem
_himembase      dd      0               ; high mem base for allocation
_himemtop       dd      0               ; top of high mem
_pspa           dd      ?               ; offset of start of PSP from 0
_code16a        dd      ?               ; offset of start of 16bit code from 0
_code32a        dd      ?               ; offset of start of 32bit code from 0
_selcode        dw      8               ; code segment selector
_seldata        dw      10h             ; data segment alias for code
_selzero        dw      18h             ; data segment starting at 0:0
_irqmode        dw      0ffffh          ; IRQ mode bits: 0=normal, 1=safe
                db      0ffh            ; misc byte, has to follow _irqmode
_sysbyte0       db      0               ; system bits:
                                        ;  0-1: 0=raw, 1=XMS, 2=VCPI, 3=DPMI
_exitcode       db      0               ; exit code for int21h ah=4ch

align 4
_getirqvect     dd      cp_getirqvect   ; get IRQ handler offset routine addx
_setirqvect     dd      cp_setirqvect   ; set IRQ handler offset routine addx
_setselector    dd      cp_setselector  ; set a selector addx offset addx

gdt32           dq      0
gdt32code32     db      0ffh,0ffh,0,0,0,9ah,0cfh,0
gdt32data32     db      0ffh,0ffh,0,0,0,92h,0cfh,0
gdt32zero32     db      0ffh,0ffh,0,0,0,92h,0cfh,0
gdt32code16     db      0ffh,0ffh,0,0,0,9ah,0,0
gdt32data16     db      0ffh,0ffh,0,0,0,92h,0,0
gdt32task       db      0ffh,0ffh,0,0,0,89h,0,0
gdt32vcpi       dq      3 dup(?)
if SELECTORS ne 0
gdt32free       db      SELECTORS dup(0ffh,0ffh,0,0,0,92h,0cfh,0)
endif

v86r_edi        label   dword           ; vregs for pmode<>real communication
v86r_di         dw      ?, ?            ;  needz to stay this way cuz its a
v86r_esi        label   dword           ;  stupid DPMI structure thingy
v86r_si         dw      ?, ?
v86r_ebp        label   dword
v86r_bp         dw      ?, ?
                dd      0
v86r_ebx        label   dword
v86r_bx         label   word
v86r_bl         db      ?
v86r_bh         db      ?, ?,?
v86r_edx        label   dword
v86r_dx         label   word
v86r_dl         db      ?
v86r_dh         db      ?, ?,?
v86r_ecx        label   dword
v86r_cx         label   word
v86r_cl         db      ?
v86r_ch         db      ?, ?,?
v86r_eax        label   dword
v86r_ax         label   word
v86r_al         db      ?
v86r_ah         db      ?, ?,?
v86r_flags      dw      ?
v86r_es         dw      ?
v86r_ds         dw      ?
v86r_fs         dw      ?
v86r_gs         dw      ?
                dd      0,0

oint1bvect      dd      ?               ; old real int 1bh vektor (ctrl+break)
oint32vect      dd      ?               ; old real int 32h vector
oirqmask        dw      ?               ; old port 21h and 0a1h masks
intslottbl      db      8,9,0ah,0bh,0ch,0dh,0eh,0fh,70h,71h,72h,73h,74h,75h,76h,77h
                db      35h,34h,33h,32h,31h,0,1,2,3,4,5,6,7,8,9,0ah,0bh,0ch,0dh,0eh

if SELECTORS ne 0
selectorbase    dw      50h
selectorinc     dw      8
selectorfree    db      SELECTORS dup(0)
endif

code16off       dw      c_retreal       ; offset in 16bit of exit function
code16sel       dw      20h             ; 16bit pmode code selector
data16sel       dw      28h             ; 16bit pmode data selector

nextmodestack   dw      (STAKSIZE-STAKMAIN)*16  ; stack for next mode switch
realstackbase   dd      ?               ; linear ptr to beginning of codeend

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 32 bit common system code
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
p_cpmode2:				; call pmode from V86
        mov gs,cx
        mov cl,10h
        mov ds,cx
        mov es,cx
        mov fs,cx
        sub nextmodestack,STAKPMODE*16
	push p_cpmodem2
	mov p_cpmodem2,V86CPMODED
        mov eax,[esp+22]
	mov p_cpmodem0,eax
        mov al,[esp+43]
	shr al,1
	and al,1
	add al,0fah
	mov p_cpmodem1,al
        jmp short p_cpmode
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
p_cpmode1:                              ; call pmode, load all
        mov esp,ebx
        mov ax,10h
        mov ds,ax
        mov es,ax
        mov ss,ax
;-----------------------------------------------------------------------------
p_cpmode0:                              ; call pmode, load FS and GS
        mov fs,_seldata
        mov gs,_selzero
;-----------------------------------------------------------------------------
p_cpmode:                               ; call pmode routine from real
        push offset p_cpmoded
        cld
        mov eax,v86r_eax
        mov ecx,v86r_ecx
        mov edx,v86r_edx
        mov ebx,v86r_ebx
        mov esi,v86r_esi
        mov edi,v86r_edi
        mov ebp,v86r_ebp
        db 68h                  ; PUSH destination address
p_cpmodem0      dd      ?       ;
p_cpmodem1      db      ?       ; CLI or STI
        ret
;-----------------------------------------------------------------------------
p_cpmoded:                              ; call to pmode done
        cli
        pushf
        pop v86r_flags
        mov v86r_eax,eax
        mov v86r_ecx,ecx
        mov v86r_edx,edx
        mov v86r_ebx,ebx
        mov v86r_esi,esi
        mov v86r_edi,edi
        mov v86r_ebp,ebp
        mov ecx,_code16a
p_cpmodem2        label word            ; return to real, modifiable to JMP
;-----------------------------------------------------------------------------
        movzx ebx,gs:savedstakoff[ecx]  ; DPMI return to real mode
        mov dx,gs:savedstakseg[ecx]
        mov ax,code16
        mov cx,dx
        mov si,ax
        mov edi,offset int32d0
        jmp dp_switchaddx
;-----------------------------------------------------------------------------
VCPMODED=(($-(p_cpmodem2+2))shl 8)+0ebh
p_cpmoded2:                             ; VCPI done with pmode
        movzx esi,gs:savedstakoff[ecx]
        mov cx,code16
        mov edi,offset int32d1
        db 0eah                 ; 16bit JMP FAR 20h:v_retreal0
        dw v_retreal0,0,20h     ;
;-----------------------------------------------------------------------------
CCPMODED=(($-(p_cpmodem2+2))shl 8)+0ebh
p_cpmoded3:                             ; raw/XMS done with pmode
        mov gs:c_retreal0m0[ecx],offset int32d3
        db 0eah                 ; 16bit JMP FAR 20h:c_retreal0
        dw c_retreal0,0,20h     ;
;-----------------------------------------------------------------------------
if ($-(p_cpmodem2+2)) gt 127
  err
endif
V86CPMODED=(($-(p_cpmodem2+2))shl 8)+0ebh
p_cpmoded4:				; V86 done with pmode
	pop p_cpmodem2
        jmp cp_int3_d3
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
p_start:                                ; common 32bit start
        mov eax,gs:[1bh*4]              ; neutralize crtl+break
        mov oint1bvect,eax
        db 65h,67h,0c7h,6       ; MOV DWORD PTR GS:[1bh*4],code16:nullint
        dw 1bh*4,nullint,code16 ;
        mov eax,gs:[32h*4]              ; set up for new real mode INT32
        mov oint32vect,eax
        db 65h,67h,0c7h,6       ; MOV DWORD PTR GS:[32h*4],code16:int32
        dw 32h*4,int32,code16   ;
        in al,21h                       ; save old PIC masks
        mov ah,al
        in al,0a1h
        mov oirqmask,ax
        jmp _main                       ; go to main code

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Allocate any mem, (first cheks low, then high)
; In:
;   EAX - size requested
; Out:
;   CF=0 - memory allocated
;   CF=1 - not enough mem
;   EAX - linear pointer to mem or ?
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_getmem:
        push eax
        call _getlomem
        jnc short getmemd
        pop eax
        jmp short _gethimem
getmemd:
        add esp,4
_ret:                                   ; generic RET instruction
        ret
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Allocate some low mem
; In:
;   EAX - size requested
; Out:
;   CF=0 - memory allocated
;   CF=1 - not enough mem
;   EAX - linear pointer to mem or ?
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
;   CF=0 - memory allocated
;   CF=1 - not enough mem
;   EAX - linear pointer to mem or ?
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
; Get status of IRQ mask bit
; In:
;   BL - IRQ num (0-15)
; Out:
;   AL - status: 0=enabled, 1=disabled
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_getirqmask:
        push ax
        in al,0a1h
        mov ah,al
        in al,21h
        xchg cl,bl
        shr ax,cl
        xchg cl,bl
        and al,1
        mov [esp],al
        pop ax
        ret
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Set status of IRQ mask bit
; In:
;   BL - IRQ num (0-15)
;   AL - status: 0=enabled, 1=disabled
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_setirqmask:
        push ax bx cx dx
        mov cl,bl
        mov bx,0fffeh
        movzx dx,al
        rol bx,cl
        shl dx,cl
        in al,0a1h
        mov ah,al
        in al,21h
        and ax,bx
        or ax,dx
        out 21h,al
        mov al,ah
        out 0a1h,al
        pop dx cx bx ax
        ret
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Set a real mode IRQ vect to redirect to pmode
; In:
;   BL - IRQ number
;   EDX - offset of IRQ handler
;   EDI -> 21 byte buffer for code stub created
; Out:
;   EAX - old seg:off of real mode IRQ handler
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
rmpmirqsetd0:
db 66h,52h              ; PUSH EDX
db 66h,0bah,?,?,?,?     ; MOV EDX,?
db 0cdh,32h             ; INT 32h
db 66h,5ah              ; POP EDX
db 0cfh                 ; IRET
db 9ch                  ; PUSHFD
db 0eh                  ; PUSH CS
db 0e8h,?,?,?,?         ; CALL ?
db 0c3h                 ; RET
;-----------------------------------------------------------------------------
_rmpmirqset:
        push esi edi
        mov esi,offset rmpmirqsetd0
        lea eax,[edi+13]
        mov [esi+4],eax
        add eax,7
        sub eax,edx
        neg eax
        mov [esi+16],eax
        mov eax,edi
        movsd
        movsd
        movsd
        movsd
        movsd
        movsb
        add eax,_code32a
        shl eax,12
        shr ax,12
        movzx edi,bl
        cmp edi,8
        jb short rmpmirqsetf0
        add edi,60h
rmpmirqsetf0:
        xchg eax,gs:[edi*4+20h]
        pop edi esi
        ret
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Reset a real more IRQ vect back to normal (just sets real mode IRQ vect)
; In:
;   BL - IRQ number
;   EAX - seg:off of real mode IRQ handler
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_rmpmirqfree:
        push ebx
        movzx ebx,bl
        cmp bl,8
        jb short rmpmirqfreef0
        add bl,60h
rmpmirqfreef0:
        mov gs:[ebx*4+20h],eax
        pop ebx
        ret
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Allocate a selector
; Out:
;   CF=1 - selector not allocated
;   CF=0 - selector allocated
;   AX - 4G data selector or ?
; Notes:
;   The selector returned is for a 4G r/w data segment with an undefined base
;    address.
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_getselector:
if SELECTORS eq 0
        stc
        ret
else
        push ecx edi
        mov edi,offset selectorfree
        mov ecx,SELECTORS
        mov al,0
        repne scasb
        jne short getselectorf0
        mov byte ptr [edi-1],1
        sub ecx,SELECTORS-1
        neg ecx
        imul cx,selectorinc
        mov ax,selectorbase
        add ax,cx
        clc
        jmp short getselectorf1
getselectorf0:
        stc
getselectorf1:
        pop edi ecx
        ret
endif
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Free an allocated selector
; In:
;   AX - selector
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_freeselector:
if SELECTORS ne 0
        push eax dx
        sub ax,selectorbase
        xor dx,dx
        div selectorinc
        movzx eax,ax
        mov selectorfree[eax],0
        pop dx eax
endif
        ret
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Exit to real mode
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
_exit:
        cli
        mov eax,oint1bvect              ; restore ctrl+break
        mov gs:[1bh*4],eax
        mov eax,oint32vect              ; restore real mode int 32h vector
        mov gs:[32h*4],eax
        mov ax,oirqmask                 ; restore PIC masks
        out 0a1h,al
        mov al,ah
        out 21h,al
        push code16sel                  ; go to 16bit pmode exit code
        push code16off
        mov ds,data16sel
        db 66h,0cbh             ; 16bit RETF

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 32 bit DPMI system data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
dp_switchaddx   df      ?               ; switch to real mode addx
dp_saveaddx     df      ?               ; save/restore state addx
dp_savelen      dw      0,0             ; length of state buffer
dp_savedstaksel dw      ?               ; current saved stack selector

dp_ointbuf      df      20 dup(?)       ; saved interrupt addx buffer
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 32 bit DPMI system code
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
dp_int32:                               ; DPMI INT32/34: CX:DX=seg:off
        pushad
        shl ecx,16
        mov cx,dx
        mov bp,offset callreal
        mov dl,1
        jmp short dp_int3_
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
dp_int33:                               ; DPMI INT33/35: AL=int num
        pushad
        movzx eax,al
        mov ecx,gs:[eax*4]
        mov bp,offset intreal
        xor dl,dl
;-----------------------------------------------------------------------------
dp_int3_:                               ; DPMI int or call to real mode
        mov ax,900h
        int 31h
        push ax
        and al,dl
        add al,0fah
        mov ebx,_code16a
        mov gs:icrealm0[ebx],al
        mov gs:icrealm1[ebx],ecx
        push cp_savedstakoff
        push dp_savedstaksel
        movzx ebx,nextmodestack
        lea eax,[ebx-STAKRMODE*16]
        mov nextmodestack,ax
        mov ax,ss
        mov es,ax
        sub esp,dword ptr dp_savelen
        mov edi,esp
        xor al,al
        call dp_saveaddx
        mov cp_savedstakoff,esp
        mov dp_savedstaksel,ss
        mov dx,codeend
        mov ax,v86r_ds
        mov cx,v86r_es
        movzx edi,bp
        mov si,code16
        jmp dp_switchaddx
;-----------------------------------------------------------------------------
dp_int3_d:                              ; done with real mode int or call
        mov edi,esp
        mov al,1
        call dp_saveaddx
        add esp,dword ptr dp_savelen
        pop dp_savedstaksel
        pop cp_savedstakoff
        add nextmodestack,STAKRMODE*16
        mov bx,v86r_flags
        pop ax
        int 31h
        mov ax,ds
        mov es,ax
        mov fs,ax
        mov gs,_selzero
        jmp cp_int3_d2
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; DPMI IRQ redirectors (needed to make all IRQ vector selectors = CS)
dp_irq0:
        jmp cs:dp_ointbuf[0]
dp_irq1:
        jmp cs:dp_ointbuf[6]
dp_irq2:
        jmp cs:dp_ointbuf[12]
dp_irq3:
        jmp cs:dp_ointbuf[18]
dp_irq4:
        jmp cs:dp_ointbuf[24]
dp_irq5:
        jmp cs:dp_ointbuf[30]
dp_irq6:
        jmp cs:dp_ointbuf[36]
dp_irq7:
        jmp cs:dp_ointbuf[42]
dp_irq8:
        jmp cs:dp_ointbuf[48]
dp_irq9:
        jmp cs:dp_ointbuf[54]
dp_irqa:
        jmp cs:dp_ointbuf[60]
dp_irqb:
        jmp cs:dp_ointbuf[66]
dp_irqc:
        jmp cs:dp_ointbuf[72]
dp_irqd:
        jmp cs:dp_ointbuf[78]
dp_irqe:
        jmp cs:dp_ointbuf[84]
dp_irqf:
        jmp cs:dp_ointbuf[90]

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; DPMI get IRQ handler offset
; In:
;   BL - IRQ num (0-0fh)
; Out:
;   EDX - offset of IRQ handler
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
dp_getirqvect:
        push ax ebx cx
        movzx ebx,bl
        mov bl,intslottbl[ebx]
        mov ax,204h
        int 31h
        pop cx ebx ax
        ret
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; DPMI set IRQ handler offset
; In:
;   BL - IRQ num (0-0fh)
;   EDX - offset of IRQ handler
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
dp_setirqvect:
        push ax ebx cx
        movzx ebx,bl
        mov bl,intslottbl[ebx]
        mov cx,cs
        mov ax,205h
        int 31h
        pop cx ebx ax
        ret
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Set the base addx for a selector
; In:
;   AX - selector
;   EDX - linear base addx for selector
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
dp_setselector:
if SELECTORS ne 0
        push ax bx ecx
        shld ecx,edx,16
        mov bx,ax
        mov ax,7
        int 31h
        pop ecx bx ax
endif
        ret

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 32 bit custom/XMS/VCPI system data
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
vp_vcpipmentry  df      3800000000h     ; VCPI entry point in pmode

cp_tssesp0ptr   dd      0               ; ptr to ESP0 in TSS, or null in VCPI
cp_idt32ptr     dd      ?               ; ptr to 32bit IDT
cp_int13vect    dd      0               ; interrupt vektor 13 ptr
cp_validexcdesp dd      0               ; valid ESP value for exc 13

cp_v86irqintr   dd      cp_int35f1,cp_int33f0   ; IRQ int call routines
cp_v86irqnum    db      ?               ; IRQ num for V86 mode
cp_v86irqmode   db      ?               ; IRQ mode for V86 mode (safe/norm)
cp_savedstakoff dd      ?               ; current saved stack offset
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; 32 bit custom/XMS/VCPI system code
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
cp_int31:                               ; INT 31h: AX=900h,901h,902h
        cmp al,1
        mov al,[esp+9]
        jb short cp_int31f0
        ja short cp_int31f1
        or byte ptr [esp+9],2
        jmp short cp_int31f1
cp_int31f0:
        and byte ptr [esp+9],0fdh
cp_int31f1:
        shr al,1
        and al,1
        iretd
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
vp_int32:                               ; VCPI INT 32h: safe CX:DX=seg:off
        pushad
        mov ebp,offset callreal
        mov si,VICREAL1D
        mov bl,2
        jmp short cp_int34f0
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
vp_int33:                               ; VCPI INT 33h: safe AL=int num
        pushad
        mov ebp,offset intreal
;-----------------------------------------------------------------------------
vp_int33f0:
        mov si,VICREAL1D
        mov bl,2
        jmp short cp_int35f0
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
cp_int32:                               ; INT 32h: safe CX:DX=seg:off
        pushad
        mov ebp,offset callreal
        mov si,CICREAL1D
        mov bl,1
        jmp short cp_int34f0
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
cp_int33:                               ; INT 33h: safe AL=int num
        pushad
        mov ebp,offset intreal
;-----------------------------------------------------------------------------
cp_int33f0:
        mov si,CICREAL1D
        mov bl,1
        jmp short cp_int35f0
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
cp_int34:                               ; INT 34h: normal CX:DX=seg:off
        pushad
        mov ebp,offset callreal
        mov si,CICREAL0D
        xor bl,bl
;-----------------------------------------------------------------------------
cp_int34f0:
        shl ecx,16
        mov cx,dx
        mov bh,1
        jmp short cp_int3_
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
cp_int35:                               ; INT 35h: normal AL=int num
        pushad
        mov ebp,offset intreal
;-----------------------------------------------------------------------------
cp_int35f1:
        mov si,CICREAL0D
        xor bl,bl
;-----------------------------------------------------------------------------
cp_int35f0:
        movzx eax,al
        mov ecx,gs:[eax*4]
        xor bh,bh
;-----------------------------------------------------------------------------
cp_int3_:                               ; int or call to real mode
        mov edi,[esp+40]
        shld eax,edi,23
        and al,bh
        add al,0fah
        mov edx,_code16a
        mov gs:icrealm0[edx],al
        mov gs:icrealm1[edx],ecx
        xchg gs:icrealm2[edx],si
        push si
        movzx esi,nextmodestack
        lea eax,[esi-STAKRMODE*16]
        mov nextmodestack,ax
        add eax,realstackbase
        mov edx,cp_tssesp0ptr
        push dword ptr [edx]
        mov [edx],eax
        sub eax,40
        push cp_validexcdesp
        mov cp_validexcdesp,eax
        push cp_savedstakoff
        mov cp_savedstakoff,esp
        cmp bl,1
        jb short cp_int3_n
        ja short vp_int3_s
;-----------------------------------------------------------------------------
cp_int3_s:                              ; safe real mode int or call
        mov edx,_code16a
        mov gs:c_sicrealm0[edx],bp
        mov esp,esi
        db 0eah                 ; 16bit JMP FAR 20h:c_retreal0
        dw c_retreal0,0,20h     ;
;-----------------------------------------------------------------------------
vp_int3_s:                              ; safe VCPI real mode int or call
        mov edi,ebp
        mov cx,v86r_ds
        mov ax,28h
        mov ds,ax
        db 0eah                 ; 16bit JMP FAR 20h:v_retreal0
        dw v_retreal0,0,20h     ;
;-----------------------------------------------------------------------------
cp_int3_n:                              ; normal real mode int or call
        sub esp,8
        push dword ptr v86r_ds
        push dword ptr v86r_es
        db 68h                  ; 32bit PUSH codeend
        dd codeend              ;
        push esi
        or edi,20000h
        and di,0fdffh
        push edi
        db 68h                  ; 32bit PUSH code16
        dd code16               ;
        push ebp
        iretd
;-----------------------------------------------------------------------------
cp_int3_d:                              ; done with real mode int or call
        mov ax,18h
        mov gs,ax
        mov ax,10h
        mov ds,ax
        mov es,ax
        mov fs,ax
        mov ss,ax
        mov esp,cp_savedstakoff
        pop cp_savedstakoff
        pop cp_validexcdesp
        mov ebx,cp_tssesp0ptr
        pop dword ptr [ebx]
        mov ebx,_code16a
        pop gs:icrealm2[ebx]
;-----------------------------------------------------------------------------
cp_int3_d3:                             ; done from real mode pmode call
        add nextmodestack,STAKRMODE*16
        mov bx,v86r_flags
;-----------------------------------------------------------------------------
cp_int3_d2:				; done from DPMI also
        mov ax,[esp+40]
        and ax,not 8d5h
        and bx,8d5h
        or ax,bx
        mov [esp+40],ax
        popad
        iretd
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
cp_excd:                                ; general protection violation
        cmp esp,cs:cp_validexcdesp      ; IRQ5 or exception
        je short cp_excdf0
        jmp cs:cp_int13vect
cp_excdf0:
        test byte ptr [esp+14],2        ; exception from V86?
        jnz short cp_excdv86
        pushad                          ; nope, pmode exception
        mov al,0dh
        jmp cp_exc
;-----------------------------------------------------------------------------
cp_excdv86:                             ; violation from V86 mode
        add esp,4
        pushad
        mov cx,18h
        mov ds,cx
        movzx ebx,word ptr [esp+36]
        shl ebx,4
        add ebx,[esp+32]
        inc word ptr [esp+32]
        mov al,[ebx]
        mov edx,3
        cmp al,0cch
        je short cp_v86int
        mov dl,4
        cmp al,0ceh
        je short cp_v86int
        inc word ptr [esp+32]
        mov dl,[ebx+1]
        cmp dl,32h
        je p_cpmode2
        cmp dl,0ffh
        je cp_int3_d
;-----------------------------------------------------------------------------
cp_v86int:                              ; need to simulate a real mode int
        movzx ebx,word ptr [esp+48]
        shl ebx,4
        sub word ptr [esp+44],6
        add ebx,[esp+44]
        mov ax,[esp+40]
        mov [ebx+4],ax
        and ah,0fch
        mov [esp+41],ah
        mov ax,[esp+36]
        mov [ebx+2],ax
        mov ax,[esp+32]
        mov [ebx],ax
        mov eax,[edx*4]
        mov [esp+32],ax
        shr eax,16
        mov [esp+36],ax
        popad
        iretd
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; all exceptions except 0dh. all are terminal, others are redirected.
cp_exc0:
        push eax
        mov ax,1000h
        jmp cp_irq
cp_exc1:
        push eax
        mov ax,1001h
        jmp cp_irq
cp_exc2:
        push eax
        mov ax,1002h
        jmp cp_irq
cp_exc3:
        push eax
        mov ax,1003h
        jmp cp_irq
cp_exc4:
        push eax
        mov ax,1004h
        jmp cp_irq
cp_exc5:
        push eax
        mov ax,1005h
        jmp cp_irq
cp_exc6:
        pushad
        mov al,6
        jmp short cp_exc
cp_exc7:
        push eax
        mov ax,1007h
        jmp cp_irq
cp_exc8:
        pushad
        mov al,8
        jmp short cp_exc
cp_exc9:
        pushad
        mov al,9
        jmp short cp_exc
cp_exca:
        pushad
        mov al,0ah
        jmp short cp_exc
cp_excb:
        pushad
        mov al,0bh
        jmp short cp_exc
cp_excc:
        pushad
        mov al,0ch
        jmp short cp_exc
cp_exce:
        pushad
        mov al,0eh
        jmp short cp_exc
cp_excf:
        pushad
        mov al,0ffh
;-----------------------------------------------------------------------------
cp_exc:                                 ; main exception handler
        mov bx,10h
        mov ds,bx
        mov es,bx
        mov fs,bx
        mov gs,_selzero
        cld
        jmp _exit
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
; IRQ redirector between modes
cp_irq0:
        push eax
        mov ax,0008h
        jmp short cp_irq
cp_irq1:
        push eax
        mov ax,0109h
        jmp short cp_irq
cp_irq2:
        push eax
        mov ax,020ah
        jmp short cp_irq
cp_irq3:
        push eax
        mov ax,030bh
        jmp short cp_irq
cp_irq4:
        push eax
        mov ax,040ch
        jmp short cp_irq
cp_irq5:
        push eax
        mov ax,050dh
        jmp short cp_irq
cp_irq6:
        push eax
        mov ax,060eh
        jmp short cp_irq
cp_irq7:
        push eax
        mov ax,070fh
        jmp short cp_irq
cp_irq8:
        push eax
        mov ax,0870h
        jmp short cp_irq
cp_irq9:
        push eax
        mov ax,0971h
        jmp short cp_irq
cp_irqa:
        push eax
        mov ax,0a72h
        jmp short cp_irq
cp_irqb:
        push eax
        mov ax,0b73h
        jmp short cp_irq
cp_irqc:
        push eax
        mov ax,0c74h
        jmp short cp_irq
cp_irqd:
        push eax
        mov ax,0d75h
        jmp short cp_irq
cp_irqe:
        push eax
        mov ax,0e76h
        jmp short cp_irq
cp_irqf:
        push eax
        mov ax,0f77h
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
cp_irq:                                 ; main IRQ handler thingy
        mov ss:cp_v86irqnum,al
        movzx eax,ah
        bt dword ptr ss:_irqmode,eax
        setc ss:cp_v86irqmode
        pop eax
        test byte ptr [esp+10],2
        jnz short cp_irqv86
        push ds es fs gs                ; real mode IRQ from pmode
        pushfd
        push cs
        push offset cp_irqpd
        pushad
        mov ax,10h
        mov ds,ax
        mov al,18h
        mov gs,ax
        mov al,cp_v86irqnum
        mov ebp,offset c_irqreal
        movzx ebx,cp_v86irqmode
        jmp cp_v86irqintr[ebx*4]
cp_irqpd:
        pop gs fs es ds
        iretd
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
cp_irqv86:                              ; IRQ from V86, safe or norm redirect
        cmp cs:cp_v86irqmode,0
        jne short cp_irqv86s
        pushad                          ; normal IRQ redirection
        mov ax,18h
        mov ds,ax
        movzx edx,ss:cp_v86irqnum
        jmp cp_v86int
;-----------------------------------------------------------------------------
cp_irqv86s:                             ; safe IRQ redirection
        pushfd
        push cs
        push offset cp_irqv86sd
        pushad
        mov ax,10h
        mov ds,ax
        mov al,18h
        mov gs,ax
        sub nextmodestack,STAKPMODE*16
        mov al,cp_v86irqnum
        mov ebp,offset c_irqreal
        jmp cp_v86irqintr[4]
;-----------------------------------------------------------------------------
cp_irqv86sd:                            ; done with safe IRQ
        add nextmodestack,STAKPMODE*16
        iretd

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Custom get IRQ handler offset
; In:
;   BL - IRQ num (0-0fh)
; Out:
;   EDX - offset of IRQ handler
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
cp_getirqvect:
        push ebx
        pushfd
        cli
        movzx ebx,bl
        mov bl,intslottbl[ebx]
;       cmp bl,13
;       je short cp_getirqvectf0
        lea ebx,[ebx*8]
        add ebx,cp_idt32ptr
        mov dx,[ebx+6]
        shl edx,16
        mov dx,[ebx]
cp_getirqvectd:
        popfd
        pop ebx
        ret
cp_getirqvectf0:
;       mov edx,cp_int13vect
;       jmp short cp_getirqvectd
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Custom set IRQ handler offset
; In:
;   BL - IRQ num (0-0fh)
;   EDX - offset of IRQ handler
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
cp_setirqvect:
        push ebx edx
        pushfd
        cli
        movzx ebx,bl
        mov bl,intslottbl[ebx]
;       cmp bl,13
;       je short cp_setirqvectf0
        lea ebx,[ebx*8]
        add ebx,cp_idt32ptr
        mov [ebx],dx
        shr edx,16
        mov [ebx+6],dx
cp_setirqvectd:
        popfd
        pop edx ebx
        ret
cp_setirqvectf0:
;       mov cp_int13vect,edx
;       jmp short cp_setirqvectd
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Custom set the base addx for a selector
; In:
;   AX - selector
;   EDX - linear base addx for selector
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
cp_setselector:
if SELECTORS ne 0
        push eax edx
        movzx eax,ax
        and edx,0ffffffh
        or edx,92000000h
        mov dword ptr gdt32[eax+2],edx
        mov dl,[esp+3]
        mov byte ptr gdt32[eax+7],dl
        pop edx eax
endif
        ret

code32  ends

;²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²
; End of program (must be at end of program or you will suffer)
;²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²²
codeend segment para stack use32 'stack'
db STAKSIZE*16 dup(?)
codeend ends
        end     start16

