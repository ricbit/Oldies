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
extrn message_buffer: dword
extrn msxmodel: dword

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
include v9938.inc

public printmsg
public printnul
public printasc
public printhex4
public printhex2
public printspace
public getchar
public toupper
public gethex4
public gethex2
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
public set_border_color
public set_border_color_dark
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
public savesnap
public greenflag
public pal_normal      
public pal_filtered    
public pal_gui         
public palette_green
public filtered_palette_green
public gui_palette_green
public wait_next_vsync
public adjust_clock
public oldmode
public fastforward 
public speaq
public sg1000_high_palette
public gui_palette_high
public border_changed
public set_palette_color
public vdplog_now
public palette_scr8

; DATA ---------------------------------------------------------------

align 4

include keyboard.inc
include keyext.inc

include palette.inc
include guipal.inc
include filpal.inc
include scr8pal.inc

include palgreen.inc
include guigreen.inc
include filgreen.inc

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
savesnap        dd      0
greenflag       dd      0
speaq           dd      1
speaker_counter dd      1
pal_normal      dd      offset palette
pal_filtered    dd      offset filtered_palette
pal_gui         dd      offset gui_palette

clockrate       db      8 dup (0)
measurestatus   dd      0
measureend      dd      0

bargraphmode    dd      0

oldmode         dd      0
fastforward     dd      0
forwardlock     dd      0
border_changed  dd      0
vdplog_now      dd      0
palette_scr8    dd      0

msg00           db      13,10,'$'

; printmsg -----------------------------------------------------------
; print a dos message
; eax=address of message

printmsg:       
                push    ebx eax edi esi

                mov     esi,eax
                mov     edi,message_buffer
print_msg_loop:
                mov     al,byte ptr [esi]
                inc     esi
                mov     byte ptr [edi],al
                inc     edi
                cmp     al,'$'
                jne     print_msg_loop

                mov     eax,message_buffer
                mov     ebx,0
                add     eax,_code32a
                shld    ebx,eax,28
                and     eax,0fh
                mov     v86r_ds,bx
                mov     v86r_dx,ax
                mov     v86r_ah,9
                mov     al,21h
                int     33h
                pop     esi edi eax ebx
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

; gethex2 ------------------------------------------------------------
; get a two-digit hex from the kdb and return in al (with echo)

gethex2:
                call    gethex
                and     eax,0fh
                mov     ecx,eax
                shl     ecx,4
                call    gethex
                and     eax,0fh
                add     eax,ecx
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
                mov     al,0
                mov     dx,03C8h
                out     dx,al
                inc     dx
                lea     ecx,[ecx+ecx*2]
setgraphmode1:  
                mov     al,[ebx]
                out     dx,al
                inc     ebx
                dec     ecx
                jnz     setgraphmode1
                pop     edx eax
                ret

; set_correct_palette -------------------------------------------------
; set the correct palette for the selected video mode/screen

set_correct_palette:
                cmp     msxmodel,0
                jne     set_correct_palette_msx2

                cmp     videomode,2
                jne     set_correct_palette_16

                mov     ebx,pal_filtered
                mov     ecx,256
                jmp     fill_palette

set_correct_palette_16:
                mov     ebx,pal_normal
                mov     ecx,16
                jmp     fill_palette

set_correct_palette_msx2:
                cmp     actualscreen,0
                je      set_correct_palette_scr0
                cmp     actualscreen,8
                je      set_correct_palette_scr8

                mov     edi,offset msx2palette
                mov     esi,offset dirty_palette
                mov     eax,0

set_correct_palette_msx2_loop:
                movzx   ecx,word ptr [edi]
                
                ; check the border color
                cmp     eax,0
                jne     set_correct_palette_msx2_check
                test    byte ptr [offset vdpregs+8],BIT_5
                jnz     set_correct_palette_msx2_check

                movzx   ecx,byte ptr [offset vdpregs+7]
                and     ecx,0Fh
                movzx   ecx,word ptr [offset msx2palette+ecx*2]

set_correct_palette_msx2_check:
                cmp     byte ptr [esi],1
                jne     set_correct_palette_msx2_next

                or      al,10h
                call    set_palette_color
                and     al,0EFh

set_correct_palette_msx2_next:
                mov     byte ptr [esi],0

                inc     esi
                add     edi,2
                inc     eax
                cmp     eax,16
                jne     set_correct_palette_msx2_loop
                mov     palette_scr8,0
                ret

set_correct_palette_scr8:
                cmp     palette_scr8,1
                je      _ret

                mov     ebx,offset palette_screen8
                mov     ecx,256
                call    fill_palette
                mov     palette_scr8,1
                ret

set_correct_palette_scr0:
                cmp     palette_scr8,1
                jne     set_correct_palette_scr0_now
                
                cmp     byte ptr [offset dirty_palette+0],1
                je      set_correct_palette_scr0_now

                movzx   ecx,byte ptr [offset vdpregs+7]
                and     ecx,0Fh
                cmp     byte ptr [offset dirty_palette+ecx],1
                je      set_correct_palette_scr0_now

                movzx   ecx,byte ptr [offset vdpregs+7]
                shr     ecx,4
                cmp     byte ptr [offset dirty_palette+ecx],1
                je      set_correct_palette_scr0_now

                ret

set_correct_palette_scr0_now:
                movzx   ecx,byte ptr [offset vdpregs+7]
                and     ecx,0Fh
                movzx   ecx,word ptr [offset msx2palette+ecx*2]
                mov     eax,010h
                call    set_palette_color

                movzx   ecx,byte ptr [offset vdpregs+7]
                shr     ecx,4
                movzx   ecx,word ptr [offset msx2palette+ecx*2]
                mov     eax,011h
                call    set_palette_color

                mov     palette_scr8,0
                ret

; setgraphmode --------------------------------------------------------
; set video mode 13h (320x200x256)

setgraphmode:
                mov     eax,01010101h
                mov     ecx,16/4
                mov     edi,offset dirty_palette
                rep     stosd
                mov     palette_scr8,0

                cmp     videomode,2
                je      setgraphmode_vesa

                cmp     videomode,6
                je      setgraphmode_vesa_512_15

                cmp     videomode,8
                je      setgraphmode_vesa_msx2

                cmp     videomode,9
                je      setgraphmode_vesa_msx2

                cmp     videomode,11
                je      setgraphmode_vesa_msx2

                cmp     videomode,12
                je      setgraphmode_vesa_512_15

                mov     v86r_ax,13h
                mov     al,10h
                int     33h

                mov     ebx,pal_normal
                mov     ecx,16
                call    fill_palette

                call    set_mouse_range

                cmp     videomode,0
                je      _ret

                cmp     videomode,7
                je      setgraphmode_msx2

                cmp     videomode,3
                je      setgraph_256x192

                mov     edx,03D4h
                mov     al,11h
                out     dx,al
                inc     edx
                in      al,dx
                and     al,07Fh
                out     dx,al

                ;SET_VGA_REG 03D4h,0,77
                ;SET_VGA_REG 03D4h,1,63
                ;SET_VGA_REG 03D4h,2,64
                ;SET_VGA_REG 03D4h,3,128+3
                ;SET_VGA_REG 03D4h,4,68
                ;SET_VGA_REG 03D4h,5,0
                ;SET_VGA_REG 03D4h,013h,32
                SET_VGA_REG 03D4h,0,04Eh
                SET_VGA_REG 03D4h,1,03Fh
                SET_VGA_REG 03D4h,2,040h
                SET_VGA_REG 03D4h,3,091h
                SET_VGA_REG 03D4h,4,042h
                SET_VGA_REG 03D4h,5,000h
                SET_VGA_REG 03D4h,013h,32

                ret

setgraphmode_msx2:
                mov     eax,01010101h
                mov     ecx,16/4
                mov     edi,offset dirty_palette
                rep     stosd
                ret

setgraphmode_vesa:
                call    set_vesa_mode
                
                mov     ebx,pal_filtered
                mov     ecx,256
                call    fill_palette
                
                call    set_mouse_range

                ret

setgraphmode_vesa_msx2:
                call    set_vesa_mode
                
                mov     ebx,pal_normal
                mov     ecx,256
                call    fill_palette
                
                call    set_mouse_range

                ret

setgraphmode_vesa_512_15:
                call    set_vesa_mode
                call    set_mouse_range
                mov     direct_color,1
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

; set_border_color ----------------------------------------------------
; set color 0 of VGA as VDP border color

set_border_color:
                cmp     msxmodel,0
                jne     _ret

                mov     border_changed,1
                
                cmp     videomode,2
                je      set_border_color_512x384
                
                push    eax ebx edx
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0fh
                mov     ebx,pal_normal
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
                mov     ebx,pal_normal
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

                mov     al,[ebx]
                out     dx,al
                mov     al,[ebx+1]
                out     dx,al
                mov     al,[ebx+2]
                out     dx,al

                ; set the color 02h
                movzx   eax,byte ptr [offset vdpregs+7]
                lea     eax,[eax+eax*2]
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

; set_border_color_dark -----------------------------------------------
; set color 0 of VGA as VDP border color

set_border_color_dark:
                push    eax ebx edx
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0fh
                lea     ebx,[offset palette+eax+eax*2]
                mov     al,0
                mov     dx,03C8h
                out     dx,al
                inc     dx
                mov     al,[ebx]
                shr     al,2
                out     dx,al
                mov     al,[ebx+1]
                shr     al,2
                out     dx,al
                mov     al,[ebx+2]
                shr     al,2
                out     dx,al

                cmp     lastscreen,0
                jne     set_border_color_dark_ret

                ; screen 0
                ; must also set the color 2

                dec     edx
                mov     al,2
                out     dx,al
                inc     edx

                movzx   eax,byte ptr [offset vdpregs+7]
                shr     eax,4
                lea     ebx,[offset palette+eax+eax*2]
                mov     al,[ebx]
                shr     al,2
                out     dx,al
                mov     al,[ebx+1]
                shr     al,2
                out     dx,al
                mov     al,[ebx+2]
                shr     al,2
                out     dx,al


set_border_color_dark_ret:

                pop     edx ebx eax
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
convhexdig2:    mov     [ebx],al
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
                mov     edi,offset tmpdecimal+19
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

                mov     eax,01234DDh
                mov     edx,0
                mov     ebx,_verticalrate  ; 60
                div     ebx
                mov     edx,0
                mov     ebx,speaq
                div     ebx

                mov     edx,eax
                mov     al,dl 
                out     040h,al
                mov     al,dh 
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

                cmp     speaker,1
                jne     my_irq_handler_nospeaker
                cmp     soundplaying,1
                jne     my_irq_handler_nospeaker
                
                call    compose_speaker
my_irq_handler_nospeaker:

                dec     speaker_counter
                jnz     my_irq_handler_noadjust

                mov     eax,speaq
                mov     speaker_counter,eax

                mov     interrupt,1

my_irq_handler_noadjust:

                pop     ds
                
                mov     al,20h
                out     20h,al
                popad
                sti
                iretd

; my_kb_irq_handler --------------------------------------------------
; this is the handler of the keyboard irq

my_kb_irq_handler:
                pushad
                push    ds 
                mov     ds,cs:_seldata
                
                in      al,060h

                cmp     key_extended,1
                je      my_kb_irq_handler_extended

                cmp     al,44h
                jne     my_kb_irq_handler1
                mov     exit_now,1

my_kb_irq_handler1:
                cmp     al,64
                je      my_kb_irq_handler_f6

                cmp     al,88
                je      my_kb_irq_handler_f12

                cmp     al,69
                je      my_kb_irq_handler_numlock

                cmp     al,78
                je      my_kb_irq_handler_keypadplus

                cmp     al,67
                je      my_kb_irq_handler_f9

                cmp     al,74
                je      my_kb_irq_handler_keypadminus

                cmp     al,75
                je      my_kb_irq_handler_left

                cmp     al,77
                je      my_kb_irq_handler_right

                cmp     al,75+128
                je      my_kb_irq_handler_left_released

                cmp     al,77+128
                je      my_kb_irq_handler_right_released

                cmp     al,69+128
                je      my_kb_irq_handler_numlock_released

                cmp     al,57
                je      my_kb_irq_handler_spacebar

                cmp     al,57+128
                je      my_kb_irq_handler_spacebar_released

                cmp     al,224
                je      my_kb_irq_handler_extended_signal
                
my_kb_irq_handler_generic_key:                      

                test    al,080h
                jnz     my_kb_irq_handler2
                and     eax,07fh
                movzx   ebx,byte ptr [offset keyboardtable+eax*2]
                mov     cl,byte ptr [offset keyboardtable+eax*2+1]
                xor     cl,255
                and     byte ptr [offset keymatrix+ebx],cl
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler2:                
                and     eax,07fh
                movzx   ebx,byte ptr [offset keyboardtable+eax*2]
                mov     cl,byte ptr [offset keyboardtable+eax*2+1]
                or      byte ptr [offset keymatrix+ebx],cl

my_kb_irq_handler_exit:

                mov     al,20h
                out     20h,al
                pop     ds
                popad
                sti
                iretd

my_kb_irq_handler_f12:
                xor     cpupaused,1
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_enter_keypad_released:
                mov     vdplog_now,0
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_enter_keypad:
                mov     vdplog_now,1
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_f6:
                mov     tape_pos,0
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_f9:
                mov     savesnap,1
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

my_kb_irq_handler_spacebar:
                test    autofire,1
                jz      my_kb_irq_handler_generic_key
                mov     autofire,3
                jmp     my_kb_irq_handler_generic_key

my_kb_irq_handler_spacebar_released:
                test    autofire,1
                jz      my_kb_irq_handler_generic_key
                mov     autofire,1
                jmp     my_kb_irq_handler_generic_key

                
my_kb_irq_handler_left:
                test    autorun,1
                jz      my_kb_irq_handler_generic_key
                and     autorun,NBIT_1
                jmp     my_kb_irq_handler_generic_key

my_kb_irq_handler_right:
                test    autorun,1
                jz      my_kb_irq_handler_generic_key
                and     autorun,NBIT_2
                jmp     my_kb_irq_handler_generic_key

my_kb_irq_handler_left_released:
                test    autorun,1
                jz      my_kb_irq_handler_generic_key
                or      autorun,BIT_1
                jmp     my_kb_irq_handler_generic_key

my_kb_irq_handler_right_released:
                test    autorun,1
                jz      my_kb_irq_handler_generic_key
                or      autorun,BIT_2
                jmp     my_kb_irq_handler_generic_key

my_kb_irq_handler_numlock:
                cmp     forwardlock,1
                je      my_kb_irq_handler_exit       
                mov     oldmode,2
                mov     fastforward,1
                mov     forwardlock,1
                jmp     my_kb_irq_handler_exit       

my_kb_irq_handler_numlock_released:
                mov     fastforward,1
                mov     forwardlock,0
                jmp     my_kb_irq_handler_exit       

my_kb_irq_handler_extended:
                cmp     al,75
                je      my_kb_irq_handler_left_extended

                cmp     al,77
                je      my_kb_irq_handler_right_extended

                cmp     al,28
                je      my_kb_irq_handler_enter_keypad

                cmp     al,28+128
                je      my_kb_irq_handler_enter_keypad_released

                cmp     al,75+128
                je      my_kb_irq_handler_left_released_extended

                cmp     al,77+128
                je      my_kb_irq_handler_right_released_extended

my_kb_irq_handler_generic_key_extended:
                mov     key_extended,0
                test    al,080h
                jnz     my_kb_irq_handler_extended_released
                and     eax,07fh
                movzx   ebx,byte ptr [offset keyboard_ext+eax*2]
                mov     cl,byte ptr [offset keyboard_ext+eax*2+1]
                xor     cl,255
                and     byte ptr [offset keymatrix+ebx],cl
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_extended_released:
                and     eax,07fh
                movzx   ebx,byte ptr [offset keyboard_ext+eax*2]
                mov     cl,byte ptr [offset keyboard_ext+eax*2+1]
                or      byte ptr [offset keymatrix+ebx],cl
                jmp     my_kb_irq_handler_exit

my_kb_irq_handler_extended_signal:
                mov     key_extended,1
                jmp     my_kb_irq_handler_exit
                
my_kb_irq_handler_left_extended:
                test    autorun,1
                jz      my_kb_irq_handler_generic_key_extended
                and     autorun,NBIT_1
                jmp     my_kb_irq_handler_generic_key_extended

my_kb_irq_handler_right_extended:
                test    autorun,1
                jz      my_kb_irq_handler_generic_key_extended
                and     autorun,NBIT_2
                jmp     my_kb_irq_handler_generic_key_extended

my_kb_irq_handler_left_released_extended:
                test    autorun,1
                jz      my_kb_irq_handler_generic_key_extended
                or      autorun,BIT_1
                jmp     my_kb_irq_handler_generic_key_extended

my_kb_irq_handler_right_released_extended:
                test    autorun,1
                jz      my_kb_irq_handler_generic_key_extended
                or      autorun,BIT_2
                jmp     my_kb_irq_handler_generic_key_extended

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

; bcdtobin -----------------------------------------------------------
; convert a byte in bl from BCD to binary

bcdtobin:
                push    ecx
                movzx   ecx,bl
                and     ecx,0F0h
                shr     ecx,3
                lea     ecx,[ecx*4+ecx]
                and     bl,0Fh
                add     bl,cl
                pop     ecx
                ret

; adjust_clock -------------------------------------------------------
; adjust the system clock based on the bios clock

adjust_clock:
                ; call the bios real time clock handler
                mov     v86r_ah,2
                mov     al,01Ah
                int     33h

                ; adjust the rtc info to clock ticks

                ; seconds
                movzx   ebx,v86r_dh
                call    bcdtobin
                mov     eax,4659        ; 18.2 * 256
                mul     ebx
                mov     esi,eax

                ; minutes
                movzx   ebx,v86r_cl
                call    bcdtobin
                mov     eax,279552      ; 18.2*60 * 256
                mul     ebx
                add     esi,eax

                ; hours
                movzx   ebx,v86r_ch
                call    bcdtobin
                mov     eax,16773120    ; 18.2*3600 * 256
                mul     ebx
                add     esi,eax

                shr     esi,8
                mov     eax,esi
                
                ; set the system time
                mov     v86r_dx,ax
                shr     eax,16
                mov     v86r_cx,ax
                mov     v86r_ah,1
                mov     al,01Ah
                int     33h
                
                ret

; set_palette_color ---------------------------------------------------
; set one MSX2 palette color
; enter eax = palette slot
;       ecx = palette value

set_palette_color:
                push    eax edx ecx
                mov     dx,03C8h
                out     dx,al
                inc     dx
                and     eax,0Fh
                ;lea     ecx,[offset msx2palette+eax*2]
                
                ; R
                mov     al,cl ;[ecx]
                shr     al,4
                and     al,7
                mov     ah,al
                shl     al,3
                or      al,ah
                out     dx,al

                ; G
                mov     al,ch ;[ecx+1]
                and     al,7
                mov     ah,al
                shl     al,3
                or      al,ah
                out     dx,al

                ; B
                mov     al,cl ;[ecx]
                and     al,7
                mov     ah,al
                shl     al,3
                or      al,ah
                out     dx,al
                
                pop     ecx edx eax
                ret

; --------------------------------------------------------------------

code32          ends
                end
