; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: PATCH.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include bit.inc

extrn emulC9: near
extrn diskimage: dword
extrn tapeimage: dword
extrn msxram: dword

public emulEDFF
public tape_pos

; DATA ---------------------------------------------------------------

align 4

boot:           db      512 dup (0)
tape_pos        dd      0
saveslot        db      0


; --------------------------------------------------------------------

; emulEDFF -----------------------------------------------------------
; main patch selector
; select patch through the PC

emulEDFF:
                cmp     edi,04010h+1
                je      patch_PHYDIO

                cmp     edi,04013h+1
                je      patch_DSKCHG

                cmp     edi,04016h+1
                je      patch_GETDPB

                cmp     edi,000E1h+1
                je      patch_TAPION

                cmp     edi,000E4h+1
                je      patch_TAPIN

                cmp     edi,000E7h+1
                je      patch_TAPIOF

                cmp     edi,000EAh+1
                je      patch_TAPOON

                cmp     edi,000EDh+1
                je      patch_TAPOUT

                cmp     edi,000F0h+1
                je      patch_TAPOOF

                ; patch not found
                inc     edi
                sub     ebp,4
                ret

; --------------------------------------------------------------------
; PHYDIO: read/write sectors

patch_PHYDIO:
                mov     iff1,1
                
                ; only drive A emulated
                cmp     dh,0
                jne     patch_PHYDIO_driveb

                ; if regb=0 then exit [security trap]
                cmp     regb,0
                je      emulC9

                push    ebp

                ; enable all RAM
                
                mov     al,prim_slotreg
                mov     saveslot,al
                mov     bl,allram
                call    outemulA8

                ; find initial offset on disk image
                mov     esi,regede
                shl     esi,9
                add     esi,diskimage
                mov     ecx,regehl
                mov     al,regb
                push    eax

                ; read or write?
                and     dl,1
                jnz     patch_PHYDIO_writesector

patch_PHYDIO1:

                mov     ebp,512

patch_PHYDIO2:

                mov     al,byte ptr [esi]
                push    esi
                call    writemem
                pop     esi
                inc     esi
                inc     cx
                dec     ebp
                jnz     patch_PHYDIO2

                dec     regb
                jnz     patch_PHYDIO1

patch_PHYDIO_done:  
                pop     eax
                mov     regb,al
                mov     edx,0

                ; enable previous slot configuration
                mov     bl,saveslot
                call    outemulA8

                pop     ebp

                jmp     emulC9

patch_PHYDIO_driveb:
                or      dl,1
                mov     dh,2
                jmp     emulC9

patch_PHYDIO_readonly:
                or      dl,1
                mov     dh,0
                mov     regb,0
                jmp     emulC9

patch_PHYDIO_writesector:

                mov     ebp,512

patch_PHYDIO_writesector_loop:

                push    esi
                call    readmem
                pop     esi
                mov     byte ptr [esi],al
                inc     esi
                inc     cx
                dec     ebp
                jnz     patch_PHYDIO_writesector_loop

                dec     regb
                jnz     patch_PHYDIO_writesector

                jmp     patch_PHYDIO_done

; --------------------------------------------------------------------
; DSKCHG: update DPB when disk has changed

patch_DSKCHG:
                mov     regb,0
                mov     iff1,1
                jmp     patch_GETDPB

; --------------------------------------------------------------------
; GETDPB: adjust DPB by looking the data on boot sector

patch_GETDPB:
                mov     ecx,diskimage
                mov     al,[ecx+512]
                cmp     al,0F8h
                je      patch_GETDPB_F8

                mov     ecx,regehl
                inc     ecx

                ; format ID [F8-FF]
                mov     al,0F9h
                call    writemem
                inc     ecx

                ; sector size
                mov     al,0
                call    writemem
                inc     ecx
                
                mov     al,2
                call    writemem
                inc     ecx

                ; directory mask/shift
                mov     al,0fh
                call    writemem
                inc     ecx
                
                mov     al,04h
                call    writemem
                inc     ecx

                ; cluster mask/shift
                
                mov     al,1
                call    writemem
                inc     ecx
                
                mov     al,2
                call    writemem
                inc     ecx

                ; sector number of first fat
                mov     al,1
                call    writemem
                inc     ecx
                
                mov     al,0
                call    writemem
                inc     ecx

                ; number of fats
                mov     al,2
                call    writemem
                inc     ecx

                ; number of directory entries
                mov     al,70h
                call    writemem
                inc     ecx

                ; daqui pra frente torrou o saco
                ; sector number of data
                mov     al,0eh
                call    writemem
                inc     ecx
                
                mov     al,0
                call    writemem
                inc     ecx

                ; number of clusters
                mov     al,0c9h
                call    writemem
                inc     ecx
                
                mov     al,02h
                call    writemem
                inc     ecx

                ; sectors per fat
                mov     al,03h
                call    writemem
                inc     ecx

                ; sector number of directory
                mov     al,07h
                call    writemem
                inc     ecx
                
                mov     al,0
                call    writemem
                inc     ecx

                mov     edx,0

                jmp     emulC9

patch_GETDPB_F8:
                push    edx
                mov     ecx,regehl
                mov     edx,offset DPB_F8
                mov     ebx,20
patch_GETDPB_F8_loop:
                push    ebx
                mov     al,[edx]
                call    writemem
                inc     ecx
                inc     edx
                pop     ebx
                dec     ebx
                jnz     patch_GETDPB_F8_loop

                pop     edx
                mov     edx,0
                jmp     emulC9

; --------------------------------------------------------------------
; TAPION: search tape for start header
; return: carry if terminated by CTRL-STOP, DI

patch_TAPION:
                mov     iff1,0
                mov     esi,tape_pos
                add     esi,7
                and     esi,0FFF8h
                mov     eax,0BADEA61Fh
                mov     ecx,0FFFFh
                sub     ecx,esi
                shr     ecx,2
                add     esi,tapeimage
patch_TAPION_again:
                repz    scasd
                cmp     ecx,0
                je      patch_TAPION_failed
                cmp     dword ptr [esi+4],0747D13CCh
                jne     patch_TAPION_again
                add     esi,8
                sub     esi,tapeimage
                mov     tape_pos,esi
                and     dl,NBIT_0
                mov     eax,0
                jmp     emulC9

patch_TAPION_failed:
                or      dl,BIT_0
                mov     eax,0
                jmp     emulC9

; --------------------------------------------------------------------
; TAPIN: read a byte from tape
; return: A=byte read, carry if error of CTRL-STOP

patch_TAPIN:
                mov     ecx,tape_pos
                add     ecx,tapeimage
                mov     dh,[ecx]
                inc     tape_pos
                and     tape_pos,0FFFFh
                and     dl,NBIT_0
                jmp     emulC9

; --------------------------------------------------------------------
; TAPIOF: end tape read
; return: EI

patch_TAPIOF:
                mov     iff1,1
                and     dl,NBIT_0
                jmp     emulC9

; --------------------------------------------------------------------
; TAPOON: write start header to tape
; return: carry if CTRL-STOP,DI

patch_TAPOON:
                mov     ecx,tape_pos
                add     ecx,7
                and     ecx,0FFF8h
                add     ecx,tapeimage
                mov     dword ptr [ecx],0BADEA61Fh
                mov     dword ptr [ecx+4],0747D13CCh
                add     tape_pos,8
                and     tape_pos,0FFFFh
                mov     iff1,0
                and     dl,NBIT_0
                jmp     emulC9

; --------------------------------------------------------------------
; TAPOUT: write a byte to tape
; enter: A=byte
; return: carry if CTRL-STOP

patch_TAPOUT:
                mov     ecx,tape_pos
                add     ecx,tapeimage
                mov     [ecx],dh
                inc     tape_pos
                and     tape_pos,0FFFFh
                and     dl,NBIT_0
                jmp     emulC9

; --------------------------------------------------------------------
; TAPOON: end tape write
; return: EI

patch_TAPOOF:
                and     dl,NBIT_0
                mov     iff1,1
                jmp     emulC9

; --------------------------------------------------------------------

DPB_F8:
        db      0,0f8h,0,2,0fh,4,1,2,1,0,2,70h,0ch,0,63h,1,2,5,0,0

code32          ends
                end


