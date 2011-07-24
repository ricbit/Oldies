; --------------------------------------------------------------------
; ADCREG - ADC A,rr rr=[a,b,c,d,e,h,l]

ADCREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                sub     ebp,4+1
                jmp     opadcreg

                endm

; --------------------------------------------------------------------
; ADCAHL - ADC A,(HL)

ADCAHL          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                call    readmem
                mov     bh,al
                sub     ebp,7+1
                jmp     opadcreg

                endm

; --------------------------------------------------------------------
; ADCIMM - ADC A,dd

ADCIMM          macro   opcode

emul&opcode:                
                FETCH1  opcode        
                add     edi,2
                mov     bh,al
                sub     ebp,7+1
                jmp     opadcreg

                endm

; --------------------------------------------------------------------
; ADCAII - ADC A,(II+dd)

ADCAII          macro   opcode,regii

emul&opcode:                
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,regii
                add     edi,2
                add     cx,bx
                call    readmem
                mov     bh,al
                sub     ebp,19+2
                jmp     opadcreg

                endm

; --------------------------------------------------------------------
; ADC rrw,regw   rrw=[hl] regw=[bc,de,hl,sp,ix,iy]

ADCREGWREGW     macro   opcode,rrlow,rrhigh,reglow,reghigh

emul&opcode:                
                inc     edi
                shr     dl,1
                mov     bl,reglow
                adc     rrlow,bl
                mov     bh,rrhigh
                mov     bl,reghigh
                mov     cl,0
                adc     rrhigh,bl
                adc     cl,cl
                sub     ebp,15+2
                mov     al,rrhigh
                xor     bl,bh
                xor     bl,al
                mov     dl,cl
                or      dl,[offset ARITP_table+eax]
                mov     al,cl
                and     bl,NBIT_0
                or      al,bl
                and     bl,BIT_4
                or      dl,bl
                or      dl,[offset OVERFLOW_table+eax]
                and     dl,NBIT_6
                mov     al,rrhigh
                or      al,rrlow
                jnz     _ret
                or      dl,BIT_6
                ret

                endm

; --------------------------------------------------------------------
; ADDREG - ADD A,rr rr=[a,b,c,d,e,h,l]

ADDREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                sub     ebp,4+1
                jmp     opaddreg

                endm

; --------------------------------------------------------------------
; ADDAHL - ADD A,(HL)

ADDAHL          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                call    readmem
                mov     bh,al
                sub     ebp,7+1
                jmp     opaddreg

                endm

; --------------------------------------------------------------------
; ADDIMM - ADD A,dd

ADDIMM          macro   opcode

emul&opcode:                
                FETCH1  opcode
                add     edi,2
                mov     bh,al
                sub     ebp,7+1
                jmp     opaddreg

                endm

; --------------------------------------------------------------------
; ADDAII - ADD A,(II+dd)

ADDAII          macro   opcode,regii

emul&opcode:                
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,regii
                add     edi,2
                add     cx,bx
                call    readmem
                mov     bh,al
                sub     ebp,19+2
                jmp     opaddreg

                endm

; --------------------------------------------------------------------
; ADD rrw,regw   rrw=[hl,ix,iy] regw=[bc,de,hl,sp,ix,iy]

ADDREGWREGW     macro   opcode,rrlow,rrhigh,reglow,reghigh,cycles

emul&opcode:                
                inc     edi
                mov     bl,reglow
                add     rrlow,bl
                mov     bh,rrhigh
                mov     bl,reghigh
                mov     cl,0
                adc     rrhigh,bl
                adc     cl,cl
                sub     ebp,cycles
                mov     al,rrhigh
                xor     bl,bh
                xor     bl,al
                and     dl,11000100b
                or      dl,cl
                and     bl,BIT_4
                or      dl,bl
                or      dl,[offset PVN53_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; ANDREG - AND rr rr=[a,b,c,d,e,h,l]

ANDREG          macro   opcode,reg

emul&opcode:                
                and     dh,reg
                inc     edi
                mov     al,dh
                mov     dl,[offset LOGICAL_table+eax]
                sub     ebp,4+1
                or      dl,BIT_4
                ret

                endm

; --------------------------------------------------------------------
; ANDHL - AND (HL)

ANDHL           macro   opcode

emul&opcode:                
                mov     ecx,regehl
                call    readmem
                and     dh,al
                inc     edi
                mov     al,dh
                mov     dl,[offset LOGICAL_table+eax]
                sub     ebp,7+1
                or      dl,BIT_4
                ret

                endm

; --------------------------------------------------------------------
; ANDIMM - AND dd

ANDIMM           macro   opcode

emul&opcode:                
                FETCH1  opcode
                and     dh,al
                add     edi,2
                mov     al,dh
                mov     dl,[offset LOGICAL_table+eax]
                sub     ebp,7+1
                or      dl,BIT_4
                ret

                endm

; --------------------------------------------------------------------
; ANDII - AND (II+dd)

ANDII           macro   opcode,regii

emul&opcode:                
                FETCH1  opcode        
                add     edi,2
                mov     ecx,regii
                movsx   ebx,al  
                add     cx,bx
                call    readmem
                and     dh,al
                mov     al,dh
                sub     ebp,19+2
                mov     dl,[offset LOGICAL_table+eax]
                or      dl,BIT_4
                ret

                endm

; --------------------------------------------------------------------
; BITREG - BIT nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

BITREG          macro   opcode,reg,bit

emul&opcode:                
                mov     al,reg
                inc     edi
                and     dl,01h
                sub     ebp,8+2
                or      dl,[offset BIT&bit&_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; BITHL - BIT nn,(HL) nn=[0..7]

BITHL           macro   opcode,bit

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                and     dl,01h
                sub     ebp,12+2
                or      dl,[offset BIT&bit&_table+eax]
                and     dl,11010111b
                ret

                endm

; --------------------------------------------------------------------
; BITII - BIT nn,(II+dd) nn=[0..7]

BITII           macro   opcode,bit,regii

emul&opcode:                
                movsx   ebx,cl
                mov     ecx,regii
                inc     edi
                add     cx,bx
                call    readmem
                and     dl,01h
                sub     ebp,20+3
                or      dl,[offset BIT&bit&_table+eax]
                and     dl,11010111b
                ret

                endm

; --------------------------------------------------------------------
; OPCALL - CALL dddd

OPCALL          macro   opcode

emul&opcode:                
                FETCHW1 opcode
                lea     ebx,[edi+3]
                mov     edi,eax
                mov     ecx,regesp
                mov     eax,ebx
                sub     cx,2
                call    writememw
                mov     regesp,ecx
                mov     eax,0
                sub     ebp,17+1
                ret

                endm

; --------------------------------------------------------------------
; CALLCC - CALL cc,dddd

CALLCC          macro   opcode,flagtype,jcc

emul&opcode:                
                test    dl,flagtype
                jcc     emulCD
                add     edi,3
                sub     ebp,10+1
                ret

                endm

; --------------------------------------------------------------------
; OPCCF - CCF

OPCCF           macro   opcode

emul&opcode:                
                mov     al,dl
                and     dl,11000101b
                shl     al,4
                xor     dl,1
                and     al,00010000b
                or      dl,al
                mov     al,dh
                or      dl,[offset PVN53_table+eax]
                inc     edi
                sub     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; CPREG - CP rr rr=[a,b,c,d,e,h,l]

CPREG           macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     al,reg                          ; clock 1 V
                xor     ebx,ebx
                sub     ebp,4+1
                jmp     opcpreg

                endm

; --------------------------------------------------------------------
; CPAHL - CP (HL)

CPAHL           macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                call    readmem
                xor     ebx,ebx
                sub     ebp,7+1
                jmp     opcpreg

                endm

; --------------------------------------------------------------------
; CPIMM - CP dd

CPIMM           macro   opcode

emul&opcode:                
                FETCH1  opcode
                add     edi,2
                xor     ebx,ebx
                sub     ebp,7+1
                jmp     opcpreg

                endm

; --------------------------------------------------------------------
; CPII - CP (II+dd)

CPII            macro   opcode,itype

emul&opcode:                
                mov     ecx,itype
                FETCH1  opcode
                movsx   ebx,al
                add     edi,2
                add     cx,bx
                call    readmem
                xor     ebx,ebx
                sub     ebp,19+2
                jmp     opcpreg

                endm

; --------------------------------------------------------------------
; OPCPIR - CPIR

OPCPIR          macro   opcode

emul&opcode:
                mov     ecx,regehl
                call    readmem
                inc     _reghl
                mov     bl,al
                xor     bl,dh
                mov     bh,dh
                sub     bh,al
                mov     al,bh
                xor     bl,al

                ; flag C is not affected

                ; flags S,Z 
                and     dl,1
                or      dl,[offset LOGICAL_table+eax]
                and     dl,11000001b

                ; flag H
                and     bl,00010000b
                or      dl,bl

                ; flag N
                or      dl,00000010b

                ; flags 5,3
                shr     bl,4
                sub     al,bl
                or      dl,[offset LDI_table+eax]

                ; flag PV 
                dec     _regbc
                jz      emul&opcode&done
                
                or      dl,00000100b
                test    dl,01000000b
                jnz     emul&opcode&done

                dec     edi
                sub     ebp,21+2
                ret

emul&opcode&done:
                inc     edi
                sub     ebp,16+2
                ret

                endm

; --------------------------------------------------------------------
; OPCPI - CPI

OPCPI           macro   opcode

emul&opcode:
                inc     edi
                mov     ecx,regehl
                call    readmem
                sub     ebp,16+2
                inc     _reghl
                mov     bl,al
                xor     bl,dh
                mov     bh,dh
                sub     bh,al
                mov     al,bh
                xor     bl,al

                ; flag C is not affected

                ; flags S,Z 
                and     dl,1
                or      dl,[offset LOGICAL_table+eax]
                and     dl,11000001b

                ; flag H
                and     bl,00010000b
                or      dl,bl

                ; flag N
                or      dl,00000010b

                ; flags 5,3
                shr     bl,4
                sub     al,bl
                or      dl,[offset LDI_table+eax]

                ; flag PV 
                dec     _regbc
                jz      _ret
                or      dl,00000100b
                ret

                endm

; --------------------------------------------------------------------
; OPCPDR - CPDR

OPCPDR          macro   opcode

emul&opcode:
                mov     ecx,regehl
                call    readmem
                dec     _reghl
                mov     bl,al
                xor     bl,dh
                mov     bh,dh
                sub     bh,al
                mov     al,bh
                xor     bl,al

                ; flag C is not affected

                ; flags S,Z 
                and     dl,1
                or      dl,[offset LOGICAL_table+eax]
                and     dl,11000001b

                ; flag H
                and     bl,00010000b
                or      dl,bl

                ; flag N
                or      dl,00000010b

                ; flags 5,3
                shr     bl,4
                sub     al,bl
                or      dl,[offset LDI_table+eax]

                ; flag PV 
                dec     _regbc
                jz      emul&opcode&done
                
                or      dl,00000100b
                
                test    dl,01000000b
                jnz     emul&opcode&done
                
                dec     edi
                sub     ebp,21+2
                ret

emul&opcode&done:
                inc     edi
                sub     ebp,16+2
                ret

                endm

; --------------------------------------------------------------------
; OPCPD - CPD

OPCPD           macro   opcode

emul&opcode:
                inc     edi
                mov     ecx,regehl
                call    readmem
                sub     ebp,16+2
                dec     _reghl
                mov     bl,al
                xor     bl,dh
                mov     bh,dh
                sub     bh,al
                mov     al,bh
                xor     bl,al

                ; flag C is not affected

                ; flags S,Z 
                and     dl,1
                or      dl,[offset LOGICAL_table+eax]
                and     dl,11000001b

                ; flag H
                and     bl,00010000b
                or      dl,bl

                ; flag N
                or      dl,00000010b

                ; flags 5,3
                shr     bl,4
                sub     al,bl
                or      dl,[offset LDI_table+eax]

                ; flag PV 
                dec     _regbc
                jz      _ret
                or      dl,00000100b
                ret

                endm

; --------------------------------------------------------------------
; OPCPL - CPL

OPCPL           macro   opcode

emul&opcode:
                xor     dh,255
                and     dl,11000101b
                mov     al,dh
                sub     ebp,4+1
                inc     edi
                or      dl,[offset CPL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPDAA - DAA

OPDAA           macro   opcode

emul&opcode:
                inc     edi
                mov     al,dl
                mov     al,[offset DAA_select_table+eax]
                shl     eax,9
                movzx   ebx,dh
                mov     dx,word ptr [offset DAA_table+ebx*2+eax]
                mov     eax,0
                sub     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; DECREG - DEC rr rr=[a,b,c,d,e,h,l]

DECREG          macro   opcode,reg

emul&opcode:
                inc     edi
                dec     reg
                and     dl,1
                mov     al,reg
                sub     ebp,4+1
                or      dl,[offset DEC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; DECHL - DEC (HL)

DECHL           macro   opcode

emul&opcode:
                inc     edi
                mov     ecx,regehl
                call    readmem
                dec     al
                call    writemem
                and     dl,1
                sub     ebp,11+1
                or      dl,[offset DEC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; DECII - DEC (II+dd)

DECII           macro   opcode,reg

emul&opcode:
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,reg
                add     edi,2
                add     cx,bx
                call    readmem
                dec     al
                call    writemem
                and     dl,1
                sub     ebp,23+2
                or      dl,[offset DEC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; DECWREG - DEC rr rr=[bc,de,hl,sp,ix,iy]

DECWREG         macro   opcode,reg,tcycles

emul&opcode:
                inc     edi
                dec     reg
                sub     ebp,tcycles
                ret

                endm

; --------------------------------------------------------------------
; OPDI - DI

OPDI            macro   opcode


emul&opcode:
                inc     edi
                mov     _iff1,0
                sub     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; OPDJNZ - DJNZ dd

OPDJNZ          macro   opcode

emul&opcode:
                dec     regb
                jz      emul&opcode&a
                FETCH1SX opcode
                sub     ebp,13+1
                lea     edi,[edi+ebx+2]
                ret
emul&opcode&a:        
                add     edi,2
                sub     ebp,8+1
                ret

                endm

; --------------------------------------------------------------------
; OPEI - EI

OPEI            macro   opcode

emul&opcode:
                inc     edi
                mov     _iff1,1
                sub     ebp,4+1
                
;                cmp     emumode,1
;                je      emul&opcode&x
;
;                cmp     iline,1
;                je      emul&opcode&iline
;
;                FETCHMACRO 0
;                inc     rcounter
;                call    dword ptr [offset iset + eax*4]
;
;                ret
;
;emul&opcode&iline:
;
;                mov     fakeirq,1
;                mov     clocksleft,ebp
;                mov     ebp,0
;
;                FETCHMACRO 0
;                inc     rcounter
;                call    dword ptr [offset iset + eax*4]
;
;                ret
;
;emul&opcode&x:
;                cmp     iline,0
;                je      _ret
;                mov     interrupt,1
;                mov     fakeirq,1
                ret

                endm

; --------------------------------------------------------------------
; OPEI - EI
; MSX2 VERSION

OPEI_MSX2       macro   opcode

emul&opcode:
                inc     edi
                mov     _iff1,1
                sub     ebp,4+1
                
                cmp     iline,1
                je      emul&opcode&iline

                FETCHMACRO 0
                inc     rcounter
                call    dword ptr [offset iset + eax*4]

                ret

emul&opcode&iline:

                FETCHMACRO 0
                inc     rcounter
                call    dword ptr [offset iset + eax*4]

                call    emulate_fakeirq_msx2

                ret

                endm

; --------------------------------------------------------------------
; OPEXAFAF - EX AF,AF'

OPEXAFAF        macro   opcode

emul&opcode:
                inc     edi
                mov     ecx,regeafl
                mov     regeafl,edx
                mov     edx,ecx
                sub     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; OPEXDEHL - EX DE,HL

OPEXDEHL        macro   opcode

emul&opcode:
                mov     ebx,regede
                mov     ecx,regehl
                mov     regehl,ebx
                mov     regede,ecx
                inc     edi
                sub     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; OPEXSPREGW - EX (SP),rr       rr=[hl,ix,iy]

OPEXSPREGW      macro   opcode,reg,cycles

emul&opcode:
                mov     ecx,regesp
                call    readmemw
                mov     ebx,reg
                mov     reg,eax
                mov     eax,ebx
                call    writememw
                sub     ebp,cycles
                inc     edi
                mov     eax,0
                ret

                endm

; --------------------------------------------------------------------
; OPEXX - EXX

OPEXX           macro   opcode

emul&opcode:
                inc     edi
                mov     ebx,regebc
                mov     ecx,regebcl
                mov     regebc,ecx
                mov     regebcl,ebx
                mov     ebx,regede
                mov     ecx,regedel
                mov     regede,ecx
                mov     regedel,ebx
                mov     ebx,regehl
                mov     ecx,regehll
                mov     regehl,ecx
                mov     regehll,ebx
                sub     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; OPHALT - HALT

OPHALT          macro   opcode

emul&opcode:
                inc     edi
                mov     ebp,0
                ret

                endm

; --------------------------------------------------------------------
; OPHALT - HALT
; MSX2 VERSION

OPHALT_MSX2     macro   opcode

emul&opcode:
                ;inc     edi
                mov     halted,1
                mov     ebp,0
                ret

                endm

; --------------------------------------------------------------------
; INADD - IN A,(dd) 

INADD           macro   opcode

emul&opcode:
                FETCH1  opcode
                add     edi,2
;                mov     out_highbyte,dh
                call    [offset inportxx+eax*4]
                mov     bl,_Value;;;
                mov     dh,bl
                sub     ebp,11+1
                ret

                endm

; --------------------------------------------------------------------
; INREG - IN rr,(C)

INREG           macro   opcode,reg

emul&opcode:
                inc     edi
                mov     al,regb
;                mov     out_highbyte,al
                mov     al,regc
                call    [offset inportxx+eax*4]
                mov     bl,_Value
                and     ebx,0ffh
                and     dl,1
                mov     reg,bl
                or      dl,[offset LOGICAL_table+ebx]
                sub     ebp,12+2
                ret

                endm

; --------------------------------------------------------------------
; INFLAG - IN (C) 

INFLAG          macro   opcode

emul&opcode:
                inc     edi
                mov     al,regc
                call    [offset inportxx+eax*4]
                mov     bl,_Value;;;
                and     ebx,0ffh
                and     dl,1
                or      dl,[offset LOGICAL_table+ebx]
                sub     ebp,12+2
                ret

                endm

; --------------------------------------------------------------------
; INCREG - INC rr rr=[a,b,c,d,e,h,l]

INCREG          macro   opcode,reg

emul&opcode:
                inc     edi
                inc     reg
                and     dl,1
                mov     al,reg
                sub     ebp,4+1
                or      dl,[offset INC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; INCHL - INC (HL)

INCHL           macro   opcode

emul&opcode:
                inc     edi
                mov     ecx,regehl
                call    readmem
                inc     al
                call    writemem
                and     dl,1
                sub     ebp,11+1
                or      dl,[offset INC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; INCII - INC (II+dd)

INCII           macro   opcode,reg

emul&opcode:
                FETCH1  opcode
                movsx   ebx,al
                add     edi,2
                mov     ecx,reg
                add     cx,bx
                call    readmem
                inc     al
                call    writemem
                and     dl,1
                sub     ebp,23+2
                or      dl,[offset INC_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; INCWREG - INC rr rr=[bc,de,hl,sp,ix,iy]

INCWREG         macro   opcode,reg,tcycles

emul&opcode:
                inc     edi
                inc     reg
                sub     ebp,tcycles
                ret

                endm

; --------------------------------------------------------------------
; OPINI - INI

OPINI           macro   opcode

emul&opcode:
                inc     edi
                mov     al,regc
                call    [offset inportxx+eax*4]
                mov     bl,_Value;;;
                mov     ecx,regehl
                mov     al,bl
                call    writemem
                inc     _reghl
                dec     regb
                and     dl,1
                mov     al,regb
                or      dl,[offset DEC_table+eax]
                sub     ebp,16+2
                ret

                endm

; --------------------------------------------------------------------
; OPINIR - INIR

OPINIR          macro   opcode

emul&opcode:
                inc     edi
emul&opcode&loop:
                mov     al,regc
                call    [offset inportxx+eax*4]
                mov     bl,_Value;;;
                mov     ecx,regehl
                mov     al,bl
                call    writemem
                inc     _reghl
                dec     regb
                and     dl,1
                mov     al,regb
                or      dl,[offset DEC_table+eax]
                sub     ebp,16+2
                test    dl,01000000b
                jz      emul&opcode&loop
                ret

                endm

; --------------------------------------------------------------------
; OPINDR - INDR

OPINDR          macro   opcode

emul&opcode:
                inc     edi
emul&opcode&loop:
                mov     al,regc
                call    [offset inportxx+eax*4]
                mov     bl,_Value;;;
                mov     ecx,regehl
                mov     al,bl
                call    writemem
                dec     _reghl
                dec     regb
                and     dl,1
                mov     al,regb
                or      dl,[offset DEC_table+eax]
                sub     ebp,16+2
                test    dl,01000000b
                jz      emul&opcode&loop
                ret

                endm

; --------------------------------------------------------------------
; OPIND - IND

OPIND           macro   opcode

emul&opcode:
                inc     edi
                mov     al,regc
                call    [offset inportxx+eax*4]
                mov     bl,_Value;;;
                mov     ecx,regehl
                mov     al,bl
                call    writemem
                dec     _reghl
                dec     regb
                and     dl,1
                mov     al,regb
                or      dl,[offset DEC_table+eax]
                sub     ebp,16+2
                ret

                endm

; --------------------------------------------------------------------
; OPIM0 - IM 0

OPIM0           macro   opcode

emul&opcode:
                inc     edi
                sub     ebp,8+2
                mov     imtype,0
                ret

                endm

; --------------------------------------------------------------------
; OPIM1 - IM 1 

OPIM1           macro   opcode

emul&opcode:
                inc     edi
                sub     ebp,8+2
                mov     imtype,1
                ret

                endm

; --------------------------------------------------------------------
; OPIM2 - IM 2

OPIM2           macro   opcode

emul&opcode:
                inc     edi
                sub     ebp,8+2
                mov     imtype,2
                ret

                endm

; --------------------------------------------------------------------
; JPCC - JP cc,dddd

JPCC            macro   opcode,jcc,flagtype

emul&opcode:    
                sub     ebp,10+1
                test    dl,flagtype
                jcc     emul&opcode&a
                FETCHW1 opcode
                mov     edi,eax
                xor     eax,eax
                ret
emul&opcode&a:  add     edi,3
                ret

                endm

; --------------------------------------------------------------------
; OPJR - JR dd

OPJR            macro   opcode

emul&opcode:    
                FETCH1  opcode
;                cmp     al,0FEh
;                je      emul&opcode&a
                movsx   ebx,al
                sub     ebp,12+1
                lea     edi,[edi+ebx+2]
                ret
;emul&opcode&a:
;                push    edx
;                mov     eax,ebp
;                mov     edx,0
;                mov     ebp,13
;                div     ebp
;                add     rcounter,eax
;                pop     edx
;                mov     eax,0
;                mov     ebp,eax
;                ret
;
                endm

; --------------------------------------------------------------------
; JRCC - JR cc,dd

JRCC            macro   opcode,jcc,flagtype

emul&opcode:    
                test    dl,flagtype
                jcc     emul&opcode&a    
                ;FETCH1  opcode
                ;movsx   ebx,al
                FETCH1SX opcode
                sub     ebp,12+1
                lea     edi,[edi+ebx+2]
                ret
emul&opcode&a:  sub     ebp,7+1
                add     edi,2
                ret

                endm

; --------------------------------------------------------------------
; OPJP - JP dddd

OPJP            macro   opcode

emul&opcode:    
                FETCHW1 opcode
                mov     edi,eax
                mov     eax,0
                sub     ebp,10+1
                ret

                endm

; --------------------------------------------------------------------
; OPJPREGW - JP (rr)            rr=[hl,ix,iy]

OPJPREGW        macro   opcode,reg,cycles

emul&opcode:    
                mov     edi,reg
                sub     ebp,cycles
                ret

                endm

; --------------------------------------------------------------------
; LDREGREG - LD rr,rr rr=[b,c,d,e,h,l]

LDREGREG        macro   opcode,reg1,reg2

emul&opcode:
                inc     edi
                mov     bl,reg2
                sub     ebp,4+1
                mov     reg1,bl
                ret

                endm

; --------------------------------------------------------------------
; LDREGA - LD rr,A rr=[b,c,d,e,h,l]

LDREGA          macro   opcode,reg

emul&opcode:
                inc     edi
                mov     reg,dh
                sub     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; LDAREG - LD A,rr rr=[a,b,c,d,e,h,l]

LDAREG          macro   opcode,reg

emul&opcode:
                inc     edi
                mov     dh,reg
                sub     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; LDREGHL - LD rr,(HL) rr=[a,b,c,d,e,h,l]

LDREGHL         macro   opcode,reg

emul&opcode:
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     reg,al
                sub     ebp,7+1
                ret

                endm

; --------------------------------------------------------------------
; LDREGWIMM - LD rr,dddd rr=[bc,de,hl,sp]

LDREGWIMM       macro   opcode,reg

emul&opcode:
                FETCHW1 opcode
                add     edi,3
                mov     reg,eax
                xor     eax,eax
                sub     ebp,10+1
                ret

                endm

; --------------------------------------------------------------------
; LDREGIMM - LD rr,dd rr=[a,b,c,d,e,h,l]

LDREGIMM        macro   opcode,reg

emul&opcode:
                FETCH1  opcode
                add     edi,2
                mov     reg,al
                sub     ebp,7+1
                ret

                endm

; --------------------------------------------------------------------
; LDREGIIDD - LD rr,(II+dd)     rr=[a,b,c,d,e,h,l]

LDREGIIDD       macro   opcode,reg,regii

emul&opcode:
                FETCH1  opcode        
                add     edi,2
                movsx   ebx,al
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     reg,al
                sub     ebp,19+2
                ret

                endm

; --------------------------------------------------------------------
; LDHLREG - LD (HL),rr rr=[a,b,c,d,e,h,l]

LDHLREG         macro   opcode,reg

emul&opcode:
                inc     edi
                mov     al,reg
                mov     ecx,regehl
                sub     ebp,7+1
                call    writemem
                ret

                endm

; --------------------------------------------------------------------
; LDSPREGW - LD SP,rr rr=[hl,ix,iy]

LDSPREGW        macro   opcode,reg,cycles

emul&opcode:
                inc     edi
                mov     ebx,reg
                mov     regesp,ebx
                sub     ebp,cycles
                ret

                endm

; --------------------------------------------------------------------
; LDREGWA - LD (rr),A rr=[bc,de,hl]

LDREGWA         macro   opcode,reg

emul&opcode:
                inc     edi
                mov     ecx,reg
                mov     al,dh
                call    writemem
                sub     ebp,7+1
                ret

                endm

; --------------------------------------------------------------------
; LDINDA - LD (dddd),A

LDINDA          macro   opcode,reg

emul&opcode:
                FETCHW1 opcode
                mov     ecx,eax
                mov     al,dh
                call    writemem
                add     edi,3
                mov     eax,0
                sub     ebp,13+1
                ret

                endm

; --------------------------------------------------------------------
; LDAIND - LD A,(dddd)

LDAIND          macro   opcode,reg

emul&opcode:
                FETCHW1 opcode
                mov     ecx,eax
                call    readmem
                mov     dh,al
                xor     eax,eax
                add     edi,3
                sub     ebp,13+1
                ret

                endm

; --------------------------------------------------------------------
; LDAREGW - LD A,(rr) rr=[bc,de,hl]

LDAREGW         macro   opcode,reg

emul&opcode:
                inc     edi
                mov     ecx,reg
                call    readmem
                mov     dh,al
                sub     ebp,7+1
                ret

                endm

; --------------------------------------------------------------------
; LDIIDDREG - LD (II+dd),rr     rr=[a,b,c,d,e,h,l]

LDIIDDREG       macro   opcode,reg,itype

emul&opcode:
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,itype
                add     edi,2
                add     cx,bx
                mov     al,reg
                call    writemem
                sub     ebp,19+2
                ret

                endm

; --------------------------------------------------------------------
; LDHLIMM - LD (HL),dd

LDHLIMM         macro   opcode

emul&opcode:
                FETCH1  opcode
                add     edi,2
                mov     ecx,regehl
                sub     ebp,10+1
                call    writemem
                ret

                endm

; --------------------------------------------------------------------
; LDREGWDDDD - LD rr,(dddd)     rr=[bc,de,hl,ix,iy]

LDREGWDDDD       macro   opcode,reg,cycles

emul&opcode:
                FETCHW1 opcode
                mov     ecx,eax
                call    readmemw
                mov     reg,eax
                add     edi,3
                xor     eax,eax
                sub     ebp,cycles
                ret

                endm

; --------------------------------------------------------------------
; LDDDDDREGW - LD (dddd),rr     rr=[bc,de,hl,ix,iy]

LDDDDDREGW      macro   opcode,reg,cycles

emul&opcode:
                FETCHW1 opcode
                add     edi,3
                mov     ecx,eax
                mov     eax,reg
                call    writememw
                xor     eax,eax
                sub     ebp,cycles
                ret

                endm

; --------------------------------------------------------------------
; LDIIDDNN - LD (II+dd),nn     rr=[a,b,c,d,e,h,l]

LDIIDDNN        macro   opcode,itype

emul&opcode:
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,itype
                add     cx,bx
                add     edi,2
                call    fetch
                inc     edi
                call    writemem
                sub     ebp,19+2
                ret

                endm

; --------------------------------------------------------------------
; LDAI - LD A,I

LDAI            macro   opcode

emul&opcode:    
                inc     edi
                mov     dh,regi
                sub     ebp,9+2
                mov     al,dh
                and     dl,1
                mov     bl,byte ptr [offset _iff1]
                shl     bl,2
                or      dl,[offset INTERRUPT_table+eax]
                or      dl,bl
                ret

                endm

; --------------------------------------------------------------------
; LDIA - LD I,A

LDIA            macro   opcode

emul&opcode:    
                inc     edi
                mov     regi,dh
                sub     ebp,9+2
                ret

                endm

; --------------------------------------------------------------------
; LDAR - LD A,R

LDAR            macro   opcode

emul&opcode:    
                inc     edi
                mov     dh,byte ptr [offset rcounter]
                and     dh,07fh
                or      dh,rmask
                sub     ebp,9+2
                mov     al,dh
                and     dl,1
                mov     bl,byte ptr [offset _iff1]
                shl     bl,2
                or      dl,[offset INTERRUPT_table+eax]
                or      dl,bl
                ret

                endm

; --------------------------------------------------------------------
; LDRA - LD R,A
    
LDRA            macro   opcode

emul&opcode:    
                inc     edi
                mov     byte ptr [offset rcounter],dh
                mov     rmask,dh
                and     rmask,080h
                sub     ebp,9+2
                ret

                endm

; --------------------------------------------------------------------
; LDD

OPLDD           macro   opcode

emul&opcode:    
                inc     edi
                mov     ecx,regehl                      ; clock 1 U
                call    readmem                         ; clock 1 V
                mov     ecx,regede                      ; clock 2 U
                call    writemem                        ; clock 2 V
                sub     ebp,16+2                        ; clock 3 U
                dec     _regde                           ; clock 3 V
                dec     _reghl                           ; clock 4 U
                add     al,dh                           ; clock 5 U
                and     dl,11000001b                    ; clock 5 V
                or      dl,[offset LDI_table+eax]
                dec     _regbc                           ; clock 6 U
                jz      _ret
                or      dl,00000100b
                ret

                endm

; --------------------------------------------------------------------
; OPLDDR - LDDR

OPLDDR          macro   opcode

emul&opcode:    
                mov     ecx,regehl                      ; clock 1 U
                call    readmem                         ; clock 1 V
                mov     ecx,regede                      ; clock 2 U
                call    writemem                        ; clock 2 V
                dec     _regde                           ; clock 3 V
                dec     _reghl                           ; clock 4 U
                add     al,dh                           ; clock 5 U
                and     dl,11000001b                    ; clock 5 V
                or      dl,[offset LDI_table+eax]
                dec     _regbc                           ; clock 6 U
                jz      emul&opcode&done
                or      dl,00000100b
                dec     edi
                sub     ebp,21+2                        ; clock 3 U
                ret

emul&opcode&done:
                inc     edi
                sub     ebp,16+2                        ; clock 3 U
                ret

                endm

; --------------------------------------------------------------------
; LDI

OPLDI           macro   opcode

emul&opcode:    
                inc     edi
                mov     ecx,regehl                      ; clock 1 U
                call    readmem                         ; clock 1 V
                mov     ecx,regede                      ; clock 2 U
                call    writemem                        ; clock 2 V
                sub     ebp,16+2                        ; clock 3 U
                inc     _regde                           ; clock 3 V
                inc     _reghl                           ; clock 4 U
                add     al,dh                           ; clock 5 U
                and     dl,11000001b                    ; clock 5 V
                or      dl,[offset LDI_table+eax]
                dec     _regbc                           ; clock 6 U
                jz      _ret                            ; clock 6 V
                or      dl,00000100b
                ret

                endm

; --------------------------------------------------------------------
; OPLDIR - LDIR

OPLDIR          macro   opcode

emul&opcode:    
                mov     ecx,regehl                      ; clock 1 U
                call    readmem                         ; clock 1 V
                mov     ecx,regede                      ; clock 2 U
                call    writemem                        ; clock 2 V
                inc     _regde                           ; clock 3 V
                inc     _reghl                           ; clock 4 U
                add     al,dh                           ; clock 5 U
                and     dl,11000001b                    ; clock 5 V
                or      dl,[offset LDI_table+eax]
                dec     _regbc                           ; clock 6 U
                jz      emul&opcode&done
                or      dl,00000100b
                dec     edi
                sub     ebp,21+2
                ret

emul&opcode&done:
                inc     edi
                sub     ebp,16+2
                ret
                endm

; --------------------------------------------------------------------
; NEG

OPNEG           macro   opcode

emul&opcode:    
                mov     al,dh                           
                inc     edi
                sub     ebp,8+2
                mov     dx,[offset NEG_table+eax*2]
                ret

                endm

; --------------------------------------------------------------------
; NOP

OPNOP           macro   opcode

emul&opcode:    
                inc     edi
                sub     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; ORREG - OR rr rr=[a,b,c,d,e,h,l]

ORREG           macro   opcode,reg

emul&opcode:                
                or      dh,reg
                inc     edi
                mov     al,dh
                sub     ebp,4+1
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; ORHL - OR (HL)

ORHL            macro   opcode

emul&opcode:                
                mov     ecx,regehl
                call    readmem
                or      dh,al
                mov     al,dh
                inc     edi
                sub     ebp,7+1
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; ORIMM - OR dd

ORIMM           macro   opcode

emul&opcode:                
                FETCH1  opcode
                or      dh,al
                add     edi,2
                mov     al,dh
                sub     ebp,7+1
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; ORII - OR (II+dd)

ORII            macro   opcode,regii

emul&opcode:                
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,regii
                add     edi,2
                add     cx,bx
                call    readmem
                or      dh,al
                sub     ebp,19+2
                mov     al,dh
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OUTIMM - OUT (dd),A

OUTIMM          macro   opcode

emul&opcode:    
                FETCH1  opcode
                add     edi,2
                mov     bl,dh
                sub     ebp,11+1
;                cmp     logout,1
;                jne     emul&opcode&skip
;                call    write_logout
;emul&opcode&skip:
                jmp     [offset outportxx+eax*4]

                endm

; --------------------------------------------------------------------
; OUTCREG - OUT (C),rr

OUTCREG         macro   opcode,reg

emul&opcode:    mov     al,regc
                inc     edi
                sub     ebp,12+2
                mov     bl,reg
;                cmp     logout,1
;                jne     emul&opcode&skip
;                call    write_logout
;emul&opcode&skip:
                jmp     [offset outportxx+eax*4]

                endm

; --------------------------------------------------------------------
; OUTC0 - OUT (C),0

OUTC0           macro   opcode

emul&opcode:    mov     al,regc
                inc     edi
                sub     ebp,12+2
                mov     bl,0
                jmp     [offset outportxx+eax*4]

                endm

; --------------------------------------------------------------------
; OPOUTI - OUTI

OPOUTI          macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     bl,al
                mov     al,regc
                push    ebx
;                cmp     logout,1
;                jne     emul&opcode&skip
;                call    write_logout
;emul&opcode&skip:

                call    [offset outportxx+eax*4]
                pop     ebx

                inc     _reghl
                mov     al,regb
                dec     al
                mov     regb,al

                ; S Z 5 3
                mov     dl,[offset DEC_table+eax]
                and     dl,11101000b 

                ; N
                mov     cl,bl
                shr     cl,6
                and     cl,2
                or      dl,cl

                ; C H
                mov     cl,regc
                inc     cl       ; forward opcode
                add     cl,bl
                sbb     cl,cl
                and     cl,11h
                or      dl,cl

                sub     ebp,16+2
                ret

                endm

; --------------------------------------------------------------------
; OPOUTD - OUTD

OPOUTD          macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     bl,al
                mov     al,regc
                call    [offset outportxx+eax*4]
                dec     _reghl
                dec     regb
                and     dl,1
                mov     al,regb
                or      dl,[offset DEC_table+eax]
                sub     ebp,16+2
                ret

                endm

; --------------------------------------------------------------------
; OPOTIR - OTIR

OPOTIR          macro   opcode

emul&opcode:                
                mov     ecx,regehl
                call    readmem
                mov     bl,al
                mov     al,regc
                push    ebx
                call    [offset outportxx+eax*4]
                pop     ebx

                inc     _reghl
                mov     al,regb
                dec     al
                mov     regb,al

                ; S Z 5 3
                mov     dl,[offset DEC_table+eax]
                and     dl,11101000b 

                ; N
                mov     cl,bl
                shr     cl,6
                and     cl,2
                or      dl,cl

                ; C H
                mov     cl,regc
                inc     cl       ; forward opcode
                add     cl,bl
                sbb     cl,cl
                and     cl,11h
                or      dl,cl

                test    dl,01000000b
                jnz     emul&opcode&done

                dec     edi
                sub     ebp,21+2
                ret

emul&opcode&done:
                inc     edi
                sub     ebp,16+2
                ret

                endm

; --------------------------------------------------------------------
; OPOTDR - OTDR

OPOTDR          macro   opcode

emul&opcode:                
                inc     edi
emul&opcode&loop:
                mov     ecx,regehl
                call    readmem
                mov     bl,al
                mov     al,regc
                call    [offset outportxx+eax*4]
                dec     _reghl
                dec     regb
                and     dl,1
                mov     al,regb
                or      dl,[offset DEC_table+eax]
                sub     ebp,16+2
                test    dl,01000000b
                jz      emul&opcode&loop
                ret

                endm

; --------------------------------------------------------------------
; POPREGW - POP rr rr=[bc,de,hl,af,ix,iy]

POPREGW         macro   opcode,reg,cycles

emul&opcode:                
                mov     ecx,regesp
                call    readmemw
                add     cx,2
                mov     reg,eax
                mov     regesp,ecx
                sub     ebp,cycles
                inc     edi
                xor     eax,eax
                ret

                endm

; --------------------------------------------------------------------
; PUSHREGW - PUSH rr rr=[bc,de,hl,af,ix,iy]

PUSHREGW        macro   opcode,reg,cycles

emul&opcode:                
                ; note: this opcode is used by the IM2 handler2
                ; and the "inc edi" must always be done
                ; AFTER the "writememw"
                mov     ecx,regesp
                mov     eax,reg
                sub     cx,2
                call    writememw
                mov     regesp,ecx
                xor     eax,eax
                inc     edi
                sub     ebp,cycles
                ret

                endm

; --------------------------------------------------------------------
; RESREG - RES nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

RESREG          macro   opcode,reg,bit

emul&opcode:                
                inc     edi
                and     reg,NBIT_&bit
                sub     ebp,8+2
                ret

                endm

; --------------------------------------------------------------------
; RESHL - RES nn,(HL)

RESHL           macro   opcode,bit

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                and     al,NBIT_&bit
                call    writemem
                sub     ebp,15+2
                ret

                endm

; --------------------------------------------------------------------
; RESII - RES nn,(II+dd)

RESII          macro   opcode,bit,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                and     al,NBIT_&bit
                call    writemem
                sub     ebp,23+3
                ret

                endm

; --------------------------------------------------------------------
; RESCOMBO - LD REG,RES nn,(II+dd)

RESCOMBO        macro   opcode,bit,regii,regcombo

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                and     al,NBIT_&bit
                call    writemem
                mov     regcombo,al
                sub     ebp,23+3
                ret

                endm

; --------------------------------------------------------------------
; OPRET - RET

OPRET           macro   opcode

emul&opcode:                
                mov     ecx,regesp
                call    readmemw
                add     cx,2
                mov     edi,eax
                mov     regesp,ecx
                mov     eax,0
                sub     ebp,10+1
                ret

                endm

; --------------------------------------------------------------------
; RETCC - RET cc  cc=[Z,NZ,PO,PE,C,NC,P,M]

RETCC           macro   opcode,flagtype,jcc

emul&opcode:                
                inc     edi
                test    dl,flagtype
                jcc     emul&opcode&ret
                sub     ebp,5+1
                ret

emul&opcode&ret:
                call    emulC9
                sub     ebp,1
                ret

                endm

; --------------------------------------------------------------------
; RLREG - RL rr rr=[a,b,c,d,e,h,l]

RLREG           macro   opcode,reg

emul&opcode:                
                inc     edi
                shr     dl,1
                mov     dl,0
                rcl     reg,1
                mov     al,reg
                adc     dl,dl
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLHL - RL (HL)

RLHL            macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                shr     dl,1
                mov     dl,0
                rcl     al,1
                adc     dl,dl
                call    writemem
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLII - RL (II+dd)

RLII            macro   opcode,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                shr     dl,1
                mov     dl,0
                rcl     al,1
                adc     dl,dl
                call    writemem
                sub     ebp,23+3
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLCOMBO - LD REG,RL (II+dd)

RLCOMBO         macro   opcode,regii,regcombo

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                shr     dl,1
                mov     dl,0
                rcl     al,1
                adc     dl,dl
                call    writemem
                mov     regcombo,al
                sub     ebp,23+3
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRLA - RLA

OPRLA           macro   opcode

emul&opcode:                
                inc     edi
                mov     bl,dl
                and     dl,11000100b
                shr     bl,1
                mov     bl,0
                rcl     dh,1
                mov     al,dh
                adc     bl,bl
                or      dl,bl
                sub     ebp,4+1
                or      dl,[offset PVN53_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLCREG - RLC rr rr=[a,b,c,d,e,h,l]

RLCREG          macro opcode,reg

emul&opcode:                
                inc     edi
                rol     reg,1
                mov     dl,reg
                mov     al,dl
                and     dl,1
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLCHL - RLC (HL)

RLCHL           macro opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                rol     al,1
                call    writemem
                mov     dl,al
                and     dl,1
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLCII - RLC (II+dd)

RLCII           macro opcode,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                rol     al,1
                call    writemem
                mov     dl,al
                and     dl,1
                sub     ebp,23+3
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RLCCOMBO - LD REG,RLC (II+dd)

RLCCOMBO         macro opcode,regii,regcombo

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                rol     al,1
                call    writemem
                mov     regcombo,al
                mov     dl,al
                and     dl,1
                sub     ebp,23+3
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRLCA - RLCA

OPRLCA          macro opcode

emul&opcode:                
                inc     edi
                and     dl,11000100b
                rol     dh,1
                mov     bl,dh
                mov     al,bl
                and     bl,1
                or      dl,bl
                sub     ebp,4+1
                or      dl,[offset PVN53_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRLD - RLD

OPRLD           macro   opcode

emul&opcode:
                inc     edi                            
                mov     ecx,regehl                    
                call    readmem                       
                mov     bl,al                         
                ; put low digit of hl in upper part of al
                shl     al,4
                mov     bh,dh                         
                ; dh has upper digit of a
                and     dh,0f0h
                ; bh has lower digit of a
                and     bh,0fh
                shr     bl,4
                ; mix
                or      dh,bl
                or      al,bh
                call    writemem
                mov     al,dh
                and     dl,1
                sub     ebp,18+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRREG - RR rr rr=[a,b,c,d,e,h,l]

RRREG           macro   opcode,reg

emul&opcode:                
                inc     edi
                shr     dl,1
                mov     dl,reg
                rcr     reg,1
                and     dl,1
                mov     al,reg
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRHL - RR (HL)

RRHL            macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                shr     dl,1
                mov     dl,al
                rcr     al,1
                and     dl,1
                call    writemem
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRII - RR (II+dd)

RRII            macro   opcode,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                shr     dl,1
                mov     dl,al
                rcr     al,1
                and     dl,1
                call    writemem
                sub     ebp,23+3
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRCOMBO - LD REG,RR (II+dd)

RRCOMBO         macro   opcode,regii,regcombo

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                shr     dl,1
                mov     dl,al
                rcr     al,1
                and     dl,1
                call    writemem
                mov     regcombo,al
                sub     ebp,23+3
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRRA - RRA

OPRRA           macro   opcode

emul&opcode:                
                inc     edi
                mov     bl,dl
                and     dl,11000100b
                shr     bl,1
                mov     bl,dh
                rcr     dh,1
                and     bl,1
                or      dl,bl
                mov     al,dh
                sub     ebp,4+1
                or      dl,[offset PVN53_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRCREG - RRC rr rr=[a,b,c,d,e,h,l]

RRCREG          macro opcode,reg

emul&opcode:                
                inc     edi
                mov     dl,reg
                ror     reg,1
                mov     al,reg
                and     dl,1
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRCHL - RRC (HL)

RRCHL           macro opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     dl,al
                ror     al,1
                call    writemem
                and     dl,1
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRCII - RRC (II+dd)

RRCII           macro opcode,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     dl,al
                ror     al,1
                call    writemem
                and     dl,1
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; RRCCOMBO - LD REG,RRC (II+dd)

RRCCOMBO        macro opcode,regii,regcombo

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     dl,al
                ror     al,1
                call    writemem
                mov     regcombo,al
                and     dl,1
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRRCA - RRCA

OPRRCA          macro   opcode

emul&opcode:                
                inc     edi
                mov     bl,dh
                and     dl,11000100b
                ror     dh,1
                mov     al,dh
                and     bl,1
                or      dl,bl
                sub     ebp,4+1
                or      dl,[offset PVN53_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRRD - RRD

OPRRD           macro   opcode

emul&opcode:
                inc     edi                            
                mov     ecx,regehl                    
                call    readmem                       
                mov     bl,al                         
                ; put high digit of hl in al
                shr     al,4
                ; put low digit of hl in bl
                and     bl,0fh                        
                mov     bh,dh                         
                ; put high digit of a in dh
                and     dh,0f0h
                ; put low digit of a in upper part of bh
                shl     bh,4
                or      dh,bl
                ; mix
                or      al,bh
                call    writemem
                mov     al,dh
                and     dl,1
                sub     ebp,18+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; OPRST - RST dd

OPRST           macro   opcode,addr

emul&opcode:                
                mov     ecx,regesp
                lea     eax,[edi+1]
                sub     ecx,2
                call    writememw
                mov     regesp,ecx
                mov     edi,addr
                xor     eax,eax
                sub     ebp,11+1
                ret

                endm

; --------------------------------------------------------------------
; SBCREG - SBC A,rr rr=[a,b,c,d,e,h,l]

SBCREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                sub     ebp,4+1
                jmp     opsbcreg

                endm

; --------------------------------------------------------------------
; SBCAHL - SBC A,(HL)

SBCAHL          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                call    readmem
                mov     bh,al
                sub     ebp,7+1
                jmp     opsbcreg

                endm

; --------------------------------------------------------------------
; SBCIMM - SBC A,dd

SBCIMM          macro   opcode

emul&opcode:                
                FETCH1  opcode
                add     edi,2
                mov     bh,al
                sub     ebp,7+1
                jmp     opsbcreg

                endm

; --------------------------------------------------------------------
; SBCAII - SBC A,(II+dd)

SBCAII          macro   opcode,regii

emul&opcode:                
                FETCH1  opcode
                add     edi,2
                movsx   ebx,al
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     bh,al
                sub     ebp,19+2
                jmp     opsbcreg

                endm

; --------------------------------------------------------------------
; SBC HL,regw   regw=[bc,de,hl,sp]

SBCHLWREG       macro   opcode,reglow,reghigh

emul&opcode:                
                inc     edi
                shr     dl,1
                mov     bl,reglow
                sbb     regl,bl
                mov     bh,regh
                mov     bl,reghigh
                mov     cl,0
                sbb     regh,bl
                adc     cl,cl
                sub     ebp,15+2
                mov     al,regh
                xor     bl,bh
                xor     bl,al
                mov     dl,cl
                or      dl,[offset ARITN_table+eax]
                mov     al,cl
                and     bl,NBIT_0
                or      al,bl
                and     bl,BIT_4
                or      dl,bl
                or      dl,[offset OVERFLOW_table+eax]
                and     dl,NBIT_6
                mov     al,regh
                or      al,regl
                jnz     _ret
                or      dl,BIT_6
                ret

                endm

; --------------------------------------------------------------------
; OPSCF - SCF

OPSCF           macro   opcode

emul&opcode:                
                inc     edi
                or      dl,1
                and     dl,11000100b
                mov     al,dh
                or      dl,1
                or      dl,[offset PVN53_table+eax]
                sub     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; SETREG - SET nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

SETREG          macro   opcode,reg,bit

emul&opcode:                
                inc     edi
                or      reg,BIT_&bit
                sub     ebp,8+2
                ret

                endm

; --------------------------------------------------------------------
; SETHL - SET nn,(HL)

SETHL          macro   opcode,bit

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                or      al,BIT_&bit
                call    writemem
                sub     ebp,15+2
                ret

                endm

; --------------------------------------------------------------------
; SETII - SET nn,(II+dd)

SETII          macro   opcode,bit,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                or      al,BIT_&bit
                call    writemem
                sub     ebp,23+3
                ret

                endm

; --------------------------------------------------------------------
; SETCOMBO - LD REG,SET nn,(II+dd)

SETCOMBO        macro   opcode,bit,regii,regcombo

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                or      al,BIT_&bit
                call    writemem
                mov     regcombo,al
                sub     ebp,23+3
                ret

                endm

; --------------------------------------------------------------------
; SLAREG - SLA rr rr=[a,b,c,d,e,h,l]

SLAREG          macro   opcode,reg

emul&opcode:
                inc     edi
                mov     dl,0
                shl     reg,1
                adc     dl,dl
                sub     ebp,8+2
                mov     al,reg
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SLAHL - SLA (HL)

SLAHL           macro   opcode

emul&opcode:
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     dl,0
                shl     al,1
                adc     dl,dl
                sub     ebp,15+2
                call    writemem
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SLAII - SLA (II+dd)

SLAII           macro   opcode,regii

emul&opcode:
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     dl,0
                shl     al,1
                adc     dl,dl
                sub     ebp,15+2
                call    writemem
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SLACOMBO - LD REG,SLA (II+dd)

SLACOMBO        macro   opcode,regii,regcombo

emul&opcode:
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     dl,0
                shl     al,1
                adc     dl,dl
                sub     ebp,15+2
                call    writemem
                mov     regcombo,al
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SLLREG - SLL rr rr=[a,b,c,d,e,h,l]

SLLREG          macro   opcode,reg

emul&opcode:
                inc     edi
                mov     dl,0
                shl     reg,1
                adc     dl,dl
                or      reg,1
                sub     ebp,8+2
                mov     al,reg
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SLLHL - SLL (HL)

SLLHL           macro   opcode

emul&opcode:
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     dl,0
                shl     al,1
                adc     dl,dl
                or      eax,1
                sub     ebp,15+2
                call    writemem
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SLLII - SLL (II+dd)

SLLII           macro   opcode,regii

emul&opcode:
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     dl,0
                shl     al,1
                adc     dl,dl
                or      eax,1
                sub     ebp,15+2
                call    writemem
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SLLCOMBO - LD REG,SLL (II+dd)

SLLCOMBO        macro   opcode,regii,regcombo

emul&opcode:
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     dl,0
                shl     al,1
                adc     dl,dl
                or      eax,1
                sub     ebp,15+2
                call    writemem
                mov     regcombo,al
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRAREG - SRA rr rr=[a,b,c,d,e,h,l]

SRAREG          macro   opcode,reg

emul&opcode:                
                inc     edi
                mov     dl,reg
                sar     reg,1
                and     dl,1
                mov     al,reg
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRAHL - SRA (HL)

SRAHL           macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     dl,al
                sar     al,1
                and     dl,1
                call    writemem
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRAII - SRA (II+dd)

SRAII           macro   opcode,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     dl,al
                sar     al,1
                and     dl,1
                call    writemem
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRACOMBO - LD REG,SRA (II+dd)

SRACOMBO        macro   opcode,regii,regcombo

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     dl,al
                sar     al,1
                and     dl,1
                call    writemem
                mov     regcombo,al
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRLREG - SRL rr rr=[a,b,c,d,e,h,l]

SRLREG          macro   opcode,reg

emul&opcode:                
                inc     edi
                mov     dl,reg
                shr     reg,1
                and     dl,1
                mov     al,reg
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRLHL - SRL (HL)

SRLHL           macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                mov     dl,al
                shr     al,1
                and     dl,1
                call    writemem
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRLII - SRL (II+dd)

SRLII           macro   opcode,regii

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     dl,al
                shr     al,1
                and     dl,1
                call    writemem
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SRLCOMBO - LD REG,SRL (II+dd)

SRLCOMBO        macro   opcode,regii,regcombo

emul&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                call    readmem
                mov     dl,al
                shr     al,1
                and     dl,1
                call    writemem
                mov     regcombo,al
                sub     ebp,15+2
                or      dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; SUBREG - SUB rr rr=[a,b,c,d,e,h,l]

SUBREG          macro   opcode,reg

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                sub     ebp,4+1
                jmp     opsubreg

                endm

; --------------------------------------------------------------------
; SUBAHL - SUB (HL)

SUBAHL          macro   opcode

emul&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                call    readmem
                mov     bh,al
                sub     ebp,7+1
                jmp     opsubreg

                endm

; --------------------------------------------------------------------
; SUBIMM - SUB dd

SUBIMM          macro   opcode

emul&opcode:                
                FETCH1  opcode
                add     edi,2
                mov     bh,al
                sub     ebp,7+1
                jmp     opsubreg

                endm

; --------------------------------------------------------------------
; SUBII - SUB (II+dd)

SUBII           macro   opcode,itype

emul&opcode:                
                mov     ecx,itype
                FETCH1  opcode
                movsx   ebx,al
                add     edi,2
                add     cx,bx
                call    readmem
                mov     bh,al
                sub     ebp,19+2
                jmp     opsubreg

                endm

; --------------------------------------------------------------------
; XORREG - XOR rr rr=[a,b,c,d,e,h,l]

XORREG          macro   opcode,reg

emul&opcode:                
                inc     edi
                xor     dh,reg
                mov     al,dh
                sub     ebp,4+1
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; XORHL - XOR (HL)

XORHL           macro   opcode

emul&opcode:                
                inc     edi
                mov     ecx,regehl
                call    readmem
                xor     dh,al
                mov     al,dh
                sub     ebp,7+1
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; XORIMM - XOR dd

XORIMM          macro   opcode

emul&opcode:                
                FETCH1  opcode
                add     edi,2
                xor     dh,al
                mov     al,dh
                sub     ebp,7+1
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; XORII - XOR (II+dd)

XORII           macro   opcode,regii

emul&opcode:                
                FETCH1  opcode
                add     edi,2
                movsx   ebx,al
                mov     ecx,regii
                add     cx,bx
                call    readmem
                xor     dh,al
                mov     al,dh
                sub     ebp,19+2
                mov     dl,[offset LOGICAL_table+eax]
                ret

                endm

; --------------------------------------------------------------------
; XNULL - used in a DD or FD prefix unknown

XNULL           macro   opcode

emul&opcode:                
                sub     ebp,4+1
                ret

                endm

; --------------------------------------------------------------------
; XNULL2 - used in a ED prefix unknown

XNULL2          macro   opcode

emul&opcode:                
                inc     edi
                sub     ebp,(4+1)+(4+1)
                ret

                endm

