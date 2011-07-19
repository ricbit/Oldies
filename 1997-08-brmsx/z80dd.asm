; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80DD.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include z80sing.inc
include opcode.inc
include bit.inc
include fetch.inc

; DATA ---------------------------------------------------------------

align 4

include isetDD.inc
include isetDDCB.inc
public isetDDxx

; --------------------------------------------------------------------

; DD 09 - ADD IX,BC
ADDREGWREGW     DD09,regixl,regixh,regc,regb,15+2

; DD 19 - ADD IX,DE
ADDREGWREGW     DD19,regixl,regixh,rege,regd,15+2

; DD 21 - LD IX,dddd
LDREGWIMM      DD21,regeix

; DD 22 - LD (dddd),IX
LDDDDDREGW      DD22,regeix,20+2

; DD 23 - INC IX
INCWREG         DD23,regix,10+2

; DD 24 - INC IXh
INCREG          DD24,regixh

; DD 25 - DEC IXh
DECREG          DD25,regixh

; DD 26 - LD IXh,dd
LDREGIMM        DD26,regixh

; DD 29 - ADD IX,IX
ADDREGWREGW     DD29,regixl,regixh,regixl,regixh,15+2

; DD 2A - LD IX,(dddd)
LDREGWDDDD      DD2A,regeix,20+2

; DD 2B - DEC IX
DECWREG         DD2B,regix,10+2

; DD 2C - INC IXl
INCREG          DD2C,regixl

; DD 2D - DEC IXl
DECREG          DD2D,regixl

; DD 2E - LD IXl,dd
LDREGIMM        DD2E,regixl

; DD 34 - INC (IX+dd)
INCII           DD34,regeix

; DD 35 - DEC (IX+dd)
DECII           DD35,regeix

; DD 36 - LD (IX+dd),dd
LDIIDDNN        DD36,regeix

; DD 39 - ADD IX,SP
ADDREGWREGW     DD39,regixl,regixh,regspl,regsph,15+2

; DD 40 - DD null prefix
XNULL           DD40

; DD 41 - DD null prefix
XNULL           DD41

; DD 42 - DD null prefix
XNULL           DD42

; DD 43 - DD null prefix
XNULL           DD43

; DD 44 - LD B,IXh
LDREGREG        DD44,regb,regixh

; DD 45 - LD B,IXl
LDREGREG        DD45,regb,regixl

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
LDREGREG        DD4C,regc,regixh

; DD 4D - LD C,IXl
LDREGREG        DD4D,regc,regixl

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
LDREGREG        DD54,regd,regixh

; DD 55 - LD D,IXl
LDREGREG        DD55,regd,regixl

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
LDREGREG        DD5C,rege,regixh

; DD 5D - LD E,IXl
LDREGREG        DD5D,rege,regixl

; DD 5E - LD E,(IX+dd)
LDREGIIDD       DD5E,rege,regeix

; DD 5F - DD null prefix
XNULL           DD5F

; DD 60 - LD IXh,B
LDREGREG        DD60,regixh,regb

; DD 61 - LD IXh,C
LDREGREG        DD61,regixh,regc

; DD 62 - LD IXh,D
LDREGREG        DD62,regixh,regd

; DD 63 - LD IXh,E
LDREGREG        DD63,regixh,rege

; DD 64 - LD IXh,IXh
LDREGREG        DD64,regixh,regixh

; DD 65 - LD IXh,IXl
LDREGREG        DD65,regixh,regixl

; DD 66 - LD H,(IX+dd)
LDREGIIDD       DD66,regh,regeix

; DD 67 - LD IXh,A
LDREGREG        DD67,regixh,dh

; DD 68 - LD IXl,B
LDREGREG        DD68,regixl,regb

; DD 69 - LD IXl,C
LDREGREG        DD69,regixl,regc

; DD 6A - LD IXl,D
LDREGREG        DD6A,regixl,regd

; DD 6B - LD IXl,E
LDREGREG        DD6B,regixl,rege

; DD 6C - LD IXl,IXh
LDREGREG        DD6C,regixl,regixh

; DD 6D - LD IXl,IXl
LDREGREG        DD6D,regixl,regixl

; DD 6E - LD L,(IX+dd)
LDREGIIDD       DD6E,regl,regeix

; DD 6F - LD IXl,A
LDREGREG        DD6F,regixl,dh

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
LDREGREG        DD7C,dh,regixh

; DD 7D - LD A,IXl
LDREGREG        DD7D,dh,regixl

; DD 7E - LD A,(IX+dd)
LDREGIIDD       DD7E,dh,regeix

; DD 7F - DD null prefix
XNULL           DD7F

; DD 84 - ADD A,IXh
ADDREG          DD84,regixh

; DD 85 - ADD A,IXl
ADDREG          DD85,regixl

; DD 86 - ADD A,(IX+dd)
ADDAII          DD86,regeix

; DD 8C - ADC A,IXh
ADCREG          DD8C,regixh

; DD 8D - ADC A,IXl
ADCREG          DD8D,regixl

; DD 8E - ADC A,(IX+dd)
ADCAII          DD8E,regeix

; DD 94 - SUB IXh
SUBREG          DD94,regixh

; DD 95 - SUB IXl
SUBREG          DD95,regixl

; DD 96 - SUB (IX+dd)
SUBII           DD96,regeix

; DD 9C - SBC A,IXh
SBCREG          DD9C,regixh

; DD 9D - SBC A,IXl
SBCREG          DD9D,regixl

; DD 9E - SBC A,(IX+dd)
SBCAII          DD9E,regeix

; DD A4 - AND IXh
ANDREG          DDA4,regixh

; DD A5 - AND IXl
ANDREG          DDA5,regixl

; DD A6 - AND (IX+dd)
ANDII           DDA6,regeix

; DD AC - XOR IXh
XORREG          DDAC,regixh

; DD AD - XOR IXl
XORREG          DDAD,regixl

; DD AE - XOR (IX+dd)
XORII           DDAE,regeix

; DD B4 - OR IXh
ORREG           DDB4,regixh

; DD B5 - OR IXl
ORREG           DDB5,regixl

; DD B6 - OR (IX+dd)
ORII            DDB6,regeix

; DD BC - CP IXh
CPREG           DDBC,regixh

; DD BD - CP IXl
CPREG           DDBD,regixl

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

code32          ends
                end               


