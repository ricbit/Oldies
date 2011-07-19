; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80CB.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include opcode.inc
include bit.inc
include fetch.inc
include pmode.inc
include z80core.inc

extrn isetCBxx: near
extrn isetDDxx: near
extrn isetEDxx: near
extrn isetFDxx: near
extrn logout: dword

public emulC9
public emulCB
public emulDD
public emulED
public emulFD
public emulFF
public emulFB_MSX2
public emul76_MSX2
public emulXX
public iset

; DATA ---------------------------------------------------------------

align 4

include flags.inc
include iset.inc

; --------------------------------------------------------------------

; 00 - NOP
OPNOP           00

; 01 - LD BC,dddd
LDREGWIMM       01,regebc

; 02 - LD (BC),A
LDREGWA         02,regebc

; 03 - INC BC
INCWREG         03,regbc,6+1

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
DECWREG         0B,regbc,6+1

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
INCWREG         13,regde,6+1

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
DECWREG         1B,regde,6+1

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
INCWREG         23,reghl,6+1

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
DECWREG         2B,reghl,6+1

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
INCWREG         33,regsp,6+1

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
ADDREGWREGW     39,regl,regh,regspl,regsph,11+1

; 3A - LD A,(dddd)
LDAIND          3A

; 3B - DEC SP
DECWREG         3B,regsp,6+1

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
OPHALT_MSX2     76_MSX2

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
               
                cmp     ebx,01FFCh
                jae     emulCB_slow

                mov     al,[esi+ebx+1]
                inc     edi
                inc     rcounter
                inc     ebx
                jmp     [offset isetCBxx+eax*4]

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
emulDD:         ;inc     edi
                ;inc     rcounter
                ;call    fetch
                ;jmp     [offset isetDDxx+eax*4]

                cmp     ebx,01FFCh
                jae     emulDD_slow

                mov     al,[esi+ebx+1]
                inc     edi
                inc     rcounter
                inc     ebx
                jmp     [offset isetDDxx+eax*4]

emulDD_slow:
                inc     edi
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

                cmp     ebx,01FFCh
                jae     emulED_slow

                mov     al,[esi+ebx+1]
                inc     edi
                inc     rcounter
                inc     ebx
                jmp     [offset isetEDxx+eax*4]

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
OPEI_MSX2       FB_MSX2

; FC - CALL M,dddd
CALLCC          FC,SIGN_FLAG,jnz

; FD - group FD
emulFD:         ;inc     edi
                ;inc     rcounter
                ;call    fetch
                ;jmp     [offset isetFDxx+eax*4]


                cmp     ebx,01FFCh
                jae     emulFD_slow

                mov     al,[esi+ebx+1]
                inc     edi
                inc     rcounter
                inc     ebx
                jmp     [offset isetFDxx+eax*4]

emulFD_slow:
                inc     edi
                inc     rcounter
                call    fetch
                jmp     [offset isetFDxx+eax*4]

; FE - CP dd
CPIMM           FE

; FF - RST 38
OPRST           FF,038h

; XX - not found
emulXX:         mov     error,1
                mov     interrupt,1
                mov     ebp,0
                ret



code32          ends
                end


