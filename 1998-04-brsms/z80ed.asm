; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80ED.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include z80sing.inc
include pmode.inc
include opcode.inc
include bit.inc
include fetch.inc

extrn emulEDFF: near

; DATA ---------------------------------------------------------------

align 4

include isetED.inc
public isetEDxx

; --------------------------------------------------------------------

; ED 40 - IN B,(C)
INREG           ED40,regb

; ED 41 - OUT (C),B
OUTCREG         ED41,regb

; ED 42 - SBC HL,BC
SBCHLWREG       ED42,regc,regb

; ED 43 - LD (dddd),BC
LDDDDDREGW      ED43,regebc,20

; ED 44 - NEG
OPNEG           ED44

; ED 45 - RETN
OPRETN          ED45

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
LDREGWDDDD      ED4B,regebc,20

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
LDDDDDREGW      ED53,regede,20

; ED 54 - NEG
OPNEG           ED54

; ED 55 - RETN
OPRETN          ED55

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
LDREGWDDDD      ED5B,regede,20

; ED 5C - NEG
OPNEG           ED5C

; ED 5D - RETN
OPRETN          ED5D

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
LDDDDDREGW      ED63,regehl,20

; ED 64 - NEG
OPNEG           ED64

; ED 65 - RETN
OPRETN          ED65

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
LDREGWDDDD      ED6B,regehl,20

; ED 6C - NEG
OPNEG           ED6C

; ED 6D - RETN
OPRETN          ED6D

; ED 6E - IM 0/1
OPIM0           ED6E

; ED 6F - RLD
OPRLD           ED6F  

; ED 70 - IN (C)
INFLAG          ED70

; ED 71 - OUT (C),0
OUTC0           ED71

; ED 72 - SBC HL,SP
SBCHLWREG       ED72,regspl,regsph

; ED 73 - LD (dddd),SP
LDDDDDREGW      ED73,regesp,20

; ED 74 - NEG
OPNEG           ED74

; ED 75 - RETN
OPRETN          ED75

; ED 76 - IM 1
OPIM1           ED76

; ED 78 - IN A,(C)
INREG           ED78,dh

; ED 79 - OUT (C),A
OUTCREG         ED79,dh

; ED 7A - ADC HL,SP
ADCREGWREGW     ED7A,regl,regh,regspl,regsph

; ED 7B - LD SP,(dddd)
LDREGWDDDD      ED7B,regesp,20

; ED 7C - NEG
OPNEG           ED7C

; ED 7D - RETN
OPRETN          ED7D

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

code32          ends
                end


