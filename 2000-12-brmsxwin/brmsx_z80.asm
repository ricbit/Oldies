	.686
	.MODEL	FLAT
       	.DATA

align 4

_regaf           dw      00h
                dw      00h
_regbc           dw      11h
                dw      00h
_regde           dw      22h
                dw      00h
_reghl           dw      33h
                dw      00h
_regix           dw      00h
                dw      00h
_regiy           dw      00h
                dw      00h
_regpc          dw      00h
                dw      00h
_regsp           dw      0fff0h
                dw      00h
_regafl          dw      00h
                dw      00h
_regbcl          dw      00h
                dw      00h
_regdel          dw      00h
                dw      00h
_reghll          dw      00h
                dw      00h

_z80speed       dd      124
clocksleft      dd      0              
rcounter        dd      0
_iff1           dd      0
imtype          dd      0
_breakpoint      dd      10000h
_stopped         dd      0
regi            db      0
rmask           db      0
prim_slotreg    db      0

rega            equ     byte ptr [offset _regaf+1]
regf            equ     byte ptr [offset _regaf+0]
regb            equ     byte ptr [offset _regbc+1]
regc            equ     byte ptr [offset _regbc+0]
regd            equ     byte ptr [offset _regde+1]
rege            equ     byte ptr [offset _regde+0]
regh            equ     byte ptr [offset _reghl+1]
regl            equ     byte ptr [offset _reghl+0]
_regixh          equ     byte ptr [offset _regix+1]
_regixl          equ     byte ptr [offset _regix+0]
_regiyh          equ     byte ptr [offset _regiy+1]
_regiyl          equ     byte ptr [offset _regiy+0]
_regsph          equ     byte ptr [offset _regsp+1]
_regspl          equ     byte ptr [offset _regsp+0]

regeaf          equ     dword ptr [offset _regaf]
regebc          equ     dword ptr [offset _regbc]
regede          equ     dword ptr [offset _regde]
regehl          equ     dword ptr [offset _reghl]
regeix          equ     dword ptr [offset _regix]
regeiy          equ     dword ptr [offset _regiy]
regepc          equ     dword ptr [offset _regpc]
regesp          equ     dword ptr [offset _regsp]
regeafl         equ     dword ptr [offset _regafl]
regebcl         equ     dword ptr [offset _regbcl]
regedel         equ     dword ptr [offset _regdel]
regehll         equ     dword ptr [offset _reghll]

_mem:
                dd      idlerom
                dd      idlerom
                dd      idlerom
                dd      idlerom
                dd      idlerom
                dd      idlerom
                dd      idlerom
                dd      idlerom

_memlock:
                dd      1
                dd      1
                dd      1
                dd      1
                dd      1
                dd      1
                dd      1
                dd      1

; --------------------------------------------------------------------

_slot:
slot0:
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
slot1:
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
slot2:
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
slot3:
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1
                dd      idlerom
                dd      1

_idlerom        dd      offset idlerom                
idlerom:       db      8192 dup(255)


        .CODE

extrn _inemul98: near
extrn _inemul99: near
extrn _inemulA9: near
extrn _inemulD0: near
extrn _inemulD1: near
extrn _inemulD2: near
extrn _inemulD3: near
extrn _inemulD4: near
extrn _outemulD0: near
extrn _outemulD1: near
extrn _outemulD2: near
extrn _outemulD3: near
extrn _outemulD4: near
extrn _outemul98: near
extrn _outemul99: near
extrn _outemulAA: near
extrn _Value: byte

include bit.inc
include bit0.inc
include bit1.inc
include bit2.inc
include bit3.inc
include bit4.inc
include bit5.inc
include bit6.inc
include bit7.inc
include inc.inc
include dec.inc
include pvn53.inc
include pvs53.inc
include daa.inc
include daas.inc
include cpl.inc
include aritn.inc
include aritp.inc
include overflow.inc
include cp.inc
include logical.inc
include neg.inc
include int.inc
include ldi.inc
include flags.inc

include iset.inc
include isetcb.inc
include iseted.inc
include isetdd.inc
include isetfd.inc
include isetddcb.inc
include isetfdcb.inc
include outport.inc
include inport.inc

include fetch.inc
include z80supp.inc
include opcode.inc

public _runZ80
public _regpc
public _regaf
public _regbc
public _regde
public _reghl
public _regsp
public _regix
public _regiy
public _mem
public _memlock
public _slot
public _readmem_asm
public _z80_interrupt
public _iff1
public _resetZ80
public _idlerom
public _stepZ80
public _breakpoint
public _stopped
public _z80speed

; --------------------------------------------------------------------

_runZ80:
                pushad
                xor     eax,eax
                xor     ecx,ecx
                mov     ebp,clocksleft
                add     ebp,_z80speed
                mov     edi,regepc
                mov     edx,regeaf
                mov     _stopped,eax
runZ80_loop:
                and     edi,0FFFFh
                cmp     edi,_breakpoint
                je      runZ80_break

                call    fetch
                inc     rcounter
                call    [offset iset + eax*4]

                cmp     ebp,0
                jg      runZ80_loop

                mov     _regpc,di
                mov     _regaf,dx
                mov     clocksleft,ebp
                popad
                ret

runZ80_break:
                mov     _regpc,di
                mov     _regaf,dx
                mov     clocksleft,ebp
                mov     _stopped,1
                popad
                ret

; --------------------------------------------------------------------

_stepZ80:
                pushad
                xor     eax,eax
                xor     ecx,ecx
                mov     ebp,clocksleft
                mov     edi,regepc
                mov     edx,regeaf

                and     edi,0FFFFh
                call    fetch
                inc     rcounter
                call    [offset iset + eax*4]

                mov     _regpc,di
                mov     _regaf,dx
                mov     clocksleft,ebp
                popad
                ret

; --------------------------------------------------------------------

_resetZ80:
                pushad
                mov     regeaf,0
                mov     regebc,0
                mov     regede,0
                mov     regehl,0
                mov     regepc,0
                mov     regeix,0
                mov     regeiy,0
                mov     regesp,0FFFFh
                mov     bl,0
                call    _outemulA8
                popad
                ret

; --------------------------------------------------------------------

; byte to be inputed returns in bl register

inemulXX:       mov     _Value,0FFh
                ret

; --------------------------------------------------------------------

; byte to be outputed must be in bl register

outemulXX:      ret

; fetch --------------------------------------------------------------
; fetch a byte from Z80 memory
; in, edi: address
; out, al: byte
; affect: esi,ebx

fetch:
                push    ecx
                mov     ecx,edi
                call    readmem
                pop     ecx
                ret

; fetch1 -------------------------------------------------------------
; fetch the next byte from Z80 memory
; in, edi: (address-1)
; out, al: byte
; affect: esi,ebx

fetch1:
                push    ecx
                mov     ecx,edi
                inc     ecx
                call    readmem
                pop     ecx
                ret

; fetchw -------------------------------------------------------------
; fetch a word from Z80 memory
; in, edi: address
; out, ax: word
; affect: esi,ebx

fetchw:
                push    ecx
                mov     ecx,edi
                call    readmem
                mov     ah,al
                inc     ecx
                call    readmem
                xchg    ah,al
                pop     ecx
                ret

; fetchw1 ------------------------------------------------------------
; fetch the next word from Z80 memory
; in, edi: (address-1)
; out, ax: word
; affect: esi,ebx

fetchw1:
                push    ecx
                mov     ecx,edi
                inc     ecx
                call    readmem
                mov     ah,al
                inc     ecx
                call    readmem
                xchg    ah,al
                pop     ecx
                ret

_inemulA8:       mov     bl,prim_slotreg
                 mov     _Value,bl
                 ret
_outemulA8:
                ;movzx   esi,prim_slotreg
                mov     prim_slotreg,bl

                irp     i,<0,1,2,3>
                mov     bl,prim_slotreg
                shr     bl,i*2
                and     ebx,03h
                shl     ebx,6

                irp     j,<0,1>
                mov     ecx,dword ptr [offset _slot+ebx+16*i+8*j]
                mov     dword ptr [offset _mem+(i*2+j)*4],ecx
                mov     ecx,dword ptr [offset _slot+ebx+16*i+8*j+4]
                mov     dword ptr [offset _memlock+(i*2+j)*4],ecx
                endm

                endm

                ret



; readmem ------------------------------------------------------------
; read a byte from Z80 memory
; in, ecx: address
; out, al: byte
; affect: esi,ebx

_readmem_asm:
readmem:        mov     esi,ecx
                mov     ebx,ecx
                shr     esi,13
                and     ebx,01fffh
                mov     esi,[offset _mem+esi*4]
                mov     al,byte ptr [esi+ebx]
                ret

; readmemw -----------------------------------------------------------
; read a word from Z80 memory
; in, ecx: address
; out, ax: word
; affect: esi,ebx

readmemw:
                inc     ecx
                call    readmem
                dec     ecx
                mov     ah,al
                jmp     readmem

; writemem -----------------------------------------------------------
; write a byte to Z80 memory
; in, ecx: address
; in, al: byte
; affect: esi,ebx

writemem:
                mov     esi,ecx
                shr     esi,13
                ; lock
                cmp     dword ptr [offset _memlock+esi*4],0
                jne     writemem0
                ;
                mov     ebx,ecx
                and     ebx,01fffh
                mov     esi,[offset _mem+esi*4]
                mov     byte ptr [esi+ebx],al
                ret
writemem0:

                ret



; writememw ----------------------------------------------------------
; write a word to Z80 memory
; in, ecx: address
; in, ax: word
; affect: esi,ebx

writememw:
                push    eax ecx
                mov     ah,0
                call    writemem
                pop     ecx eax
                shr     eax,8
                inc     ecx
                call    writemem
                dec     ecx
                ret

_z80_interrupt:
                pushad
                xor     eax,eax
                xor     ecx,ecx
                mov     ebp,clocksleft
                ;add     ebp,124
                mov     edi,regepc
                mov     edx,regeaf

                cmp     imtype,2
                je      z80_interrupt_im2

                ; IM 0 and IM 1
                call    emulIM
                mov     edi,038h
                mov     _regpc,di
                mov     _regaf,dx
                mov     clocksleft,ebp
                popad
                ret

z80_interrupt_im2:
                ; IM 2
                call    emulIM
                mov     ch,regi
                mov     cl,0FFh
                call    readmemw
                mov     edi,eax
                mov     eax,0
                mov     _regpc,di
                mov     _regaf,dx
                mov     clocksleft,ebp
                popad
                ret

PUSHREGW        IM,edi,0


; 00 - NOP
OPNOP           00

; 01 - LD BC,dddd
LDREGWIMM       01,regebc

; 02 - LD (BC),A
LDREGWA         02,regebc

; 03 - INC BC
INCWREG         03,_regbc,6+1

; 04 - INC B
INCREG          04,regb

; 05 - DEC B
DECREG          05,regb

; 06 - LD B,dd
LDREGIMM        06,regb

; 07 - RLCA
OPRLCA          07

; 08 - EX AF,AF'
OPEXAFAF        08

; 09 - ADD HL,BC
ADDREGWREGW     09,regl,regh,regc,regb,11+1

; 0A - LD A,(BC)
LDAREGW         0A,regebc

; 0B - DEC BC
DECWREG         0B,_regbc,6+1

; 0C - INC C
INCREG          0C,regc

; 0D - DEC C
DECREG          0D,regc

; 0E - LD C,dd
LDREGIMM        0E,regc

; 0F - RRCA
OPRRCA          0F      

; 10 - DJNZ dd
OPDJNZ          10

; 11 - LD DE,dddd
LDREGWIMM       11,regede

; 12 - LD (DE),A
LDREGWA         12,regede

; 13 - INC DE
INCWREG         13,_regde,6+1

; 14 - INC D
INCREG          14,regd

; 15 - DEC D
DECREG          15,regd

; 16 - LD D,dd
LDREGIMM        16,regd

; 17 - RLA
OPRLA           17

; 18 - JR dd
OPJR            18

; 19 - ADD HL,DE
ADDREGWREGW     19,regl,regh,rege,regd,11+1

; 1A - LD A,(DE)
LDAREGW         1A,regede

; 1B - DEC DE
DECWREG         1B,_regde,6+1

; 1C - INC E
INCREG          1C,rege

; 1D - DEC E
DECREG          1D,rege

; 1E - LD E,dd
LDREGIMM        1E,rege

; 1F - RRA
OPRRA           1F

; 20 - JR NZ,dd           
JRCC            20,jnz,ZERO_FLAG

; 21 - LD HL,dddd
LDREGWIMM      21,regehl

; 22 - LD (dddd),HL
LDDDDDREGW      22,regehl,16+1

; 23 - INC HL
INCWREG         23,_reghl,6+1

; 24 - INC H
INCREG          24,regh

; 25 - DEC H
DECREG          25,regh

; 26 - LD H,dd
LDREGIMM        26,regh

; 27 - DAA
OPDAA           27

; 28 - JR Z,dd
JRCC            28,jz,ZERO_FLAG

; 29 - ADD HL,HL
ADDREGWREGW     29,regl,regh,regl,regh,11+1

; 2A - LD HL,(dddd)
LDREGWDDDD      2A,regehl,16+1

; 2B - DEC HL
DECWREG         2B,_reghl,6+1

; 2C - INC L
INCREG          2C,regl

; 2D - DEC L
DECREG          2D,regl

; 2E - LD L,dd
LDREGIMM        2E,regl

; 2F - CPL
OPCPL           2F

; 30 - JR NC,dd
JRCC            30,jnz,CARRY_FLAG

; 31 - LD SP,dddd
LDREGWIMM      31,regesp

; 32 - LD (dddd),A
LDINDA          32

; 33 - INC SP
INCWREG         33,_regsp,6+1

; 34 - INC (HL)
INCHL           34

; 35 - DEC (HL)
DECHL           35

; 36 - LD (HL),dd
LDHLIMM         36

; 37 - SCF
OPSCF           37

; 38 - JR C,dd
JRCC            38,jz,CARRY_FLAG

; 39 - ADD HL,SP
ADDREGWREGW     39,regl,regh,_regspl,_regsph,11+1

; 3A - LD A,(dddd)
LDAIND          3A

; 3B - DEC SP
DECWREG         3B,_regsp,6+1

; 3C - INC A
INCREG          3C,dh

; 3D - DEC A                      
DECREG          3D,dh

; 3E - LD A,dd
LDREGIMM        3E,dh

; 3F - CCF
OPCCF           3F

; 40 - LD B,B
LDREGREG        40,regb,regb

; 41 - LD B,C
LDREGREG        41,regb,regc

; 42 - LD B,D
LDREGREG        42,regb,regd

; 43 - LD B,E
LDREGREG        43,regb,rege

; 44 - LD B,H
LDREGREG        44,regb,regh

; 45 - LD B,L
LDREGREG        45,regb,regl

; 46 - LD B,(HL)
LDREGHL         46,regb

; 47 - LD B,A
LDREGA          47,regb

; 48 - LD C,B
LDREGREG        48,regc,regb

; 49 - LD C,C
LDREGREG        49,regc,regc

; 4A - LD C,D
LDREGREG        4A,regc,regd

; 4B - LD C,E
LDREGREG        4B,regc,rege

; 4C - LD C,H
LDREGREG        4C,regc,regh

; 4D - LD C,L
LDREGREG        4D,regc,regl

; 4E - LD C,(HL)
LDREGHL         4E,regc

; 4F - LD C,A
LDREGA          4F,regc

; 50 - LD D,B
LDREGREG        50,regd,regb

; 51 - LD D,C
LDREGREG        51,regd,regc

; 52 - LD D,D
LDREGREG        52,regd,regd

; 53 - LD D,E
LDREGREG        53,regd,rege

; 54 - LD D,H
LDREGREG        54,regd,regh

; 55 - LD D,L
LDREGREG        55,regd,regl

; 56 - LD D,(HL)
LDREGHL         56,regd

; 57 - LD D,A
LDREGA          57,regd

; 58 - LD E,B
LDREGREG        58,rege,regb

; 59 - LD E,C
LDREGREG        59,rege,regc

; 5A - LD E,D
LDREGREG        5A,rege,regd

; 5B - LD E,E
LDREGREG        5B,rege,rege

; 5C - LD E,H
LDREGREG        5C,rege,regh

; 5D - LD E,L
LDREGREG        5D,rege,regl

; 5E - LD E,(HL)
LDREGHL         5E,rege

; 5F - LD E,A
LDREGA          5F,rege

; 60 - LD H,B
LDREGREG        60,regh,regb

; 61 - LD H,C
LDREGREG        61,regh,regc

; 62 - LD H,D
LDREGREG        62,regh,regd

; 63 - LD H,E
LDREGREG        63,regh,rege

; 64 - LD H,H
LDREGREG        64,regh,regh

; 65 - LD H,L
LDREGREG        65,regh,regl

; 66 - LD H,(HL)
LDREGHL         66,regh

; 67 - LD H,A
LDREGA          67,regh

; 68 - LD L,B
LDREGREG        68,regl,regb

; 69 - LD L,C
LDREGREG        69,regl,regc

; 6A - LD L,D
LDREGREG        6A,regl,regd

; 6B - LD L,E
LDREGREG        6B,regl,rege

; 6C - LD L,H
LDREGREG        6C,regl,regh

; 6D - LD L,L
LDREGREG        6D,regl,regl

; 6E - LD L,(HL)
LDREGHL         6E,regl

; 6F - LD L,A
LDREGA          6F,regl

; 70 - LD (HL),B
LDHLREG         70,regb

; 71 - LD (HL),C
LDHLREG         71,regc

; 72 - LD (HL),D
LDHLREG         72,regd

; 73 - LD (HL),E
LDHLREG         73,rege

; 74 - LD (HL),H
LDHLREG         74,regh

; 75 - LD (HL),L
LDHLREG         75,regl

; 76 - HALT
OPHALT          76
;OPHALT_MSX2     76_MSX2

; 77 - LD (HL),A
LDHLREG         77,dh

; 78 - LD A,B
LDAREG          78,regb

; 79 - LD A,C
LDAREG          79,regc

; 7A - LD A,D
LDAREG          7A,regd

; 7B - LD A,E
LDAREG          7B,rege

; 7C - LD A,H
LDAREG          7C,regh

; 7D - LD A,L
LDAREG          7D,regl
                              
; 7E - LD A,(HL)
LDREGHL         7E,dh

; 7F - LD A,A
LDAREG          7F,dh

; 80 - ADD A,B  
ADDREG          80,regb

; 81 - ADD A,C
ADDREG          81,regc

; 82 - ADD A,D
ADDREG          82,regd

; 83 - ADD A,E
ADDREG          83,rege

; 84 - ADD A,H
ADDREG          84,regh

; 85 - ADD A,L
ADDREG          85,regl

; 86 - ADD A,(HL)
ADDAHL          86

; 87 - ADD A,A
ADDREG          87,dh

; 88 - ADC A,B
ADCREG          88,regb

; 89 - ADC A,C
ADCREG          89,regc

; 8A - ADC A,D
ADCREG          8A,regd

; 8B - ADC A,E
ADCREG          8B,rege

; 8C - ADC A,H
ADCREG          8C,regh

; 8D - ADC A,L
ADCREG          8D,regl

; 8E - ADC A,(HL)
ADCAHL          8E

; 8F - ADC A,A
ADCREG          8F,dh

; 90 - SUB B
SUBREG          90,regb

; 91 - SUB C
SUBREG          91,regc

; 92 - SUB D
SUBREG          92,regd

; 93 - SUB E
SUBREG          93,rege

; 94 - SUB H
SUBREG          94,regh

; 95 - SUB L
SUBREG          95,regl

; 96 - SUB (HL)
SUBAHL          96

; 97 - SUB A
SUBREG          97,dh

; 98 - SBC A,B
SBCREG          98,regb

; 99 - SBC A,C
SBCREG          99,regc

; 9A - SBC A,D
SBCREG          9A,regd

; 9B - SBC A,E
SBCREG          9B,rege

; 9C - SBC A,H
SBCREG          9C,regh

; 9D - SBC A,L
SBCREG          9D,regl

; 9E - SBC A,(HL)
SBCAHL          9E

; 9F - SBC A,A
SBCREG          9F,dh

; A0 - AND B
ANDREG          A0,regb

; A1 - AND C
ANDREG          A1,regc

; A2 - AND D
ANDREG          A2,regd

; A3 - AND E
ANDREG          A3,rege

; A4 - AND H
ANDREG          A4,regh

; A5 - AND L
ANDREG          A5,regl

; A6 - AND (HL)
ANDHL           A6

; A7 - AND A
ANDREG          A7,dh

; A8 - XOR B
XORREG          A8,regb

; A9 - XOR C
XORREG          A9,regc

; AA - XOR D
XORREG          AA,regd

; AB - XOR E
XORREG          AB,rege

; AC - XOR H
XORREG          AC,regh

; AD - XOR L
XORREG          AD,regl

; AE - XOR (HL)
XORHL           AE

; AF - XOR A
XORREG          AF,dh
                
; B0 - OR B
ORREG           B0,regb

; B1 - OR C
ORREG           B1,regc

; B2 - OR D
ORREG           B2,regd

; B3 - OR E
ORREG           B3,rege

; B4 - OR H
ORREG           B4,regh

; B5 - OR L
ORREG           B5,regl

; B6 - OR (HL)
ORHL            B6

; B7 - OR A
ORREG           B7,dh

; B8 - CP B
CPREG           B8,regb

; B9 - CP C
CPREG           B9,regc

; BA - CP D
CPREG           BA,regd

; BB - CP E
CPREG           BB,rege

; BC - CP H
CPREG           BC,regh

; BD - CP L
CPREG           BD,regl

; BE - CP (HL)
CPAHL           BE

; BF - CP A
CPREG           BF,dh

; C0 - RET NZ
RETCC           C0,ZERO_FLAG,jz

; C1 - POP BC
POPREGW         C1,regebc,10+1

; C2 - JP NZ,dddd
JPCC            C2,jnz,ZERO_FLAG

; C3 - JP dddd
OPJP            C3

; C4 - CALL NZ,dddd
CALLCC          C4,ZERO_FLAG,jz

; C5 - PUSH BC
PUSHREGW        C5,regebc,11+1

; C6 - ADD A,dd
ADDIMM          C6

; C7 - RST 0
OPRST           C7,0

; C8 - RET Z
RETCC           C8,ZERO_FLAG,jnz

; C9 - RET
OPRET           C9

; CA - JP Z,dddd
JPCC            CA,jz,ZERO_FLAG

; CB - group CB
emulCB:         ;inc     edi
                ;inc     rcounter
                ;call    fetch
                ;jmp     [offset isetCBxx+eax*4]
               
;                cmp     ebx,01FFCh
;                jae     emulCB_slow
;
;                mov     al,[esi+ebx+1]
;                inc     edi
;                inc     rcounter
;                inc     ebx
;                jmp     [offset isetCBxx+eax*4]

emulCB_slow:
                inc     edi
                inc     rcounter
                call    fetch
                jmp     [offset isetCBxx+eax*4]

; CC - CALL Z,dddd
CALLCC          CC,ZERO_FLAG,jnz

; CD - CALL dddd
OPCALL          CD

; CE - ADC A,dd
ADCIMM          CE

; CF - RST 08
OPRST           CF,08h

; D0 - RET NC
RETCC           D0,CARRY_FLAG,jz

; D1 - POP DE
POPREGW         D1,regede,10+1

; D2 - JP NC,dddd
JPCC            D2,jnz,CARRY_FLAG

; D3 - OUT (dd),A
OUTIMM          D3

; D4 - CALL NC,dddd
CALLCC          D4,CARRY_FLAG,jz

; D5 - PUSH DE
PUSHREGW        D5,regede,11+1

; D6 - SUB dd
SUBIMM          D6

; D7 - RST 10
OPRST           D7,010h

; D8 - RET C
RETCC           D8,CARRY_FLAG,jnz

; D9 - EXX
OPEXX           D9

; DA - JP C,dddd
JPCC            DA,jz,CARRY_FLAG

; DB - IN A,(dd)
INADD           DB

; DC - CALL C,dddd 
CALLCC          DC,CARRY_FLAG,jnz

; DD - group DD
emulDD:         inc     edi
                inc     rcounter
                call    fetch
                jmp     [offset isetDDxx+eax*4]


; DE - SBC A,dd
SBCIMM          DE

; DF - RST 18
OPRST           DF,018h

; E0 - RET PO
RETCC           E0,PARITY_FLAG,jz

; E1 - POP HL
POPREGW         E1,regehl,10+1

; E2 - JP PO,dddd
JPCC            E2,jnz,PARITY_FLAG

; E3 - EX (SP),HL
OPEXSPREGW      E3,regehl,19+1

; E4 - CALL PO,dddd
CALLCC          E4,PARITY_FLAG,jz

; E5 - PUSH HL
PUSHREGW        E5,regehl,11+1

; E6 - AND dd
ANDIMM          E6

; E7 - RST 20
OPRST           E7,020h

; E8 - RET PE
RETCC           E8,PARITY_FLAG,jnz

; E9 - JP (HL)
OPJPREGW        E9,regehl,4+1

; EA - JP PE,dddd
JPCC            EA,jz,PARITY_FLAG

; EB - EX DE,HL
OPEXDEHL        EB                

; EC - CALL PE,dddd
CALLCC          EC,PARITY_FLAG,jnz

; ED - group ED
emulED:         ;inc     edi
                ;inc     rcounter
                ;call    fetch
                ;jmp     [offset isetEDxx+eax*4]

;                cmp     ebx,01FFCh
;                jae     emulED_slow
;
;                mov     al,[esi+ebx+1]
;                inc     edi
;                inc     rcounter
;                inc     ebx
;                jmp     [offset isetEDxx+eax*4]
;
emulED_slow:
                inc     edi
                inc     rcounter
                call    fetch
                jmp     [offset isetEDxx+eax*4]

; EE - XOR dd
XORIMM          EE

; EF - RST 28
OPRST           EF,028h

; F0 - RET P
RETCC           F0,SIGN_FLAG,jz

; F1 - POP AF
POPREGW         F1,edx,10+1

; F2 - JP P,dddd
JPCC            F2,jnz,SIGN_FLAG

; F3 - DI
OPDI            F3

; F4 - CALL P,dddd
CALLCC          F4,SIGN_FLAG,jz

; F5 - PUSH AF
PUSHREGW        F5,edx,11+1

; F6 - OR dd
ORIMM           F6

; F7 - RST 30
OPRST           F7,030h

; F8 - RET M
RETCC           F8,SIGN_FLAG,jnz

; F9 - LD SP,HL
LDSPREGW        F9,regehl,6+1

; FA - JP M,dddd
JPCC            FA,jz,SIGN_FLAG

; FB - EI
OPEI            FB      
;OPEI_MSX2       FB_MSX2

; FC - CALL M,dddd
CALLCC          FC,SIGN_FLAG,jnz

; FD - group FD
emulFD:         ;inc     edi
                ;inc     rcounter
                ;call    fetch
                ;jmp     [offset isetFDxx+eax*4]


;                cmp     ebx,01FFCh
;                jae     emulFD_slow
;
;                mov     al,[esi+ebx+1]
;                inc     edi
;                inc     rcounter
;                inc     ebx
;                jmp     [offset isetFDxx+eax*4]

emulFD_slow:
                inc     edi
                inc     rcounter
                call    fetch
                jmp     [offset isetFDxx+eax*4]

; FE - CP dd
CPIMM           FE

; FF - RST 38
OPRST           FF,038h

; --------------------------------------------------------------------

; CB 00 - RLC B
RLCREG          CB00,regb

; CB 01 - RLC C
RLCREG          CB01,regc

; CB 02 - RLC D
RLCREG          CB02,regd

; CB 03 - RLC E
RLCREG          CB03,rege

; CB 04 - RLC H
RLCREG          CB04,regh

; CB 05 - RLC L
RLCREG          CB05,regl

; CB 06 - RLC (HL)
RLCHL           CB06

; CB 07 - RLC A
RLCREG          CB07,dh

; CB 08 - RRC B
RRCREG          CB08,regb

; CB 09 - RRC C
RRCREG          CB09,regc

; CB 0A - RRC D
RRCREG          CB0A,regd

; CB 0B - RRC E
RRCREG          CB0B,rege

; CB 0C - RRC H
RRCREG          CB0C,regh

; CB 0D - RRC L
RRCREG          CB0D,regl

; CB 0E - RRC (HL)
RRCHL           CB0E

; CB 0F - RRC A
RRCREG          CB0F,dh

; CB 10 - RL B
RLREG           CB10,regb

; CB 11 - RL C
RLREG           CB11,regc

; CB 12 - RL D
RLREG           CB12,regd

; CB 13 - RL E
RLREG           CB13,rege

; CB 14 - RL H
RLREG           CB14,regh

; CB 15 - RL L
RLREG           CB15,regl

; CB 16 - RL (HL)
RLHL            CB16

; CB 17 - RL A
RLREG           CB17,dh

; CB 18 - RR B
RRREG           CB18,regb

; CB 19 - RR C
RRREG           CB19,regc

; CB 1A - RR D
RRREG           CB1A,regd

; CB 1B - RR E
RRREG           CB1B,rege

; CB 1C - RR H
RRREG           CB1C,regh

; CB 1D - RR L
RRREG           CB1D,regl

; CB 1E - RR (HL)
RRHL            CB1E

; CB 1F - RR A
RRREG           CB1F,dh

; CB 20 - SLA B
SLAREG          CB20,regb

; CB 21 - SLA C
SLAREG          CB21,regc

; CB 22 - SLA D
SLAREG          CB22,regd

; CB 23 - SLA E
SLAREG          CB23,rege

; CB 24 - SLA H
SLAREG          CB24,regh

; CB 25 - SLA L
SLAREG          CB25,regl

; CB 26 - SLA (HL)
SLAHL           CB26

; CB 27 - SLA A
SLAREG          CB27,dh

; CB 28 - SRA B
SRAREG          CB28,regb

; CB 29 - SRA C
SRAREG          CB29,regc

; CB 2A - SRA D
SRAREG          CB2A,regd

; CB 2B - SRA E
SRAREG          CB2B,rege

; CB 2C - SRA H
SRAREG          CB2C,regh

; CB 2D - SRA L
SRAREG          CB2D,regl

; CB 2E - SRA (HL)
SRAHL           CB2E

; CB 2F - SRA A
SRAREG          CB2F,dh

; CB 30 - SLL B
SLLREG          CB30,regb

; CB 31 - SLL C
SLLREG          CB31,regc

; CB 32 - SLL D
SLLREG          CB32,regd

; CB 33 - SLL E
SLLREG          CB33,rege

; CB 34 - SLL H
SLLREG          CB34,regh

; CB 35 - SLL L
SLLREG          CB35,regl

; CB 36 - SLL (HL)
SLLHL           CB36

; CB 37 - SLL A
SLLREG          CB37,dh

; CB 38 - SRL B
SRLREG          CB38,regb

; CB 39 - SRL C
SRLREG          CB39,regc

; CB 3A - SRL D
SRLREG          CB3A,regd

; CB 3B - SRL E
SRLREG          CB3B,rege

; CB 3C - SRL H
SRLREG          CB3C,regh

; CB 3D - SRL L
SRLREG          CB3D,regl

; CB 3E - SRL (HL)
SRLHL           CB3E

; CB 3F - SRL A
SRLREG          CB3F,dh

; CB 40 - BIT 0,B
BITREG          CB40,regb,0

; CB 41 - BIT 0,C
BITREG          CB41,regc,0

; CB 42 - BIT 0,D
BITREG          CB42,regd,0

; CB 43 - BIT 0,E
BITREG          CB43,rege,0

; CB 44 - BIT 0,H
BITREG          CB44,regh,0

; CB 45 - BIT 0,L
BITREG          CB45,regl,0

; CB 46 - BIT 0,(HL)
BITHL           CB46,0

; CB 47 - BIT 0,A
BITREG          CB47,dh,0

; CB 48 - BIT 1,B
BITREG          CB48,regb,1

; CB 49 - BIT 1,C
BITREG          CB49,regc,1

; CB 4A - BIT 1,D
BITREG          CB4A,regd,1

; CB 4B - BIT 1,E
BITREG          CB4B,rege,1

; CB 4C - BIT 1,H
BITREG          CB4C,regh,1

; CB 4D - BIT 1,L
BITREG          CB4D,regl,1

; CB 4E - BIT 1,(HL)
BITHL           CB4E,1

; CB 4F - BIT 1,A
BITREG          CB4F,dh,1

; CB 50 - BIT 2,B
BITREG          CB50,regb,2

; CB 51 - BIT 2,C
BITREG          CB51,regc,2

; CB 52 - BIT 2,D
BITREG          CB52,regd,2

; CB 53 - BIT 2,E
BITREG          CB53,rege,2

; CB 54 - BIT 2,H
BITREG          CB54,regh,2

; CB 55 - BIT 2,L
BITREG          CB55,regl,2

; CB 56 - BIT 2,(HL)
BITHL           CB56,2

; CB 57 - BIT 2,A
BITREG          CB57,dh,2

; CB 58 - BIT 3,B
BITREG          CB58,regb,3

; CB 59 - BIT 3,C
BITREG          CB59,regc,3

; CB 5A - BIT 3,D
BITREG          CB5A,regd,3

; CB 5B - BIT 3,E
BITREG          CB5B,rege,3

; CB 5C - BIT 3,H
BITREG          CB5C,regh,3

; CB 5D - BIT 3,L
BITREG          CB5D,regl,3

; CB 5E - BIT 3,(HL)
BITHL           CB5E,3

; CB 5F - BIT 3,A
BITREG          CB5F,dh,3

; CB 60 - BIT 4,B
BITREG          CB60,regb,4

; CB 61 - BIT 4,C
BITREG          CB61,regc,4

; CB 62 - BIT 4,D
BITREG          CB62,regd,4

; CB 63 - BIT 4,E
BITREG          CB63,rege,4

; CB 64 - BIT 4,H
BITREG          CB64,regh,4

; CB 65 - BIT 4,L
BITREG          CB65,regl,4

; CB 66 - BIT 4,(HL)
BITHL           CB66,4

; CB 67 - BIT 4,A
BITREG          CB67,dh,4

; CB 68 - BIT 5,B
BITREG          CB68,regb,5

; CB 69 - BIT 5,C
BITREG          CB69,regc,5

; CB 6A - BIT 5,D
BITREG          CB6A,regd,5

; CB 6B - BIT 5,E
BITREG          CB6B,rege,5

; CB 6C - BIT 5,H
BITREG          CB6C,regh,5

; CB 6D - BIT 5,L
BITREG          CB6D,regl,5

; CB 6E - BIT 5,(HL)
BITHL           CB6E,5

; CB 6F - BIT 5,A
BITREG          CB6F,dh,5

; CB 70 - BIT 6,B
BITREG          CB70,regb,6

; CB 71 - BIT 6,C
BITREG          CB71,regc,6

; CB 72 - BIT 6,D
BITREG          CB72,regd,6

; CB 73 - BIT 6,E
BITREG          CB73,rege,6

; CB 74 - BIT 6,H
BITREG          CB74,regh,6

; CB 75 - BIT 6,L
BITREG          CB75,regl,6

; CB 76 - BIT 6,(HL)
BITHL           CB76,6

; CB 77 - BIT 6,A
BITREG          CB77,dh,6

; CB 78 - BIT 7,B
BITREG          CB78,regb,7

; CB 79 - BIT 7,C
BITREG          CB79,regc,7

; CB 7A - BIT 7,D
BITREG          CB7A,regd,7

; CB 7B - BIT 7,E
BITREG          CB7B,rege,7

; CB 7C - BIT 7,H
BITREG          CB7C,regh,7

; CB 7D - BIT 7,L
BITREG          CB7D,regl,7

; CB 7E - BIT 7,(HL)
BITHL           CB7E,7

; CB 7F - BIT 7,A
BITREG          CB7F,dh,7

; CB 80 - RES 0,B
RESREG          CB80,regb,0

; CB 81 - RES 0,C
RESREG          CB81,regc,0

; CB 82 - RES 0,D
RESREG          CB82,regd,0

; CB 83 - RES 0,E
RESREG          CB83,rege,0

; CB 84 - RES 0,H
RESREG          CB84,regh,0

; CB 85 - RES 0,L
RESREG          CB85,regl,0

; CB 86 - RES 0,(HL)
RESHL           CB86,0

; CB 87 - RES 0,A
RESREG          CB87,dh,0

; CB 88 - RES 1,B
RESREG          CB88,regb,1

; CB 89 - RES 1,C
RESREG          CB89,regc,1

; CB 8A - RES 1,D
RESREG          CB8A,regd,1

; CB 8B - RES 1,E
RESREG          CB8B,rege,1

; CB 8C - RES 1,H
RESREG          CB8C,regh,1

; CB 8D - RES 1,L
RESREG          CB8D,regl,1

; CB 8E - RES 1,(HL)
RESHL           CB8E,1

; CB 8F - RES 1,A
RESREG          CB8F,dh,1

; CB 90 - RES 2,B
RESREG          CB90,regb,2

; CB 91 - RES 2,C
RESREG          CB91,regc,2

; CB 92 - RES 2,D
RESREG          CB92,regd,2

; CB 93 - RES 2,E
RESREG          CB93,rege,2

; CB 94 - RES 2,H
RESREG          CB94,regh,2

; CB 95 - RES 2,L
RESREG          CB95,regl,2

; CB 96 - RES 2,(HL)
RESHL           CB96,2

; CB 97 - RES 2,A
RESREG          CB97,dh,2

; CB 98 - RES 3,B
RESREG          CB98,regb,3

; CB 99 - RES 3,C
RESREG          CB99,regc,3

; CB 9A - RES 3,D
RESREG          CB9A,regd,3

; CB 9B - RES 3,E
RESREG          CB9B,rege,3

; CB 9C - RES 3,H
RESREG          CB9C,regh,3

; CB 9D - RES 3,L
RESREG          CB9D,regl,3

; CB 9E - RES 3,(HL)
RESHL           CB9E,3

; CB 9F - RES 3,A
RESREG          CB9F,dh,3

; CB A0 - RES 4,B
RESREG          CBA0,regb,4

; CB A1 - RES 4,C
RESREG          CBA1,regc,4

; CB A2 - RES 4,D
RESREG          CBA2,regd,4

; CB A3 - RES 4,E
RESREG          CBA3,rege,4

; CB A4 - RES 4,H
RESREG          CBA4,regh,4

; CB A5 - RES 4,L
RESREG          CBA5,regl,4

; CB A6 - RES 4,(HL)
RESHL           CBA6,4

; CB A7 - RES 4,A
RESREG          CBA7,dh,4

; CB A8 - RES 5,B
RESREG          CBA8,regb,5

; CB A9 - RES 5,C
RESREG          CBA9,regc,5

; CB AA - RES 5,D
RESREG          CBAA,regd,5

; CB AB - RES 5,E
RESREG          CBAB,rege,5

; CB AC - RES 5,H
RESREG          CBAC,regh,5

; CB AD - RES 5,L
RESREG          CBAD,regl,5

; CB AE - RES 5,(HL)
RESHL           CBAE,5

; CB AF - RES 5,A
RESREG          CBAF,dh,5

; CB B0 - RES 6,B
RESREG          CBB0,regb,6

; CB B1 - RES 6,C
RESREG          CBB1,regc,6

; CB B2 - RES 6,D
RESREG          CBB2,regd,6

; CB B3 - RES 6,E
RESREG          CBB3,rege,6

; CB B4 - RES 6,H
RESREG          CBB4,regh,6

; CB B5 - RES 6,L
RESREG          CBB5,regl,6

; CB B6 - RES 6,(HL)
RESHL           CBB6,6

; CB B7 - RES 6,A
RESREG          CBB7,dh,6

; CB B8 - RES 7,B
RESREG          CBB8,regb,7

; CB B9 - RES 7,C
RESREG          CBB9,regc,7

; CB BA - RES 7,D
RESREG          CBBA,regd,7

; CB BB - RES 7,E
RESREG          CBBB,rege,7

; CB BC - RES 7,H
RESREG          CBBC,regh,7

; CB BD - RES 7,L
RESREG          CBBD,regl,7

; CB BE - RES 7,(HL)
RESHL           CBBE,7

; CB BF - RES 7,A
RESREG          CBBF,dh,7

; CB C0 - SET 0,B
SETREG          CBC0,regb,0

; CB C1 - SET 0,C
SETREG          CBC1,regc,0

; CB C2 - SET 0,D
SETREG          CBC2,regd,0

; CB C3 - SET 0,E
SETREG          CBC3,rege,0

; CB C4 - SET 0,H
SETREG          CBC4,regh,0

; CB C5 - SET 0,L
SETREG          CBC5,regl,0

; CB C6 - SET 0,(HL)
SETHL           CBC6,0

; CB C7 - SET 0,A
SETREG          CBC7,dh,0

; CB C8 - SET 1,B
SETREG          CBC8,regb,1

; CB C9 - SET 1,C
SETREG          CBC9,regc,1

; CB CA - SET 1,D
SETREG          CBCA,regd,1

; CB CB - SET 1,E
SETREG          CBCB,rege,1

; CB CC - SET 1,H
SETREG          CBCC,regh,1

; CB CD - SET 1,L
SETREG          CBCD,regl,1

; CB CE - SET 1,(HL)
SETHL           CBCE,1

; CB CF - SET 1,A
SETREG          CBCF,dh,1

; CB D0 - SET 2,B
SETREG          CBD0,regb,2

; CB D1 - SET 2,C
SETREG          CBD1,regc,2

; CB D2 - SET 2,D
SETREG          CBD2,regd,2

; CB D3 - SET 2,E
SETREG          CBD3,rege,2

; CB D4 - SET 2,H
SETREG          CBD4,regh,2

; CB D5 - SET 2,L
SETREG          CBD5,regl,2

; CB D6 - SET 2,(HL)
SETHL           CBD6,2

; CB D7 - SET 2,A
SETREG          CBD7,dh,2

; CB D8 - SET 3,B
SETREG          CBD8,regb,3

; CB D9 - SET 3,C
SETREG          CBD9,regc,3

; CB DA - SET 3,D
SETREG          CBDA,regd,3

; CB DB - SET 3,E
SETREG          CBDB,rege,3

; CB DC - SET 3,H
SETREG          CBDC,regh,3

; CB DD - SET 3,L
SETREG          CBDD,regl,3

; CB DE - SET 3,(HL)
SETHL           CBDE,3

; CB DF - SET 3,A
SETREG          CBDF,dh,3

; CB E0 - SET 4,B
SETREG          CBE0,regb,4

; CB E1 - SET 4,C
SETREG          CBE1,regc,4

; CB E2 - SET 4,D
SETREG          CBE2,regd,4

; CB E3 - SET 4,E
SETREG          CBE3,rege,4

; CB E4 - SET 4,H
SETREG          CBE4,regh,4

; CB E5 - SET 4,L
SETREG          CBE5,regl,4

; CB E6 - SET 4,(HL)
SETHL           CBE6,4

; CB E7 - SET 4,A
SETREG          CBE7,dh,4

; CB E8 - SET 5,B
SETREG          CBE8,regb,5

; CB E9 - SET 5,C
SETREG          CBE9,regc,5

; CB EA - SET 5,D
SETREG          CBEA,regd,5

; CB EB - SET 5,E
SETREG          CBEB,rege,5

; CB EC - SET 5,H
SETREG          CBEC,regh,5

; CB ED - SET 5,L
SETREG          CBED,regl,5

; CB EE - SET 5,(HL)
SETHL           CBEE,5

; CB EF - SET 5,A
SETREG          CBEF,dh,5

; CB F0 - SET 6,B
SETREG          CBF0,regb,6

; CB F1 - SET 6,C
SETREG          CBF1,regc,6

; CB F2 - SET 6,D
SETREG          CBF2,regd,6

; CB F3 - SET 6,E
SETREG          CBF3,rege,6

; CB F4 - SET 6,H
SETREG          CBF4,regh,6

; CB F5 - SET 6,L
SETREG          CBF5,regl,6

; CB F6 - SET 6,(HL)
SETHL           CBF6,6

; CB F7 - SET 6,A
SETREG          CBF7,dh,6

; CB F8 - SET 7,B
SETREG          CBF8,regb,7

; CB F9 - SET 7,C
SETREG          CBF9,regc,7

; CB FA - SET 7,D
SETREG          CBFA,regd,7

; CB FB - SET 7,E
SETREG          CBFB,rege,7

; CB FC - SET 7,H
SETREG          CBFC,regh,7

; CB FD - SET 7,L
SETREG          CBFD,regl,7

; CB FE - SET 7,(HL)
SETHL           CBFE,7

; CB FF - SET 7,A
SETREG          CBFF,dh,7

; --------------------------------------------------------------------

; ED 40 - IN B,(C)
INREG           ED40,regb

; ED 41 - OUT (C),B
OUTCREG         ED41,regb

; ED 42 - SBC HL,BC
SBCHLWREG       ED42,regc,regb

; ED 43 - LD (dddd),BC
LDDDDDREGW      ED43,regebc,20+2

; ED 44 - NEG
OPNEG           ED44

; ED 45 - RETN
OPRET           ED45

; ED 46 - IM 0
OPIM0           ED46

; ED 47 - LD I,A
LDIA            ED47

; ED 48 - IN C,(C)
INREG           ED48,regc

; ED 49 - OUT (C),C
OUTCREG         ED49,regc

; ED 4A - ADC HL,BC
ADCREGWREGW     ED4A,regl,regh,regc,regb

; ED 4B - LD BC,(dddd)
LDREGWDDDD      ED4B,regebc,20+2

; ED 4C - NEG
OPNEG           ED4C

; ED 4D - RETI
OPRET           ED4D

; ED 4E - IM 0/1
OPIM1           ED4E

; ED 4F - LD R,A
LDRA            ED4F

; ED 50 - IN D,(C)
INREG           ED50,regd

; ED 51 - OUT (C),D
OUTCREG         ED51,regd

; ED 52 - SBC HL,DE
SBCHLWREG       ED52,rege,regd

; ED 53 - LD (dddd),DE
LDDDDDREGW      ED53,regede,20+2

; ED 54 - NEG
OPNEG           ED54

; ED 55 - RETN
OPRET           ED55

; ED 56 - IM 1
OPIM1           ED56

; ED 57 - LD A,I
LDAI            ED57

; ED 58 - IN E,(C)
INREG           ED58,rege

; ED 59 - OUT (C),E
OUTCREG         ED59,rege

; ED 5A - ADC HL,DE
ADCREGWREGW     ED5A,regl,regh,rege,regd

; ED 5B - LD DE,(dddd)
LDREGWDDDD      ED5B,regede,20+2

; ED 5C - NEG
OPNEG           ED5C

; ED 5D - RETN
OPRET           ED5D

; ED 5E - IM 2
OPIM2           ED5E

; ED 5F - LD A,R
LDAR            ED5F    

; ED 60 - IN H,(C)
INREG           ED60,regh

; ED 61 - OUT (C),H
OUTCREG         ED61,regh

; ED 62 - SBC HL,HL
SBCHLWREG       ED62,regl,regh

; ED 63 - LD (dddd),HL
LDDDDDREGW      ED63,regehl,20+2

; ED 64 - NEG
OPNEG           ED64

; ED 65 - RETN
OPRET           ED65

; ED 66 - IM 0
OPIM0           ED66

; ED 67 - RRD
OPRRD           ED67

; ED 68 - IN L,(C)
INREG           ED68,regl

; ED 69 - OUT (C),L
OUTCREG         ED69,regl

; ED 6A - ADC HL,HL
ADCREGWREGW     ED6A,regl,regh,regl,regh

; ED 6B - LD HL,(dddd)
LDREGWDDDD      ED6B,regehl,20+2

; ED 6C - NEG
OPNEG           ED6C

; ED 6D - RETN
OPRET           ED6D

; ED 6E - IM 0/1
OPIM0           ED6E

; ED 6F - RLD
OPRLD           ED6F  

; ED 70 - IN (C)
INFLAG          ED70

; ED 71 - OUT (C),0
OUTC0           ED71

; ED 72 - SBC HL,SP
SBCHLWREG       ED72,_regspl,_regsph

; ED 73 - LD (dddd),SP
LDDDDDREGW      ED73,regesp,20+2

; ED 74 - NEG
OPNEG           ED74

; ED 75 - RETN
OPRET           ED75

; ED 76 - IM 1
OPIM1           ED76

; ED 78 - IN A,(C)
INREG           ED78,dh

; ED 79 - OUT (C),A
OUTCREG         ED79,dh

; ED 7A - ADC HL,SP
ADCREGWREGW     ED7A,regl,regh,_regspl,_regsph

; ED 7B - LD SP,(dddd)
LDREGWDDDD      ED7B,regesp,20+2

; ED 7C - NEG
OPNEG           ED7C

; ED 7D - RETN
OPRET           ED7D

; ED 7E - IM 2
OPIM2           ED7E

; ED A0 - LDI
OPLDI           EDA0

; ED A1 - CPI
OPCPI           EDA1

; ED A2 - INI
OPINI           EDA2

; ED A3 - OUTI
OPOUTI          EDA3

; ED A8 - LDD
OPLDD           EDA8

; ED A9 - CPD
OPCPD           EDA9

; ED AA - IND
OPIND           EDAA

; ED AB - OUTD
OPOUTD          EDAB

; ED B0 - LDIR
OPLDIR          EDB0   

; ED B1 - CPIR
OPCPIR          EDB1

; ED B2 - INIR
OPINIR          EDB2

; ED B3 - OTIR
OPOTIR          EDB3

; ED B8 - LDDR
OPLDDR          EDB8

; ED B9 - CPDR
OPCPDR          EDB9

; ED BA - INDR
OPINDR          EDBA

; ED BB - OTDR
OPOTDR          EDBB

; ED (NULL) - ED null opcode
XNULL2          EDNULL

; --------------------------------------------------------------------

; DD 09 - ADD IX,BC
ADDREGWREGW     DD09,_regixl,_regixh,regc,regb,15+2

; DD 19 - ADD IX,DE
ADDREGWREGW     DD19,_regixl,_regixh,rege,regd,15+2

; DD 21 - LD IX,dddd
LDREGWIMM      DD21,regeix

; DD 22 - LD (dddd),IX
LDDDDDREGW      DD22,regeix,20+2

; DD 23 - INC IX
INCWREG         DD23,_regix,10+2

; DD 24 - INC IXh
INCREG          DD24,_regixh

; DD 25 - DEC IXh
DECREG          DD25,_regixh

; DD 26 - LD IXh,dd
LDREGIMM        DD26,_regixh

; DD 29 - ADD IX,IX
ADDREGWREGW     DD29,_regixl,_regixh,_regixl,_regixh,15+2

; DD 2A - LD IX,(dddd)
LDREGWDDDD      DD2A,regeix,20+2

; DD 2B - DEC IX
DECWREG         DD2B,_regix,10+2

; DD 2C - INC IXl
INCREG          DD2C,_regixl

; DD 2D - DEC IXl
DECREG          DD2D,_regixl

; DD 2E - LD IXl,dd
LDREGIMM        DD2E,_regixl

; DD 34 - INC (IX+dd)
INCII           DD34,regeix

; DD 35 - DEC (IX+dd)
DECII           DD35,regeix

; DD 36 - LD (IX+dd),dd
LDIIDDNN        DD36,regeix

; DD 39 - ADD IX,SP
ADDREGWREGW     DD39,_regixl,_regixh,_regspl,_regsph,15+2

; DD 40 - DD null prefix
XNULL           DD40

; DD 41 - DD null prefix
XNULL           DD41

; DD 42 - DD null prefix
XNULL           DD42

; DD 43 - DD null prefix
XNULL           DD43

; DD 44 - LD B,IXh
LDREGREG        DD44,regb,_regixh

; DD 45 - LD B,IXl
LDREGREG        DD45,regb,_regixl

; DD 46 - LD B,(IX+dd)
LDREGIIDD       DD46,regb,regeix

; DD 47 - DD null prefix
XNULL           DD47

; DD 48 - DD null prefix
XNULL           DD48

; DD 49 - DD null prefix
XNULL           DD49

; DD 4A - DD null prefix
XNULL           DD4A

; DD 4B - DD null prefix
XNULL           DD4B

; DD 4C - LD C,IXh
LDREGREG        DD4C,regc,_regixh

; DD 4D - LD C,IXl
LDREGREG        DD4D,regc,_regixl

; DD 4E - LD C,(IX+dd)
LDREGIIDD       DD4E,regc,regeix

; DD 4F - DD null prefix
XNULL           DD4F

; DD 50 - DD null prefix
XNULL           DD50

; DD 51 - DD null prefix
XNULL           DD51

; DD 52 - DD null prefix
XNULL           DD52

; DD 53 - DD null prefix
XNULL           DD53

; DD 54 - LD D,IXh
LDREGREG        DD54,regd,_regixh

; DD 55 - LD D,IXl
LDREGREG        DD55,regd,_regixl

; DD 56 - LD D,(IX+dd)
LDREGIIDD       DD56,regd,regeix

; DD 57 - DD null prefix
XNULL           DD57

; DD 58 - DD null prefix
XNULL           DD58

; DD 59 - DD null prefix
XNULL           DD59

; DD 5A - DD null prefix
XNULL           DD5A

; DD 5B - DD null prefix
XNULL           DD5B

; DD 5C - LD E,IXh
LDREGREG        DD5C,rege,_regixh

; DD 5D - LD E,IXl
LDREGREG        DD5D,rege,_regixl

; DD 5E - LD E,(IX+dd)
LDREGIIDD       DD5E,rege,regeix

; DD 5F - DD null prefix
XNULL           DD5F

; DD 60 - LD IXh,B
LDREGREG        DD60,_regixh,regb

; DD 61 - LD IXh,C
LDREGREG        DD61,_regixh,regc

; DD 62 - LD IXh,D
LDREGREG        DD62,_regixh,regd

; DD 63 - LD IXh,E
LDREGREG        DD63,_regixh,rege

; DD 64 - LD IXh,IXh
LDREGREG        DD64,_regixh,_regixh

; DD 65 - LD IXh,IXl
LDREGREG        DD65,_regixh,_regixl

; DD 66 - LD H,(IX+dd)
LDREGIIDD       DD66,regh,regeix

; DD 67 - LD IXh,A
LDREGREG        DD67,_regixh,dh

; DD 68 - LD IXl,B
LDREGREG        DD68,_regixl,regb

; DD 69 - LD IXl,C
LDREGREG        DD69,_regixl,regc

; DD 6A - LD IXl,D
LDREGREG        DD6A,_regixl,regd

; DD 6B - LD IXl,E
LDREGREG        DD6B,_regixl,rege

; DD 6C - LD IXl,IXh
LDREGREG        DD6C,_regixl,_regixh

; DD 6D - LD IXl,IXl
LDREGREG        DD6D,_regixl,_regixl

; DD 6E - LD L,(IX+dd)
LDREGIIDD       DD6E,regl,regeix

; DD 6F - LD IXl,A
LDREGREG        DD6F,_regixl,dh

; DD 70 - LD (IX+dd),B
LDIIDDREG       DD70,regb,regeix

; DD 71 - LD (IX+dd),C
LDIIDDREG       DD71,regc,regeix

; DD 72 - LD (IX+dd),D
LDIIDDREG       DD72,regd,regeix

; DD 73 - LD (IX+dd),E
LDIIDDREG       DD73,rege,regeix

; DD 74 - LD (IX+dd),H
LDIIDDREG       DD74,regh,regeix

; DD 75 - LD (IX+dd),L
LDIIDDREG       DD75,regl,regeix

; DD 76 - DD null prefix
XNULL           DD76

; DD 77 - LD (IX+dd),A
LDIIDDREG       DD77,dh,regeix

; DD 78 - DD null prefix
XNULL           DD78

; DD 79 - DD null prefix
XNULL           DD79

; DD 7A - DD null prefix
XNULL           DD7A

; DD 7B - DD null prefix
XNULL           DD7B

; DD 7C - LD A,IXh
LDREGREG        DD7C,dh,_regixh

; DD 7D - LD A,IXl
LDREGREG        DD7D,dh,_regixl

; DD 7E - LD A,(IX+dd)
LDREGIIDD       DD7E,dh,regeix

; DD 7F - DD null prefix
XNULL           DD7F

; DD 84 - ADD A,IXh
ADDREG          DD84,_regixh

; DD 85 - ADD A,IXl
ADDREG          DD85,_regixl

; DD 86 - ADD A,(IX+dd)
ADDAII          DD86,regeix

; DD 8C - ADC A,IXh
ADCREG          DD8C,_regixh

; DD 8D - ADC A,IXl
ADCREG          DD8D,_regixl

; DD 8E - ADC A,(IX+dd)
ADCAII          DD8E,regeix

; DD 94 - SUB IXh
SUBREG          DD94,_regixh

; DD 95 - SUB IXl
SUBREG          DD95,_regixl

; DD 96 - SUB (IX+dd)
SUBII           DD96,regeix

; DD 9C - SBC A,IXh
SBCREG          DD9C,_regixh

; DD 9D - SBC A,IXl
SBCREG          DD9D,_regixl

; DD 9E - SBC A,(IX+dd)
SBCAII          DD9E,regeix

; DD A4 - AND IXh
ANDREG          DDA4,_regixh

; DD A5 - AND IXl
ANDREG          DDA5,_regixl

; DD A6 - AND (IX+dd)
ANDII           DDA6,regeix

; DD AC - XOR IXh
XORREG          DDAC,_regixh

; DD AD - XOR IXl
XORREG          DDAD,_regixl

; DD AE - XOR (IX+dd)
XORII           DDAE,regeix

; DD B4 - OR IXh
ORREG           DDB4,_regixh

; DD B5 - OR IXl
ORREG           DDB5,_regixl

; DD B6 - OR (IX+dd)
ORII            DDB6,regeix

; DD BC - CP IXh
CPREG           DDBC,_regixh

; DD BD - CP IXl
CPREG           DDBD,_regixl

; DD BE - CP (IX+dd)
CPII            DDBE,regeix

; DD CB - group DD CB
emulDDCB:       inc     edi
                inc     rcounter
                call    fetch
                mov     cl,al
                inc     edi
                call    fetch
                jmp     [offset isetDDCBxx+eax*4]

; DD E1 - POP IX
POPREGW         DDE1,regeix,14+2

; DD E3 - EX (SP),IX
OPEXSPREGW      DDE3,regeix,23+2

; DD E5 - PUSH IX
PUSHREGW        DDE5,regeix,15+2

; DD E9 - JP (IX)
OPJPREGW        DDE9,regeix,8+2

; DD F9 - LD SP,IX
LDSPREGW        DDF9,regeix,10+2

; DD (NULL) - DD null prefix
XNULL           DDNULL

; DD CB 00 - LD B,RLC (IX+dd)
RLCCOMBO        DDCB00,regeix,regb

; DD CB 01 - LD C,RLC (IX+dd)
RLCCOMBO        DDCB01,regeix,regc

; DD CB 02 - LD D,RLC (IX+dd)
RLCCOMBO        DDCB02,regeix,regd

; DD CB 03 - LD E,RLC (IX+dd)
RLCCOMBO        DDCB03,regeix,rege

; DD CB 04 - LD H,RLC (IX+dd)
RLCCOMBO        DDCB04,regeix,regh

; DD CB 05 - LD L,RLC (IX+dd)
RLCCOMBO        DDCB05,regeix,regl

; DD CB 06 - RLC (IX+dd)
RLCII           DDCB06,regeix

; DD CB 07 - LD A,RLC (IX+dd)
RLCCOMBO        DDCB07,regeix,dh

; DD CB 08 - LD B,RRC (IX+dd)
RRCCOMBO        DDCB08,regeix,regb

; DD CB 09 - LD C,RRC (IX+dd)
RRCCOMBO        DDCB09,regeix,regc

; DD CB 0A - LD D,RRC (IX+dd)
RRCCOMBO        DDCB0A,regeix,regd

; DD CB 0B - LD E,RRC (IX+dd)
RRCCOMBO        DDCB0B,regeix,rege

; DD CB 0C - LD H,RRC (IX+dd)
RRCCOMBO        DDCB0C,regeix,regh

; DD CB 0D - LD L,RRC (IX+dd)
RRCCOMBO        DDCB0D,regeix,regl

; DD CB 0E - RRC (IX+dd)
RRCII           DDCB0E,regeix

; DD CB 0F - LD A,RRC (IX+dd)
RRCCOMBO        DDCB0F,regeix,dh

; DD CB 10 - LD B,RL (IX+dd)
RLCOMBO         DDCB10,regeix,regb

; DD CB 11 - LD C,RL (IX+dd)
RLCOMBO         DDCB11,regeix,regc

; DD CB 12 - LD D,RL (IX+dd)
RLCOMBO         DDCB12,regeix,regd

; DD CB 13 - LD E,RL (IX+dd)
RLCOMBO         DDCB13,regeix,rege

; DD CB 14 - LD H,RL (IX+dd)
RLCOMBO         DDCB14,regeix,regh

; DD CB 15 - LD L,RL (IX+dd)
RLCOMBO         DDCB15,regeix,regl

; DD CB 16 - RL (IX+dd)
RLII            DDCB16,regeix

; DD CB 17 - LD A,RL (IX+dd)
RLCOMBO         DDCB17,regeix,dh

; DD CB 18 - LD B,RR (IX+dd)
RRCOMBO         DDCB18,regeix,regb

; DD CB 19 - LD C,RR (IX+dd)
RRCOMBO         DDCB19,regeix,regc

; DD CB 1A - LD D,RR (IX+dd)
RRCOMBO         DDCB1A,regeix,regd

; DD CB 1B - LD E,RR (IX+dd)
RRCOMBO         DDCB1B,regeix,rege

; DD CB 1C - LD H,RR (IX+dd)
RRCOMBO         DDCB1C,regeix,regh

; DD CB 1D - LD L,RR (IX+dd)
RRCOMBO         DDCB1D,regeix,regl

; DD CB 1E - RR (IX+dd)
RRII            DDCB1E,regeix

; DD CB 1F - LD A,RR (IX+dd)
RRCOMBO         DDCB1F,regeix,dh

; DD CB 20 - LD B,SLA (IX+dd)
SLACOMBO        DDCB20,regeix,regb

; DD CB 21 - LD C,SLA (IX+dd)
SLACOMBO        DDCB21,regeix,regc

; DD CB 22 - LD D,SLA (IX+dd)
SLACOMBO        DDCB22,regeix,regd

; DD CB 23 - LD E,SLA (IX+dd)
SLACOMBO        DDCB23,regeix,rege

; DD CB 24 - LD H,SLA (IX+dd)
SLACOMBO        DDCB24,regeix,regh

; DD CB 25 - LD L,SLA (IX+dd)
SLACOMBO        DDCB25,regeix,regl

; DD CB 26 - SLA (IX+dd)
SLAII           DDCB26,regeix

; DD CB 27 - LD A,SLA (IX+dd)
SLACOMBO        DDCB27,regeix,dh

; DD CB 28 - LD B,SRA (IX+dd)
SRACOMBO        DDCB28,regeix,regb

; DD CB 29 - LD C,SRA (IX+dd)
SRACOMBO        DDCB29,regeix,regc

; DD CB 2A - LD D,SRA (IX+dd)
SRACOMBO        DDCB2A,regeix,regd

; DD CB 2B - LD E,SRA (IX+dd)
SRACOMBO        DDCB2B,regeix,rege

; DD CB 2C - LD H,SRA (IX+dd)
SRACOMBO        DDCB2C,regeix,regh

; DD CB 2D - LD L,SRA (IX+dd)
SRACOMBO        DDCB2D,regeix,regl

; DD CB 2E - SRA (IX+dd)
SRAII           DDCB2E,regeix

; DD CB 2F - LD A,SRA (IX+dd)
SRACOMBO        DDCB2F,regeix,dh

; DD CB 30 - LD B,SLL (IX+dd)
SLLCOMBO        DDCB30,regeix,regb

; DD CB 31 - LD C,SLL (IX+dd)
SLLCOMBO        DDCB31,regeix,regc

; DD CB 32 - LD D,SLL (IX+dd)
SLLCOMBO        DDCB32,regeix,regd

; DD CB 33 - LD E,SLL (IX+dd)
SLLCOMBO        DDCB33,regeix,rege

; DD CB 34 - LD H,SLL (IX+dd)
SLLCOMBO        DDCB34,regeix,regh

; DD CB 35 - LD L,SLL (IX+dd)
SLLCOMBO        DDCB35,regeix,regl

; DD CB 36 - SLL (IX+dd)
SLLII           DDCB36,regeix

; DD CB 37 - LD A,SLL (IX+dd)
SLLCOMBO        DDCB37,regeix,dh

; DD CB 38 - LD B,SRL (IX+dd)
SRLCOMBO        DDCB38,regeix,regb

; DD CB 39 - LD C,SRL (IX+dd)
SRLCOMBO        DDCB39,regeix,regc

; DD CB 3A - LD D,SRL (IX+dd)
SRLCOMBO        DDCB3A,regeix,regd

; DD CB 3B - LD E,SRL (IX+dd)
SRLCOMBO        DDCB3B,regeix,rege

; DD CB 3C - LD H,SRL (IX+dd)
SRLCOMBO        DDCB3C,regeix,regh

; DD CB 3D - LD L,SRL (IX+dd)
SRLCOMBO        DDCB3D,regeix,regl

; DD CB 3E - SRL (IX+dd)
SRLII           DDCB3E,regeix

; DD CB 3F - LD A,SRL (IX+dd)
SRLCOMBO        DDCB3F,regeix,dh

; DD CB 40 - BIT 0,(IX+dd)
BITII           DDCB40,0,regeix

; DD CB 41 - BIT 0,(IX+dd)
BITII           DDCB41,0,regeix

; DD CB 42 - BIT 0,(IX+dd)
BITII           DDCB42,0,regeix

; DD CB 43 - BIT 0,(IX+dd)
BITII           DDCB43,0,regeix

; DD CB 44 - BIT 0,(IX+dd)
BITII           DDCB44,0,regeix

; DD CB 45 - BIT 0,(IX+dd)
BITII           DDCB45,0,regeix

; DD CB 46 - BIT 0,(IX+dd)
BITII           DDCB46,0,regeix

; DD CB 47 - BIT 0,(IX+dd)
BITII           DDCB47,0,regeix

; DD CB 48 - BIT 1,(IX+dd)
BITII           DDCB48,1,regeix

; DD CB 49 - BIT 1,(IX+dd)
BITII           DDCB49,1,regeix

; DD CB 4A - BIT 1,(IX+dd)
BITII           DDCB4A,1,regeix

; DD CB 4B - BIT 1,(IX+dd)
BITII           DDCB4B,1,regeix

; DD CB 4C - BIT 1,(IX+dd)
BITII           DDCB4C,1,regeix

; DD CB 4D - BIT 1,(IX+dd)
BITII           DDCB4D,1,regeix

; DD CB 4E - BIT 1,(IX+dd)
BITII           DDCB4E,1,regeix

; DD CB 4F - BIT 1,(IX+dd)
BITII           DDCB4F,1,regeix

; DD CB 50 - BIT 2,(IX+dd)
BITII           DDCB50,2,regeix

; DD CB 51 - BIT 2,(IX+dd)
BITII           DDCB51,2,regeix

; DD CB 52 - BIT 2,(IX+dd)
BITII           DDCB52,2,regeix

; DD CB 53 - BIT 2,(IX+dd)
BITII           DDCB53,2,regeix

; DD CB 54 - BIT 2,(IX+dd)
BITII           DDCB54,2,regeix

; DD CB 55 - BIT 2,(IX+dd)
BITII           DDCB55,2,regeix

; DD CB 56 - BIT 2,(IX+dd)
BITII           DDCB56,2,regeix

; DD CB 57 - BIT 2,(IX+dd)
BITII           DDCB57,2,regeix

; DD CB 58 - BIT 3,(IX+dd)
BITII           DDCB58,3,regeix

; DD CB 59 - BIT 3,(IX+dd)
BITII           DDCB59,3,regeix

; DD CB 5A - BIT 3,(IX+dd)
BITII           DDCB5A,3,regeix

; DD CB 5B - BIT 3,(IX+dd)
BITII           DDCB5B,3,regeix

; DD CB 5C - BIT 3,(IX+dd)
BITII           DDCB5C,3,regeix

; DD CB 5D - BIT 3,(IX+dd)
BITII           DDCB5D,3,regeix

; DD CB 5E - BIT 3,(IX+dd)
BITII           DDCB5E,3,regeix

; DD CB 5F - BIT 3,(IX+dd)
BITII           DDCB5F,3,regeix

; DD CB 60 - BIT 4,(IX+dd)
BITII           DDCB60,4,regeix

; DD CB 61 - BIT 4,(IX+dd)
BITII           DDCB61,4,regeix

; DD CB 62 - BIT 4,(IX+dd)
BITII           DDCB62,4,regeix

; DD CB 63 - BIT 4,(IX+dd)
BITII           DDCB63,4,regeix

; DD CB 64 - BIT 4,(IX+dd)
BITII           DDCB64,4,regeix

; DD CB 65 - BIT 4,(IX+dd)
BITII           DDCB65,4,regeix

; DD CB 66 - BIT 4,(IX+dd)
BITII           DDCB66,4,regeix

; DD CB 67 - BIT 4,(IX+dd)
BITII           DDCB67,4,regeix

; DD CB 68 - BIT 5,(IX+dd)
BITII           DDCB68,5,regeix

; DD CB 69 - BIT 5,(IX+dd)
BITII           DDCB69,5,regeix

; DD CB 6A - BIT 5,(IX+dd)
BITII           DDCB6A,5,regeix

; DD CB 6B - BIT 5,(IX+dd)
BITII           DDCB6B,5,regeix

; DD CB 6C - BIT 5,(IX+dd)
BITII           DDCB6C,5,regeix

; DD CB 6D - BIT 5,(IX+dd)
BITII           DDCB6D,5,regeix

; DD CB 6E - BIT 5,(IX+dd)
BITII           DDCB6E,5,regeix

; DD CB 6F - BIT 5,(IX+dd)
BITII           DDCB6F,5,regeix

; DD CB 70 - BIT 6,(IX+dd)
BITII           DDCB70,6,regeix

; DD CB 71 - BIT 6,(IX+dd)
BITII           DDCB71,6,regeix

; DD CB 72 - BIT 6,(IX+dd)
BITII           DDCB72,6,regeix

; DD CB 73 - BIT 6,(IX+dd)
BITII           DDCB73,6,regeix

; DD CB 74 - BIT 6,(IX+dd)
BITII           DDCB74,6,regeix

; DD CB 75 - BIT 6,(IX+dd)
BITII           DDCB75,6,regeix

; DD CB 76 - BIT 6,(IX+dd)
BITII           DDCB76,6,regeix

; DD CB 77 - BIT 6,(IX+dd)
BITII           DDCB77,6,regeix

; DD CB 78 - BIT 7,(IX+dd)
BITII           DDCB78,7,regeix

; DD CB 79 - BIT 7,(IX+dd)
BITII           DDCB79,7,regeix

; DD CB 7A - BIT 7,(IX+dd)
BITII           DDCB7A,7,regeix

; DD CB 7B - BIT 7,(IX+dd)
BITII           DDCB7B,7,regeix

; DD CB 7C - BIT 7,(IX+dd)
BITII           DDCB7C,7,regeix

; DD CB 7D - BIT 7,(IX+dd)
BITII           DDCB7D,7,regeix

; DD CB 7E - BIT 7,(IX+dd)
BITII           DDCB7E,7,regeix

; DD CB 7F - BIT 7,(IX+dd)
BITII           DDCB7F,7,regeix

; DD CB 80 - LD B,RES 0,(IX+dd)
RESCOMBO        DDCB80,0,regeix,regb

; DD CB 81 - LD C,RES 0,(IX+dd)
RESCOMBO        DDCB81,0,regeix,regc

; DD CB 82 - LD D,RES 0,(IX+dd)
RESCOMBO        DDCB82,0,regeix,regd

; DD CB 83 - LD E,RES 0,(IX+dd)
RESCOMBO        DDCB83,0,regeix,rege

; DD CB 84 - LD H,RES 0,(IX+dd)
RESCOMBO        DDCB84,0,regeix,regh

; DD CB 85 - LD L,RES 0,(IX+dd)
RESCOMBO        DDCB85,0,regeix,regl

; DD CB 86 - RES 0,(IX+dd)
RESII           DDCB86,0,regeix

; DD CB 87 - LD L,RES 0,(IX+dd)
RESCOMBO        DDCB87,0,regeix,dh

; DD CB 88 - LD B,RES 1,(IX+dd)
RESCOMBO        DDCB88,1,regeix,regb

; DD CB 89 - LD C,RES 1,(IX+dd)
RESCOMBO        DDCB89,1,regeix,regc

; DD CB 8A - LD D,RES 1,(IX+dd)
RESCOMBO        DDCB8A,1,regeix,regd

; DD CB 8B - LD E,RES 1,(IX+dd)
RESCOMBO        DDCB8B,1,regeix,rege

; DD CB 8C - LD H,RES 1,(IX+dd)
RESCOMBO        DDCB8C,1,regeix,regh

; DD CB 8D - LD L,RES 1,(IX+dd)
RESCOMBO        DDCB8D,1,regeix,regl

; DD CB 8E - RES 1,(IX+dd)
RESII           DDCB8E,1,regeix

; DD CB 8F - LD A,RES 1,(IX+dd)
RESCOMBO        DDCB8F,1,regeix,dh

; DD CB 90 - LD B,RES 2,(IX+dd)
RESCOMBO        DDCB90,2,regeix,regb

; DD CB 91 - LD C,RES 2,(IX+dd)
RESCOMBO        DDCB91,2,regeix,regc

; DD CB 92 - LD D,RES 2,(IX+dd)
RESCOMBO        DDCB92,2,regeix,regd

; DD CB 93 - LD E,RES 2,(IX+dd)
RESCOMBO        DDCB93,2,regeix,rege

; DD CB 94 - LD H,RES 2,(IX+dd)
RESCOMBO        DDCB94,2,regeix,regh

; DD CB 95 - LD L,RES 2,(IX+dd)
RESCOMBO        DDCB95,2,regeix,regl

; DD CB 96 - RES 2,(IX+dd)
RESII           DDCB96,2,regeix

; DD CB 97 - LD L,RES 2,(IX+dd)
RESCOMBO        DDCB97,2,regeix,regl

; DD CB 98 - LD B,RES 3,(IX+dd)
RESCOMBO        DDCB98,3,regeix,regb

; DD CB 99 - LD C,RES 3,(IX+dd)
RESCOMBO        DDCB99,3,regeix,regc

; DD CB 9A - LD D,RES 3,(IX+dd)
RESCOMBO        DDCB9A,3,regeix,regd

; DD CB 9B - LD E,RES 3,(IX+dd)
RESCOMBO        DDCB9B,3,regeix,rege

; DD CB 9C - LD H,RES 3,(IX+dd)
RESCOMBO        DDCB9C,3,regeix,regh

; DD CB 9D - LD L,RES 3,(IX+dd)
RESCOMBO        DDCB9D,3,regeix,regl

; DD CB 9E - RES 3,(IX+dd)
RESII           DDCB9E,3,regeix

; DD CB 9F - LD A,RES 3,(IX+dd)
RESCOMBO        DDCB9F,3,regeix,dh

; DD CB A0 - LD B,RES 4,(IX+dd)
RESCOMBO        DDCBA0,4,regeix,regb

; DD CB A1 - LD C,RES 4,(IX+dd)
RESCOMBO        DDCBA1,4,regeix,regc

; DD CB A2 - LD D,RES 4,(IX+dd)
RESCOMBO        DDCBA2,4,regeix,regd

; DD CB A3 - LD E,RES 4,(IX+dd)
RESCOMBO        DDCBA3,4,regeix,rege

; DD CB A4 - LD H,RES 4,(IX+dd)
RESCOMBO        DDCBA4,4,regeix,regh

; DD CB A5 - LD L,RES 4,(IX+dd)
RESCOMBO        DDCBA5,4,regeix,regl

; DD CB A6 - RES 4,(IX+dd)
RESII           DDCBA6,4,regeix

; DD CB A7 - LD A,RES 4,(IX+dd)
RESCOMBO        DDCBA7,4,regeix,dh

; DD CB A8 - LD B,RES 5,(IX+dd)
RESCOMBO        DDCBA8,5,regeix,regb

; DD CB A9 - LD C,RES 5,(IX+dd)
RESCOMBO        DDCBA9,5,regeix,regc

; DD CB AA - LD D,RES 5,(IX+dd)
RESCOMBO        DDCBAA,5,regeix,regd

; DD CB AB - LD E,RES 5,(IX+dd)
RESCOMBO        DDCBAB,5,regeix,rege

; DD CB AC - LD H,RES 5,(IX+dd)
RESCOMBO        DDCBAC,5,regeix,regh

; DD CB AD - LD L,RES 5,(IX+dd)
RESCOMBO        DDCBAD,5,regeix,regl

; DD CB AE - RES 5,(IX+dd)
RESII           DDCBAE,5,regeix

; DD CB AF - LD A,RES 5,(IX+dd)
RESCOMBO        DDCBAF,5,regeix,dh

; DD CB B0 - LD B,RES 6,(IX+dd)
RESCOMBO        DDCBB0,6,regeix,regb

; DD CB B1 - LD C,RES 6,(IX+dd)
RESCOMBO        DDCBB1,6,regeix,regc

; DD CB B2 - LD D,RES 6,(IX+dd)
RESCOMBO        DDCBB2,6,regeix,regd

; DD CB B3 - LD E,RES 6,(IX+dd)
RESCOMBO        DDCBB3,6,regeix,rege

; DD CB B4 - LD H,RES 6,(IX+dd)
RESCOMBO        DDCBB4,6,regeix,regh

; DD CB B5 - LD L,RES 6,(IX+dd)
RESCOMBO        DDCBB5,6,regeix,regl

; DD CB B6 - RES 6,(IX+dd)
RESII           DDCBB6,6,regeix

; DD CB B7 - LD A,RES 6,(IX+dd)
RESCOMBO        DDCBB7,6,regeix,dh

; DD CB B8 - LD B,RES 7,(IX+dd)
RESCOMBO        DDCBB8,7,regeix,regb

; DD CB B9 - LD C,RES 7,(IX+dd)
RESCOMBO        DDCBB9,7,regeix,regc

; DD CB BA - LD D,RES 7,(IX+dd)
RESCOMBO        DDCBBA,7,regeix,regd

; DD CB BB - LD E,RES 7,(IX+dd)
RESCOMBO        DDCBBB,7,regeix,rege

; DD CB BC - LD H,RES 7,(IX+dd)
RESCOMBO        DDCBBC,7,regeix,regh

; DD CB BD - LD L,RES 7,(IX+dd)
RESCOMBO        DDCBBD,7,regeix,regl

; DD CB BE - RES 7,(IX+dd)
RESII           DDCBBE,7,regeix

; DD CB BF - LD A,RES 7,(IX+dd)
RESCOMBO        DDCBBF,7,regeix,dh

; DD CB C0 - LD B,SET 0,(IX+dd)
SETCOMBO        DDCBC0,0,regeix,regb

; DD CB C1 - LD C,SET 0,(IX+dd)
SETCOMBO        DDCBC1,0,regeix,regc

; DD CB C2 - LD D,SET 0,(IX+dd)
SETCOMBO        DDCBC2,0,regeix,regd

; DD CB C3 - LD E,SET 0,(IX+dd)
SETCOMBO        DDCBC3,0,regeix,rege

; DD CB C4 - LD H,SET 0,(IX+dd)
SETCOMBO        DDCBC4,0,regeix,regh

; DD CB C5 - LD L,SET 0,(IX+dd)
SETCOMBO        DDCBC5,0,regeix,regl

; DD CB C6 - SET 0,(IX+dd)
SETII           DDCBC6,0,regeix

; DD CB C7 - LD A,SET 0,(IX+dd)
SETCOMBO        DDCBC7,0,regeix,dh

; DD CB C8 - LD B,SET 1,(IX+dd)
SETCOMBO        DDCBC8,1,regeix,regb

; DD CB C9 - LD C,SET 1,(IX+dd)
SETCOMBO        DDCBC9,1,regeix,regc

; DD CB CA - LD D,SET 1,(IX+dd)
SETCOMBO        DDCBCA,1,regeix,regd

; DD CB CB - LD E,SET 1,(IX+dd)
SETCOMBO        DDCBCB,1,regeix,rege

; DD CB CC - LD H,SET 1,(IX+dd)
SETCOMBO        DDCBCC,1,regeix,regh

; DD CB CD - LD L,SET 1,(IX+dd)
SETCOMBO        DDCBCD,1,regeix,regl

; DD CB CE - SET 1,(IX+dd)
SETII           DDCBCE,1,regeix

; DD CB CF - LD A,SET 1,(IX+dd)
SETCOMBO        DDCBCF,1,regeix,dh

; DD CB D0 - LD B,SET 2,(IX+dd)
SETCOMBO        DDCBD0,2,regeix,regb

; DD CB D1 - LD C,SET 2,(IX+dd)
SETCOMBO        DDCBD1,2,regeix,regc

; DD CB D2 - LD D,SET 2,(IX+dd)
SETCOMBO        DDCBD2,2,regeix,regd

; DD CB D3 - LD E,SET 2,(IX+dd)
SETCOMBO        DDCBD3,2,regeix,rege

; DD CB D4 - LD H,SET 2,(IX+dd)
SETCOMBO        DDCBD4,2,regeix,regh

; DD CB D5 - LD L,SET 2,(IX+dd)
SETCOMBO        DDCBD5,2,regeix,regl

; DD CB D6 - SET 2,(IX+dd)
SETII           DDCBD6,2,regeix

; DD CB D7 - LD A,SET 2,(IX+dd)
SETCOMBO        DDCBD7,2,regeix,dh

; DD CB D8 - LD B,SET 3,(IX+dd)
SETCOMBO        DDCBD8,3,regeix,regb

; DD CB D9 - LD C,SET 3,(IX+dd)
SETCOMBO        DDCBD9,3,regeix,regc

; DD CB DA - LD D,SET 3,(IX+dd)
SETCOMBO        DDCBDA,3,regeix,regd

; DD CB DB - LD E,SET 3,(IX+dd)
SETCOMBO        DDCBDB,3,regeix,rege

; DD CB DC - LD H,SET 3,(IX+dd)
SETCOMBO        DDCBDC,3,regeix,regh

; DD CB DD - LD L,SET 3,(IX+dd)
SETCOMBO        DDCBDD,3,regeix,regl

; DD CB DE - SET 3,(IX+dd)
SETII           DDCBDE,3,regeix

; DD CB DF - LD A,SET 3,(IX+dd)
SETCOMBO        DDCBDF,3,regeix,dh

; DD CB E0 - LD B,SET 4,(IX+dd)
SETCOMBO        DDCBE0,4,regeix,regb

; DD CB E1 - LD C,SET 4,(IX+dd)
SETCOMBO        DDCBE1,4,regeix,regc

; DD CB E2 - LD D,SET 4,(IX+dd)
SETCOMBO        DDCBE2,4,regeix,regd

; DD CB E3 - LD E,SET 4,(IX+dd)
SETCOMBO        DDCBE3,4,regeix,rege

; DD CB E4 - LD H,SET 4,(IX+dd)
SETCOMBO        DDCBE4,4,regeix,regh

; DD CB E5 - LD L,SET 4,(IX+dd)
SETCOMBO        DDCBE5,4,regeix,regl

; DD CB E6 - SET 4,(IX+dd)
SETII           DDCBE6,4,regeix

; DD CB E7 - LD A,SET 4,(IX+dd)
SETCOMBO        DDCBE7,4,regeix,dh

; DD CB E8 - LD B,SET 5,(IX+dd)
SETCOMBO        DDCBE8,5,regeix,regb

; DD CB E9 - LD C,SET 5,(IX+dd)
SETCOMBO        DDCBE9,5,regeix,regc

; DD CB EA - LD D,SET 5,(IX+dd)
SETCOMBO        DDCBEA,5,regeix,regd

; DD CB EB - LD E,SET 5,(IX+dd)
SETCOMBO        DDCBEB,5,regeix,rege

; DD CB EC - LD H,SET 5,(IX+dd)
SETCOMBO        DDCBEC,5,regeix,regh

; DD CB ED - LD L,SET 5,(IX+dd)
SETCOMBO        DDCBED,5,regeix,regl

; DD CB EE - SET 5,(IX+dd)
SETII           DDCBEE,5,regeix

; DD CB EF - LD A,SET 5,(IX+dd)
SETCOMBO        DDCBEF,5,regeix,dh

; DD CB F0 - LD B,SET 6,(IX+dd)
SETCOMBO        DDCBF0,6,regeix,regb

; DD CB F1 - LD C,SET 6,(IX+dd)
SETCOMBO        DDCBF1,6,regeix,regc

; DD CB F2 - LD D,SET 6,(IX+dd)
SETCOMBO        DDCBF2,6,regeix,regd

; DD CB F3 - LD E,SET 6,(IX+dd)
SETCOMBO        DDCBF3,6,regeix,rege

; DD CB F4 - LD H,SET 6,(IX+dd)
SETCOMBO        DDCBF4,6,regeix,regh

; DD CB F5 - LD L,SET 6,(IX+dd)
SETCOMBO        DDCBF5,6,regeix,regl

; DD CB F6 - SET 6,(IX+dd)
SETII           DDCBF6,6,regeix

; DD CB F7 - LD A,SET 6,(IX+dd)
SETCOMBO        DDCBF7,6,regeix,dh

; DD CB F8 - LD B,SET 7,(IX+dd)
SETCOMBO        DDCBF8,7,regeix,regb

; DD CB F9 - LD C,SET 7,(IX+dd)
SETCOMBO        DDCBF9,7,regeix,regc

; DD CB FA - LD D,SET 7,(IX+dd)
SETCOMBO        DDCBFA,7,regeix,regd

; DD CB FB - LD E,SET 7,(IX+dd)
SETCOMBO        DDCBFB,7,regeix,rege

; DD CB FC - LD H,SET 7,(IX+dd)
SETCOMBO        DDCBFC,7,regeix,regh

; DD CB FD - LD L,SET 7,(IX+dd)
SETCOMBO        DDCBFD,7,regeix,regl

; DD CB FE - SET 7,(IX+dd)
SETII           DDCBFE,7,regeix

; DD CB FF - LD A,SET 7,(IX+dd)
SETCOMBO        DDCBFF,7,regeix,dh

; --------------------------------------------------------------------

; FD 09 - ADD IY,BC
ADDREGWREGW     FD09,_regiyl,_regiyh,regc,regb,15+2

; FD 19 - ADD IY,DE
ADDREGWREGW     FD19,_regiyl,_regiyh,rege,regd,15+2

; FD 21 - LD IY,dddd
LDREGWIMM      FD21,regeiy

; FD 22 - LD (dddd),IY
LDDDDDREGW      FD22,regeiy,20+2

; FD 23 - INC IY
INCWREG         FD23,_regiy,10+2

; FD 24 - INC IYh
INCREG          FD24,_regiyh

; FD 25 - DEC IYh
DECREG          FD25,_regiyh

; FD 26 - LD IYh,dd
LDREGIMM        FD26,_regiyh

; FD 29 - ADD IY,IY
ADDREGWREGW     FD29,_regiyl,_regiyh,_regiyl,_regiyh,15+2

; FD 2A - LD IY,(dddd)
LDREGWDDDD      FD2A,regeiy,20+2

; FD 2B - DEC IY
DECWREG         FD2B,_regiy,10+2

; FD 2C - INC IYl
INCREG          FD2C,_regiyl

; FD 2D - DEC IYl
DECREG          FD2D,_regiyl

; FD 2E - LD IYl,dd
LDREGIMM        FD2E,_regiyl

; FD 34 - INC (IY+dd)
INCII           FD34,regeiy

; FD 35 - DEC (IY+dd)
DECII           FD35,regeiy

; FD 36 - LD (IY+dd),dd
LDIIDDNN        FD36,regeiy

; FD 39 - ADD IY,SP
ADDREGWREGW     FD39,_regiyl,_regiyh,_regspl,_regsph,15+2

; FD 40 - FD null prefix
XNULL           FD40

; FD 41 - FD null prefix
XNULL           FD41

; FD 42 - FD null prefix
XNULL           FD42

; FD 43 - FD null prefix
XNULL           FD43

; FD 44 - LD B,IYh
LDREGREG        FD44,regb,_regiyh

; FD 45 - LD B,IYl
LDREGREG        FD45,regb,_regiyl

; FD 46 - LD B,(IY+dd)
LDREGIIDD       FD46,regb,regeiy

; FD 47 - FD null prefix
XNULL           FD47

; FD 48 - FD null prefix
XNULL           FD48

; FD 49 - FD null prefix
XNULL           FD49

; FD 4A - FD null prefix
XNULL           FD4A

; FD 4B - FD null prefix
XNULL           FD4B

; FD 4C - LD C,IYh
LDREGREG        FD4C,regc,_regiyh

; FD 4D - LD C,IYl
LDREGREG        FD4D,regc,_regiyl

; FD 4E - LD C,(IY+dd)
LDREGIIDD       FD4E,regc,regeiy

; FD 4F - FD null prefix
XNULL           FD4F

; FD 50 - FD null prefix
XNULL           FD50

; FD 51 - FD null prefix
XNULL           FD51

; FD 52 - FD null prefix
XNULL           FD52

; FD 53 - FD null prefix
XNULL           FD53

; FD 54 - LD D,IYh
LDREGREG        FD54,regd,_regiyh

; FD 55 - LD D,IYl
LDREGREG        FD55,regd,_regiyl

; FD 56 - LD D,(IY+dd)
LDREGIIDD       FD56,regd,regeiy

; FD 57 - FD null prefix
XNULL           FD57

; FD 58 - FD null prefix
XNULL           FD58

; FD 59 - FD null prefix
XNULL           FD59

; FD 5A - FD null prefix
XNULL           FD5A

; FD 5B - FD null prefix
XNULL           FD5B

; FD 5C - LD E,IYh
LDREGREG        FD5C,rege,_regiyh

; FD 5D - LD E,IYl
LDREGREG        FD5D,rege,_regiyl

; FD 5E - LD E,(IY+dd)
LDREGIIDD       FD5E,rege,regeiy

; FD 5F - FD null prefix
XNULL           FD5F

; FD 60 - LD IYh,B
LDREGREG        FD60,_regiyh,regb

; FD 61 - LD IYh,C
LDREGREG        FD61,_regiyh,regc

; FD 62 - LD IYh,D
LDREGREG        FD62,_regiyh,regd

; FD 63 - LD IYh,E
LDREGREG        FD63,_regiyh,rege

; FD 64 - LD IYh,IYh
LDREGREG        FD64,_regiyh,_regiyh

; FD 65 - LD IYh,IYl
LDREGREG        FD65,_regiyh,_regiyl

; FD 66 - LD H,(IY+dd)
LDREGIIDD       FD66,regh,regeiy

; FD 67 - LD IYh,A
LDREGREG        FD67,_regiyh,dh

; FD 68 - LD IYl,B
LDREGREG        FD68,_regiyl,regb

; FD 69 - LD IYl,C
LDREGREG        FD69,_regiyl,regc

; FD 6A - LD IYl,D
LDREGREG        FD6A,_regiyl,regd

; FD 6B - LD IYl,E
LDREGREG        FD6B,_regiyl,rege

; FD 6C - LD IYl,IYh
LDREGREG        FD6C,_regiyl,_regiyh

; FD 6D - LD IYl,IYl
LDREGREG        FD6D,_regiyl,_regiyl

; FD 6E - LD L,(IY+dd)
LDREGIIDD       FD6E,regl,regeiy

; FD 6F - LD IYl,A
LDREGREG        FD6F,_regiyl,dh

; FD 70 - LD (IY+dd),B
LDIIDDREG       FD70,regb,regeiy

; FD 71 - LD (IY+dd),C
LDIIDDREG       FD71,regc,regeiy

; FD 72 - LD (IY+dd),D
LDIIDDREG       FD72,regd,regeiy

; FD 73 - LD (IY+dd),E
LDIIDDREG       FD73,rege,regeiy

; FD 74 - LD (IY+dd),H
LDIIDDREG       FD74,regh,regeiy

; FD 75 - LD (IY+dd),L
LDIIDDREG       FD75,regl,regeiy

; FD 76 - FD null prefix
XNULL           FD76

; FD 77 - LD (IY+dd),A
LDIIDDREG       FD77,dh,regeiy

; FD 78 - FD null prefix
XNULL           FD78

; FD 79 - FD null prefix
XNULL           FD79

; FD 7A - FD null prefix
XNULL           FD7A

; FD 7B - FD null prefix
XNULL           FD7B

; FD 7C - LD A,IYh
LDREGREG        FD7C,dh,_regiyh

; FD 7D - LD A,IYl
LDREGREG        FD7D,dh,_regiyl

; FD 7E - LD A,(IY+dd)
LDREGIIDD       FD7E,dh,regeiy

; FD 7F - FD null prefix
XNULL           FD7F

; FD 84 - ADD A,IXh
ADDREG          FD84,_regiyh

; FD 85 - ADD A,IXl
ADDREG          FD85,_regiyl

; FD 86 - ADD A,(IY+dd)
ADDAII          FD86,regeiy

; FD 8C - ADC A,IXh
ADCREG          FD8C,_regiyh

; FD 8D - ADC A,IXl
ADCREG          FD8D,_regiyl

; FD 8E - ADC A,(IY+dd)
ADCAII          FD8E,regeiy

; FD 94 - SUB IXh
SUBREG          FD94,_regiyh

; FD 95 - SUB IXl
SUBREG          FD95,_regiyl

; FD 96 - SUB (IY+dd)
SUBII           FD96,regeiy

; FD 9C - SBC A,IXh
SBCREG          FD9C,_regiyh

; FD 9D - SBC A,IXl
SBCREG          FD9D,_regiyl

; FD 9E - SBC A,(IY+dd)
SBCAII          FD9E,regeiy

; FD A4 - AND IXh
ANDREG          FDA4,_regiyh

; FD A5 - AND IXl
ANDREG          FDA5,_regiyl

; FD A6 - AND (IY+dd)
ANDII           FDA6,regeiy

; FD AC - AND IXh
XORREG          FDAC,_regiyh

; FD AD - AND IXl
XORREG          FDAD,_regiyl

; FD AE - XOR (IY+dd)
XORII           FDAE,regeiy

; FD B4 - OR IXh
ORREG           FDB4,_regiyh

; FD B5 - OR IXl
ORREG           FDB5,_regiyl

; FD B6 - OR (IY+dd)
ORII            FDB6,regeiy

; FD BC - CP IXh
CPREG           FDBC,_regiyh

; FD BD - CP IXl
CPREG           FDBD,_regiyl

; FD BE - CP (IY+dd)
CPII            FDBE,regeiy

; FD CB - group FD CB
emulFDCB:       inc     edi
                inc     rcounter
                call    fetch
                mov     cl,al
                inc     edi
                call    fetch
                jmp     [offset isetFDCBxx+eax*4]

; FD E1 - POP IY
POPREGW         FDE1,regeiy,14+2

; FD E3 - EX (SP),IY
OPEXSPREGW      FDE3,regeiy,23+2

; FD E5 - PUSH IY
PUSHREGW        FDE5,regeiy,15+2

; FD E9 - JP (IY)
OPJPREGW        FDE9,regeiy,8+2

; FD F9 - LD SP,IY
LDSPREGW        FDF9,regeiy,10+2

; FD (NULL) - FD null prefix
XNULL           FDNULL

; FD CB 00 - LD B,RLC (IY+dd)
RLCCOMBO        FDCB00,regeiy,regb

; FD CB 01 - LD C,RLC (IY+dd)
RLCCOMBO        FDCB01,regeiy,regc

; FD CB 02 - LD D,RLC (IY+dd)
RLCCOMBO        FDCB02,regeiy,regd

; FD CB 03 - LD E,RLC (IY+dd)
RLCCOMBO        FDCB03,regeiy,rege

; FD CB 04 - LD H,RLC (IY+dd)
RLCCOMBO        FDCB04,regeiy,regh

; FD CB 05 - LD L,RLC (IY+dd)
RLCCOMBO        FDCB05,regeiy,regl

; FD CB 06 - RLC (IY+dd)
RLCII           FDCB06,regeiy

; FD CB 07 - LD A,RLC (IY+dd)
RLCCOMBO        FDCB07,regeiy,dh

; FD CB 08 - LD B,RRC (IY+dd)
RRCCOMBO        FDCB08,regeiy,regb

; FD CB 09 - LD C,RRC (IY+dd)
RRCCOMBO        FDCB09,regeiy,regc

; FD CB 0A - LD D,RRC (IY+dd)
RRCCOMBO        FDCB0A,regeiy,regd

; FD CB 0B - LD E,RRC (IY+dd)
RRCCOMBO        FDCB0B,regeiy,rege

; FD CB 0C - LD H,RRC (IY+dd)
RRCCOMBO        FDCB0C,regeiy,regh

; FD CB 0D - LD L,RRC (IY+dd)
RRCCOMBO        FDCB0D,regeiy,regl

; FD CB 0E - RRC (IY+dd)
RRCII           FDCB0E,regeiy

; FD CB 0F - LD A,RRC (IY+dd)
RRCCOMBO        FDCB0F,regeiy,dh

; FD CB 10 - LD B,RL (IY+dd)
RLCOMBO         FDCB10,regeiy,regb

; FD CB 11 - LD C,RL (IY+dd)
RLCOMBO         FDCB11,regeiy,regc

; FD CB 12 - LD D,RL (IY+dd)
RLCOMBO         FDCB12,regeiy,regd
  
; FD CB 13 - LD E,RL (IY+dd)
RLCOMBO         FDCB13,regeiy,rege

; FD CB 14 - LD H,RL (IY+dd)
RLCOMBO         FDCB14,regeiy,regh

; FD CB 15 - LD L,RL (IY+dd)
RLCOMBO         FDCB15,regeiy,regl

; FD CB 16 - RL (IY+dd)
RLII            FDCB16,regeiy

; FD CB 17 - LD A,RL (IY+dd)
RLCOMBO         FDCB17,regeiy,dh

; FD CB 18 - LD B,RR (IY+dd)
RRCOMBO         FDCB18,regeiy,regb

; FD CB 19 - LD C,RR (IY+dd)
RRCOMBO         FDCB19,regeiy,regc

; FD CB 1A - LD D,RR (IY+dd)
RRCOMBO         FDCB1A,regeiy,regd

; FD CB 1B - LD E,RR (IY+dd)
RRCOMBO         FDCB1B,regeiy,rege
  
; FD CB 1C - LD H,RR (IY+dd)
RRCOMBO         FDCB1C,regeiy,regh

; FD CB 1D - LD L,RR (IY+dd)
RRCOMBO         FDCB1D,regeiy,regl

; FD CB 1E - RR (IY+dd)
RRII            FDCB1E,regeiy

; FD CB 1F - LD A,RR (IY+dd)
RRCOMBO         FDCB1F,regeiy,dh

; FD CB 20 - LD B,SLA (IY+dd)
SLACOMBO        FDCB20,regeiy,regb

; FD CB 21 - LD C,SLA (IY+dd)
SLACOMBO        FDCB21,regeiy,regc

; FD CB 22 - LD D,SLA (IY+dd)
SLACOMBO        FDCB22,regeiy,regd
  
; FD CB 23 - LD E,SLA (IY+dd)
SLACOMBO        FDCB23,regeiy,rege

; FD CB 24 - LD H,SLA (IY+dd)
SLACOMBO        FDCB24,regeiy,regh

; FD CB 25 - LD L,SLA (IY+dd)
SLACOMBO        FDCB25,regeiy,regl

; FD CB 26 - SLA (IY+dd)
SLAII           FDCB26,regeiy

; FD CB 27 - LD A,SLA (IY+dd)
SLACOMBO        FDCB27,regeiy,dh

; FD CB 28 - LD B,SRA (IY+dd)
SRACOMBO        FDCB28,regeiy,regb

; FD CB 29 - LD C,SRA (IY+dd)
SRACOMBO        FDCB29,regeiy,regc

; FD CB 2A - LD D,SRA (IY+dd)
SRACOMBO        FDCB2A,regeiy,regd

; FD CB 2B - LD E,SRA (IY+dd)
SRACOMBO        FDCB2B,regeiy,rege
  
; FD CB 2C - LD H,SRA (IY+dd)
SRACOMBO        FDCB2C,regeiy,regh

; FD CB 2D - LD L,SRA (IY+dd)
SRACOMBO        FDCB2D,regeiy,regl

; FD CB 2E - SRA (IY+dd)
SRAII           FDCB2E,regeiy

; FD CB 2F - LD A,SRA (IY+dd)
SRACOMBO        FDCB2F,regeiy,dh

; FD CB 30 - LD B,SLL (IY+dd)
SLLCOMBO        FDCB30,regeiy,regb

; FD CB 31 - LD C,SLL (IY+dd)
SLLCOMBO        FDCB31,regeiy,regc

; FD CB 32 - LD D,SLL (IY+dd)
SLLCOMBO        FDCB32,regeiy,regd
  
; FD CB 33 - LD E,SLL (IY+dd)
SLLCOMBO        FDCB33,regeiy,rege

; FD CB 34 - LD H,SLL (IY+dd)
SLLCOMBO        FDCB34,regeiy,regh

; FD CB 35 - LD L,SLL (IY+dd)
SLLCOMBO        FDCB35,regeiy,regl

; FD CB 36 - SLL (IY+dd)
SLLII           FDCB36,regeiy

; FD CB 37 - LD A,SLL (IY+dd)
SLLCOMBO        FDCB37,regeiy,dh

; FD CB 38 - LD B,SRL (IY+dd)
SRLCOMBO        FDCB38,regeiy,regb

; FD CB 39 - LD C,SRL (IY+dd)
SRLCOMBO        FDCB39,regeiy,regc

; FD CB 3A - LD D,SRL (IY+dd)
SRLCOMBO        FDCB3A,regeiy,regd

; FD CB 3B - LD E,SRL (IY+dd)
SRLCOMBO        FDCB3B,regeiy,rege
  
; FD CB 3C - LD H,SRL (IY+dd)
SRLCOMBO        FDCB3C,regeiy,regh

; FD CB 3D - LD L,SRL (IY+dd)
SRLCOMBO        FDCB3D,regeiy,regl

; FD CB 3E - SRL (IY+dd)
SRLII           FDCB3E,regeiy

; FD CB 3F - LD A,SRL (IY+dd)
SRLCOMBO        FDCB3F,regeiy,dh

; FD CB 40 - BIT 0,(IY+dd)
BITII           FDCB40,0,regeiy

; FD CB 41 - BIT 0,(IY+dd)
BITII           FDCB41,0,regeiy

; FD CB 42 - BIT 0,(IY+dd)
BITII           FDCB42,0,regeiy

; FD CB 43 - BIT 0,(IY+dd)
BITII           FDCB43,0,regeiy

; FD CB 44 - BIT 0,(IY+dd)
BITII           FDCB44,0,regeiy

; FD CB 45 - BIT 0,(IY+dd)
BITII           FDCB45,0,regeiy

; FD CB 46 - BIT 0,(IY+dd)
BITII           FDCB46,0,regeiy

; FD CB 47 - BIT 0,(IY+dd)
BITII           FDCB47,0,regeiy

; FD CB 48 - BIT 1,(IY+dd)
BITII           FDCB48,1,regeiy

; FD CB 49 - BIT 1,(IY+dd)
BITII           FDCB49,1,regeiy

; FD CB 4A - BIT 1,(IY+dd)
BITII           FDCB4A,1,regeiy

; FD CB 4B - BIT 1,(IY+dd)
BITII           FDCB4B,1,regeiy

; FD CB 4C - BIT 1,(IY+dd)
BITII           FDCB4C,1,regeiy

; FD CB 4D - BIT 1,(IY+dd)
BITII           FDCB4D,1,regeiy

; FD CB 4E - BIT 1,(IY+dd)
BITII           FDCB4E,1,regeiy

; FD CB 4F - BIT 1,(IY+dd)
BITII           FDCB4F,1,regeiy

; FD CB 50 - BIT 2,(IY+dd)
BITII           FDCB50,2,regeiy

; FD CB 51 - BIT 2,(IY+dd)
BITII           FDCB51,2,regeiy

; FD CB 52 - BIT 2,(IY+dd)
BITII           FDCB52,2,regeiy

; FD CB 53 - BIT 2,(IY+dd)
BITII           FDCB53,2,regeiy

; FD CB 54 - BIT 2,(IY+dd)
BITII           FDCB54,2,regeiy

; FD CB 55 - BIT 2,(IY+dd)
BITII           FDCB55,2,regeiy

; FD CB 56 - BIT 2,(IY+dd)
BITII           FDCB56,2,regeiy

; FD CB 57 - BIT 2,(IY+dd)
BITII           FDCB57,2,regeiy

; FD CB 58 - BIT 3,(IY+dd)
BITII           FDCB58,3,regeiy

; FD CB 59 - BIT 3,(IY+dd)
BITII           FDCB59,3,regeiy

; FD CB 5A - BIT 3,(IY+dd)
BITII           FDCB5A,3,regeiy

; FD CB 5B - BIT 3,(IY+dd)
BITII           FDCB5B,3,regeiy

; FD CB 5C - BIT 3,(IY+dd)
BITII           FDCB5C,3,regeiy

; FD CB 5D - BIT 3,(IY+dd)
BITII           FDCB5D,3,regeiy

; FD CB 5E - BIT 3,(IY+dd)
BITII           FDCB5E,3,regeiy

; FD CB 5F - BIT 3,(IY+dd)
BITII           FDCB5F,3,regeiy

; FD CB 60 - BIT 4,(IY+dd)
BITII           FDCB60,4,regeiy

; FD CB 61 - BIT 4,(IY+dd)
BITII           FDCB61,4,regeiy

; FD CB 62 - BIT 4,(IY+dd)
BITII           FDCB62,4,regeiy

; FD CB 63 - BIT 4,(IY+dd)
BITII           FDCB63,4,regeiy

; FD CB 64 - BIT 4,(IY+dd)
BITII           FDCB64,4,regeiy

; FD CB 65 - BIT 4,(IY+dd)
BITII           FDCB65,4,regeiy

; FD CB 66 - BIT 4,(IY+dd)
BITII           FDCB66,4,regeiy

; FD CB 67 - BIT 4,(IY+dd)
BITII           FDCB67,4,regeiy

; FD CB 68 - BIT 5,(IY+dd)
BITII           FDCB68,5,regeiy

; FD CB 69 - BIT 5,(IY+dd)
BITII           FDCB69,5,regeiy

; FD CB 6A - BIT 5,(IY+dd)
BITII           FDCB6A,5,regeiy

; FD CB 6B - BIT 5,(IY+dd)
BITII           FDCB6B,5,regeiy

; FD CB 6C - BIT 5,(IY+dd)
BITII           FDCB6C,5,regeiy

; FD CB 6D - BIT 5,(IY+dd)
BITII           FDCB6D,5,regeiy

; FD CB 6E - BIT 5,(IY+dd)
BITII           FDCB6E,5,regeiy

; FD CB 6F - BIT 5,(IY+dd)
BITII           FDCB6F,5,regeiy

; FD CB 70 - BIT 6,(IY+dd)
BITII           FDCB70,6,regeiy

; FD CB 71 - BIT 6,(IY+dd)
BITII           FDCB71,6,regeiy

; FD CB 72 - BIT 6,(IY+dd)
BITII           FDCB72,6,regeiy

; FD CB 73 - BIT 6,(IY+dd)
BITII           FDCB73,6,regeiy

; FD CB 74 - BIT 6,(IY+dd)
BITII           FDCB74,6,regeiy

; FD CB 75 - BIT 6,(IY+dd)
BITII           FDCB75,6,regeiy

; FD CB 76 - BIT 6,(IY+dd)
BITII           FDCB76,6,regeiy

; FD CB 77 - BIT 6,(IY+dd)
BITII           FDCB77,6,regeiy

; FD CB 78 - BIT 7,(IY+dd)
BITII           FDCB78,7,regeiy

; FD CB 79 - BIT 7,(IY+dd)
BITII           FDCB79,7,regeiy

; FD CB 7A - BIT 7,(IY+dd)
BITII           FDCB7A,7,regeiy

; FD CB 7B - BIT 7,(IY+dd)
BITII           FDCB7B,7,regeiy

; FD CB 7C - BIT 7,(IY+dd)
BITII           FDCB7C,7,regeiy

; FD CB 7D - BIT 7,(IY+dd)
BITII           FDCB7D,7,regeiy

; FD CB 7E - BIT 7,(IY+dd)
BITII           FDCB7E,7,regeiy

; FD CB 7F - BIT 7,(IY+dd)
BITII           FDCB7F,7,regeiy

; FD CB 80 - LD B,RES 0,(IY+dd)
RESCOMBO        FDCB80,0,regeiy,regb

; FD CB 81 - LD C,RES 0,(IY+dd)
RESCOMBO        FDCB81,0,regeiy,regc

; FD CB 82 - LD D,RES 0,(IY+dd)
RESCOMBO        FDCB82,0,regeiy,regd

; FD CB 83 - LD E,RES 0,(IY+dd)
RESCOMBO        FDCB83,0,regeiy,rege

; FD CB 84 - LD H,RES 0,(IY+dd)
RESCOMBO        FDCB84,0,regeiy,regh

; FD CB 85 - LD L,RES 0,(IY+dd)
RESCOMBO        FDCB85,0,regeiy,regl

; FD CB 86 - RES 0,(IY+dd)
RESII           FDCB86,0,regeiy

; FD CB 87 - LD A,RES 0,(IY+dd)
RESCOMBO        FDCB87,0,regeiy,dh

; FD CB 88 - LD B,RES 1,(IY+dd)
RESCOMBO        FDCB88,1,regeiy,regb

; FD CB 89 - LD C,RES 1,(IY+dd)
RESCOMBO        FDCB89,1,regeiy,regc

; FD CB 8A - LD D,RES 1,(IY+dd)
RESCOMBO        FDCB8A,1,regeiy,regd

; FD CB 8B - LD E,RES 1,(IY+dd)
RESCOMBO        FDCB8B,1,regeiy,rege

; FD CB 8C - LD H,RES 1,(IY+dd)
RESCOMBO        FDCB8C,1,regeiy,regh

; FD CB 8D - LD L,RES 1,(IY+dd)
RESCOMBO        FDCB8D,1,regeiy,regl

; FD CB 8E - RES 1,(IY+dd)
RESII           FDCB8E,1,regeiy

; FD CB 8F - LD A,RES 1,(IY+dd)
RESCOMBO        FDCB8F,1,regeiy,dh

; FD CB 90 - LD B,RES 2,(IY+dd)
RESCOMBO        FDCB90,2,regeiy,regb

; FD CB 91 - LD C,RES 2,(IY+dd)
RESCOMBO        FDCB91,2,regeiy,regc

; FD CB 92 - LD D,RES 2,(IY+dd)
RESCOMBO        FDCB92,2,regeiy,regd

; FD CB 93 - LD E,RES 2,(IY+dd)
RESCOMBO        FDCB93,2,regeiy,rege

; FD CB 94 - LD H,RES 2,(IY+dd)
RESCOMBO        FDCB94,2,regeiy,regh

; FD CB 95 - LD L,RES 2,(IY+dd)
RESCOMBO        FDCB95,2,regeiy,regl

; FD CB 96 - RES 2,(IY+dd)
RESII           FDCB96,2,regeiy

; FD CB 97 - LD A,RES 2,(IY+dd)
RESCOMBO        FDCB97,2,regeiy,dh

; FD CB 98 - LD B,RES 3,(IY+dd)
RESCOMBO        FDCB98,3,regeiy,regb

; FD CB 99 - LD C,RES 3,(IY+dd)
RESCOMBO        FDCB99,3,regeiy,regc

; FD CB 9A - LD D,RES 3,(IY+dd)
RESCOMBO        FDCB9A,3,regeiy,regd

; FD CB 9B - LD E,RES 3,(IY+dd)
RESCOMBO        FDCB9B,3,regeiy,rege

; FD CB 9C - LD H,RES 3,(IY+dd)
RESCOMBO        FDCB9C,3,regeiy,regh

; FD CB 9D - LD L,RES 3,(IY+dd)
RESCOMBO        FDCB9D,3,regeiy,regl

; FD CB 9E - RES 3,(IY+dd)
RESII           FDCB9E,3,regeiy

; FD CB 9F - LD A,RES 3,(IY+dd)
RESCOMBO        FDCB9F,3,regeiy,dh

; FD CB A0 - LD B,RES 4,(IY+dd)
RESCOMBO        FDCBA0,4,regeiy,regb

; FD CB A1 - LD C,RES 4,(IY+dd)
RESCOMBO        FDCBA1,4,regeiy,regc

; FD CB A2 - LD D,RES 4,(IY+dd)
RESCOMBO        FDCBA2,4,regeiy,regd

; FD CB A3 - LD E,RES 4,(IY+dd)
RESCOMBO        FDCBA3,4,regeiy,rege

; FD CB A4 - LD H,RES 4,(IY+dd)
RESCOMBO        FDCBA4,4,regeiy,regh

; FD CB A5 - LD L,RES 4,(IY+dd)
RESCOMBO        FDCBA5,4,regeiy,regl

; FD CB A6 - RES 4,(IY+dd)
RESII           FDCBA6,4,regeiy

; FD CB A7 - LD A,RES 4,(IY+dd)
RESCOMBO        FDCBA7,4,regeiy,dh

; FD CB A8 - LD B,RES 5,(IY+dd)
RESCOMBO        FDCBA8,5,regeiy,regb

; FD CB A9 - LD C,RES 5,(IY+dd)
RESCOMBO        FDCBA9,5,regeiy,regc

; FD CB AA - LD D,RES 5,(IY+dd)
RESCOMBO        FDCBAA,5,regeiy,regd

; FD CB AB - LD E,RES 5,(IY+dd)
RESCOMBO        FDCBAB,5,regeiy,rege

; FD CB AC - LD H,RES 5,(IY+dd)
RESCOMBO        FDCBAC,5,regeiy,regh

; FD CB AD - LD L,RES 5,(IY+dd)
RESCOMBO        FDCBAD,5,regeiy,regl

; FD CB AE - RES 5,(IY+dd)
RESII           FDCBAE,5,regeiy

; FD CB AF - LD A,RES 5,(IY+dd)
RESCOMBO        FDCBAF,5,regeiy,dh

; FD CB B0 - LD B,RES 6,(IY+dd)
RESCOMBO        FDCBB0,6,regeiy,regb

; FD CB B1 - LD C,RES 6,(IY+dd)
RESCOMBO        FDCBB1,6,regeiy,regc

; FD CB B2 - LD D,RES 6,(IY+dd)
RESCOMBO        FDCBB2,6,regeiy,regd

; FD CB B3 - LD E,RES 6,(IY+dd)
RESCOMBO        FDCBB3,6,regeiy,rege

; FD CB B4 - LD H,RES 6,(IY+dd)
RESCOMBO        FDCBB4,6,regeiy,regh

; FD CB B5 - LD L,RES 6,(IY+dd)
RESCOMBO        FDCBB5,6,regeiy,regl

; FD CB B6 - RES 6,(IY+dd)
RESII           FDCBB6,6,regeiy

; FD CB B7 - LD A,RES 6,(IY+dd)
RESCOMBO        FDCBB7,6,regeiy,dh

; FD CB B8 - LD B,RES 7,(IY+dd)
RESCOMBO        FDCBB8,7,regeiy,regb

; FD CB B9 - LD C,RES 7,(IY+dd)
RESCOMBO        FDCBB9,7,regeiy,regc

; FD CB BA - LD D,RES 7,(IY+dd)
RESCOMBO        FDCBBA,7,regeiy,regd

; FD CB BB - LD E,RES 7,(IY+dd)
RESCOMBO        FDCBBB,7,regeiy,rege

; FD CB BC - LD H,RES 7,(IY+dd)
RESCOMBO        FDCBBC,7,regeiy,regh

; FD CB BD - LD L,RES 7,(IY+dd)
RESCOMBO        FDCBBD,7,regeiy,regl

; FD CB BE - RES 7,(IY+dd)
RESII           FDCBBE,7,regeiy

; FD CB BF - LD A,RES 7,(IY+dd)
RESCOMBO        FDCBBF,7,regeiy,dh

; FD CB C0 - LD B,SET 0,(IY+dd)
SETCOMBO        FDCBC0,0,regeiy,regb

; FD CB C1 - LD C,SET 0,(IY+dd)
SETCOMBO        FDCBC1,0,regeiy,regc

; FD CB C2 - LD D,SET 0,(IY+dd)
SETCOMBO        FDCBC2,0,regeiy,regd

; FD CB C3 - LD E,SET 0,(IY+dd)
SETCOMBO        FDCBC3,0,regeiy,rege

; FD CB C4 - LD H,SET 0,(IY+dd)
SETCOMBO        FDCBC4,0,regeiy,regh

; FD CB C5 - LD L,SET 0,(IY+dd)
SETCOMBO        FDCBC5,0,regeiy,regl

; FD CB C6 - SET 0,(IY+dd)
SETII           FDCBC6,0,regeiy

; FD CB C7 - LD A,SET 0,(IY+dd)
SETCOMBO        FDCBC7,0,regeiy,dh

; FD CB C8 - LD B,SET 1,(IY+dd)
SETCOMBO        FDCBC8,1,regeiy,regb

; FD CB C9 - LD C,SET 1,(IY+dd)
SETCOMBO        FDCBC9,1,regeiy,regc

; FD CB CA - LD D,SET 1,(IY+dd)
SETCOMBO        FDCBCA,1,regeiy,regd

; FD CB CB - LD E,SET 1,(IY+dd)
SETCOMBO        FDCBCB,1,regeiy,rege

; FD CB CC - LD H,SET 1,(IY+dd)
SETCOMBO        FDCBCC,1,regeiy,regh

; FD CB CD - LD L,SET 1,(IY+dd)
SETCOMBO        FDCBCD,1,regeiy,regl

; FD CB CE - SET 1,(IY+dd)
SETII           FDCBCE,1,regeiy

; FD CB CF - LD A,SET 1,(IY+dd)
SETCOMBO        FDCBCF,1,regeiy,dh

; FD CB D0 - LD B,SET 2,(IY+dd)
SETCOMBO        FDCBD0,2,regeiy,regb

; FD CB D1 - LD C,SET 2,(IY+dd)
SETCOMBO        FDCBD1,2,regeiy,regc

; FD CB D2 - LD D,SET 2,(IY+dd)
SETCOMBO        FDCBD2,2,regeiy,regd

; FD CB D3 - LD E,SET 2,(IY+dd)
SETCOMBO        FDCBD3,2,regeiy,rege

; FD CB D4 - LD H,SET 2,(IY+dd)
SETCOMBO        FDCBD4,2,regeiy,regh

; FD CB D5 - LD L,SET 2,(IY+dd)
SETCOMBO        FDCBD5,2,regeiy,regl

; FD CB D6 - SET 2,(IY+dd)
SETII           FDCBD6,2,regeiy

; FD CB D7 - LD A,SET 2,(IY+dd)
SETCOMBO        FDCBD7,2,regeiy,dh

; FD CB D8 - LD B,SET 3,(IY+dd)
SETCOMBO        FDCBD8,3,regeiy,regb

; FD CB D9 - LD C,SET 3,(IY+dd)
SETCOMBO        FDCBD9,3,regeiy,regc

; FD CB DA - LD D,SET 3,(IY+dd)
SETCOMBO        FDCBDA,3,regeiy,regd

; FD CB DB - LD E,SET 3,(IY+dd)
SETCOMBO        FDCBDB,3,regeiy,rege

; FD CB DC - LD H,SET 3,(IY+dd)
SETCOMBO        FDCBDC,3,regeiy,regh

; FD CB DD - LD L,SET 3,(IY+dd)
SETCOMBO        FDCBDD,3,regeiy,regl

; FD CB DE - SET 3,(IY+dd)
SETII           FDCBDE,3,regeiy

; FD CB DF - LD A,SET 3,(IY+dd)
SETCOMBO        FDCBDF,3,regeiy,dh

; FD CB E0 - LD B,SET 4,(IY+dd)
SETCOMBO        FDCBE0,4,regeiy,regb

; FD CB E1 - LD C,SET 4,(IY+dd)
SETCOMBO        FDCBE1,4,regeiy,regc

; FD CB E2 - LD D,SET 4,(IY+dd)
SETCOMBO        FDCBE2,4,regeiy,regd

; FD CB E3 - LD E,SET 4,(IY+dd)
SETCOMBO        FDCBE3,4,regeiy,rege

; FD CB E4 - LD H,SET 4,(IY+dd)
SETCOMBO        FDCBE4,4,regeiy,regh

; FD CB E5 - LD L,SET 4,(IY+dd)
SETCOMBO        FDCBE5,4,regeiy,regl

; FD CB E6 - SET 4,(IY+dd)
SETII           FDCBE6,4,regeiy

; FD CB E7 - LD A,SET 4,(IY+dd)
SETCOMBO        FDCBE7,4,regeiy,dh

; FD CB E8 - LD B,SET 5,(IY+dd)
SETCOMBO        FDCBE8,5,regeiy,regb

; FD CB E9 - LD C,SET 5,(IY+dd)
SETCOMBO        FDCBE9,5,regeiy,regc

; FD CB EA - LD D,SET 5,(IY+dd)
SETCOMBO        FDCBEA,5,regeiy,regd

; FD CB EB - LD E,SET 5,(IY+dd)
SETCOMBO        FDCBEB,5,regeiy,rege

; FD CB EC - LD H,SET 5,(IY+dd)
SETCOMBO        FDCBEC,5,regeiy,regh

; FD CB ED - LD L,SET 5,(IY+dd)
SETCOMBO        FDCBED,5,regeiy,regl

; FD CB EE - SET 5,(IY+dd)
SETII           FDCBEE,5,regeiy

; FD CB EF - LD A,SET 5,(IY+dd)
SETCOMBO        FDCBEF,5,regeiy,dh

; FD CB F0 - LD B,SET 6,(IY+dd)
SETCOMBO        FDCBF0,6,regeiy,regb

; FD CB F1 - LD C,SET 6,(IY+dd)
SETCOMBO        FDCBF1,6,regeiy,regc

; FD CB F2 - LD D,SET 6,(IY+dd)
SETCOMBO        FDCBF2,6,regeiy,regd

; FD CB F3 - LD E,SET 6,(IY+dd)
SETCOMBO        FDCBF3,6,regeiy,rege

; FD CB F4 - LD H,SET 6,(IY+dd)
SETCOMBO        FDCBF4,6,regeiy,regh

; FD CB F5 - LD L,SET 6,(IY+dd)
SETCOMBO        FDCBF5,6,regeiy,regl

; FD CB F6 - SET 6,(IY+dd)
SETII           FDCBF6,6,regeiy

; FD CB F7 - LD A,SET 6,(IY+dd)
SETCOMBO        FDCBF7,6,regeiy,dh

; FD CB F8 - LD B,SET 7,(IY+dd)
SETCOMBO        FDCBF8,7,regeiy,regb

; FD CB F9 - LD C,SET 7,(IY+dd)
SETCOMBO        FDCBF9,7,regeiy,regc

; FD CB FA - LD D,SET 7,(IY+dd)
SETCOMBO        FDCBFA,7,regeiy,regd

; FD CB FB - LD E,SET 7,(IY+dd)
SETCOMBO        FDCBFB,7,regeiy,rege

; FD CB FC - LD H,SET 7,(IY+dd)
SETCOMBO        FDCBFC,7,regeiy,regh

; FD CB FD - LD L,SET 7,(IY+dd)
SETCOMBO        FDCBFD,7,regeiy,regl

; FD CB FE - SET 7,(IY+dd)
SETII           FDCBFE,7,regeiy

; FD CB FF - LD A,SET 7,(IY+dd)
SETCOMBO        FDCBFF,7,regeiy,dh


        end
