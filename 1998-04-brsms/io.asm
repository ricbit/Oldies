; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: IO.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

extrn blitbuffer: dword
extrn start_counter: near
extrn end_counter: near
extrn tape_pos: dword
extrn gamegear: dword
extrn speaker: dword
extrn sg1000: dword
extrn sc3000: dword

include pmode.inc
include pentium.inc
include vdp.inc
include gui.inc
include z80.inc
include bit.inc
include blit.inc
include psg.inc
include mouse.inc
include vesa.inc
include debug.inc

public printmsg
public printnul
public printasc
public printhex4
public printhex2
public printspace
public getchar
public toupper
public gethex4
public setgraphmode
public settextmode
public crlf
public testkbd
public turnon_irq
public turnoff_irq
public turnon_kb_irq
public turnoff_kb_irq
public exit_now
public open_file
public create_file
public close_file
public write_file
public read_file
public read_size_file
public framerate
public on_off
public palette
public videomode
public measurespeed
public clockrate
public printdecimal
public bargraphmode
public set_cursor_position
public tmphex4
public tmphex2
public convhex4
public cpupaused
public gui_palette
public fill_palette
public palette
public wait_vsync
public find_first
public find_next
public set_correct_palette
public setkb
public noled
public set_SMS_color
public set_SMS_palette
public set_GG_color
public savenow
public loadnow
public savesnap
public currentpalette
public dirty_palette
public set_border_color
public sg1000_high_palette
public keyboardtable_sc3000
public keyboard_actual
public keyboard_ext_sc3000
public keyboard_extended
public wait_next_vsync
public keyboardtable_coleco
public keyboard_ext_coleco
public time_base
public frames_drawed
public fps_counter
public reset_autoframe

; DATA ---------------------------------------------------------------

align 4

include keyboard.inc
include keyext.inc
include keysc3.inc
include keyesc3.inc
include keycol.inc
include keyecol.inc
include palette.inc
include guipal.inc
include filpal.inc
include 3dpal.inc
include overlay.inc

tmphex4         db      '0000$'         ; temp buffer for print routines
tmphex2         equ     tmphex4+2
tmpasc          equ     tmphex2+1
tmpspace        db      ' $'
tmpdecimal      db      20 dup (' ')
                db      '$'

irq_stub_buf    db      21 dup (0)
oldpirqvect     dd      0
oldrirqvect     dd      0

kbd_stub_buf    db      21 dup (0)
oldkbpirqvect   dd      0
oldkbrirqvect   dd      0

align 4

framerate       dd      1
exit_now        dd      0
on_off          dd      1
videomode       dd      0
cpupaused       dd      0
key_extended    dd      0
noled           dd      0
time_base       dd      0
frames_drawed   dd      0
fps_counter     dd      0

keyboard_actual   dd      offset keyboardtable
keyboard_extended dd      offset keyboard_ext

clockrate       db      8 dup (1)
measurestatus   dd      0
measureend      dd      0

bargraphmode    dd      0
savenow         dd      0
loadnow         dd      0
savesnap        dd      0

dirty_palette   db      32 dup (1)

pal_normal      dd      offset palette
pal_filtered    dd      offset filtered_palette

PAL_NONE        EQU     0
PAL_MASTER      EQU     1
PAL_FIXED       EQU     2
PAL_3D          EQU     3
PAL_GG          EQU     4

currentpalette  dd      PAL_NONE

msg00           db      13,10,'$'

; printmsg -----------------------------------------------------------
; print a dos message
; eax=address of message

printmsg:       push    ebx eax
                add     eax,_code32a
                shld    ebx,eax,28
                and     eax,0fh
                mov     v86r_ds,bx
                mov     v86r_dx,ax
                mov     v86r_ah,9
                mov     al,21h
                int     33h
                pop     eax ebx
                ret

; printasc -----------------------------------------------------------
; print a single ascii code
; al=code

printasc:       push    eax
                mov     tmpasc,al                
                mov     eax,offset tmpasc
                call    printmsg     
                pop     eax
                ret

        
; printnul -----------------------------------------------------------
; print a NULL-terminated message
; eax=address of message

printnul:
                push    ebx
                mov     ebx,eax
printnul_loop:
                mov     al,[ebx]
                or      al,al
                jz      printnul_exit
                call    printasc
                inc     ebx
                jmp     printnul_loop
printnul_exit:
                pop     ebx
                ret


; printspace ---------------------------------------------------------
; print a space

printspace:  
                push    eax
                mov     eax,offset tmpspace
                call    printmsg     
                pop     eax
                ret

        
; set_cursor_postion -------------------------------------------------
; set the cursor position
; enter dh=row dl=column

set_cursor_position:
                mov     v86r_dx,dx
                mov     v86r_bh,0
                mov     v86r_ah,2
                mov     al,10h
                int     33h
                ret

; getchar ------------------------------------------------------------
; wait for key and return ascii code in al

getchar:
                mov     v86r_ah,0           
                mov     al,16h
                int     33h
                mov     ax,v86r_ax
                ret

; testkbd ------------------------------------------------------------
; check if there is a char in the keyboard buffer
; return zero flag if char found

testkbd:
                mov     v86r_ah,1
                mov     al,16h
                int     33h
                ret

; gethex -------------------------------------------------------------
; get a hex digit from the kdb and return in al with echo

gethex:
                call    getchar
                call    toupper
                push    eax
                mov     tmpasc,al
                mov     eax,offset tmpasc
                call    printmsg
                pop     eax
                cmp     al,'A'
                jae     gethex1
                sub     al,'0'
                ret
gethex1:        sub     al,'A'-10
                ret

; gethex4 ------------------------------------------------------------
; get a four-digit hex from the kdb and return in ax (with echo)

gethex4:
                call    gethex
                and     eax,0fh
                mov     ecx,eax
                shl     ecx,4
                call    gethex
                and     eax,0fh
                add     ecx,eax
                shl     ecx,4
                call    gethex
                and     eax,0fh
                add     ecx,eax
                shl     ecx,4
                call    gethex
                and     eax,0fh
                add     ecx,eax
                mov     eax,ecx
                ret

; wait_vsync ----------------------------------------------------------
; wait for vertical retrace
                
wait_vsync:                
                mov     edx,03DAh
wait_vsync_loop:                
                in      al,dx
                test    al,BIT_3
                jz      wait_vsync_loop

                ret

; wait_next_vsync -----------------------------------------------------
; wait for the next vertical retrace
                
wait_next_vsync:                
                mov     edx,03DAh
wait_next_vsync_loop:                
                in      al,dx
                test    al,BIT_3
                jnz     wait_next_vsync_loop

                jmp     wait_vsync

; toupper -------------------------------------------------------------
; upcase a char
; in/out = al

toupper:
        cmp     al,'a'
        jb      toupper1
        cmp     al,'z'
        ja      toupper1
        sub     al,'a'-'A'
toupper1:
        ret

; SET_VGA_REG ---------------------------------------------------------
; set a vga register

SET_VGA_REG     macro   reg,index,value

                mov     dx,reg
                mov     al,index
                out     dx,al
                inc     dx
                mov     al,value
                out     dx,al

                endm

; fill_palette --------------------------------------------------------
; fill the palette with colors 
; enter ebx = offset palette  ecx = number of colors

fill_palette:
                push    eax edx
                mov     dx,03C8h
                out     dx,al
                inc     dx
                lea     ecx,[ecx+ecx*2]
fill_palette_loop:
                mov     al,[ebx]
                out     dx,al
                inc     ebx
                dec     ecx
                jnz     fill_palette_loop
                pop     edx eax
                ret

; fill_palette_dark ---------------------------------------------------
; fill the palette with darkened colors 
; enter ebx = offset palette  ecx = number of colors

fill_palette_dark:
                push    eax edx
                mov     dx,03C8h
                out     dx,al
                inc     dx
                lea     ecx,[ecx+ecx*2]
fill_palette_loop_dark:
                mov     al,[ebx]
                shr     al,1
                out     dx,al
                inc     ebx
                dec     ecx
                jnz     fill_palette_loop_dark
                pop     edx eax
                ret

; set_correct_palette -------------------------------------------------
; set the correct palette for the selected video mode/screen

set_correct_palette:
                cmp     sg1000,1
                jne     _ret

                cmp     videomode,2
                jne     set_correct_palette_16

                mov     ebx,pal_filtered
                mov     ecx,256
                mov     al,32
                jmp     fill_palette

set_correct_palette_16:
                mov     ebx,pal_normal
                mov     ecx,16
                mov     al,32
                jmp     fill_palette

; setgraphmode --------------------------------------------------------
; set video mode 13h (320x200x256)

setgraphmode:
                cmp     videomode,8
                je      setgraphmode_vesa_512_15

                cmp     videomode,6
                je      setgraphmode_vesa_512_15

                cmp     videomode,4
                je      setgraphmode_vesa_512_15

                cmp     videomode,2
                je      setgraphmode_vesa_512
                
                cmp     videomode,1
                je      setgraphmode_vesa_400

                mov     v86r_ax,13h
                mov     al,10h
                int     33h

                ; these are the cpugraph colors
                mov     ebx,offset palette
                mov     ecx,16
                mov     al,0
                call    fill_palette
                mov     ebx,offset palette
                mov     ecx,16
                mov     al,0+40h
                call    fill_palette
                call    set_SMS_palette

                call    set_mouse_range

                cmp     videomode,0
                je      _ret

                cmp     videomode,6
                je      setgraph_256x192

                mov     edx,03D4h
                mov     al,11h
                out     dx,al
                inc     edx
                in      al,dx
                and     al,07Fh
                out     dx,al

                SET_VGA_REG 03D4h,0,77
                SET_VGA_REG 03D4h,1,63
                SET_VGA_REG 03D4h,2,64
                SET_VGA_REG 03D4h,3,128+3
                SET_VGA_REG 03D4h,4,68
                SET_VGA_REG 03D4h,5,0
                SET_VGA_REG 03D4h,013h,32

                ret

setgraphmode_vesa_512_15:
                call    set_vesa_mode
                call    set_mouse_range
                mov     direct_color,1
                ret

setgraphmode_vesa_512:
                mov     eax,512
                call    set_vesa_mode
                
                mov     ebx,offset palette
                mov     ecx,16
                mov     al,0
                call    fill_palette
                mov     ebx,offset palette
                mov     ecx,16
                mov     al,0+40h
                call    fill_palette

                cmp     sg1000,1
                je      setgraphmode_res512_sg1000

                call    set_SMS_palette                
                call    set_mouse_range
                ret

setgraphmode_res512_sg1000:
                mov     ebx,offset filtered_palette
                mov     ecx,256
                mov     eax,0
                call    fill_palette
                call    set_mouse_range
                ret

setgraphmode_vesa_400:
                mov     eax,400
                call    set_vesa_mode
                
                call    set_SMS_palette                
                mov     ebx,offset palette
                mov     ecx,16
                mov     al,32
                call    fill_palette
                mov     ebx,offset palette
                mov     ecx,16
                mov     al,32+40h
                call    fill_palette
                ;call    clear_left_column

                call    set_mouse_range

                ret

setgraph_256x192:

mov dx,3C2h
mov al,0E3h     ; use 63h to stretch the display
out dx,al

mov dx,3D4h     ; enable CRTC write access
mov al,11h
out dx,al
inc dx
in al,dx
and al,7Fh
out dx,al
dec dx

mov ax,05F00h
out dx,ax
mov ax,03F01h
out dx,ax
mov ax,04002h
out dx,ax
mov ax,08203h
out dx,ax
mov ax,04C04h
out dx,ax
mov ax,09805h
out dx,ax
mov ax,0BF06h
out dx,ax
mov ax,01F07h
out dx,ax
mov ax,00008h
out dx,ax
mov ax,04109h
out dx,ax
mov ax,09410h
out dx,ax
mov ax,08611h
out dx,ax
mov ax,07F12h
out dx,ax
mov ax,02013h
out dx,ax
mov ax,04014h
out dx,ax
mov ax,08615h
out dx,ax
mov ax,0B916h
out dx,ax
mov ax,0A317h
out dx,ax
mov ax,0FF18h
out dx,ax

ret

; settextmode ---------------------------------------------------------
; set text mode 3h (80x25 color)

settextmode:
        mov v86r_ax,03h
        mov al,10h
        int 33h
        ret

; convhex ------------------------------------------------------------
; convert a hex number in ax to string in tmphex
; ax= hex number

convhexdig:     push    eax
                and     eax,0fh
                cmp     eax,0ah
                jae     convhexdig1
                add     eax,'0'
                jmp     convhexdig2
convhexdig1:    add     eax,'A'-10
convhexdig2:    mov     [bx],al
                pop     eax
                ret

convhex4:       push    eax ebx
                mov     ebx,offset tmphex4+3
                call    convhexdig
                shr     eax,4
                dec     ebx
                call    convhexdig
                shr     eax,4
                dec     ebx
convhex41:      call    convhexdig
                shr     eax,4
                dec     ebx
                call    convhexdig
                pop     ebx eax
                ret

convhex2:       push    eax ebx
                mov     ebx,offset tmphex2+1
                jmp     convhex41

; printhex -----------------------------------------------------------
; print a hex number
; ax= hex number

printhex4:      push    eax
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsg
                pop     eax
                ret

printhex2:      push    eax
                call    convhex2
                mov     eax,offset tmphex2
                call    printmsg
                pop     eax
                ret

; printdecimal -------------------------------------------------------
; print a decimal number
; eax = decimal 

printdecimal:
                mov     ebx,eax
                mov     ecx,20/4
                mov     eax,20202020h
                mov     edi,offset tmpdecimal
                rep     stosd
                mov     edi,offset tmpdecimal+18
                mov     byte ptr [offset tmpdecimal+19],'$'
                mov     eax,ebx
                mov     ebx,10
printdecimal1:
                xor     edx,edx
                div     ebx
                add     edx,30h
                mov     [edi],dl
                dec     edi
                cmp     eax,0
                jnz     printdecimal1

                lea     eax,[edi+1]
                call    printmsg
                ret

; crlf ---------------------------------------------------------------
; prints a cr/lf

crlf:           push    eax
                mov     eax,offset msg00
                call    printmsg
                pop     eax
                ret

; turnon_irq ---------------------------------------------------------
; turn on the irq handler

turnon_irq:
                mov     bl,0
                call    _getirqvect
                mov     oldpirqvect,edx
                mov     edx,offset my_irq_handler
                call    _setirqvect
                mov     edi,offset irq_stub_buf
                call    _rmpmirqset
                mov     oldrirqvect,eax
                mov     al,034h
                out     043h,al
                mov     al,0aeh
                out     040h,al
                mov     al,04dh
                out     040h,al
                ret

; turnoff_irq --------------------------------------------------------
; turn off the timer irq handler

turnoff_irq:
                mov     bl,0
                mov     eax,oldrirqvect
                call    _rmpmirqfree
                mov     edx,oldpirqvect
                call    _setirqvect
                mov     al,034h
                out     043h,al
                mov     al,0
                out     040h,al
                mov     al,0
                out     040h,al
                ret

; measurespeed -------------------------------------------------------
; measure how many clock cycles the computer spends
; between one one interrupt and another

measurespeed:                
                cli
                mov     measurestatus,0
                mov     measureend,0
                mov     bl,0
                call    _getirqvect
                mov     oldpirqvect,edx
                mov     edx,offset measure_handler
                call    _setirqvect
                mov     edi,offset irq_stub_buf
                call    _rmpmirqset
                mov     oldrirqvect,eax
                mov     al,034h
                out     043h,al
                mov     al,0aeh
                out     040h,al
                mov     al,04dh
                out     040h,al
                sti
measurespeed0:
                cmp     measureend,1
                jne     measurespeed0

                cli
                mov     bl,0
                mov     eax,oldrirqvect
                call    _rmpmirqfree
                mov     edx,oldpirqvect
                call    _setirqvect
                mov     al,034h
                out     043h,al
                mov     al,0
                out     040h,al
                mov     al,0
                out     040h,al
                sti
                ret

; turnon_kb_irq ------------------------------------------------------
; turn on the keyboard irq handler

turnon_kb_irq:
                mov     bl,1
                call    _getirqvect
                mov     oldkbpirqvect,edx
                mov     edx,offset my_kb_irq_handler
                call    _setirqvect
                mov     edi,offset kbd_stub_buf
                call    _rmpmirqset
                mov     oldkbrirqvect,eax
                ret

; turnoff_kb_irq -----------------------------------------------------
; turn off the keyboard irq handler

turnoff_kb_irq:
                mov     bl,1
                mov     eax,oldkbrirqvect
                call    _rmpmirqfree
                mov     edx,oldkbpirqvect
                call    _setirqvect
                ret

; measure_handler ----------------------------------------------------
; this handler is used to measure the clock of the processor

measure_handler:
                pushad
                push    ds
                inc     measurestatus
                cmp     measurestatus,5
                jb      measure_handler_exit
                ja      measure_handler1
                rdtsc
                mov     dword ptr [offset clockrate],eax
                mov     dword ptr [offset clockrate+4],edx
                jmp     measure_handler_exit
measure_handler1:
                rdtsc
                sub     eax,dword ptr [offset clockrate]
                sbb     edx,dword ptr [offset clockrate+4]
                mov     dword ptr [offset clockrate],eax
                mov     dword ptr [offset clockrate+4],edx
                mov     measureend,1
measure_handler_exit:
                mov     al,20h
                out     20h,al
                pop     ds
                popad
                sti
                iretd

; my_irq_handler -----------------------------------------------------
; this is the handler of the timer irq

my_irq_handler:
                pushad
                
                push    ds 
                mov     ds,cs:_seldata

                call    compose_speaker

                mov     interrupt,1
                inc     time_base
                mov     eax,time_base
                mov     edx,0
                mov     ebx,60
                div     ebx
                cmp     edx,0
                jne     my_irq_handler_exit

                mov     eax,frames_drawed
                mov     fps_counter,eax
                mov     frames_drawed,0

my_irq_handler_exit:
                pop     ds
                
                mov     al,20h
                out     20h,al
                popad
                sti
                iretd

; reset_autoframe ----------------------------------------------------
; reset the autoframe renderer

reset_autoframe:
                push    eax
                mov     eax,time_base
                mov     cpu_frames,eax
                pop     eax
                ret

; my_kb_irq_handler --------------------------------------------------
; this is the handler of the keyboard irq

my_kb_irq_handler:
                pushad
                push    ds 
                mov     ds,cs:_seldata
                
                in      al,060h
                mov     edi,keyboard_actual
                mov     esi,keyboard_extended

                cmp     key_extended,1
                je      my_kb_irq_handler_extended

                cmp     al,44h
                jne     my_kb_irq_handler1
                mov     exit_now,1

my_kb_irq_handler1:
                cmp     al,25
                je      my_kb_irq_handler_P

                cmp     al,64
                je      my_kb_irq_handler_f6

                cmp     al,67
                je      my_kb_irq_handler_f9

                cmp     al,69
                je      my_kb_irq_handler_numlock

                cmp     al,69+128
                je      my_kb_irq_handler_numlock_released

                cmp     al,87
                je      my_kb_irq_handler_f11

                cmp     al,88
                je      my_kb_irq_handler_f12

                cmp     al,63
                je      my_kb_irq_handler_f5

                cmp     al,65
                je      my_kb_irq_handler_f7

                cmp     al,78
                je      my_kb_irq_handler_keypadplus

                cmp     al,74
                je      my_kb_irq_handler_keypadminus

                cmp     al,224
                je      my_kb_irq_handler_extended_signal

my_kb_start:
                
                test    al,080h
                jnz     my_kb_irq_handler2
                and     eax,07fh
                movzx   ebx,byte ptr [edi+eax*2]
                mov     cl,byte ptr [edi+eax*2+1]
                xor     cl,255
                and     byte ptr [offset smsjoya+ebx],cl
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler2:                
                and     eax,07fh
                movzx   ebx,byte ptr [edi+eax*2]
                mov     cl,byte ptr [edi+eax*2+1]
                or      byte ptr [offset smsjoya+ebx],cl

my_kb_irq_handler_exit:

                mov     al,20h
                out     20h,al
                pop     ds
                popad
                sti
                iretd

my_kb_irq_handler_P:
                cmp     sc3000,1
                je      my_kb_start

                mov     nmi,1
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_f12:
                ;xor     cpupaused,1
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_f11:
                xor     turnedoff,1
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_f6:
                mov     tape_pos,0
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_f9:
                mov     savesnap,1
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_numlock:
                mov     fastforward,1
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_numlock_released:
                mov     fastforward,0
                call    reset_autoframe
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_f5:
                ;mov     savenow,1
                inc     padstatus
                and     padstatus,0Fh
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_f7:
                ;mov     loadnow,1
                dec     padstatus
                and     padstatus,0Fh
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_keypadplus:
                call    read_master_volume
                cmp     al,0Fh
                je      my_kb_irq_handler_exit
                inc     al
                call    write_master_volume
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_keypadminus:
                call    read_master_volume
                cmp     al,0h
                je      my_kb_irq_handler_exit
                dec     al
                call    write_master_volume
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_extended:
                mov     key_extended,0
                test    al,080h
                jnz     my_kb_irq_handler_extended_released
                and     eax,07fh
                movzx   ebx,byte ptr [esi+eax*2]
                mov     cl,byte ptr [esi+eax*2+1]
                xor     cl,255
                and     byte ptr [offset smsjoya+ebx],cl
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_extended_released:
                and     eax,07fh
                movzx   ebx,byte ptr [esi+eax*2]
                mov     cl,byte ptr [esi+eax*2+1]
                or      byte ptr [offset smsjoya+ebx],cl
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_extended_signal:
                mov     key_extended,1
                jmp     my_kb_irq_handler_exit
                
; open_file ----------------------------------------------------------
; open a file
; in: edx = ASCIIZ filename
; out: v86r_bx = file handle
;      carry = 1 -> error                

open_file:                
                push    eax
                add     edx,_code32a
                mov     eax,edx
                shr     edx,4
                and     eax,0fh
                mov     v86r_dx,ax
                mov     v86r_ds,dx
                mov     v86r_ax,03d00h
                mov     al,21h
                int     33h
                mov     ax,v86r_ax
                mov     v86r_bx,ax
                pop     eax
                ret

; create_file --------------------------------------------------------
; create a file
; in: edx = ASCIIZ filename
; out: v86r_bx = file handle
;      carry = 1 -> error                

create_file:                
                push    eax
                add     edx,_code32a
                mov     eax,edx
                shr     edx,4
                and     eax,0fh
                mov     v86r_dx,ax
                mov     v86r_ds,dx
                mov     v86r_ax,03C02h
                mov     v86r_cx,BIT_5
                mov     al,21h
                int     33h
                mov     ax,v86r_ax
                mov     v86r_bx,ax
                pop     eax
                ret

; read_file ----------------------------------------------------------
; read a file
; in: v86r_bx = file handle
;     edx = address of read buffer
;     ecx = number of bytes to read (must be <0ffffh)

read_file:                
                push    eax
                add     edx,_code32a
                mov     eax,edx
                shr     edx,4
                and     eax,0fh
                mov     v86r_ds,dx
                mov     v86r_dx,ax
                mov     v86r_cx,cx
                mov     v86r_ax,03f00h
                mov     al,21h
                int     33h
                pop     eax
                ret

; write_file ---------------------------------------------------------
; write a file
; in: v86r_bx = file handle
;     edx = address of write buffer
;     ecx = number of bytes to write (must be <0ffffh)

write_file:                
                push    eax
                add     edx,_code32a
                mov     eax,edx
                shr     edx,4
                and     eax,0fh
                mov     v86r_ds,dx
                mov     v86r_dx,ax
                mov     v86r_cx,cx
                mov     v86r_ax,04000h
                mov     al,21h
                int     33h
                pop     eax
                ret

; close_file ---------------------------------------------------------
; close a file
; in: v86r_bx = file handle

close_file:                
                push    eax
                mov     v86r_ax,03E00h
                mov     al,21h
                int     33h
                pop     eax
                ret

; read_size_file -----------------------------------------------------
; read the size of the file
; in: v86r_bx = file handle
; return: eax=file size

read_size_file:
                mov     v86r_ax,4201h
                xor     eax,eax
                mov     v86r_cx,ax
                mov     v86r_dx,ax
                mov     al,21h
                int     33h
                push    v86r_dx
                push    v86r_ax
                mov     v86r_ax,4202h
                xor     eax,eax
                mov     v86r_cx,ax
                mov     v86r_dx,ax
                mov     al,21h
                int     33h
                mov     ax,v86r_dx
                shl     eax,16
                mov     ax,v86r_ax
                pop     v86r_dx
                pop     v86r_cx
                mov     v86r_ax,4200h
                push    eax
                mov     al,21h
                int     33h
                pop     eax
                ret

; find_first ---------------------------------------------------------
; find the first file 
; enter: edi -> path
;        edx -> buffer
; exit:  carry flag on error (or not found)

find_first:
                push    edi
        
                ; set up segmented address
                add     edi,_code32a
                mov     esi,edi
                and     esi,0fh
                shr     edi,4
                mov     v86r_ds,di
                mov     v86r_dx,si

                ; perform the call to DOS
                mov     v86r_ah,04Eh
                mov     v86r_cx,20h
                mov     al,21h
                int     33h
        
                ; copy the file name to correct destination
                mov     esi,_code16a
                sub     esi,62h
                sub     esi,_code32a
                mov     edi,edx
                mov     ecx,13
                rep     movsb
        
                ; set the carry flag on error
                bt      v86r_flags,0

                pop     edi
                ret

; find_next ----------------------------------------------------------
; find the next file 
; enter: edi -> path
;        edx -> buffer
; exit:  carry flag on error (or not found)

find_next:
                push    edi
        
                ; set up segmented address
                add     edi,_code32a
                mov     esi,edi
                and     esi,0fh
                shr     edi,4
                mov     v86r_ds,di
                mov     v86r_dx,si

                ; perform the call to DOS
                mov     v86r_ah,04Fh
                mov     v86r_cx,20h
                mov     al,21h
                int     33h
        
                ; copy the file name to correct destination
                mov     esi,_code16a
                sub     esi,62h
                sub     esi,_code32a
                mov     edi,edx
                mov     ecx,13
                rep     movsb
        
                ; set the carry flag on error
                bt      v86r_flags,0

                pop     edi
                ret

; setkb --------------------------------------------------------------
; set the keyboard LEDs
; enter: BL=leds 00000CNS , C=Caps, N=Num, S=Scroll

setkb:                         
                ; in the SMS there is no need to leds
                ret

                cmp     noled,1
                je      _ret

                cli
                mov     al,0edh
                call    outtokb
                mov     al,bl
                call    outtokb
                mov     al,0f4h
                call    outtokb
                sti
                ret

waitforkb:                              
                mov     ecx,20000h
waitforkbl:
                in      al,64h
                test    al,2
                loopnz  waitforkbl
                ret

outtokb:
                mov     ah,al
                mov     bh,1 
outtokbl0:
                call    waitforkb
                mov     al,ah
                out     60h,al
                mov     ecx,4000h
outtokbl1:
                in      al,61h
                test    al,10h
                jz      $-4
                in      al,61h
                test    al,10h
                jnz     $-4
                in      al,64h
                test    al,1
                loopz   outtokbl1
                in      al,60h
                cmp     al,0fah
                je      _ret
                dec     bh
                jnz     outtokbl0
                ret        

; set_SMS_color ------------------------------------------------------
; set a single SMS color in palette
; enter al=color slot bl=color index
; modify ecx eax

set_SMS_color:
                cmp     system3d,1
                je      _ret

                push    edx eax ebx
                mov     dx,03C8h
                out     dx,al
                inc     dx

                mov     bl,byte ptr [offset smspalette+ebx]
                and     al,040h
                setnz   cl
                ;
                mov     al,bl
                and     al,3
                mov     ch,al
                shl     ch,2
                or      al,ch
                shl     ch,2
                or      al,ch
                
                shr     al,cl
                
                out     dx,al
                ;
                mov     al,bl
                and     al,12
                mov     ch,al
                shl     ch,2
                or      al,ch
                shr     ch,4
                or      al,ch
                
                shr     al,cl
                
                out     dx,al
                ;
                mov     al,bl
                and     al,030h
                mov     ch,al
                shr     ch,2
                or      al,ch
                shr     ch,2
                or      al,ch
                
                shr     al,cl
                
                out     dx,al

                pop     ebx eax edx

                ret

; set_GG_color ------------------------------------------------------
; set a single GG color in palette
; modify ecx eax

set_GG_color:
                push    ebx edx eax
                
                mov     dx,03C8h
                out     dx,al
                inc     dx
                and     al,040h
                setnz   cl

                mov     bx,word ptr [offset smspalette+ebx*2]

                ;
                mov     al,bl
                shr     al,1                
                and     al,7
                mov     ch,al
                shl     ch,3
                or      al,ch
                out     dx,al
                ;
                mov     al,bl
                shr     al,5
                and     al,7
                mov     ch,al
                shl     ch,3
                or      al,ch
                out     dx,al
                ;
                mov     al,bh
                shr     al,1
                and     al,7
                mov     ch,al
                shl     ch,3
                or      al,ch
                out     dx,al
                ;

                pop     eax edx ebx

                ret

; set_SMS_palette ----------------------------------------------------
; set all SMS colors based in vdp palette registers
; modify ecx eax edx

set_SMS_palette:
                cmp     system3d,1
                je      set_3d_palette

                cmp     palette_raster,1
                je      set_SMS_palette_raster
                
                cmp     gamegear,1
                je      set_GG_palette

                cmp     sg1000,1
                je      _ret
                
                irp     i,<0,40h,80h,0C0h>
                
                mov     al,i
                mov     dx,03C8h
                ;
                or      al,020h
                ;
                out     dx,al
                inc     dx
                mov     esi,offset smspalette
                mov     edi,32
                ;
set_SMS_palette_loop_&i:
                mov     bl,[esi]
                inc     esi
                ;
                mov     al,bl
                and     al,3
                mov     cl,al
                shl     cl,2
                or      al,cl
                shl     cl,2
                or      al,cl
                if      ((i AND 040h) EQ 40h)
                shr     al,1
                endif
                out     dx,al
                ;
                mov     al,bl
                and     al,12
                mov     cl,al
                shl     cl,2
                or      al,cl
                shr     cl,4
                or      al,cl
                if      ((i AND 040h) EQ 40h)
                shr     al,1
                endif
                out     dx,al
                ;
                mov     al,bl
                and     al,030h
                mov     cl,al
                shr     cl,2
                or      al,cl
                shr     cl,2
                or      al,cl
                if      ((i AND 040h) EQ 40h)
                shr     al,1
                endif
                out     dx,al
                ;
                dec     edi
                jnz     set_SMS_palette_loop_&i

                endm

                ret
                
set_SMS_palette_fixed:
                ;cmp     currentpalette,PAL_FIXED
                ;je      _ret

                mov     ebx,offset palette
                mov     ecx,16
                mov     al,0
                call    fill_palette
                mov     ebx,offset palette
                mov     ecx,16
                mov     al,40h
                call    fill_palette_dark
                ret

set_3d_palette:
                cmp     currentpalette,PAL_3D
                je      _ret

                mov     ebx,offset overlay_palette
                mov     ecx,256
                mov     al,0
                call    fill_palette
                ret

set_SMS_palette_raster:
                irp     i,<080h,0C0h>
                local   set_SMS_palette_raster_loop
                
                mov     al,i
                mov     dx,03C8h
                out     dx,al
                inc     dx
                mov     edi,0
                ;
set_SMS_palette_raster_loop:
                mov     ebx,edi
                ;
                mov     al,bl
                and     al,3
                mov     cl,al
                shl     cl,2
                or      al,cl
                shl     cl,2
                or      al,cl
                if      ((i AND 040h) EQ 40h)
                shr     al,1
                endif
                out     dx,al
                ;
                mov     al,bl
                and     al,12
                mov     cl,al
                shl     cl,2
                or      al,cl
                shr     cl,4
                or      al,cl
                if      ((i AND 040h) EQ 40h)
                shr     al,1
                endif
                out     dx,al
                ;
                mov     al,bl
                and     al,030h
                mov     cl,al
                shr     cl,2
                or      al,cl
                shr     cl,2
                or      al,cl
                if      ((i AND 040h) EQ 40h)
                shr     al,1
                endif
                out     dx,al
                ;
                inc     edi
                cmp     edi,64
                jne     set_SMS_palette_raster_loop

                endm

                ret
                
; set_GG_palette ----------------------------------------------------
; set all GG colors based in vdp palette registers
; modify ecx eax edx

set_GG_palette:
                cmp     currentpalette,PAL_GG
                je      _ret

                push    eax edx edi ebp

                irp     i,<0,40h,80h,0C0h>
                local   set_GG_palette_loop
                
                mov     al,i
                mov     dx,03C8h
                or      al,020h
                out     dx,al
                inc     dx
                mov     esi,offset smspalette
                mov     edi,32
                ; 
set_GG_palette_loop:
                mov     bx,[esi]
                add     esi,2
                ;
                mov     al,bl
                shr     al,1                
                and     al,7
                mov     cl,al
                shl     cl,3
                or      al,cl
                out     dx,al
                ;
                mov     al,bl
                shr     al,5
                and     al,7
                mov     cl,al
                shl     cl,3
                or      al,cl
                out     dx,al
                ;
                mov     al,bh
                shr     al,1
                and     al,7
                mov     cl,al
                shl     cl,3
                or      al,cl
                out     dx,al
                ;
                dec     edi
                jnz     set_GG_palette_loop

                endm
                
                pop     ebp edi edx eax
                ret

; --------------------------------------------------------------------

set_border_color:
                cmp      sg1000,1
                jne     _ret
                
                cmp     videomode,2
                je      set_border_color_512x384
                
                push    eax ebx edx
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0fh
                ;lea     ebx,[offset palette+eax+eax*2]
                mov     ebx,pal_normal
                ;lea     ebx,[ebx+eax+eax*2]
                add     ebx,eax
                add     ebx,eax
                add     ebx,eax
                mov     al,0
                mov     dx,03C8h
                out     dx,al
                inc     dx
                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al
                
                cmp     lastscreen,0
                jne     set_border_color_ret
                
                ; screen 0
                ; must also set the color 2
                movzx   eax,byte ptr [offset vdpregs+7]
                shr     eax,4
                ;lea     ebx,[offset palette+eax+eax*2]
                mov     ebx,pal_normal
                ;lea     ebx,[ebx+eax+eax*2]
                add     ebx,eax
                add     ebx,eax
                add     ebx,eax
                
                dec     edx
                mov     al,2
                out     dx,al
                inc     edx
                
                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

set_border_color_ret:
                pop     edx ebx eax
                ret

set_border_color_512x384:
                
                cmp     lastscreen,0
                je      set_border_color_512x384_scr0

                push    eax ebx edx

                mov     al,0
                mov     dx,03C8h
                out     dx,al
                inc     dx

                ; set the color 00h
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                mov     ebx,eax
                shl     ebx,4
                or      eax,ebx
                lea     eax,[eax+eax*2]
                mov     ebx,pal_filtered
                add     ebx,eax
                ;lea     ebx,[offset filtered_palette+eax]
                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

                ; set the first row of combined colors
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                lea     eax,[eax+eax*2]
                shl     eax,4
                mov     ebx,pal_filtered
                ;add     ebx,eax
                ;lea     ebx,[offset filtered_palette+eax+3]
                lea     ebx,[ebx+eax+3]

                mov     ecx,15*3
set_border_color_512x384_loop1:
                mov     al,[ebx]
                inc     ebx
                out     dx,al
                dec     ecx
                jnz     set_border_color_512x384_loop1
                
                ; set the first column of combined colors
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                lea     eax,[eax+eax*2]
                shl     eax,4
                mov     esi,10h
                mov     ebx,pal_filtered
                lea     ebx,[ebx+eax+3]
                ;lea     ebx,[offset filtered_palette+eax+3]

                dec     edx
                mov     ecx,15
set_border_color_512x384_loop2:

                mov     eax,esi
                out     dx,al
                inc     edx
                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al
                add     ebx,3
                add     esi,10h
                dec     edx
                dec     ecx
                jnz     set_border_color_512x384_loop2

                pop     edx ebx eax
                ret

set_border_color_512x384_scr0:
                push    eax ebx edx

                mov     al,0
                mov     dx,03C8h
                out     dx,al
                inc     dx

                ; set the color 00h
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                mov     ebx,eax
                shl     ebx,4
                or      eax,ebx
                lea     eax,[eax+eax*2]
                mov     ebx,pal_filtered
                add     ebx,eax
                ;lea     ebx,[offset filtered_palette+eax]

                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

                ; set the color 01h
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                or      eax,10h
                lea     eax,[eax+eax*2]
                mov     ebx,pal_filtered
                add     ebx,eax
                ;lea     ebx,[offset filtered_palette+eax]

                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

                ; set the color 02h
                movzx   eax,byte ptr [offset vdpregs+7]
                lea     eax,[eax+eax*2]
                ;lea     ebx,[offset filtered_palette+eax]
                mov     ebx,pal_filtered
                add     ebx,eax

                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

                ; set the color 10h

                dec     edx
                mov     al,10h
                out     dx,al
                inc     edx

                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                or      eax,10h
                lea     eax,[eax+eax*2]
                ;lea     ebx,[offset filtered_palette+eax]
                mov     ebx,pal_filtered
                add     ebx,eax

                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

                ; set the color 12h

                dec     edx
                mov     al,12h
                out     dx,al
                inc     edx

                movzx   eax,byte ptr [offset vdpregs+7]
                shr     eax,4
                or      eax,10h
                lea     eax,[eax+eax*2]
                ;lea     ebx,[offset filtered_palette+eax]
                mov     ebx,pal_filtered
                add     ebx,eax

                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

                ; set the color 20h

                dec     edx
                mov     al,20h
                out     dx,al
                inc     edx

                movzx   eax,byte ptr [offset vdpregs+7]
                shr     eax,4
                mov     ebx,eax
                shl     ebx,4
                or      eax,ebx
                lea     eax,[eax+eax*2]
                ;lea     ebx,[offset filtered_palette+eax]
                mov     ebx,pal_filtered
                add     ebx,eax

                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

                ; set the color 21h
                movzx   eax,byte ptr [offset vdpregs+7]
                shr     eax,4
                or      eax,10h
                lea     eax,[eax+eax*2]
                ;lea     ebx,[offset filtered_palette+eax]
                mov     ebx,pal_filtered
                add     ebx,eax

                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

                ; set the color 22h
                movzx   eax,byte ptr [offset vdpregs+7]
                shr     eax,4
                mov     ebx,eax
                shl     ebx,4
                or      eax,ebx
                lea     eax,[eax+eax*2]
                ;lea     ebx,[offset filtered_palette+eax]
                mov     ebx,pal_filtered
                add     ebx,eax

                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

                pop     edx ebx eax
                ret



code32          ends
                end
