; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: PRINT.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include z80.inc
include debug.inc
include io.inc
include pset.inc
include print.inc
include symdeb.inc

extrn psetCBxx: near
extrn psetEDxx: near
extrn psetDDxx: near
extrn psetFDxx: near
extrn psetDDCBxx: near
extrn psetFDCBxx: near

public pset
public prinXX
public prinDDCB
public prinFDCB
public isize
public printmsgp
public printhex2p
public printhex4p
public printnulp
public smart_print

; DATA ---------------------------------------------------------------

align 4

isize           dd      0

; --------------------------------------------------------------------

printmsgp:
                call    printmsgd
printmsgp1:
                cmp     byte ptr [eax],'$'
                je      _ret
                inc     eax
                inc     edx
                jmp     printmsgp1

; --------------------------------------------------------------------

printnulp:
                call    printnuld
printnulp1:
                cmp     byte ptr [eax],0
                je      _ret
                inc     eax
                inc     edx
                jmp     printnulp1

; --------------------------------------------------------------------

printhex4p:
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd
                add     edx,4
                ret

printhex2p:
                call    convhex4
                mov     eax,offset tmphex2
                call    printmsgd
                add     edx,2
                ret

; --------------------------------------------------------------------

smart_print:
                push    ecx
                movzx   ecx,byte ptr [ebx]

                cmp     ecx,1
                je      print_100
                cmp     ecx,2
                je      print_200
                cmp     ecx,3
                je      print_211
                cmp     ecx,5
                je      print_221
                cmp     ecx,8
                je      print_321
                cmp     ecx,11
                je      print_42x

                inc     ebx
                call    ebx
                pop     ecx
                ret

print_100:
                mov     isize,1
                lea     eax,[ebx+1]
                call    printmsgp
                pop     ecx
                ret

print_200:                
                mov     isize,2
                lea     eax,[ebx+1]
                call    printmsgp
                pop     ecx
                ret

print_221:                
                mov     isize,2
                lea     eax,[ebx+1]
                call    printmsgp
                push    eax
                inc     edi
                call    fetch
                call    printhex2p
                pop     eax
                inc     eax
                call    printmsgp
                pop     ecx
                ret

print_42x:                
                mov     isize,4
                lea     eax,[ebx+1]
                call    printmsgp
                push    eax
                add     edi,2
                call    fetch
                call    printhex2p
                pop     eax
                inc     eax
                call    printmsgp
                pop     ecx
                ret

print_211:                
                mov     isize,2
                lea     eax,[ebx+1]
                call    printmsgp
                inc     edi
                call    fetch
                call    printhex2p
                pop     ecx
                ret

print_321:                
                mov     isize,3
                lea     eax,[ebx+1]
                call    printmsgp
                push    eax
                add     edi,2
                call    fetch
                call    printhex2p
                pop     eax
                inc     eax
                call    printmsgp
                pop     ecx
                ret

; --------------------------------------------------------------------

prinCB:         
                db      0
                inc     edi
                call    fetch
                dec     edi
                push    ebx
                mov     ebx,[offset psetCBxx+eax*4]
                call    smart_print
                pop     ebx
                ret

prinDD:         
                db      0
                inc     edi
                call    fetch
                dec     edi
                push    ebx
                mov     ebx,[offset psetDDxx+eax*4]
                call    smart_print
                pop     ebx
                ret

prinDDCB:       
                db      0
                add     edi,3
                call    fetch
                sub     edi,3
                push    ebx
                mov     ebx,[offset psetDDCBxx+eax*4]
                call    smart_print
                pop     ebx
                ret

prinED:         
                db      0
                inc     edi
                call    fetch
                dec     edi
                push    ebx
                mov     ebx,[offset psetEDxx+eax*4]
                call    smart_print
                pop     ebx
                ret


prinFD:         
                db      0
                inc     edi
                call    fetch
                dec     edi
                push    ebx
                mov     ebx,[offset psetFDxx+eax*4]
                call    smart_print
                pop     ebx
                ret


prinFDCB:       
                db      0
                add     edi,3
                call    fetch
                sub     edi,3
                push    ebx
                mov     ebx,[offset psetFDCBxx+eax*4]
                call    smart_print
                pop     ebx
                ret

PRINTOP100      00,'NOP$'
PRINTOP312      01,'LD BC,$'
PRINTOP100      02,'LD (BC),A$'
PRINTOP100      03,'INC BC$'
PRINTOP100      04,'INC B$'
PRINTOP100      05,'DEC B$'
PRINTOP211      06,'LD B,$'
PRINTOP100      07,'RLCA$'
PRINTOP100      08,'EX AF,AF''$'
PRINTOP100      09,'ADD HL,BC$'
PRINTOP100      0A,'LD A,(BC)$'
PRINTOP100      0B,'DEC BC$'
PRINTOP100      0C,'INC C$'
PRINTOP100      0D,'DEC C$'
PRINTOP211      0E,'LD C,$'
PRINTOP100      0F,'RRCA$'
PRINTOP2JR      10,'DJNZ $'
PRINTOP312      11,'LD DE,$'
PRINTOP100      12,'LD (DE),A$'
PRINTOP100      13,'INC DE$'
PRINTOP100      14,'INC D$'
PRINTOP100      15,'DEC D$'
PRINTOP211      16,'LD D,$'
PRINTOP100      17,'RLA$'
PRINTOP2JR      18,'JR $'
PRINTOP100      19,'ADD HL,DE$'
PRINTOP100      1A,'LD A,(DE)$'
PRINTOP100      1B,'DEC DE$'
PRINTOP100      1C,'INC E$'
PRINTOP100      1D,'DEC E$'
PRINTOP211      1E,'LD E,$'
PRINTOP100      1F,'RRA$'
PRINTOP2JR      20,'JR NZ,$'
PRINTOP312      21,'LD HL,$'
PRINTOP322      22,'LD ($','),HL$'
PRINTOP100      23,'INC HL$'
PRINTOP100      24,'INC H$'
PRINTOP100      25,'DEC H$'
PRINTOP211      26,'LD H,$'
PRINTOP100      27,'DAA$'
PRINTOP2JR      28,'JR Z,$'
PRINTOP100      29,'ADD HL,HL$'
PRINTOP322      2A,'LD HL,($',')$'
PRINTOP100      2B,'DEC HL$'
PRINTOP100      2C,'INC L$'
PRINTOP100      2D,'DEC L$'
PRINTOP211      2E,'LD L,$'
PRINTOP100      2F,'CPL$'
PRINTOP2JR      30,'JR NC,$'
PRINTOP312      31,'LD SP,$'
PRINTOP322      32,'LD ($','),A$'
PRINTOP100      33,'INC SP$'
PRINTOP100      34,'INC (HL)$'
PRINTOP100      35,'DEC (HL)$'
PRINTOP211      36,'LD (HL),$'
PRINTOP100      37,'SCF$'
PRINTOP2JR      38,'JR C,$'
PRINTOP100      39,'ADD HL,SP$'
PRINTOP322      3A,'LD A,($',')$'
PRINTOP100      3B,'DEC SP$'
PRINTOP100      3C,'INC A$'
PRINTOP100      3D,'DEC A$'
PRINTOP211      3E,'LD A,$'
PRINTOP100      3F,'CCF$'
PRINTOP100      40,'LD B,B$'
PRINTOP100      41,'LD B,C$'
PRINTOP100      42,'LD B,D$'
PRINTOP100      43,'LD B,E$'
PRINTOP100      44,'LD B,H$'
PRINTOP100      45,'LD B,L$'
PRINTOP100      46,'LD B,(HL)$'
PRINTOP100      47,'LD B,A$'
PRINTOP100      48,'LD C,B$'
PRINTOP100      49,'LD C,C$'
PRINTOP100      4A,'LD C,D$'
PRINTOP100      4B,'LD C,E$'
PRINTOP100      4C,'LD C,H$'    
PRINTOP100      4D,'LD C,L$'
PRINTOP100      4E,'LD C,(HL)$'
PRINTOP100      4F,'LD C,A$'                
PRINTOP100      50,'LD D,B$'
PRINTOP100      51,'LD D,C$'
PRINTOP100      52,'LD D,D$'
PRINTOP100      53,'LD D,E$'
PRINTOP100      54,'LD D,H$'
PRINTOP100      55,'LD D,L$'
PRINTOP100      56,'LD D,(HL)$'
PRINTOP100      57,'LD D,A$'
PRINTOP100      58,'LD E,B$'
PRINTOP100      59,'LD E,C$'
PRINTOP100      5A,'LD E,D$'
PRINTOP100      5B,'LD E,E$'
PRINTOP100      5C,'LD E,H$'
PRINTOP100      5D,'LD E,L$'
PRINTOP100      5E,'LD E,(HL)$'
PRINTOP100      5F,'LD E,A$'
PRINTOP100      60,'LD H,B$'
PRINTOP100      61,'LD H,C$'
PRINTOP100      62,'LD H,D$'
PRINTOP100      63,'LD H,E$'
PRINTOP100      64,'LD H,H$'
PRINTOP100      65,'LD H,L$'
PRINTOP100      66,'LD H,(HL)$'
PRINTOP100      67,'LD H,A$'
PRINTOP100      68,'LD L,B$'
PRINTOP100      69,'LD L,C$'
PRINTOP100      6A,'LD L,D$'
PRINTOP100      6B,'LD L,E$'
PRINTOP100      6C,'LD L,H$'
PRINTOP100      6D,'LD L,L$'
PRINTOP100      6E,'LD L,(HL)$'
PRINTOP100      6F,'LD L,A$'
PRINTOP100      70,'LD (HL),B$'
PRINTOP100      71,'LD (HL),C$'
PRINTOP100      72,'LD (HL),D$'
PRINTOP100      73,'LD (HL),E$'
PRINTOP100      74,'LD (HL),H$'
PRINTOP100      75,'LD (HL),L$'
PRINTOP100      76,'HALT$'
PRINTOP100      77,'LD (HL),A$'
PRINTOP100      78,'LD A,B$'
PRINTOP100      79,'LD A,C$'
PRINTOP100      7A,'LD A,D$'
PRINTOP100      7B,'LD A,E$'
PRINTOP100      7C,'LD A,H$'
PRINTOP100      7D,'LD A,L$'
PRINTOP100      7E,'LD A,(HL)$'
PRINTOP100      7F,'LD A,A$'
PRINTOP100      80,'ADD A,B$'
PRINTOP100      81,'ADD A,C$'
PRINTOP100      82,'ADD A,D$'
PRINTOP100      83,'ADD A,E$'
PRINTOP100      84,'ADD A,H$'
PRINTOP100      85,'ADD A,L$'
PRINTOP100      86,'ADD A,(HL)$'
PRINTOP100      87,'ADD A,A$'
PRINTOP100      88,'ADC A,B$'
PRINTOP100      89,'ADC A,C$'
PRINTOP100      8A,'ADC A,D$'
PRINTOP100      8B,'ADC A,E$'
PRINTOP100      8C,'ADC A,H$'
PRINTOP100      8D,'ADC A,L$'
PRINTOP100      8E,'ADC A,(HL)$'
PRINTOP100      8F,'ADC A,A$'
PRINTOP100      90,'SUB B$'
PRINTOP100      91,'SUB C$'
PRINTOP100      92,'SUB D$'
PRINTOP100      93,'SUB E$'
PRINTOP100      94,'SUB H$'
PRINTOP100      95,'SUB L$'
PRINTOP100      96,'SUB (HL)$'
PRINTOP100      97,'SUB A$'
PRINTOP100      98,'SBC A,B$'
PRINTOP100      99,'SBC A,C$'
PRINTOP100      9A,'SBC A,D$'
PRINTOP100      9B,'SBC A,E$'
PRINTOP100      9C,'SBC A,H$'
PRINTOP100      9D,'SBC A,L$'
PRINTOP100      9E,'SBC A,(HL)$'
PRINTOP100      9F,'SBC A,A$'
PRINTOP100      A0,'AND B$'
PRINTOP100      A1,'AND C$'
PRINTOP100      A2,'AND D$'
PRINTOP100      A3,'AND E$'
PRINTOP100      A4,'AND H$'
PRINTOP100      A5,'AND L$'
PRINTOP100      A6,'AND (HL)$'
PRINTOP100      A7,'AND A$'
PRINTOP100      A8,'XOR B$'
PRINTOP100      A9,'XOR C$'
PRINTOP100      AA,'XOR D$'
PRINTOP100      AB,'XOR E$'
PRINTOP100      AC,'XOR H$'
PRINTOP100      AD,'XOR L$'
PRINTOP100      AE,'XOR (HL)$'
PRINTOP100      AF,'XOR A$'
PRINTOP100      B0,'OR B$'
PRINTOP100      B1,'OR C$'
PRINTOP100      B2,'OR D$'
PRINTOP100      B3,'OR E$'
PRINTOP100      B4,'OR H$'
PRINTOP100      B5,'OR L$'
PRINTOP100      B6,'OR (HL)$'
PRINTOP100      B7,'OR A$'
PRINTOP100      B8,'CP B$'
PRINTOP100      B9,'CP C$'
PRINTOP100      BA,'CP D$'
PRINTOP100      BB,'CP E$'
PRINTOP100      BC,'CP H$'
PRINTOP100      BD,'CP L$'
PRINTOP100      BE,'CP (HL)$'
PRINTOP100      BF,'CP A$'
PRINTOP100      C0,'RET NZ$'
PRINTOP100      C1,'POP BC$'    
PRINTOP312      C2,'JP NZ,$'
PRINTOP312      C3,'JP $'
PRINTOP312      C4,'CALL NZ,$'
PRINTOP100      C5,'PUSH BC$'
PRINTOP211      C6,'ADD A,$'
PRINTOP100      C7,'RST 0$'
PRINTOP100      C8,'RET Z$'
PRINTOP100      C9,'RET$'
PRINTOP312      CA,'JP Z,$'
PRINTOP312      CC,'CALL Z,$'
PRINTOP312      CD,'CALL $'
PRINTOP211      CE,'ADC A,$'
PRINTOP100      CF,'RST 08$'
PRINTOP100      D0,'RET NC$'
PRINTOP100      D1,'POP DE$'
PRINTOP312      D2,'JP NC,$'
PRINTOP221      D3,'OUT ($','),A$'
PRINTOP312      D4,'CALL NC,$'
PRINTOP100      D5,'PUSH DE$'
PRINTOP211      D6,'SUB $'
PRINTOP100      D7,'RST 10$'
PRINTOP100      D8,'RET C$'
PRINTOP100      D9,'EXX$'
PRINTOP312      DA,'JP C,$'
PRINTOP221      DB,'IN A,($',')$'
PRINTOP312      DC,'CALL C,$'
PRINTOP211      DE,'SBC A,$'
PRINTOP100      DF,'RST 18$'
PRINTOP100      E0,'RET PO$'
PRINTOP100      E1,'POP HL$'
PRINTOP312      E2,'JP PO,$'
PRINTOP100      E3,'EX (SP),HL$'
PRINTOP312      E4,'CALL PO,$'
PRINTOP100      E5,'PUSH HL$'
PRINTOP211      E6,'AND $'
PRINTOP100      E7,'RST 20$'
PRINTOP100      E8,'RET PE$'
PRINTOP100      E9,'JP (HL)$'
PRINTOP312      EA,'JP PO,$'
PRINTOP100      EB,'EX DE,HL$'
PRINTOP312      EC,'CALL PE,$'
PRINTOP211      EE,'XOR $'
PRINTOP100      EF,'RST 28$'
PRINTOP100      F0,'RET P$'
PRINTOP100      F1,'POP AF$'
PRINTOP312      F2,'JP P,$'
PRINTOP100      F3,'DI$'
PRINTOP312      F4,'CALL P,$'
PRINTOP100      F5,'PUSH AF$'
PRINTOP211      F6,'OR $'
PRINTOP100      F7,'RST 30$'
PRINTOP100      F8,'RET M$'
PRINTOP100      F9,'LD SP,HL$'
PRINTOP312      FA,'JP M,$'
PRINTOP100      FB,'EI$'
PRINTOP312      FC,'CALL M,$'
PRINTOP211      FE,'CP $'
PRINTOP100      FF,'RST 38$'
PRINTOP100      XX,'not emulated yet$'

; --------------------------------------------------------------------

code32          ends
                end

