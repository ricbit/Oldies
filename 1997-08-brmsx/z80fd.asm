; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80FD.ASM
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

include isetFD.inc
include isetFDCB.inc
public isetFDxx

; --------------------------------------------------------------------

; FD 09 - ADD IY,BC
ADDREGWREGW     FD09,regiyl,regiyh,regc,regb,15+2

; FD 19 - ADD IY,DE
ADDREGWREGW     FD19,regiyl,regiyh,rege,regd,15+2

; FD 21 - LD IY,dddd
LDREGWIMM      FD21,regeiy

; FD 22 - LD (dddd),IY
LDDDDDREGW      FD22,regeiy,20+2

; FD 23 - INC IY
INCWREG         FD23,regiy,10+2

; FD 24 - INC IYh
INCREG          FD24,regiyh

; FD 25 - DEC IYh
DECREG          FD25,regiyh

; FD 26 - LD IYh,dd
LDREGIMM        FD26,regiyh

; FD 29 - ADD IY,IY
ADDREGWREGW     FD29,regiyl,regiyh,regiyl,regiyh,15+2

; FD 2A - LD IY,(dddd)
LDREGWDDDD      FD2A,regeiy,20+2

; FD 2B - DEC IY
DECWREG         FD2B,regiy,10+2

; FD 2C - INC IYl
INCREG          FD2C,regiyl

; FD 2D - DEC IYl
DECREG          FD2D,regiyl

; FD 2E - LD IYl,dd
LDREGIMM        FD2E,regiyl

; FD 34 - INC (IY+dd)
INCII           FD34,regeiy

; FD 35 - DEC (IY+dd)
DECII           FD35,regeiy

; FD 36 - LD (IY+dd),dd
LDIIDDNN        FD36,regeiy

; FD 39 - ADD IY,SP
ADDREGWREGW     FD39,regiyl,regiyh,regspl,regsph,15+2

; FD 40 - FD null prefix
XNULL           FD40

; FD 41 - FD null prefix
XNULL           FD41

; FD 42 - FD null prefix
XNULL           FD42

; FD 43 - FD null prefix
XNULL           FD43

; FD 44 - LD B,IYh
LDREGREG        FD44,regb,regiyh

; FD 45 - LD B,IYl
LDREGREG        FD45,regb,regiyl

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
LDREGREG        FD4C,regc,regiyh

; FD 4D - LD C,IYl
LDREGREG        FD4D,regc,regiyl

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
LDREGREG        FD54,regd,regiyh

; FD 55 - LD D,IYl
LDREGREG        FD55,regd,regiyl

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
LDREGREG        FD5C,rege,regiyh

; FD 5D - LD E,IYl
LDREGREG        FD5D,rege,regiyl

; FD 5E - LD E,(IY+dd)
LDREGIIDD       FD5E,rege,regeiy

; FD 5F - FD null prefix
XNULL           FD5F

; FD 60 - LD IYh,B
LDREGREG        FD60,regiyh,regb

; FD 61 - LD IYh,C
LDREGREG        FD61,regiyh,regc

; FD 62 - LD IYh,D
LDREGREG        FD62,regiyh,regd

; FD 63 - LD IYh,E
LDREGREG        FD63,regiyh,rege

; FD 64 - LD IYh,IYh
LDREGREG        FD64,regiyh,regiyh

; FD 65 - LD IYh,IYl
LDREGREG        FD65,regiyh,regiyl

; FD 66 - LD H,(IY+dd)
LDREGIIDD       FD66,regh,regeiy

; FD 67 - LD IYh,A
LDREGREG        FD67,regiyh,dh

; FD 68 - LD IYl,B
LDREGREG        FD68,regiyl,regb

; FD 69 - LD IYl,C
LDREGREG        FD69,regiyl,regc

; FD 6A - LD IYl,D
LDREGREG        FD6A,regiyl,regd

; FD 6B - LD IYl,E
LDREGREG        FD6B,regiyl,rege

; FD 6C - LD IYl,IYh
LDREGREG        FD6C,regiyl,regiyh

; FD 6D - LD IYl,IYl
LDREGREG        FD6D,regiyl,regiyl

; FD 6E - LD L,(IY+dd)
LDREGIIDD       FD6E,regl,regeiy

; FD 6F - LD IYl,A
LDREGREG        FD6F,regiyl,dh

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
LDREGREG        FD7C,dh,regiyh

; FD 7D - LD A,IYl
LDREGREG        FD7D,dh,regiyl

; FD 7E - LD A,(IY+dd)
LDREGIIDD       FD7E,dh,regeiy

; FD 7F - FD null prefix
XNULL           FD7F

; FD 84 - ADD A,IXh
ADDREG          FD84,regiyh

; FD 85 - ADD A,IXl
ADDREG          FD85,regiyl

; FD 86 - ADD A,(IY+dd)
ADDAII          FD86,regeiy

; FD 8C - ADC A,IXh
ADCREG          FD8C,regiyh

; FD 8D - ADC A,IXl
ADCREG          FD8D,regiyl

; FD 8E - ADC A,(IY+dd)
ADCAII          FD8E,regeiy

; FD 94 - SUB IXh
SUBREG          FD94,regiyh

; FD 95 - SUB IXl
SUBREG          FD95,regiyl

; FD 96 - SUB (IY+dd)
SUBII           FD96,regeiy

; FD 9C - SBC A,IXh
SBCREG          FD9C,regiyh

; FD 9D - SBC A,IXl
SBCREG          FD9D,regiyl

; FD 9E - SBC A,(IY+dd)
SBCAII          FD9E,regeiy

; FD A4 - AND IXh
ANDREG          FDA4,regiyh

; FD A5 - AND IXl
ANDREG          FDA5,regiyl

; FD A6 - AND (IY+dd)
ANDII           FDA6,regeiy

; FD AC - AND IXh
XORREG          FDAC,regiyh

; FD AD - AND IXl
XORREG          FDAD,regiyl

; FD AE - XOR (IY+dd)
XORII           FDAE,regeiy

; FD B4 - OR IXh
ORREG           FDB4,regiyh

; FD B5 - OR IXl
ORREG           FDB5,regiyl

; FD B6 - OR (IY+dd)
ORII            FDB6,regeiy

; FD BC - CP IXh
CPREG           FDBC,regiyh

; FD BD - CP IXl
CPREG           FDBD,regiyl

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



code32          ends
                end


