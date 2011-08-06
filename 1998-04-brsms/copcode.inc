; --------------------------------------------------------------------
; GENERIC_ADD

GENERIC_ADD     macro                
                
                mov     esi,offset opaddreg
                call    esi

                endm

; --------------------------------------------------------------------
; GENERIC_ADC

GENERIC_ADC     macro                
                
                mov     esi,offset opadcreg
                call    esi

                endm

; --------------------------------------------------------------------
; GENERIC_SUB

GENERIC_SUB     macro                
                
                mov     esi,offset opsubreg
                call    esi

                endm

; --------------------------------------------------------------------
; GENERIC_SBC

GENERIC_SBC     macro                
                
                mov     esi,offset opsbcreg
                call    esi

                endm

; --------------------------------------------------------------------
; GENERIC_CP

GENERIC_CP      macro                
                
                mov     esi,offset opcpreg
                call    esi

                endm

; --------------------------------------------------------------------
; ADCREG - ADC A,rr rr=[a,b,c,d,e,h,l]

ADCREG          macro   opcode,reg

comp&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                sub     ebp,4+1
                GENERIC_ADC

                endm

; --------------------------------------------------------------------
; ADCAHL - ADC A,(HL)

ADCAHL          macro   opcode

comp&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                READMEM
                mov     bh,al
                sub     ebp,7+2
                GENERIC_ADC

                endm

; --------------------------------------------------------------------
; ADCIMM - ADC A,dd

ADCIMM          macro   opcode

comp&opcode:                
                FETCH1  opcode        
                add     edi,2
                mov     bh,al
                sub     ebp,7+2
                GENERIC_ADC

                endm

; --------------------------------------------------------------------
; ADCAII - ADC A,(II+dd)

ADCAII          macro   opcode,regii

comp&opcode:                
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,regii
                add     edi,2
                add     cx,bx
                READMEM
                mov     bh,al
                sub     ebp,19+4
                GENERIC_ADC

                endm

; --------------------------------------------------------------------
; ADC rrw,regw   rrw=[hl] regw=[bc,de,hl,sp,ix,iy]

ADCREGWREGW     macro   opcode,rrlow,rrhigh,reglow,reghigh

comp&opcode:                
                add     edi,2
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
                jnz     comp&opcode&a
                or      dl,BIT_6
comp&opcode&a:

                endm

; --------------------------------------------------------------------
; ADDREG - ADD A,rr rr=[a,b,c,d,e,h,l]

ADDREG          macro   opcode,reg

comp&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                sub     ebp,4+1
                GENERIC_ADD

                endm

; --------------------------------------------------------------------
; ADDAHL - ADD A,(HL)

ADDAHL          macro   opcode

comp&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                READMEM
                mov     bh,al
                sub     ebp,7+2
                GENERIC_ADD

                endm

; --------------------------------------------------------------------
; ADDIMM - ADD A,dd

ADDIMM          macro   opcode

comp&opcode:                
                FETCH1  opcode
                add     edi,2
                mov     bh,al
                sub     ebp,7+2
                GENERIC_ADD

                endm

; --------------------------------------------------------------------
; ADDAII - ADD A,(II+dd)

ADDAII          macro   opcode,regii

comp&opcode:                
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,regii
                add     edi,2
                add     cx,bx
                READMEM
                mov     bh,al
                sub     ebp,19+4
                GENERIC_ADD

                endm

; --------------------------------------------------------------------
; ADD rrw,regw   rrw=[hl,ix,iy] regw=[bc,de,hl,sp,ix,iy]

ADDREGWREGW     macro   opcode,rrlow,rrhigh,reglow,reghigh,cycles

comp&opcode:                
                inc     edi
                mov     bl,reglow
                add     rrlow,bl
                mov     bh,rrhigh
                mov     bl,reghigh
                mov     cl,0
                adc     rrhigh,bl
                adc     cl,cl
                sub     ebp,cycles+1
                mov     al,rrhigh
                xor     bl,bh
                xor     bl,al
                and     dl,11000100b
                or      dl,cl
                and     bl,BIT_4
                or      dl,bl
                or      dl,[offset PVN53_table+eax]

                endm

; --------------------------------------------------------------------
; ANDREG - AND rr rr=[a,b,c,d,e,h,l]

ANDREG          macro   opcode,reg

comp&opcode:                
                and     dh,reg
                inc     edi
                mov     al,dh
                mov     dl,[offset LOGICAL_table+eax]
                sub     ebp,4+1
                or      dl,BIT_4

                endm

; --------------------------------------------------------------------
; ANDHL - AND (HL)

ANDHL           macro   opcode

comp&opcode:                
                mov     ecx,regehl
                READMEM
                and     dh,al
                inc     edi
                mov     al,dh
                mov     dl,[offset LOGICAL_table+eax]
                sub     ebp,7+3
                or      dl,BIT_4

                endm

; --------------------------------------------------------------------
; ANDIMM - AND dd

ANDIMM           macro   opcode

comp&opcode:                
                FETCH1  opcode
                and     dh,al
                add     edi,2
                mov     al,dh
                mov     dl,[offset LOGICAL_table+eax]
                sub     ebp,7+2
                or      dl,BIT_4

                endm

; --------------------------------------------------------------------
; ANDII - AND (II+dd)

ANDII           macro   opcode,regii

comp&opcode:                
                FETCH1  opcode        
                add     edi,2
                mov     ecx,regii
                movsx   ebx,al  
                add     cx,bx
                READMEM
                and     dh,al
                mov     al,dh
                sub     ebp,19+4
                mov     dl,[offset LOGICAL_table+eax]
                or      dl,BIT_4

                endm

; --------------------------------------------------------------------
; BITREG - BIT nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

BITREG          macro   opcode,reg,bit

comp&opcode:                
                mov     al,reg
                add     edi,2
                and     dl,01h
                sub     ebp,8+2
                or      dl,[offset BIT&bit&_table+eax]

                endm

; --------------------------------------------------------------------
; BITHL - BIT nn,(HL) nn=[0..7]

BITHL           macro   opcode,bit

comp&opcode:                
                add     edi,2
                mov     ecx,regehl
                READMEM
                and     dl,01h
                sub     ebp,12+3
                or      dl,[offset BIT&bit&_table+eax]
                and     dl,11010111b

                endm

; --------------------------------------------------------------------
; BITII - BIT nn,(II+dd) nn=[0..7]

BITII           macro   opcode,bit,regii

comp&opcode:                
                movsx   ebx,cl
                mov     ecx,regii
                inc     edi
                add     cx,bx
                READMEM
                and     dl,01h
                sub     ebp,20+4
                or      dl,[offset BIT&bit&_table+eax]
                and     dl,11010111b

                endm

; --------------------------------------------------------------------
; OPCALL - CALL dddd

OPCALL          macro   opcode

comp&opcode:                
                FETCHW1 opcode
                lea     ebx,[edi+3]
                mov     edi,eax
                mov     ecx,regesp
                mov     eax,ebx
                sub     ecx,2
                WRITEMEMW
                mov     regesp,ecx
                mov     eax,0
                sub     ebp,17+5

                endm

; --------------------------------------------------------------------
; CALLCC - CALL cc,dddd

CALLCC          macro   opcode,flagtype,jcc

comp&opcode:                
                FETCHW1 opcode
                test    dl,flagtype
                jcc     comp&opcode&a
                add     edi,3
                sub     ebp,10+3
                jmp     comp&opcode&b
comp&opcode&a:
                lea     ebx,[edi+3]
                mov     edi,eax
                mov     ecx,regesp
                mov     eax,ebx
                sub     ecx,2
                WRITEMEMW
                mov     regesp,ecx
                sub     ebp,17+5
comp&opcode&b:
                mov     eax,0

                endm

; --------------------------------------------------------------------
; OPCCF - CCF

OPCCF           macro   opcode

comp&opcode:                
                xor     dl,1
                inc     edi
                and     dl,11101101b
                sub     ebp,4+1

                endm

; --------------------------------------------------------------------
; CPREG - CP rr rr=[a,b,c,d,e,h,l]

CPREG           macro   opcode,reg

comp&opcode:                
                inc     edi                             ; clock 1 U
                mov     al,reg                          ; clock 1 V
                xor     ebx,ebx
                sub     ebp,4+1
                GENERIC_CP

                endm

; --------------------------------------------------------------------
; CPAHL - CP (HL)

CPAHL           macro   opcode

comp&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                READMEM
                xor     ebx,ebx
                sub     ebp,7+2
                GENERIC_CP

                endm

; --------------------------------------------------------------------
; CPIMM - CP dd

CPIMM           macro   opcode

comp&opcode:                
                FETCH1  opcode
                add     edi,2
                xor     ebx,ebx
                sub     ebp,7+2
                GENERIC_CP

                endm

; --------------------------------------------------------------------
; CPII - CP (II+dd)

CPII            macro   opcode,itype

comp&opcode:                
                FETCH1  opcode
                mov     ecx,itype
                movsx   ebx,al
                add     edi,2
                add     cx,bx
                READMEM
                xor     ebx,ebx
                sub     ebp,19+3
                GENERIC_CP

                endm

; --------------------------------------------------------------------
; OPCPIR - CPIR

OPCPIR          macro   opcode

comp&opcode:
                add     edi,2
comp&opcode&b:      
                mov     ecx,regehl
                READMEM
                cmp     dh,al
                jz      comp&opcode&a
                sub     ebp,21+2
                inc     reghl
                dec     regbc
                jnz     comp&opcode&b
                and     dl,10111011b
                add     ebp,5-2
                jmp     comp&opcode&c
comp&opcode&a:      
                inc     reghl
                dec     regbc
                or      dl,01000100b
                add     ebp,5-2
comp&opcode&c:

                endm

; --------------------------------------------------------------------
; OPCPDR - CPDR

OPCPDR          macro   opcode

comp&opcode:
                add     edi,2
comp&opcode&b:      
                mov     ecx,regehl
                READMEM
                cmp     dh,al
                jz      comp&opcode&a
                sub     ebp,21+2
                dec     reghl
                dec     regbc
                jnz     comp&opcode&b
                and     dl,10111011b
                add     ebp,5-2
                jmp     comp&opcode&c
comp&opcode&a:      
                dec     reghl
                dec     regbc
                or      dl,01000100b
                add     ebp,5-2
comp&opcode&c:

                endm

; --------------------------------------------------------------------
; OPCPL - CPL

OPCPL           macro   opcode

comp&opcode:
                xor     dh,255
                and     dl,11000101b
                mov     al,dh
                sub     ebp,4+1
                inc     edi
                or      dl,[offset CPL_table+eax]

                endm

; --------------------------------------------------------------------
; OPDAA - DAA

OPDAA           macro   opcode

comp&opcode:
                inc     edi
                xor     ecx,ecx
                mov     al,dh
                mov     cl,dl
                mov     dl,0
                add     dx,[offset DAA_table+ecx*2]
                mov     ebx,[offset DAA_select_table+ecx*4]
                add     dx,[ebx+eax*2]
                mov     cl,dh
                or      dl,[offset LOGICAL_table+ecx]
                and     edx,0ffffh
                sub     ebp,4+1

                endm

; --------------------------------------------------------------------
; DECREG - DEC rr rr=[a,b,c,d,e,h,l]

DECREG          macro   opcode,reg

comp&opcode:
                inc     edi
                dec     reg
                and     dl,1
                mov     al,reg
                sub     ebp,4+1
                or      dl,[offset DEC_table+eax]

                endm

; --------------------------------------------------------------------
; DECHL - DEC (HL)

DECHL           macro   opcode

comp&opcode:
                inc     edi
                mov     ecx,regehl
                READMEM
                dec     al
                WRITEMEM
                and     dl,1
                sub     ebp,11+3
                or      dl,[offset DEC_table+eax]

                endm

; --------------------------------------------------------------------
; DECII - DEC (II+dd)

DECII           macro   opcode,reg

comp&opcode:
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,reg
                add     edi,2
                add     cx,bx
                READMEM
                dec     al
                WRITEMEM
                and     dl,1
                sub     ebp,23+5
                or      dl,[offset DEC_table+eax]

                endm

; --------------------------------------------------------------------
; DECWREG - DEC rr rr=[bc,de,hl,sp,ix,iy]

DECWREG         macro   opcode,reg,tcycles

comp&opcode:
                inc     edi
                dec     reg
                sub     ebp,tcycles+1

                endm

; --------------------------------------------------------------------
; OPDI - DI

OPDI            macro   opcode


comp&opcode:
                inc     edi
                mov     iff1,0
                sub     ebp,4+1

                endm

; --------------------------------------------------------------------
; OPDJNZ - DJNZ dd

OPDJNZ          macro   opcode

comp&opcode:
                FETCH1S opcode
                dec     regb
                jz      comp&opcode&a
                sub     ebp,13+2
                mov     edi,ecx
                jmp     comp&opcode&b
comp&opcode&a:        
                sub     ebp,8+2
                add     edi,2
comp&opcode&b:

                endm

; --------------------------------------------------------------------
; OPEI - EI

OPEI            macro   opcode

comp&opcode:
                inc     edi
                mov     iff1,1
                sub     ebp,4+1

                endm

; --------------------------------------------------------------------
; OPEXAFAF - EX AF,AF'

OPEXAFAF        macro   opcode

comp&opcode:
                inc     edi
                mov     ecx,regeafl
                mov     regeafl,edx
                mov     edx,ecx
                sub     ebp,4+1

                endm

; --------------------------------------------------------------------
; OPEXDEHL - EX DE,HL

OPEXDEHL        macro   opcode

comp&opcode:
                mov     ebx,regede
                mov     ecx,regehl
                mov     regehl,ebx
                mov     regede,ecx
                inc     edi
                sub     ebp,4+1

                endm

; --------------------------------------------------------------------
; OPEXSPREGW - EX (SP),rr       rr=[hl,ix,iy]

OPEXSPREGW      macro   opcode,reg

comp&opcode:
                mov     ecx,regesp
                READMEMW
                mov     ebx,reg
                mov     reg,eax
                mov     eax,ebx
                WRITEMEMW
                sub     ebp,19+3
                inc     edi
                mov     eax,0

                endm

; --------------------------------------------------------------------
; OPEXX - EXX

OPEXX           macro   opcode

comp&opcode:
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

                endm

; --------------------------------------------------------------------
; OPHALT - HALT

OPHALT          macro   opcode

comp&opcode:
                inc     edi
comp&opcode&a:
                cmp     interrupt,1
                jne     comp&opcode&a
                sub     ebp,5

                endm

; --------------------------------------------------------------------
; INADD - IN A,(dd) 

INADD           macro   opcode

comp&opcode:
                FETCH1  opcode
                add     edi,2
                call    [offset inportxx+eax*4]
                and     dl,1
                mov     al,bl
                mov     dh,bl
                sub     ebp,11+2
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; INREG - IN rr,(C) 

INREG           macro   opcode,reg

comp&opcode:
                add     edi,2
                mov     al,regc
                call    [offset inportxx+eax*4]
                and     ebx,0ffh
                and     dl,1
                mov     reg,bl
                or      dl,[offset LOGICAL_table+ebx]
                sub     ebp,12+2

                endm

; --------------------------------------------------------------------
; INCREG - INC rr rr=[a,b,c,d,e,h,l]

INCREG          macro   opcode,reg

comp&opcode:
                inc     edi
                inc     reg
                and     dl,1
                mov     al,reg
                sub     ebp,4+1
                or      dl,[offset INC_table+eax]

                endm

; --------------------------------------------------------------------
; INCHL - INC (HL)

INCHL           macro   opcode

comp&opcode:
                inc     edi
                mov     ecx,regehl
                READMEM
                inc     al
                WRITEMEM
                and     dl,1
                sub     ebp,11+3
                or      dl,[offset INC_table+eax]

                endm

; --------------------------------------------------------------------
; INCII - INC (II+dd)

INCII           macro   opcode,reg

comp&opcode:
                FETCH1  opcode
                movsx   ebx,al
                add     edi,2
                mov     ecx,reg
                add     cx,bx
                READMEM
                inc     al
                WRITEMEM
                and     dl,1
                sub     ebp,23+5
                or      dl,[offset INC_table+eax]

                endm

; --------------------------------------------------------------------
; INCWREG - INC rr rr=[bc,de,hl,sp,ix,iy]

INCWREG         macro   opcode,reg,tcycles

comp&opcode:
                inc     edi
                inc     reg
                sub     ebp,tcycles+1

                endm

; --------------------------------------------------------------------
; OPINI - INI

OPINI           macro   opcode

comp&opcode:
                add     edi,2
                mov     al,regc
                call    [offset inportxx+eax*4]
                mov     ecx,regehl
                mov     al,bl
                WRITEMEM
                inc     reghl
                dec     regb
                and     dl,1
                mov     al,regb
                or      dl,[offset DEC_table+eax]
                sub     ebp,16+3

                endm

; --------------------------------------------------------------------
; OPIM1 - IM 1 

OPIM1           macro   opcode

comp&opcode:
                add     edi,2
                sub     ebp,8+2

                endm

; --------------------------------------------------------------------
; JPCC - JP cc,dddd

JPCC            macro   opcode,jcc,flagtype

comp&opcode:    
                FETCHW1 opcode
                sub     ebp,10+3
                test    dl,flagtype
                jcc     comp&opcode&a
                mov     edi,eax
                jmp     comp&opcode&b
comp&opcode&a:  
                add     edi,3
comp&opcode&b:
                mov     eax,0

                endm

; --------------------------------------------------------------------
; OPJR - JR dd

OPJR            macro   opcode

comp&opcode:    
                ;FETCH1S opcode
                mov     edi,0
                sub     ebp,12+2

                endm

; --------------------------------------------------------------------
; JRCC - JR cc,dd

JRCC            macro   opcode,jcc,flagtype

comp&opcode:    
                FETCH1S opcode
                test    dl,flagtype
                jcc     comp&opcode&a    
                sub     ebp,12+2
                mov     edi,ecx
                jmp     comp&opcode&b
comp&opcode&a:  
                sub     ebp,7+2
                add     edi,2
comp&opcode&b:

                endm

; --------------------------------------------------------------------
; OPJP - JP dddd

OPJP            macro   opcode

comp&opcode:    
                ;FETCHW1 opcode
                ;mov     edi,eax
                ;mov     eax,0

                mov     edi,0
                sub     ebp,10+3

                endm

; --------------------------------------------------------------------
; OPJPREGW - JP (rr)            rr=[hl,ix,iy]

OPJPREGW        macro   opcode,reg

comp&opcode:    
                mov     edi,reg
                sub     ebp,4+1

                endm

; --------------------------------------------------------------------
; LDREGREG - LD rr,rr rr=[b,c,d,e,h,l]

LDREGREG        macro   opcode,reg1,reg2

comp&opcode:
                inc     edi
                mov     bl,reg2
                sub     ebp,4+1
                mov     reg1,bl

                endm

; --------------------------------------------------------------------
; LDREGA - LD rr,A rr=[b,c,d,e,h,l]

LDREGA          macro   opcode,reg

comp&opcode:
                inc     edi
                mov     reg,dh
                sub     ebp,4+1

                endm

; --------------------------------------------------------------------
; LDAREG - LD A,rr rr=[a,b,c,d,e,h,l]

LDAREG          macro   opcode,reg

comp&opcode:
                inc     edi
                mov     dh,reg
                sub     ebp,4+1

                endm

; --------------------------------------------------------------------
; LDREGHL - LD rr,(HL) rr=[a,b,c,d,e,h,l]

LDREGHL         macro   opcode,reg

comp&opcode:
                inc     edi
                mov     ecx,regehl
                READMEM
                mov     reg,al
                sub     ebp,7+2

                endm

; --------------------------------------------------------------------
; LDREGWIMM - LD rr,dddd rr=[bc,de,hl,sp]

LDREGWIMM       macro   opcode,reg

comp&opcode:
                FETCHW1 opcode
                add     edi,3
                mov     reg,eax
                xor     eax,eax
                sub     ebp,10+3

                endm

; --------------------------------------------------------------------
; LDREGIMM - LD rr,dd rr=[a,b,c,d,e,h,l]

LDREGIMM        macro   opcode,reg

comp&opcode:
                FETCH1  opcode
                add     edi,2
                mov     reg,al
                sub     ebp,7+2

                endm

; --------------------------------------------------------------------
; LDREGIIDD - LD rr,(II+dd)     rr=[a,b,c,d,e,h,l]

LDREGIIDD       macro   opcode,reg,regii

comp&opcode:
                FETCH1  opcode        
                add     edi,2
                movsx   ebx,al
                mov     ecx,regii
                add     cx,bx
                READMEM
                mov     reg,al
                sub     ebp,19+4

                endm

; --------------------------------------------------------------------
; LDHLREG - LD (HL),rr rr=[a,b,c,d,e,h,l]

LDHLREG         macro   opcode,reg

comp&opcode:
                inc     edi
                mov     al,reg
                mov     ecx,regehl
                sub     ebp,7+2
                WRITEMEM                

                endm

; --------------------------------------------------------------------
; LDSPREGW - LD SP,rr rr=[hl,ix,iy]

LDSPREGW        macro   opcode,reg

comp&opcode:
                inc     edi
                mov     ebx,reg
                mov     regesp,ebx
                sub     ebp,6+1

                endm

; --------------------------------------------------------------------
; LDREGWA - LD (rr),A rr=[bc,de,hl]

LDREGWA         macro   opcode,reg

comp&opcode:
                inc     edi
                mov     ecx,reg
                mov     al,dh
                WRITEMEM
                sub     ebp,7+2

                endm

; --------------------------------------------------------------------
; LDINDA - LD (dddd),A

LDINDA          macro   opcode,reg

comp&opcode:
                ;FETCHW1 opcode
                ;mov     ecx,eax

                mov     ecx,0
                mov     al,dh
                WRITEMEM
                add     edi,3
                ;mov     eax,0
                sub     ebp,13+4

                endm

; --------------------------------------------------------------------
; LDAIND - LD A,(dddd)

LDAIND          macro   opcode,reg

comp&opcode:
                ;FETCHW1 opcode
                ;mov     ecx,eax

                mov     ecx,0
                READMEM
                mov     dh,al
                ;xor     eax,eax
                add     edi,3
                sub     ebp,13+4

                endm

; --------------------------------------------------------------------
; LDAREGW - LD A,(rr) rr=[bc,de,hl]

LDAREGW         macro   opcode,reg

comp&opcode:
                inc     edi
                mov     ecx,reg
                READMEM
                mov     dh,al
                sub     ebp,7+2

                endm

; --------------------------------------------------------------------
; LDIIDDREG - LD (II+dd),rr     rr=[a,b,c,d,e,h,l]

LDIIDDREG       macro   opcode,reg,itype

comp&opcode:
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,itype
                add     edi,2
                add     cx,bx
                mov     al,reg
                WRITEMEM
                sub     ebp,19+4

                endm

; --------------------------------------------------------------------
; LDHLIMM - LD (HL),dd

LDHLIMM         macro   opcode

comp&opcode:
                FETCH1  opcode
                add     edi,2
                mov     ecx,regehl
                sub     ebp,10+3
                WRITEMEM

                endm

; --------------------------------------------------------------------
; LDREGWDDDD - LD rr,(dddd)     rr=[hl]

LDREGWDDDD       macro   opcode,reg

comp&opcode:
                ;FETCHW1 opcode
                ;mov     ecx,eax

                mov     ecx,0
                READMEMW
                mov     reg,eax
                add     edi,3
                xor     eax,eax
                sub     ebp,16+5

                endm

; --------------------------------------------------------------------
; LDREGWDDDD2 - LD rr,(dddd)     rr=[bc,de,sp,ix,iy]

LDREGWDDDD2      macro   opcode,reg

comp&opcode:
                ;FETCHW1 opcode
                ;mov     ecx,eax

                mov     ecx,0
                READMEMW
                mov     reg,eax
                add     edi,4
                xor     eax,eax
                sub     ebp,16+5

                endm

; --------------------------------------------------------------------
; LDDDDDREGW - LD (dddd),rr     rr=[hl]

LDDDDDREGW      macro   opcode,reg

comp&opcode:
                ;FETCHW1 opcode
                mov     ecx,0
                add     edi,3
                ;mov     ecx,eax
                mov     eax,reg
                WRITEMEMW
                xor     eax,eax
                sub     ebp,16+5

                endm

; --------------------------------------------------------------------
; LDDDDDREGW2 - LD (dddd),rr     rr=[bc,de,ix,iy,sp]

LDDDDDREGW2     macro   opcode,reg

comp&opcode:
                ;FETCHW1 opcode
                mov     ecx,0
                add     edi,4
                ;mov     ecx,eax
                mov     eax,reg
                WRITEMEMW
                xor     eax,eax
                sub     ebp,16+5

                endm

; --------------------------------------------------------------------
; LDIIDDNN - LD (II+dd),nn     rr=[a,b,c,d,e,h,l]

LDIIDDNN        macro   opcode,itype

comp&opcode:
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,itype
                add     cx,bx
                add     edi,2
                mov     ecx,edi
                READMEM
                inc     edi
                WRITEMEM
                sub     ebp,19+5

                endm

; --------------------------------------------------------------------
; LDAI - LD A,I

LDAI            macro   opcode

comp&opcode:    
                add     edi,2
                mov     dh,regi
                sub     ebp,9+2
                mov     al,dh
                and     dl,1
                mov     bl,byte ptr [offset iff1]
                shl     bl,2
                or      dl,[offset INTERRUPT_table+eax]
                or      dl,bl

                endm

; --------------------------------------------------------------------
; LDAR - LD A,R

LDAR            macro   opcode

comp&opcode:    
                add     edi,2
                mov     dh,byte ptr [offset rcounter]
                and     dh,07fh
                or      dh,rmask
                sub     ebp,9+2
                mov     al,dh
                and     dl,1
                mov     bl,byte ptr [offset iff1]
                shl     bl,2
                or      dl,[offset INTERRUPT_table+eax]
                or      dl,bl
                
                endm

; --------------------------------------------------------------------
; LDD

OPLDD           macro   opcode

comp&opcode:    
                add     edi,2
                mov     ecx,regehl                      ; clock 1 U
                READMEM
                mov     ecx,regede                      ; clock 2 U
                WRITEMEM
                sub     ebp,16+4                        ; clock 3 U
                dec     regde                           ; clock 3 V
                dec     reghl                           ; clock 4 U
                add     al,dh                           ; clock 5 U
                and     dl,11000001b                    ; clock 5 V
                dec     regbc                           ; clock 6 U
                jz      comp&opcode&a                   ; clock 6 V
                or      dl,[offset PVS53_table+eax]     ; clock 7 U
                jmp     comp&opcode&b
comp&opcode&a:
                or      dl,[offset PVN53_table+eax]     ; clock 7 U
comp&opcode&b:

                endm

; --------------------------------------------------------------------
; OPLDDR - LDDR

OPLDDR          macro   opcode

comp&opcode:    
                add     edi,2
comp&opcode&a:      
                mov     ecx,regehl
                READMEM
                mov     ecx,regede
                WRITEMEM
                sub     ebp,21+2
                dec     reghl
                dec     regde
                dec     regbc
                jnz     comp&opcode&a
                add     ebp,5-2

                endm

; --------------------------------------------------------------------
; LDI

OPLDI           macro   opcode

comp&opcode:    
                add     edi,2                        
                mov     ecx,regehl                      ; clock 1 U
                READMEM
                mov     ecx,regede                      ; clock 2 U
                WRITEMEM
                sub     ebp,16+4                        ; clock 3 U
                inc     regde                           ; clock 3 V
                inc     reghl                           ; clock 4 U
                add     al,dh                           ; clock 5 U
                and     dl,11000001b                    ; clock 5 V
                dec     regbc                           ; clock 6 U
                jz      comp&opcode&a                   ; clock 6 V
                or      dl,[offset PVS53_table+eax]     ; clock 7 U
                jmp     comp&opcode&b
comp&opcode&a:
                or      dl,[offset PVN53_table+eax]     ; clock 7 U
comp&opcode&b:

                endm

; --------------------------------------------------------------------
; OPLDIR - LDIR

OPLDIR          macro   opcode

comp&opcode:    
                add     edi,2
comp&opcode&a:      
                mov     ecx,regehl
                READMEM
                mov     ecx,regede
                WRITEMEM
                sub     ebp,21+2
                inc     reghl
                inc     regde
                dec     regbc
                jnz     comp&opcode&a
                add     ebp,5-2

                endm

; --------------------------------------------------------------------
; NEG

OPNEG           macro   opcode

comp&opcode:    
                mov     al,dh                           
                add     edi,2
                sub     ebp,8+2
                mov     dx,[offset NEG_table+eax*2]

                endm

; --------------------------------------------------------------------
; NOP

OPNOP           macro   opcode

comp&opcode:    
                inc     edi
                sub     ebp,4+1

                endm

; --------------------------------------------------------------------
; ORREG - OR rr rr=[a,b,c,d,e,h,l]

ORREG           macro   opcode,reg

comp&opcode:                
                or      dh,reg
                inc     edi
                mov     al,dh
                sub     ebp,4+1
                mov     dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; ORHL - OR (HL)

ORHL            macro   opcode

comp&opcode:                
                mov     ecx,regehl
                READMEM
                or      dh,al
                mov     al,dh
                inc     edi
                sub     ebp,7+2
                mov     dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; ORIMM - OR dd

ORIMM           macro   opcode

comp&opcode:                
                FETCH1  opcode
                or      dh,al
                add     edi,2
                mov     al,dh
                sub     ebp,7+2
                mov     dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; ORII - OR (II+dd)

ORII            macro   opcode,regii

comp&opcode:                
                FETCH1  opcode
                movsx   ebx,al
                mov     ecx,regii
                add     edi,2
                add     cx,bx
                READMEM
                or      dh,al
                sub     ebp,19+4
                mov     al,dh
                mov     dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; OUTIMM - OUT (dd),A

OUTIMM          macro   opcode

comp&opcode:    
                FETCH1  opcode
                add     edi,2
                mov     bl,dh
                sub     ebp,11+2
                call    [offset outportxx+eax*4]

                endm

; --------------------------------------------------------------------
; OUTCREG - OUT (C),rr

OUTCREG         macro   opcode,reg

comp&opcode:    mov     al,regc
                add     edi,2
                sub     ebp,12+2
                mov     bl,reg
                call    [offset outportxx+eax*4]

                endm

; --------------------------------------------------------------------
; OPOUTI - OUTI

OPOUTI          macro   opcode

comp&opcode:                
                add     edi,2
                mov     ecx,regehl
                READMEM
                mov     bl,al
                mov     al,regc
                call    [offset outportxx+eax*4]
                inc     reghl
                dec     regb
                and     dl,1
                mov     al,regb
                or      dl,[offset DEC_table+eax]
                sub     ebp,16+3

                endm

; --------------------------------------------------------------------
; POPREGW - POP rr rr=[bc,de,hl,af,ix,iy]

POPREGW         macro   opcode,reg

comp&opcode:                
                mov     ecx,regesp
                READMEMW
                add     ecx,2
                mov     reg,eax
                mov     regesp,ecx
                sub     ebp,10+3
                inc     edi
                xor     eax,eax

                endm

; --------------------------------------------------------------------
; PUSHREGW - PUSH rr rr=[bc,de,hl,af,ix,iy]

PUSHREGW        macro   opcode,reg

comp&opcode:                
                mov     ecx,regesp
                sub     ecx,2
                mov     eax,reg
                WRITEMEMW
                mov     regesp,ecx
                xor     eax,eax
                inc     edi
                sub     ebp,11+3

                endm

; --------------------------------------------------------------------
; RESREG - RES nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

RESREG          macro   opcode,reg,bit

comp&opcode:                
                add     edi,2
                and     reg,NBIT_&bit
                sub     ebp,8+2

                endm

; --------------------------------------------------------------------
; RESHL - RES nn,(HL)

RESHL           macro   opcode,bit

comp&opcode:                
                add     edi,2
                mov     ecx,regehl
                READMEM
                and     al,NBIT_&bit
                WRITEMEM
                sub     ebp,15+4

                endm

; --------------------------------------------------------------------
; RESII - RES nn,(II+dd)

RESII          macro   opcode,bit,regii

comp&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                READMEM
                and     al,NBIT_&bit
                WRITEMEM
                sub     ebp,23+6

                endm

; --------------------------------------------------------------------
; OPRET - RET

OPRET           macro   opcode

comp&opcode:                
                mov     ecx,regesp
                READMEMW
                add     ecx,2
                mov     edi,eax
                mov     regesp,ecx
                mov     eax,0
                sub     ebp,10+3

                endm

; --------------------------------------------------------------------
; RETCC - RET cc  cc=[Z,NZ,PO,PE,C,NC,P,M]

RETCC           macro   opcode,flagtype,jcc

comp&opcode:                
                inc     edi
                test    dl,flagtype
                jcc     comp&opcode&a
                sub     ebp,5+1
                jmp     comp&opcode&b
comp&opcode&a:
                OPRET   opcode&XX
comp&opcode&b:

                endm

; --------------------------------------------------------------------
; RLREG - RL rr rr=[a,b,c,d,e,h,l]

RLREG           macro   opcode,reg

comp&opcode:                
                add     edi,2
                shr     dl,1
                mov     dl,0
                rcl     reg,1
                mov     al,reg
                adc     dl,dl
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; RLHL - RL (HL)

RLHL            macro   opcode

comp&opcode:                
                add     edi,2
                mov     ecx,regehl
                READMEM
                shr     dl,1
                mov     dl,0
                rcl     al,1
                adc     dl,dl
                WRITEMEM
                sub     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; RLII - RL (II+dd)

RLII            macro   opcode,regii

comp&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regehl
                add     cx,bx
                READMEM
                shr     dl,1
                mov     dl,0
                rcl     al,1
                adc     dl,dl
                WRITEMEM
                sub     ebp,23+6
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; OPRLA - RLA

OPRLA           macro   opcode

comp&opcode:                
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

                endm

; --------------------------------------------------------------------
; RLCREG - RLC rr rr=[a,b,c,d,e,h,l]

RLCREG          macro opcode,reg

comp&opcode:                
                add     edi,2
                rol     reg,1
                mov     dl,reg
                mov     al,dl
                and     dl,1
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; RLCHL - RLC (HL)

RLCHL           macro opcode

comp&opcode:                
                add     edi,2
                mov     ecx,regehl
                READMEM
                rol     al,1
                WRITEMEM
                mov     dl,al
                and     dl,1
                sub     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; RLCII - RLC (II+dd)

RLCII           macro opcode,regii

comp&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                READMEM
                rol     al,1
                WRITEMEM
                mov     dl,al
                and     dl,1
                sub     ebp,23+6
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; OPRLCA - RLCA

OPRLCA          macro opcode

comp&opcode:                
                inc     edi
                and     dl,11000100b
                rol     dh,1
                mov     bl,dh
                mov     al,bl
                and     bl,1
                or      dl,bl
                sub     ebp,4+1
                or      dl,[offset PVN53_table+eax]

                endm

; --------------------------------------------------------------------
; OPRLD - RLD

OPRLD           macro   opcode

comp&opcode:
                add     edi,2
                mov     ecx,regehl                    
                READMEM
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
                WRITEMEM
                mov     al,dh
                and     dl,1
                sub     ebp,18+4
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; RRREG - RR rr rr=[a,b,c,d,e,h,l]

RRREG           macro   opcode,reg

comp&opcode:                
                add     edi,2
                shr     dl,1
                mov     dl,reg
                rcr     reg,1
                and     dl,1
                mov     al,reg
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; RRHL - RR (HL)

RRHL            macro   opcode

comp&opcode:                
                add     edi,2
                mov     ecx,regehl
                READMEM
                shr     dl,1
                mov     dl,al
                rcr     al,1
                and     dl,1
                WRITEMEM
                sub     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; RRII - RR (II+dd)

RRII            macro   opcode,regii

comp&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                READMEM
                shr     dl,1
                mov     dl,al
                rcr     al,1
                and     dl,1
                WRITEMEM
                sub     ebp,23+6
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; OPRRA - RRA

OPRRA           macro   opcode

comp&opcode:                
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

                endm

; --------------------------------------------------------------------
; RRCREG - RRC rr rr=[a,b,c,d,e,h,l]

RRCREG          macro opcode,reg

comp&opcode:                
                add     edi,2
                mov     dl,reg
                ror     reg,1
                mov     al,reg
                and     dl,1
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; RRCHL - RRC (HL)

RRCHL           macro opcode

comp&opcode:                
                add     edi,2
                mov     ecx,regehl
                READMEM
                mov     dl,al
                ror     al,1
                WRITEMEM
                and     dl,1
                sub     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; OPRRCA - RRCA

OPRRCA          macro   opcode

comp&opcode:                
                inc     edi
                mov     bl,dh
                and     dl,11000100b
                ror     dh,1
                mov     al,dh
                and     bl,1
                or      dl,bl
                sub     ebp,4+1
                or      dl,[offset PVN53_table+eax]

                endm

; --------------------------------------------------------------------
; OPRRD - RRD

OPRRD           macro   opcode

comp&opcode:
                add     edi,2
                mov     ecx,regehl                    
                READMEM
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
                WRITEMEM
                mov     al,dh
                and     dl,1
                sub     ebp,18+4
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; OPRST - RST dd

OPRST           macro   opcode,addr

comp&opcode:                
                mov     ecx,regesp
                lea     eax,[edi+1]
                sub     ecx,2
                WRITEMEMW
                mov     regesp,ecx
                mov     edi,addr
                xor     eax,eax
                sub     ebp,7+3

                endm

; --------------------------------------------------------------------
; SBCREG - SBC A,rr rr=[a,b,c,d,e,h,l]

SBCREG          macro   opcode,reg

comp&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                sub     ebp,4+1
                GENERIC_SBC

                endm

; --------------------------------------------------------------------
; SBCAHL - SBC A,(HL)

SBCAHL          macro   opcode

comp&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                READMEM
                mov     bh,al
                sub     ebp,7+2
                GENERIC_SBC

                endm

; --------------------------------------------------------------------
; SBCIMM - SBC A,dd

SBCIMM          macro   opcode

comp&opcode:                
                FETCH1  opcode
                add     edi,2
                mov     bh,al
                sub     ebp,7+2
                GENERIC_SBC

                endm

; --------------------------------------------------------------------
; SBCAII - SBC A,(II+dd)

SBCAII          macro   opcode,regii

comp&opcode:                
                FETCH1  opcode
                add     edi,2
                movsx   ebx,al
                mov     ecx,regii
                add     cx,bx
                READMEM
                mov     bh,al
                sub     ebp,19+4
                GENERIC_SBC

                endm

; --------------------------------------------------------------------
; SBC HL,regw   regw=[bc,de,hl,sp]

SBCHLWREG       macro   opcode,reglow,reghigh

comp&opcode:                
                add     edi,2
                shr     dl,1
                mov     bl,reglow
                sbb     regl,bl
                mov     bh,regh
                mov     bl,reghigh
                mov     cl,0
                sbb     regh,bl
                adc     cl,cl
                sub     ebp,15+1
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
                jnz     comp&opcode&a
                or      dl,BIT_6
comp&opcode&a:

                endm

; --------------------------------------------------------------------
; OPSCF - SCF

OPSCF           macro   opcode

comp&opcode:                
                inc     edi
                or      dl,1
                and     dl,11101101b
                sub     ebp,4+1

                endm

; --------------------------------------------------------------------
; SETREG - SET nn,rr nn=[0..7] rr=[a,b,c,d,e,h,l]

SETREG          macro   opcode,reg,bit

comp&opcode:                
                add     edi,2
                or      reg,BIT_&bit
                sub     ebp,8+2

                endm

; --------------------------------------------------------------------
; SETHL - SET nn,(HL)

SETHL          macro   opcode,bit

comp&opcode:                
                add     edi,2
                mov     ecx,regehl
                READMEM
                or      al,BIT_&bit
                WRITEMEM
                sub     ebp,15+4

                endm

; --------------------------------------------------------------------
; SETII - SET nn,(II+dd)

SETII          macro   opcode,bit,regii

comp&opcode:                
                inc     edi
                movsx   ebx,cl
                mov     ecx,regii
                add     cx,bx
                READMEM
                or      al,BIT_&bit
                WRITEMEM
                sub     ebp,23+6

                endm

; --------------------------------------------------------------------
; SLAREG - SLA rr rr=[a,b,c,d,e,h,l]

SLAREG          macro   opcode,reg

comp&opcode:
                add     edi,2
                mov     dl,0
                shl     reg,1
                adc     dl,dl
                sub     ebp,8+2
                mov     al,reg
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; SLAHL - SLA (HL)

SLAHL           macro   opcode

comp&opcode:
                add     edi,2
                mov     ecx,regehl
                READMEM
                mov     dl,0
                shl     al,1
                adc     dl,dl
                sub     ebp,15+4
                WRITEMEM
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; SRAREG - SRA rr rr=[a,b,c,d,e,h,l]

SRAREG          macro   opcode,reg

comp&opcode:                
                add     edi,2
                mov     dl,reg
                sar     reg,1
                and     dl,1
                mov     al,reg
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; SRAHL - SRA (HL)

SRAHL           macro   opcode

comp&opcode:                
                add     edi,2
                mov     ecx,regehl
                READMEM
                mov     dl,al
                sar     al,1
                and     dl,1
                WRITEMEM
                sub     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; SRLREG - SRL rr rr=[a,b,c,d,e,h,l]

SRLREG          macro   opcode,reg

comp&opcode:                
                add     edi,2
                mov     dl,reg
                shr     reg,1
                and     dl,1
                mov     al,reg
                sub     ebp,8+2
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; SRLHL - SRL (HL)

SRLHL           macro   opcode

comp&opcode:                
                add     edi,2
                mov     ecx,regehl
                READMEM
                mov     dl,al
                shr     al,1
                and     dl,1
                WRITEMEM
                sub     ebp,15+4
                or      dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; SUBREG - SUB rr rr=[a,b,c,d,e,h,l]

SUBREG          macro   opcode,reg

comp&opcode:                
                inc     edi                             ; clock 1 U
                mov     bh,reg                          ; clock 1 V
                sub     ebp,4+1
                GENERIC_SUB

                endm

; --------------------------------------------------------------------
; SUBAHL - SUB (HL)

SUBAHL          macro   opcode

comp&opcode:                
                inc     edi                             ; clock 1 U
                mov     ecx,regehl
                READMEM
                mov     bh,al
                sub     ebp,7+2
                GENERIC_SUB

                endm

; --------------------------------------------------------------------
; SUBIMM - SUB dd

SUBIMM          macro   opcode

comp&opcode:                
                FETCH1  opcode
                add     edi,2
                mov     bh,al
                sub     ebp,7+2
                GENERIC_SUB

                endm

; --------------------------------------------------------------------
; SUBII - SUB (II+dd)

SUBII           macro   opcode,itype

comp&opcode:                
                FETCH1  opcode
                mov     ecx,itype
                movsx   ebx,al
                add     edi,2
                add     cx,bx
                READMEM
                mov     bh,al
                sub     ebp,19+4
                GENERIC_SUB

                endm

; --------------------------------------------------------------------
; XORREG - XOR rr rr=[a,b,c,d,e,h,l]

XORREG          macro   opcode,reg

comp&opcode:                
                inc     edi
                xor     dh,reg
                mov     al,dh
                sub     ebp,4+1
                mov     dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; XORHL - XOR (HL)

XORHL           macro   opcode

comp&opcode:                
                inc     edi
                mov     ecx,regehl
                READMEM
                xor     dh,al
                mov     al,dh
                sub     ebp,7+2
                mov     dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; XORIMM - XOR dd

XORIMM          macro   opcode

comp&opcode:                
                FETCH1  opcode
                add     edi,2
                xor     dh,al
                mov     al,dh
                sub     ebp,7+2
                mov     dl,[offset LOGICAL_table+eax]

                endm

; --------------------------------------------------------------------
; XORII - XOR (II+dd)

XORII           macro   opcode,regii

comp&opcode:                
                FETCH1  opcode
                add     edi,2
                movsx   ebx,al
                mov     ecx,regii
                add     cx,bx
                READMEM
                xor     dh,al
                mov     al,dh
                sub     ebp,19+4
                mov     dl,[offset LOGICAL_table+eax]

                endm

