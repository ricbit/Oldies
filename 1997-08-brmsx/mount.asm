; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: MOUNT.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include io.inc
include pmode.inc
include bit.inc

extrn mountdir_name: byte
extrn diskimage: dword
extrn transf_buffer: dword
extrn dos2enabled: dword
extrn disksize: dword
extrn drivea_name: byte

public mount_disk_image
public flush_dsk

; DATA ---------------------------------------------------------------

include msxboot.inc
include msxboot2.inc

msg1            db      'Mounting <$'
msg2            db      '> as drive A: ... $'
msg3            db      'Done.',13,10,'$'
msg4            db      'Error: too many files.',13,10,'$'
msg5            db      'Error: disk full.',13,10,'$'

align 4

name_pointer    dd      0
fat             dd      0
direc           dd      0
cluster         dd      0
totalfiles      dd      0
size_avail      dd      1428*512
file_size       dd      0
pos             dd      2

filename        db      128 dup (0)
full_filename   db      128 dup (0)

; mount_disk_image ---------------------------------------------------
; mount a directory pointed by mountdir_name
; into the diskimage

mount_disk_image:

                mov     eax,offset msg1
                call    printmsg
                mov     eax,offset mountdir_name
                call    printnul
                mov     eax,offset msg2
                call    printmsg

; --------------------------------------------------------------------
; find the end of the mountdir_name string

                mov     esi,offset mountdir_name                
                mov     edi,offset full_filename
mount_disk_name_loop:
                mov     al,[esi]
                mov     [edi],al
                or      al,al
                jz      mount_disk_found
                inc     esi
                inc     edi
                jmp     mount_disk_name_loop

; --------------------------------------------------------------------
; append the name with "\*.*"

mount_disk_found:
                mov     name_pointer,edi
                mov     dword ptr [esi],'*.*\'
                mov     byte ptr [esi+4],0

; --------------------------------------------------------------------
; copy the boot sector

                mov     esi,offset msx_boot
                cmp     dos2enabled,0
                je      copy_boot_now
                mov     esi,offset msx_boot_dos2
copy_boot_now:
                mov     edi,diskimage
                mov     ecx,512/4
                rep     movsd

; --------------------------------------------------------------------
; init the fat

                mov     edi,diskimage
                add     edi,512
                mov     fat,edi
                mov     byte ptr [edi+0],0F9h
                mov     byte ptr [edi+1],0FFh
                mov     byte ptr [edi+2],0FFh

                mov     edi,diskimage
                add     edi,7*512
                mov     direc,edi

                mov     edi,diskimage
                add     edi,14*512
                mov     cluster,edi

; --------------------------------------------------------------------
; insert the files

                mov     edi,offset mountdir_name
                mov     edx,offset filename
                call    find_first

mount_disk_outer_loop:
                jc      mount_disk_ret

                mov     edi,name_pointer
                mov     byte ptr [edi],'\'
                inc     edi
                mov     esi,offset filename

mount_dsk_filename_loop:
                mov     al,[esi]
                mov     [edi],al
                inc     esi
                inc     edi
                or      al,al
                jnz     mount_dsk_filename_loop

                ;mov     eax,offset full_filename
                ;call    printnul
                ;call    crlf
                
; --------------------------------------------------------------------
; check if the file isn't too big to fit in disk
                
                mov     edx,offset full_filename
                call    open_file
                call    read_size_file
                mov     file_size,eax
                
                cmp     size_avail,eax
                jl      mount_disk_ret_disk_full

                ; check if the file has size 0
                cmp     eax,0
                je      search_next_file

                sub     size_avail,eax

; --------------------------------------------------------------------
; check if the directory isn't full

                cmp     totalfiles,112
                jae     mount_disk_ret_too_many_files

; --------------------------------------------------------------------
; insert filename in directory

                mov     esi,offset filename
                mov     edi,direc
                mov     al,20h
                mov     ecx,8+3
                rep     stosb
                mov     edi,direc

insert_filename_loop_1:                
                mov     al,[esi]
                cmp     al,0
                je      insert_filename_exit
                cmp     al,'.'
                je      insert_filename_extension
                mov     [edi],al
                inc     edi
                inc     esi
                jmp     insert_filename_loop_1

insert_filename_extension:
                mov     edi,direc
                add     edi,8
                inc     esi
insert_filename_loop_2:
                mov     al,[esi]
                cmp     al,0
                je      insert_filename_exit
                mov     [edi],al
                inc     esi
                inc     edi
                jmp     insert_filename_loop_2


insert_filename_exit:

; --------------------------------------------------------------------
; insert file size and first fat entry in directory

                mov     eax,file_size
                mov     edi,direc
                mov     dword ptr [edi+01Ch],eax

                mov     eax,pos
                mov     word ptr [edi+01Ah],ax

; --------------------------------------------------------------------
; insert file in disk image

                mov     ebx,file_size
                add     ebx,1023
                shr     ebx,10
                mov     edi,cluster

insert_file_loop:
                push    ebx edi
                mov     edx,transf_buffer
                mov     ecx,1024
                call    read_file
                pop     edi ebx

                mov     esi,transf_buffer
                mov     ecx,1024/4
                rep     movsd

                mov     eax,pos
                lea     ecx,[eax+1]
                
                cmp     ebx,1
                jne     insert_file_middle
                or      ecx,0FFFh
insert_file_middle:

                shr     eax,1
                lea     eax,[eax+eax*2]
                add     eax,fat
                
                test    pos,BIT_0
                jnz     insert_file_1

                ; 0
                mov     byte ptr [eax],cl
                shr     ecx,8
                and     byte ptr [eax+1],0F0h
                or      byte ptr [eax+1],cl
                jmp     insert_file_next

insert_file_1:
                push    ecx
                shr     ecx,4
                mov     byte ptr [eax+2],cl
                and     byte ptr [eax+1],0Fh
                pop     ecx
                and     ecx,0Fh
                shl     ecx,4
                or      byte ptr [eax+1],cl
insert_file_next:
                inc     pos

                dec     ebx
                jnz     insert_file_loop

                mov     cluster,edi

; --------------------------------------------------------------------
; close file and search for more

                inc     totalfiles
                add     direc,32
                
search_next_file:                
                call    close_file

                mov     edi,offset mountdir_name
                mov     edx,offset filename
                call    find_next
                jmp     mount_disk_outer_loop

; --------------------------------------------------------------------
; copy the first fat over the second and return

mount_disk_ret:
                mov     esi,diskimage
                add     esi,512
                mov     edi,esi ;diskimage
                add     edi,3*512
                mov     ecx,3*512/4
                rep     movsd

                mov     eax,offset msg3
                call    printmsg
                or      al,al
                ret

mount_disk_ret_too_many_files:                
                mov     eax,offset msg4
                call    printmsg
                stc
                ret

mount_disk_ret_disk_full:
                mov     eax,offset msg5
                call    printmsg
                stc
                ret

; flush_dsk ----------------------------------------------------------
; flush the DSK image to the disk
                
flush_dsk:

                mov     edx,offset drivea_name
                call    create_file

                mov     ebx,disksize 
                mov     esi,diskimage
flush_dsk_loop:               
                mov     edi,transf_buffer
                mov     ecx,4096/4 
                rep     movsd

                mov     ecx,4096 
                mov     edx,transf_buffer
                push    ebx
                call    write_file
                pop     ebx

                dec     ebx
                jnz     flush_dsk_loop
                call    close_file
                ret


code32          ends
                end


