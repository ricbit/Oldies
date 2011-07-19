; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: SAVELOAD.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include io.inc
include vdp.inc
include pmode.inc
include vesa.inc

extrn msxram: dword
extrn msxvram: dword
extrn transf_buffer: dword
extrn writemessage: near

public save_state
public load_state
public save_histogram
public save_snapshot_pcx
public save_snapshot_raw

; DATA ---------------------------------------------------------------

include pcxhead.inc
include pcxhead2.inc

align 4

file_handler    dw      0

filename        db      'BRMSX.STA',0
fileid          db      'MSXSTATE',26,0
snapshotname    db      'BRMSX.PCX',0
histogrname     db      'HISTOGR.STA',0
msgfnf          db      'File not found$'
dumpfile        db      'DUMP0000.RAW',0

; WRITE_DWORD --------------------------------------------------------
; write a word in the state file, but by reading a dword

WRITE_DWORD     macro   dword_data
                
                mov     eax,dword_data
                mov     edx,transf_buffer
                mov     [edx],ax
                mov     ecx,2
                call    write_file

                endm

; READ_DWORD ---------------------------------------------------------
; read a word from the state file, placing in a dword

READ_DWORD      macro   dword_data
                
                mov     edx,transf_buffer
                mov     ecx,2
                call    read_file
                xor     eax,eax
                mov     edx,transf_buffer
                mov     ax,[edx]
                mov     dword_data,eax

                endm

; WRITE_BYTE ---------------------------------------------------------
; write a byte in the state file

WRITE_BYTE      macro   byte_data
                
                mov     al,byte_data
                mov     edx,transf_buffer
                mov     [edx],al
                mov     ecx,1
                call    write_file

                endm

; READ_BYTE ----------------------------------------------------------
; read a byte from the state file

READ_BYTE       macro   byte_data
                
                mov     edx,transf_buffer
                mov     ecx,1
                call    read_file
                mov     edx,transf_buffer
                mov     al,[edx]
                mov     byte_data,al

                endm

; WRITE_IMM ----------------------------------------------------------
; write a immediate byte loaded in al in the state file

WRITE_IMM       macro   
                
                mov     edx,transf_buffer
                mov     [edx],al
                mov     ecx,1
                call    write_file

                endm

; READ_IMM -----------------------------------------------------------
; read a immediate byte from the state file and store it in al

READ_IMM        macro   
                
                mov     edx,transf_buffer
                mov     ecx,1
                call    read_file
                mov     edx,transf_buffer
                mov     al,[edx]

                endm

; custom_write -------------------------------------------------------
; write to a file pointed in v86r_bx
; but first move the data to the low memory transfer buffer

custom_write:
                push    ecx
                mov     esi,edx
                mov     edi,transf_buffer
                rep     movsb
                pop     ecx
                mov     edx,transf_buffer
                jmp     write_file

; custom_read --------------------------------------------------------
; read from a file pointed in v86r_bx
; the data is then moved from the transf buffer to location
; pointed by edx

custom_read:
                push    ecx edx
                mov     edx,transf_buffer
                call    read_file
                pop     edx ecx
                mov     esi,transf_buffer
                mov     edi,edx
                rep     movsb
                ret

; save_state ---------------------------------------------------------
; save the entire state of MSX machine in
; a file called "BRMSX.STA"

save_state:
                mov     edx,offset filename
                call    create_file

; --------------------------------------------------------------------
                
                ; write the file ID and the version

                mov     edx,offset fileid
                mov     ecx,10
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of Z80 registers

                WRITE_DWORD     regeaf
                WRITE_DWORD     regebc
                WRITE_DWORD     regede
                WRITE_DWORD     regehl
                WRITE_DWORD     regepc
                WRITE_DWORD     regesp
                WRITE_DWORD     regeix
                WRITE_DWORD     regeiy
                WRITE_DWORD     regeafl
                WRITE_DWORD     regebcl
                WRITE_DWORD     regedel
                WRITE_DWORD     regehll
                WRITE_BYTE      regi
                
                mov     eax,rcounter
                and     al,07Fh
                or      al,rmask
                WRITE_IMM

                mov     eax,iff1
                WRITE_IMM

                mov     al,1
                WRITE_IMM

                mov     eax,imtype
                WRITE_IMM

; --------------------------------------------------------------------
                
                ; write the contents of VDP registers

                mov     edx,offset vdpregs
                mov     ecx,8
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of PSG registers

                mov     edx,offset psgreg
                mov     ecx,16
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of PPI registers

                WRITE_BYTE      prim_slotreg

                mov     al,0FFh
                WRITE_IMM

                WRITE_BYTE      ppic

                mov     al,082h
                WRITE_IMM

; --------------------------------------------------------------------
                
                ; write the contents of megarom block selectors

                irp     i,<0,1,2,3,4,5,6,7>

                mov     eax,dword ptr [offset megablock+i*4]
                WRITE_IMM

                endm

; --------------------------------------------------------------------
                
                ; write the contents of the RAM

                mov     edx,msxram
                mov     ecx,32768
                call    custom_write

                mov     edx,msxram
                add     edx,32768
                mov     ecx,32768
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of the VRAM

                mov     edx,msxvram
                mov     ecx,16384
                call    custom_write

; --------------------------------------------------------------------
                
                call    close_file
                ret

; load_state ---------------------------------------------------------
; load the entire state of MSX machine from
; a file called "BRMSX.STA"


load_state:

                mov     edx,offset filename
                call    open_file
                jc      file_not_found

; --------------------------------------------------------------------

                ; skip file ID
                
                mov     edx,transf_buffer
                mov     ecx,10
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of Z80 registers

                READ_DWORD      regeaf
                READ_DWORD      regebc
                READ_DWORD      regede
                READ_DWORD      regehl
                READ_DWORD      regepc
                READ_DWORD      regesp
                READ_DWORD      regeix
                READ_DWORD      regeiy
                READ_DWORD      regeafl
                READ_DWORD      regebcl
                READ_DWORD      regedel
                READ_DWORD      regehll
                READ_BYTE       regi

                READ_IMM
                push    eax
                and     eax,0FFh
                mov     rcounter,eax
                pop     eax
                and     eax,080h
                mov     rmask,al

                READ_IMM
                and     eax,0FFh
                mov     iff1,eax

                READ_IMM
                READ_IMM
                and     eax,0FFh
                mov     imtype,eax

; --------------------------------------------------------------------
                
                ; read the contents of VDP registers

                mov     edx,offset vdpregs
                mov     ecx,8
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of PSG registers

                mov     edx,offset psgreg
                mov     ecx,16
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of PPI registers

                READ_BYTE       prim_slotreg
                READ_IMM
                READ_BYTE       ppic
                READ_IMM

; --------------------------------------------------------------------
                
                ; read the contents of megarom block selectors

                irp     i,<0,1,2,3,4,5,6,7>

                READ_IMM
                cmp     dword ptr [offset slot1+i*8+4],2
                jne     load_state_mega_&i
                mov     esi,i
                and     eax,0FFh
                call    callback_megarom0
load_state_mega_&i:

                endm

; --------------------------------------------------------------------
                
                ; read the contents of RAM

                mov     edx,msxram
                mov     ecx,32768
                call    custom_read

                mov     edx,msxram
                add     edx,32768
                mov     ecx,32768
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of VRAM

                mov     edx,msxvram
                mov     ecx,16384
                call    custom_read

; --------------------------------------------------------------------

                ; adjust the slot selection

                mov     bl,prim_slotreg
                call    outemulA8

; --------------------------------------------------------------------

                ; adjust the VDP for correct screen mode

                call    eval_base_address
                mov     firstscreen,1
                mov     enabled,0
                ;mov     imagetype,0

; --------------------------------------------------------------------
                
                call    close_file
                ret

; --------------------------------------------------------------------

file_not_found:
                mov     eax,offset msgfnf
                jmp     writemessage

; save_histogram -----------------------------------------------------
; save the Z80 histogram in a file called "HISTOGR.STA"

save_histogram:                
                mov     edx,offset histogrname
                call    create_file
                mov     edx,offset histogr
                mov     ecx,256*4
                call    custom_write
                call    close_file
                ret

; save_snapshot_pcx --------------------------------------------------
; save a snapshot in PCX format in a file called "BRMSX.PCX"

save_snapshot_pcx:               
                cli

                mov     edx,offset snapshotname
                call    create_file

                cmp     videomode,2
                je      save_snapshot_pcx_512

                cmp     videomode,8
                je      save_snapshot_pcx_512

                cmp     videomode,9
                je      save_snapshot_pcx_512

                cmp     videomode,7
                je      save_snapshot_pcx_320
                
                cmp     videomode,0
                jne     save_snapshot_pcx_256

save_snapshot_pcx_320:
                mov     edx,offset pcx_header
                mov     ecx,128
                call    custom_write

                mov     ebp,192
                mov     esi,0A0000h+32
                sub     esi,_code32a
save_snapshot_pcx_outer:
                mov     edi,transf_buffer
                mov     ecx,256
save_snapshot_pcx_inner:
                mov     al,[esi]
                mov     byte ptr [edi],11000001b
                mov     [edi+1],al
                inc     esi
                add     edi,2
                dec     ecx
                jnz     save_snapshot_pcx_inner

                push    esi ebp
                mov     edx,transf_buffer
                mov     ecx,512
                call    custom_write
                pop     ebp esi

                add     esi,64
                dec     ebp
                jnz     save_snapshot_pcx_outer

                mov     al,12
                WRITE_IMM

                call    save_snapshot_pcx_palette
                
                call    close_file
                sti
                ret

save_snapshot_pcx_256:
                
                mov     edx,offset pcx_header
                mov     ecx,128
                call    custom_write

                mov     ebp,192
                mov     esi,0A0000h
                sub     esi,_code32a
save_snapshot_pcx_outer_256:
                mov     edi,transf_buffer
                mov     ecx,256
save_snapshot_pcx_inner_256:
                mov     al,[esi]
                mov     byte ptr [edi],11000001b
                mov     [edi+1],al
                inc     esi
                add     edi,2
                dec     ecx
                jnz     save_snapshot_pcx_inner_256

                push    esi ebp
                mov     edx,transf_buffer
                mov     ecx,512
                call    custom_write
                pop     ebp esi

                dec     ebp
                jnz     save_snapshot_pcx_outer_256

                mov     al,12
                WRITE_IMM

                call    save_snapshot_pcx_palette
                
                call    close_file
                sti
                ret


save_snapshot_pcx_palette:                
                mov     ebp,256
                mov     edx,03C7h
                mov     al,0
                out     dx,al
                add     dx,2
save_snapshot_pcx_palette_loop:
                in      al,dx
                shl     al,2
                push    edx
                WRITE_IMM
                pop     edx
                
                in      al,dx
                shl     al,2
                push    edx
                WRITE_IMM
                pop     edx
                
                in      al,dx
                shl     al,2
                push    edx
                WRITE_IMM
                pop     edx
                
                dec     ebp
                jnz     save_snapshot_pcx_palette_loop

                ret

save_snapshot_pcx_512:
                mov     edx,offset pcx_header_512
                mov     ecx,128
                call    custom_write
                cli

                mov     bx,v86r_bx
                mov     file_handler,bx
                
                mov     eax,0
save_snapshot_pcx_bank:
                push    eax
                call    set_vesa_bank
                cli
                mov     ebp,128
                mov     esi,0A0000h
                sub     esi,_code32a
save_snapshot_pcx_outer_512:
                mov     edi,transf_buffer
                mov     ecx,512
save_snapshot_pcx_inner_512:
                mov     al,[esi]
                mov     byte ptr [edi],11000001b
                mov     [edi+1],al
                inc     esi
                add     edi,2
                dec     ecx
                jnz     save_snapshot_pcx_inner_512

                push    esi ebp
                mov     edx,transf_buffer
                mov     ecx,1024
                mov     bx,file_handler
                mov     v86r_bx,bx
                call    custom_write
                cli
                pop     ebp esi

                dec     ebp
                jnz     save_snapshot_pcx_outer_512

                pop     eax
                inc     eax
                cmp     eax,3
                jne     save_snapshot_pcx_bank

                mov     al,12
                WRITE_IMM       
                cli

                call    save_snapshot_pcx_palette

                call    close_file
                sti
                ret

; save_snapshot_raw --------------------------------------------------
; save a snapshot in RAW format 

dumpnumber      dd      0

save_snapshot_raw:
                mov     eax,dumpnumber
                call    convhex4
                mov     eax,dword ptr [offset tmphex4]
                mov     dword ptr [offset dumpfile+4],eax

                mov     edx,offset dumpfile
                call    create_file

                mov     edx,offset pcx_header
                mov     ecx,128
                call    custom_write

                call    close_file
                inc     dumpnumber
                ret

code32          ends
                end


