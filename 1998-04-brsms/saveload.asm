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
include fetch.inc

extrn msxram: dword
extrn msxvram: dword
extrn transf_buffer: dword
extrn writemessage: near
extrn cart1: dword
extrn cartname: byte
extrn log_music: dword
extrn log_name: byte

public save_state
public load_state
public save_histogram
public save_snapshot_pcx
public create_log_file
public close_log_file
public log_psg_sample
public log_interrupt

; DATA ---------------------------------------------------------------

include pcxhead.inc
include pcxhead2.inc

filename        db      'BRSMS.STA',0
fileid          db      'SMSSTATE',26,0
histogrname     db      'HISTOGR.STA',0
snapshotname    db      'BRSMS.PCX',0
msgfnf          db      'File not found$'

file_handler    dw      0

; log variables

align 4

log_buffer      dd      0
log_size        dd      0                
log_handler     dw      0

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
                ;mov     regepc,edi
                ;mov     regeaf,edx
                ;mov     clocksleft,ebp

                mov     edx,offset cartname
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
                mov     ecx,16
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of PSG registers

                mov     edx,offset psgreg
                mov     ecx,16
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of mapper selector

                irp     i,<0,1,2>

                mov     eax,dword ptr [offset mapperblock+i*4]
                WRITE_IMM

                endm

; --------------------------------------------------------------------
                
                ; write the contents of the RAM

                mov     edx,msxram
                mov     ecx,8192
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of the VRAM

                mov     edx,msxvram
                mov     ecx,16384
                call    custom_write

; --------------------------------------------------------------------
                
                ; write the contents of the palette

                mov     edx,offset smspalette
                mov     ecx,64
                call    custom_write

; --------------------------------------------------------------------
                
                ; write misc VDP internal registers

                mov     edx,offset vdpcond
                mov     ecx,4
                call    custom_write
                
                mov     edx,offset vdppalcond
                mov     ecx,4
                call    custom_write
                
                mov     edx,offset vdppaladdr
                mov     ecx,4
                call    custom_write
                
                mov     edx,offset vdpaddress
                mov     ecx,4
                call    custom_write

                mov     edx,offset vdpstatus
                mov     ecx,1
                call    custom_write

                mov     edx,offset vdptemp
                mov     ecx,1
                call    custom_write

                mov     edx,offset lookahead
                mov     ecx,1
                ;call    custom_write

                mov     edx,offset currentline
                mov     ecx,4
                ;call    custom_write

                mov     edx,offset soundclocks
                mov     ecx,4
                ;call    custom_write
                
                mov     edx,offset clocksleft
                mov     ecx,4
                ;call    custom_write

; --------------------------------------------------------------------
                
                call    close_file
                ret

; load_state ---------------------------------------------------------
; load the entire state of MSX machine from
; a file called "BRMSX.STA"


load_state:

                mov     edx,offset cartname
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
                mov     ecx,16
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of PSG registers

                mov     edx,offset psgreg
                mov     ecx,16
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of mapper selectors

                irp     i,<0,1,2>

                mov     eax,0
                READ_IMM
                and     eax,0FFh
                mov     dword ptr [offset mapperblock+i*4],eax
                shl     eax,14
                add     eax,cart1
                mov     dword ptr [offset mem+i*8],eax
                add     eax,2000h
                mov     dword ptr [offset mem+i*8+4],eax

                endm

; --------------------------------------------------------------------
                
                ; read the contents of RAM

                mov     edx,msxram
                mov     ecx,8192
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of VRAM

                mov     edx,msxvram
                mov     ecx,16384
                call    custom_read

; --------------------------------------------------------------------
                
                ; read the contents of palette

                mov     edx,offset smspalette
                mov     ecx,64
                call    custom_read

; --------------------------------------------------------------------
                
                ; read misc VDP internal registers

                mov     edx,offset vdpcond
                mov     ecx,4
                call    custom_read
                
                mov     edx,offset vdppalcond
                mov     ecx,4
                call    custom_read
                
                mov     edx,offset vdppaladdr
                mov     ecx,4
                call    custom_read
                
                mov     edx,offset vdpaddress
                mov     ecx,4
                call    custom_read

                mov     edx,offset vdpstatus
                mov     ecx,1
                call    custom_read

                mov     edx,offset vdptemp
                mov     ecx,1
                call    custom_read

                mov     edx,offset lookahead
                mov     ecx,1
                ;call    custom_read

                mov     edx,offset currentline
                mov     ecx,4
                ;call    custom_read

                mov     edx,offset soundclocks
                mov     ecx,4
                ;call    custom_read

                mov     edx,offset clocksleft
                mov     ecx,4
                ;call    custom_read

; --------------------------------------------------------------------
                
                ; mark all the dirty patterns with 1

                mov     eax,01010101h
                mov     ecx,512/4
                mov     edi,offset dirtypattern
                rep     stosd

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
; save a snapshot in PCX format in a file called "HISTOGR.STA"

save_snapshot_pcx:               
                cli

                mov     edx,offset snapshotname
                call    create_file

                cmp     videomode,2
                je      save_snapshot_pcx_512

                cmp     videomode,4
                je      save_snapshot_direct_512

                cmp     videomode,6
                je      save_snapshot_direct_512

                cmp     videomode,8
                je      save_snapshot_direct_512

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

save_snapshot_direct_512:

                mov     bx,v86r_bx
                mov     file_handler,bx
                
                mov     eax,0
save_snapshot_direct_bank:
                push    eax
                call    set_vesa_bank
                cli
                mov     ebp,64 ;128
                mov     esi,0A0000h
                sub     esi,_code32a
save_snapshot_direct_outer_512:
                mov     edi,transf_buffer
                mov     ecx,512
save_snapshot_direct_inner_512:
                ;mov     al,[esi]
                ;mov     byte ptr [edi],11000001b
                ;mov     [edi+1],al
                movzx   eax,word ptr [esi]
                mov     ebx,eax
                and     ebx,111110000000000b
                shr     ebx,7
                mov     byte ptr [edi],bl
                mov     ebx,eax
                and     ebx,000001111100000b
                shr     ebx,2
                mov     byte ptr [edi+1],bl
                mov     ebx,eax
                and     ebx,000000000011111b
                shl     ebx,3
                mov     byte ptr [edi+2],bl

                add     esi,2
                add     edi,3
                dec     ecx
                jnz     save_snapshot_direct_inner_512

                push    esi ebp
                mov     edx,transf_buffer
                mov     ecx,512*3 ;1024
                mov     bx,file_handler
                mov     v86r_bx,bx
                call    custom_write
                cli
                pop     ebp esi

                dec     ebp
                jnz     save_snapshot_direct_outer_512

                pop     eax
                inc     eax
                cmp     eax,6 ;3
                jne     save_snapshot_direct_bank

                call    close_file
                sti
                ret


; create_log_file ----------------------------------------------------
; create a file to log the music

create_log_file:
                cmp     log_music,1
                jne     _ret

                mov     edx,offset log_name
                call    create_file

                mov     bx,v86r_bx
                mov     log_handler,bx

                mov     eax,16384
                call    _gethimem
                mov     log_buffer,eax

                mov     log_size,0
                
                ret

; close_log_file -----------------------------------------------------
; close the log music file

close_log_file:
                cmp     log_music,1
                jne     _ret

                mov     bx,log_handler
                mov     v86r_bx,bx

                cmp     log_size,0
                je      close_log_file_now

                mov     ecx,log_size
                mov     edx,log_buffer
                call    custom_write

close_log_file_now:
                call    close_file
                ret

; log_psg_sample -----------------------------------------------------
; log a psg sample

log_psg_sample:
                mov     ecx,TOTALCLOCKS
                sub     ecx,ebp
                add     ecx,soundclocks

                push    ebx

                xchg    bl,al
                mov     bl,1
                call    log_byte
                xchg    bl,al
                
                call    log_byte

                mov     bl,cl
                call    log_byte

                shr     ecx,8
                mov     bl,cl
                call    log_byte

                shr     ecx,8
                mov     bl,cl
                call    log_byte

                shr     ecx,8
                mov     bl,cl
                call    log_byte

                pop     ebx

                ret

; log_interrupt ------------------------------------------------------
; log a interrupt to log music file

log_interrupt:
                cmp     log_music,1
                jne     _ret

                push    ebx
                mov     bl,0FFh
                call    log_byte
                pop     ebx
                ret

; log_byte -----------------------------------------------------------
; log a single byte to the log file

log_byte:
                push    ecx edx
                mov     edx,log_buffer
                mov     ecx,log_size
                mov     [ecx+edx],bl
                inc     ecx
                cmp     ecx,16384
                je      log_byte_flush

                mov     log_size,ecx
                pop     edx ecx
                ret

log_byte_flush:
                mov     log_size,0
                pushad

                mov     bx,log_handler
                mov     v86r_bx,bx

                mov     ecx,16384
                mov     edx,log_buffer

                call    custom_write

                popad     
                pop     edx ecx
                ret


code32          ends
                end


