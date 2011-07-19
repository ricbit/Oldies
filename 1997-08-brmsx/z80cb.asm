; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80CB.ASM
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

include isetCB.inc
public isetCBxx

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


code32          ends
                end


