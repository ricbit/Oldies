; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: DRIVE.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include bit.inc
include pmode.inc
include z80core.inc

public outemulD0
public outemulD1
public outemulD2
public outemulD3
public outemulD4

public inemulD0
public inemulD1
public inemulD2
public inemulD3
public inemulD4

public driveD0
public driveD1
public driveD2
public driveD3
public driveD4

public portenabled
public shiftfactor
public spin_irqs

extrn diskimage: dword
extrn disksize: dword

; DATA ---------------------------------------------------------------

align 4

portenabled     dd      1

driveD0         db      0
driveD1         db      0
driveD2         db      0
driveD3         db      0
driveD4         db      0

drive_status    db      0
status_type     db      0
shiftfactor     db      1
timeout         dd      0
spin_irqs       dd      12

current_track   db      0
current_sector  db      0
direction       db      0

command         dd      0
current_byte    dd      ?
avail_bytes     dd      ?

FORCE_INTERRUPT EQU     0
RESTORE         EQU     1
READ_SECTOR     EQU     2
SEEK            EQU     3
STEP            EQU     4
STEP_IN         EQU     5
STEP_OUT        EQU     6
WRITE_SECTOR    EQU     7

DIRECTION_IN    EQU     0
DIRECTION_OUT   EQU     1       

; --------------------------------------------------------------------

outemulD0:
                cmp     portenabled,1
                jne     _ret

                mov     driveD0,bl

                cmp     bl,0D0h
                je      outemulD0_force_interrupt

                and     bl,0F8h
                cmp     bl,0
                je      outemulD0_restore

                mov     bl,driveD0
                and     bl,0F0h
                cmp     bl,080h
                je      outemulD0_read_sector

                cmp     bl,0A0h
                je      outemulD0_write_sector

                mov     bl,driveD0
                and     bl,0F8h
                cmp     bl,010h
                je      outemulD0_seek

                mov     bl,driveD0
                and     bl,0E8h
                cmp     bl,020h
                je      outemulD0_step

                cmp     bl,040h
                je      outemulD0_step_in

                cmp     bl,060h
                je      outemulD0_step_out

                ret

outemulD0_force_interrupt:
                mov     drive_status,0
                mov     status_type,0
                mov     command,FORCE_INTERRUPT
                ret

outemulD0_restore:
                mov     command,RESTORE
                test    driveD4,BIT_0
                jz      outemulD0_restore_driveb
                mov     current_track,0
                mov     status_type,0
                mov     drive_status,1
                mov     timeout,5
                ret
outemulD0_restore_driveb:
                mov     status_type,0
                mov     drive_status,1
                mov     timeout,20000h
                ret

outemulD0_read_sector:
                mov     status_type,1
                mov     drive_status,3
                mov     avail_bytes,512
                mov     command,READ_SECTOR

                ; current_byte is
                ; disk_image+(track*18+sector+side*9)*512

                mov     esi,disksize
                ;mov     cl,0
                ;cmp     esi,45
                ;jbe     outemulD0_read_sector_180
                ;mov     cl,1
                mov     cl,shiftfactor
outemulD0_read_sector_180:
                movzx   eax,current_track
                movzx   ebx,current_sector
                lea     eax,[eax+eax*8]
                shl     eax,cl
                lea     eax,[ebx+eax]
                movzx   ebx,driveD4
                shr     ebx,4
                and     ebx,1
                lea     ebx,[ebx+ebx*8]
                add     eax,ebx
                shl     eax,9
                add     eax,diskimage
                mov     current_byte,eax
                mov     eax,0
                ret

outemulD0_write_sector:
                mov     status_type,1
                mov     drive_status,3
                mov     avail_bytes,512
                mov     command,WRITE_SECTOR

                ; current_byte is
                ; disk_image+(track*18+sector+side*9)*512

                mov     esi,disksize
                mov     cl,shiftfactor
outemulD0_write_sector_180:
                movzx   eax,current_track
                movzx   ebx,current_sector
                lea     eax,[eax+eax*8]
                shl     eax,cl
                lea     eax,[ebx+eax]
                movzx   ebx,driveD4
                shr     ebx,4
                and     ebx,1
                lea     ebx,[ebx+ebx*8]
                add     eax,ebx
                shl     eax,9
                add     eax,diskimage
                mov     current_byte,eax
                mov     eax,0
                ret

outemulD0_seek:
                mov     status_type,0
                mov     drive_status,0
                mov     command,SEEK
                mov     bl,driveD3
                mov     current_track,bl
                ret

outemulD0_step:
                mov     status_type,0
                mov     drive_status,0
                mov     command,STEP
                cmp     direction,DIRECTION_OUT
                je      outemulD0_step_dir_out
                inc     current_track
                ret
outemulD0_step_dir_out:
                dec     current_track
                ret

outemulD0_step_in:
                mov     status_type,0
                mov     drive_status,0
                mov     command,STEP_IN
                mov     direction,DIRECTION_IN
                inc     current_track
                ret

outemulD0_step_out:
                mov     status_type,0
                mov     drive_status,0
                mov     command,STEP_OUT
                mov     direction,DIRECTION_OUT
                dec     current_track
                ret

; --------------------------------------------------------------------

outemulD1:
                cmp     portenabled,1
                jne     _ret

                mov     driveD1,bl
                ret

; --------------------------------------------------------------------

outemulD2:
                cmp     portenabled,1
                jne     _ret

                mov     driveD2,bl
                dec     bl
                mov     current_sector,bl
                ret

; --------------------------------------------------------------------

outemulD3:
                cmp     portenabled,1
                jne     _ret

                cmp     command,WRITE_SECTOR
                je      outemulD3_write_sector
                mov     driveD3,bl
                ret

outemulD3_write_sector:
                mov     ecx,current_byte
                mov     [ecx],bl
                inc     current_byte
                dec     avail_bytes
                jnz     _ret
                mov     drive_status,0
                ret

; --------------------------------------------------------------------

outemulD4:
                cmp     portenabled,1
                jne     _ret

                mov     driveD4,bl
                mov     drive_status,0
                and     bl,BIT_0
                and     newleds,NBIT_0
                or      newleds,bl
                ret

; --------------------------------------------------------------------

inemulD0:
                cmp     portenabled,1
                jne     inemul_disabled

                cmp     status_type,0
                jne     inemulD0_stopped
                
                test    driveD4,BIT_5
                jz      inemulD0_stopped

                ; drive motor is on
                ; index mark is spinning
                cmp     index_mark,0
                je      inemulD0_no_index

                push    eax edx ecx
                mov     eax,intcount
                mov     edx,0
                mov     ecx,spin_irqs
                div     ecx
                cmp     edx,0
                je      inemulD0_index
                pop     ecx edx eax
                mov     index_mark,0
                jmp     inemulD0_no_index

inemulD0_index:
                pop     ecx edx eax
                mov     index_mark,0
                or      drive_status,BIT_1
                jmp     inemulD0_stopped

inemulD0_no_index:
                and     drive_status,NBIT_1
inemulD0_stopped:
                mov     bl,drive_status
                cmp     timeout,0
                je      _ret
                dec     timeout
                jnz     _ret
                mov     drive_status,4
                ret

; --------------------------------------------------------------------

inemulD1:
                mov     bl,current_track
                ret

; --------------------------------------------------------------------

inemulD2:
                mov     bl,driveD2
                ret

; --------------------------------------------------------------------

inemulD3:
                cmp     command,READ_SECTOR
                je      inemulD3_read_sector

                mov     bl,driveD3
                ret

inemulD3_read_sector:
                mov     ecx,current_byte
                mov     bl,[ecx]
                inc     current_byte
                dec     avail_bytes
                jnz     _ret
                mov     drive_status,0
                ret

; --------------------------------------------------------------------

inemulD4:
                mov     bl,driveD4
                ret

; --------------------------------------------------------------------

inemul_disabled:
                ret


code32          ends
                end


