; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: GUI.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include z80.inc
include io.inc
include bit.inc
include number.inc
include vdp.inc
include psg.inc
include blit.inc
include mouse.inc
include debug.inc
include saveload.inc

extrn blitbuffer: dword
extrn filenamelist: dword
extrn read_rom: near
extrn cart1: dword
extrn staticbuffer: dword
extrn gamegear: dword
extrn redbuffer: dword

public rendercounter
public spritecounter
public blitcounter
public guicounter
public psgcounter

public renderrate
public spriterate
public blitrate
public guirate
public psgrate

public psggraph

public draw_gui
public start_gui
public dirty_bargraph

; DATA ---------------------------------------------------------------

align 4

include alf.inc
include logo.inc
include cursor.inc
include scroll.inc

align 4

rendercounter   db      8 dup (0)
spritecounter   db      8 dup (0)
blitcounter     db      8 dup (0)
guicounter      db      8 dup (0)
psgcounter      db      8 dup (0)

z80acc          db      8 dup (0)
renderacc       db      8 dup (0)
spriteacc       db      8 dup (0)
blitacc         db      8 dup (0)
guiacc          db      8 dup (0)
psgacc          db      8 dup (0)

renderrate      dd      0
spriterate      dd      0
blitrate        dd      0
guirate         dd      0
psgrate         dd      0

z80number       dd      0
rendernumber    dd      0
spritenumber    dd      0
blitnumber      dd      0
guinumber       dd      0
psgnumber       dd      0

framenumber     dd      0
lastmouse       dd      0
psggraph        dd      0
overflow        dd      0

; vars for main menu

menu_selected   dd      0
menu_last       dd      0
menu_number     dd      8
menu_locked     dd      0
menu_child      dd      0

menu_callback:
                dd      offset unpause_cpu
                dd      offset reset_cpu_now
                dd      offset load_rom
                dd      offset changebargraph
                dd      offset change_psggraph
                dd      offset change_sound
                dd      offset save_sta
                dd      offset load_sta
                dd      offset quit_emulator

menu_msg:
                dd      offset msg_reset
                dd      offset msg_load_cart
                dd      offset msg_bargraph
                dd      offset msg_psggraph
                dd      offset msg_sound
                dd      offset msg_save_sta
                dd      offset msg_load_sta
                dd      offset msg_quit

msg_reset       db      'Reset',0
msg_load_cart   db      'Load ROM',0
msg_bargraph    db      'CPU Graph',0
msg_psggraph    db      'PSG Graph',0
msg_sound       db      'Sound',0
msg_save_sta    db      'Save State',0
msg_load_sta    db      'Load State',0
msg_quit        db      'Quit',0

; vars for load rom menu

align 4

load_rom_selected       dd      0
load_rom_last           dd      0
load_rom_scroll         dd      0
firstrom                dd      0        
totalrom                dd      0
name_buffer             db      16 dup (0)
rom_mask                db      '*.ROM',0
rom_extension           db      '.ROM',0

; psg color bars

psgcolor:
                db      12,12,12,12,03,03,03,03
                db      10,10,11,11,09,09,08,08

; CODE ---------------------------------------------------------------

; draw_gui -----------------------------------------------------------
; draw the gui in blitbuffer

draw_gui:
                ;call    draw_wave_graph
                
                cmp     bargraphmode,0
                je      draw_gui_psg
                call    draw_bar_graph
draw_gui_psg:
                cmp     psggraph,0
                je      _ret
                call    draw_psggraph

                ret

; --------------------------------------------------------------------
                
draw_wave_graph:
                mov     esi,dmastart
                mov     ecx,252
                mov     edx,0
draw_wave_graph_loop:
                movzx   eax,byte ptr [esi]
                movzx   ebx,byte ptr [esi+1]
                add     eax,ebx
                movzx   ebx,byte ptr [esi+2]
                add     eax,ebx
                movzx   ebx,byte ptr [esi+3]
                add     eax,ebx
                shr     eax,2
                shr     eax,1
                shl     eax,8
                add     eax,edx
                add     eax,blitbuffer
                add     eax,256*100
                mov     byte ptr [eax],013
                add     esi,3
                inc     edx
                dec     ecx
                jnz     draw_wave_graph_loop
                ret

; --------------------------------------------------------------------
                
draw_bar_graph:

                ; draw the bar graph

                mov     edi,0
                mov     ebp,z80number
                mov     eax,z80rate
                call    drawline
                mov     edi,8
                mov     ebp,rendernumber
                mov     eax,renderrate
                call    drawline
                mov     edi,16
                mov     ebp,spritenumber
                mov     eax,spriterate
                call    drawline
                mov     edi,24
                mov     ebp,blitnumber
                mov     eax,blitrate
                call    drawline
                mov     edi,32
                mov     ebp,guinumber
                mov     eax,guirate
                call    drawline
                mov     edi,40
                mov     ebp,psgnumber
                mov     eax,psgrate
                call    drawline
                mov     edi,48
                mov     ebp,fps_counter
                lea     ebp,[ebp+ebp*4]
                shl     ebp,1
                mov     eax,100
                call    drawline
                
; --------------------------------------------------------------------
                
                ; update the counters

                mov     eax,z80rate
                mov     ebx,offset z80acc
                mov     ecx,offset z80number
                call    evalcounter

                mov     eax,renderrate
                mov     ebx,offset renderacc
                mov     ecx,offset rendernumber
                call    evalcounter

                mov     eax,spriterate
                mov     ebx,offset spriteacc
                mov     ecx,offset spritenumber
                call    evalcounter

                mov     eax,blitrate
                mov     ebx,offset blitacc
                mov     ecx,offset blitnumber
                call    evalcounter

                mov     eax,guirate
                mov     ebx,offset guiacc
                mov     ecx,offset guinumber
                call    evalcounter

                mov     eax,psgrate
                mov     ebx,offset psgacc
                mov     ecx,offset psgnumber
                call    evalcounter

                inc     framenumber
                cmp     framenumber,10
                jne     draw_update0
                mov     framenumber,0
draw_update0:

                call    dirty_bargraph
                call    copy_cpugraph

                ret

; --------------------------------------------------------------------


dirty_bargraph:
                cmp     bargraphmode,0
                je      _ret

                ; update the dirty table

                mov     ebp,001010101h
                mov     ebx,001010101h
                mov     eax,0
                mov     edi,offset dirtyname
                mov     ecx,7*8+1
                movzx   edx,byte ptr [offset vdpregs+9]
                mov     esi,offset xscrollbuf

dirty_bargraph_loop:
                cmp     edx,28*8
                jb      dirty_bargraph_start
                sub     edx,28*8
dirty_bargraph_start:
                push    edi edx 
                mov     al,[esi]
                xor     al,255
                shr     al,3
                and     edx,11111000b
                cmp     al,32-8
                jae     dirty_bargraph_slow
                add     edi,eax
                mov     [edi+edx*4],ebp
                mov     [edi+edx*4+4],ebp
dirty_bargraph_continue:
                pop     edx edi
                inc     edx
                inc     esi
                dec     ecx
                jnz     dirty_bargraph_loop

                ret

dirty_bargraph_slow:
                push    ecx
                mov     ecx,8
                lea     edi,[edi+edx*4]
dirty_bargraph_slow_loop:
                mov     [edi+eax],bl
                inc     eax
                and     eax,31
                dec     ecx
                jnz     dirty_bargraph_slow_loop
                pop     ecx
                jmp     dirty_bargraph_continue

; draw_psggraph ------------------------------------------------------
; draw bar graph for PSG-VU meter

draw_psggraph:

                irp     i,<0,1,2>
                
                movzx   eax,byte ptr [offset psgreg+8+i]
                and     eax,0Fh
                mov     edi,30*8+i*4
                call    draw_psggraph_channel

                endm

                call    copy_psggraph

                ret

draw_psggraph_channel:
                add     edi,staticbuffer
                add     edi,256
                mov     ecx,15

draw_psggraph_channel_loop:
                cmp     ecx,eax
                ja      draw_psggraph_channel_black

                mov     bl,[offset psgcolor+ecx]
                add     bl,32
draw_psggraph_channel_cont:
                mov     [edi+1],bl
                mov     [edi+2],bl
                mov     [edi+3],bl
                cmp     ecx,1
                je      draw_psggraph_channel_next
                mov     byte ptr [edi+1+256],21h
                mov     word ptr [edi+2+256],2121h

draw_psggraph_channel_next:
                add     edi,512
                dec     ecx
                jnz     draw_psggraph_channel_loop

                ret

draw_psggraph_channel_black:
                mov     bl,32
                jmp     draw_psggraph_channel_cont

; drawline -----------------------------------------------------------
; draw a single bar in blitbuffer

drawline:
                mov     ebx,100
                mul     ebx                
                xor     edx,edx
                mov     ebx,dword ptr [offset clockrate]
                div     ebx
                mov     ecx,50
                mov     esi,eax
                shr     esi,1
                shl     edi,8
                add     edi,staticbuffer
                add     edi,256+1
                mov     ebx,0F0Dh
drawline1:      
                cmp     ecx,esi
                jbe     drawline2
                irp     i,<0,1,2,3,4,5,6>
                mov     byte ptr [edi+256*i],bh
                endm
                jmp     drawline_loop
drawline2:
                irp     i,<0,1,2,3,4,5,6>
                mov     byte ptr [edi+256*i],bl
                endm
drawline_loop:
                inc     edi
                dec     ecx
                jnz     drawline1

                mov     eax,ebp
                sub     edi,33
                mov     ebx,100
                xor     edx,edx
                div     ebx

                mov     overflow,0
                cmp     eax,9
                jb      drawline_go
                mov     eax,9
                mov     overflow,1

drawline_go:

                mov     esi,eax
                shl     esi,6
                add     esi,offset number_font
                irp     i,<0,1,2,3,4>
                mov     ebx,[esi+i*8]
                mov     ecx,[esi+i*8+4]
                and     [edi+(i+1)*256],ebx
                and     [edi+(i+1)*256+4],ecx
                xor     ebx,0FFFFFFFFh
                xor     ecx,0FFFFFFFFh
                and     ebx,004040404h
                and     ecx,004040404h
                or      [edi+(i+1)*256],ebx
                or      [edi+(i+1)*256+4],ecx
                endm
                
                mov     eax,edx
                mov     ebx,10
                xor     edx,edx
                div     ebx

                cmp     overflow,1
                jne     drawline_go2
                mov     eax,9

drawline_go2:

                mov     esi,eax
                shl     esi,6
                add     esi,offset number_font
                irp     i,<0,1,2,3,4>
                mov     ebx,[esi+i*8]
                mov     ecx,[esi+i*8+4]
                and     [edi+(i+1)*256+5],ebx
                and     [edi+(i+1)*256+4+5],ecx
                xor     ebx,0FFFFFFFFh
                xor     ecx,0FFFFFFFFh
                and     ebx,004040404h
                and     ecx,004040404h
                or      [edi+(i+1)*256+5],ebx
                or      [edi+(i+1)*256+4+5],ecx
                endm
                
                mov     byte ptr [edi+5*256+10],04h

                cmp     overflow,1
                jne     drawline_go3
                mov     edx,9

drawline_go3:
                mov     esi,edx
                shl     esi,6
                add     esi,offset number_font
                irp     i,<0,1,2,3,4>
                mov     ebx,[esi+i*8]
                mov     ecx,[esi+i*8+4]
                and     [edi+(i+1)*256+12],ebx
                and     [edi+(i+1)*256+4+12],ecx
                xor     ebx,0FFFFFFFFh
                xor     ecx,0FFFFFFFFh
                and     ebx,004040404h
                and     ecx,004040404h
                or      [edi+(i+1)*256+12],ebx
                or      [edi+(i+1)*256+4+12],ecx
                endm
                
                ret

; evalcounter --------------------------------------------------------
; update a counter

evalcounter:
                add     dword ptr [ebx],eax
                adc     dword ptr [ebx+4],0
                cmp     framenumber,0
                jnz     _ret

                mov     eax,dword ptr [ebx]
                mov     edi,100
                mul     edi
                mov     esi,edx
                mov     dword ptr [ebx],eax
                mov     eax,dword ptr [ebx+4]
                mul     edi
                add     eax,esi
                mov     dword ptr [ebx+4],eax

                mov     eax,dword ptr [ebx]
                mov     edx,dword ptr [ebx+4]
                mov     edi,dword ptr [offset clockrate]
                div     edi
                mov     dword ptr [ecx],eax

                mov     dword ptr [ebx],0
                mov     dword ptr [ebx+4],0

                ret

; copy_cpugraph ------------------------------------------------------
; copy cpu graph from static buffer to blit buffer
; compensing the scroll

copy_cpugraph:
                cmp     gamegear,1
                je      _ret

                cmp     direct_color,1
                je      copy_cpugraph_direct

                cmp     linebyline,1
                je      copy_cpugraph_linebyline

                mov     esi,staticbuffer
                movzx   ebx,byte ptr [offset vdpregs+9]
                mov     edx,offset xscrollbuf
                cmp     ebx,28*8
                jb      copy_cpugraph_start
                sub     ebx,28*8
copy_cpugraph_start:
                shl     ebx,8
                mov     edi,blitbuffer
                mov     eax,7*8+1
copy_cpugraph_loop:
                mov     ecx,13
                push    edi edx
                movzx   edx,byte ptr [edx]
                add     edi,ebx
                ;;;
                cmp     edx,13*4
                jb      copy_cpugraph_skip
                add     edi,256
                sub     edi,edx
                rep     movsd
                jmp     copy_cpugraph_cont
copy_cpugraph_skip:
                push    ecx
                mov     ecx,edx
                add     edi,256
                sub     edi,edx
                rep     movsb
                pop     ecx
                shl     ecx,2
                sub     ecx,edx
                sub     edi,256
                rep     movsb
copy_cpugraph_cont:
                ;;;
                pop     edx edi
                inc     edx
                add     esi,256-13*4
                add     ebx,256        
                cmp     ebx,28*8*256
                jb      copy_cpugraph_fine
                sub     ebx,28*8*256
copy_cpugraph_fine:
                dec     eax
                jnz     copy_cpugraph_loop
                ret

copy_cpugraph_linebyline:
                mov     ebx,7*8+1
                mov     esi,staticbuffer
                mov     edi,blitbuffer

copy_cpugraph_linebyline_loop:
                mov     ecx,13
                rep     movsd
                add     edi,256-13*4
                add     esi,256-13*4
                dec     ebx
                jnz     copy_cpugraph_linebyline_loop

                ret

copy_cpugraph_direct:
                mov     ebx,7*8+1
                mov     esi,staticbuffer
                mov     edi,redbuffer

copy_cpugraph_direct_loop:
                mov     ecx,13*4

copy_cpugraph_direct_inner:
                movzx   eax,byte ptr [esi]
                inc     esi
                ;imul    eax,000010000100001b
                movzx   eax,word ptr [offset sg1000_high_palette+eax*2]
                mov     word ptr [edi],ax
                add     edi,2
                dec     ecx
                jnz     copy_cpugraph_direct_inner

                add     edi,(256-13*4)*2
                add     esi,256-13*4
                dec     ebx
                jnz     copy_cpugraph_direct_loop

                ret


; copy_psggraph ------------------------------------------------------
; copy psg graph from static buffer to blit buffer
; compensing the scroll

copy_psggraph:
                mov     esi,staticbuffer
                movzx   ebx,byte ptr [offset vdpregs+9]
                mov     edx,offset xscrollbuf
                cmp     ebx,28*8
                jb      copy_psggraph_start
                sub     ebx,28*8
copy_psggraph_start:
                test    byte ptr [offset vdpregs+0],BIT_7
                jz      copy_psggraph_golvellius
                mov     ebx,0
copy_psggraph_golvellius:
                shl     ebx,8
                mov     edi,blitbuffer
                add     esi,30*8
                mov     eax,16*2-1
copy_psggraph_loop:
                mov     ecx,3*4+1
                push    edi edx
                add     edi,ebx
                movzx   edx,byte ptr [edx]
                ;;;
                mov     ebp,30*8
                cmp     ebp,edx
                ja      copy_psggraph_above
                add     ebp,ecx
                cmp     ebp,edx
                ja      copy_psggraph_split
                mov     ebp,30*8
                add     ebp,256
                sub     ebp,edx
                add     edi,ebp
                rep     movsb
                jmp     copy_psggraph_next
copy_psggraph_above:
                mov     ebp,30*8
                sub     ebp,edx
                add     edi,ebp
                rep     movsb
                jmp     copy_psggraph_next
copy_psggraph_split:
                mov     ebp,30*8
                mov     ecx,edx
                sub     ecx,ebp
                add     ebp,256
                sub     ebp,edx
                xchg    edi,ebp
                add     edi,ebp
                rep     movsb
                mov     edi,ebp
                mov     ecx,3*4+1
                sub     ecx,edx
                add     ecx,30*8
                rep     movsb
copy_psggraph_next:
                ;;;
                pop     edx edi
                inc     edx
                add     esi,256-3*4-1
                add     ebx,256        
                cmp     ebx,28*8*256
                jb      copy_psggraph_fine
                sub     ebx,28*8*256
copy_psggraph_fine:
                dec     eax
                jnz     copy_psggraph_loop
                ret

; start_gui ----------------------------------------------------------
; start the gui

start_gui:
                
                call    release_button
                
                call    clear
                mov     menu_locked,0
                
                ; update palette
                mov     ebx,offset gui_palette
                mov     ecx,256
                call    fill_palette
                mov     firstscreen,1

start_gui_loop:
                cmp     enabled,0
                jne     start_gui_pipeline
                mov     enabled,1
                mov     eax,01010101h
                mov     ecx,32*24/4
                mov     edi,offset dirtyname
                rep     stosd
start_gui_pipeline:
                call    dirty_mouse
                cli     
                call    render
                sti
                call    sprite_render
                call    draw_logo
                call    read_mouse
                call    draw_main_menu
                call    dirty_mouse
                call    draw_mouse_cursor
                call    wait_vsync
                ;call    set_border_color_dark
                call    blit
                call    action
                cmp     cpupaused,1
                je      start_gui_loop
                
                call    clear
                mov     eax,01010101h
                mov     ecx,32*24/4
                mov     edi,offset dirtyname
                rep     stosd
                mov     firstscreen,1
                mov     enabled,1

                ;call    set_correct_palette

                ret

; action -------------------------------------------------------------
; perform an action if the mouse button has been pressed

action:
                mov     eax,mouseleft
                xor     eax,lastmouse
                and     eax,mouseleft
                jz      action_end

                mov     eax,menu_selected
                call    dword ptr [offset menu_callback+eax*4]

action_end:
                mov     eax,mouseleft
                mov     lastmouse,eax
                ret

; draw_logo ----------------------------------------------------------
; draw the brmsx logo

draw_logo:
                mov     edi,135*256
                add     edi,blitbuffer
                mov     esi,offset logo_bitmap
                mov     ecx,57

draw_gui_drawlogo:
                mov     ebx,89

draw_gui_drawlogo_loop:
                mov     al,[esi]
                or      al,al
                jz      draw_gui_drawlogo_next

                mov     [edi],al

draw_gui_drawlogo_next:
                inc     edi
                inc     esi
                dec     ebx
                jnz     draw_gui_drawlogo_loop

                add     edi,256-89
                dec     ecx
                jnz     draw_gui_drawlogo

                ret

; draw_mouse_cursor --------------------------------------------------
; draw the mouse cursor

draw_mouse_cursor:
                
                mov     edi,mousey
                shl     edi,8
                add     edi,mousex
                add     edi,blitbuffer
                mov     esi,offset cursor_bitmap
                mov     ecx,17

draw_cursor:
                mov     ebx,51

draw_cursor_loop:
                mov     al,[esi]
                or      al,al
                jz      draw_cursor_next

                mov     [edi],al

draw_cursor_next:
                inc     edi
                inc     esi
                dec     ebx
                jnz     draw_cursor_loop

                add     edi,256-51
                dec     ecx
                jnz     draw_cursor

                ret

; dirty_mouse --------------------------------------------------------
; turn the screen behind the cursor dirty

dirty_mouse:
                mov     eax,mousey
                shr     eax,3
                shl     eax,5
                mov     ebx,mousex
                shr     ebx,3
                add     eax,ebx
                add     eax,offset dirtyname
                mov     dword ptr [eax],01010101h
                mov     dword ptr [eax+4],01010101h
                mov     dword ptr [eax+32],01010101h
                mov     dword ptr [eax+4+32],01010101h
                mov     dword ptr [eax+64],01010101h
                mov     dword ptr [eax+4+64],01010101h
                ret

; draw_main_menu -----------------------------------------------------
; draw the main menu

draw_main_menu:
                mov     eax,0808h
                mov     ebx,784Ah
                call    draw_box

                call    check_selection

                mov     ebp,menu_number
                mov     edi,offset menu_msg
                mov     ebx,1010h

draw_main_menu_loop:
                mov     eax,[edi]
                call    printgr_shaded
                add     ebx,0800h
                add     edi,4
                dec     ebp
                jnz     draw_main_menu_loop

                call    draw_menu_child

                ret

; draw_box -----------------------------------------------------------
; draw a box window
; enter ah=y coord al=x coord   
;       bh=y size  bl=x size

draw_box:
                movzx   edi,ax
                add     edi,blitbuffer
                mov     esi,edi
                movzx   edx,bh
                movzx   ecx,bl

draw_box_loop:
                mov     al,0F0h
                rep     stosb
                movzx   ecx,bl
                add     edi,256
                sub     edi,ecx
                dec     edx
                jnz     draw_box_loop

                ; draw the orange lines
                lea     edi,[esi+1+256]
                movzx   ecx,bl
                mov     esi,ecx
                sub     ecx,2
                mov     al,0E4h
                rep     stosb
                
                add     edi,256
                sub     edi,esi
                movzx   edx,bh
                sub     edx,4
                movzx   ecx,bl
                sub     ecx,2

draw_box_line_loop:
                mov     byte ptr [edi+2],al
                mov     byte ptr [edi+ecx+1],al
                add     edi,256
                dec     edx
                jnz     draw_box_line_loop

                add     edi,2
                rep     stosb
                
                ret

; printgr_shaded -----------------------------------------------------
; print a string the blit buffer, using shaded colors
; enter: eax -> offset of the message (ASCIIZ)
;        bh = y coord , bl = x coord

printgr_shaded:
                push    ebp edx ebx edi

                sub     ebx,0101h

                mov     esi,0D3D3D3D3h
                push    eax
                call    printgr
                pop     eax

                add     ebx,0101h
                
                mov     esi,0FAFAFAFAh
                push    eax
                call    printgr
                pop     eax
                
                pop     edi ebx edx ebp                
                ret

; printgr ------------------------------------------------------------
; print a string the blit buffer
; enter: eax -> offset of the message (ASCIIZ)
;        bh = y coord , bl = x coord
;       esi = color (replicated four times)

printgr:
                movzx   edi,bx
                add     edi,blitbuffer

printgr_loop:

                movzx   edx,byte ptr [eax]
                or      edx,edx
                jz      _ret

                shl     edx,6
                add     edx,offset alf_pattern

                irp     i,<0,1,2,3,4,5,6,7>

                mov     ecx,[edx+i*8]
                mov     ebp,ecx
                xor     ecx,0FFFFFFFFh
                and     [edi+i*256],ecx
                and     ebp,esi
                or      [edi+i*256],ebp

                mov     ecx,[edx+i*8+4]
                mov     ebp,ecx
                xor     ecx,0FFFFFFFFh
                and     [edi+i*256+4],ecx
                and     ebp,esi
                or      [edi+i*256+4],ebp

                endm

                inc     eax
                add     edi,6
                jmp     printgr_loop

; check_selection ----------------------------------------------------
; check if the mouse is over an item that can be selected
; light that item if affirmative

check_selection:

                cmp     menu_locked,1
                je      check_selection_locked

                ; check Y boundaries
                mov     eax,mousey
                add     eax,3
                sub     eax,16
                js      check_selection_none
                mov     ebx,menu_number
                shl     ebx,3
                cmp     eax,ebx
                jae     check_selection_none

                ; check X boundaries
                mov     ecx,mousex
                sub     ecx,12
                js      check_selection_none
                cmp     ecx,04Ah-8
                ja      check_selection_none

                mov     ebx,eax                
                shr     ebx,3
                inc     ebx
                mov     menu_selected,ebx

check_selection_drawbar:

                and     eax,0FFFFFFF8h
                add     eax,15

                mov     edi,eax
                shl     edi,8
                add     edi,10
                add     edi,blitbuffer

                mov     edx,9
                mov     eax,0D2D2D2D2h

check_selection_draw:
                mov     ecx,(04Ah-4)
                rep     stosb

                add     edi,256-(04Ah-4)
                dec     edx
                jnz     check_selection_draw

                jmp     check_selection_update

check_selection_none:
                mov     menu_selected,0

check_selection_update:
                mov     eax,menu_selected
                cmp     eax,menu_last
                je      _ret
                
                mov     menu_last,eax
                mov     firstscreen,1
                ret

check_selection_locked:
                mov     eax,menu_selected
                dec     eax
                shl     eax,3
                jmp     check_selection_drawbar

; load_rom -----------------------------------------------------------
; prepare the gui to open the "load rom" window

load_rom:
                cmp     menu_locked,1
                je      load_rom_now
                mov     menu_locked,1
                mov     eax,offset draw_load_rom
                mov     menu_child,eax
                mov     firstscreen,1
                mov     firstrom,0
                ret

load_rom_now:
                cmp     load_rom_selected,0
                je      load_rom_perform_scroll
                
                ; clear name buffer
                mov     ecx,16/4
                mov     edi,offset name_buffer
                mov     eax,0
                rep     stosd
                
                ; copy the name of the rom
                mov     eax,load_rom_selected
                add     eax,firstrom
                dec     eax
                shl     eax,3
                add     eax,filenamelist
                mov     ebx,[eax]
                mov     dword ptr [offset name_buffer],ebx
                mov     ebx,[eax+4]
                mov     dword ptr [offset name_buffer+4],ebx
                
                ; search the first zero of the name
                mov     al,0
                mov     edi,offset name_buffer
                mov     ecx,16
                repnz   scasb
                
                ; append ".ROM" to the name
                dec     edi
                mov     esi,offset rom_extension
                mov     ecx,1
                rep     movsd
                
                ; perform the load
                mov     edx,offset name_buffer
                mov     eax,cart1
                mov     ebp,offset slot1
                call    read_rom
                jnc     reset_cpu_now
                ret

load_rom_perform_scroll:
                cmp     load_rom_scroll,0
                je      load_rom_unlock

                cmp     load_rom_scroll,1
                jne     load_rom_perform_scroll_down

                cmp     totalrom,15
                jbe     _ret
                
                mov     eax,firstrom
                add     eax,15
                cmp     eax,totalrom
                je      _ret

                inc     firstrom
                mov     firstscreen,1
                ret

load_rom_perform_scroll_down:
                cmp     firstrom,0
                je      _ret
                dec     firstrom
                mov     firstscreen,1
                ret

load_rom_unlock:
                mov     menu_locked,0
                call    clear
                mov     firstscreen,1
                ret

; draw_menu_child ----------------------------------------------------
; draw the child menu if the parent is locked

draw_menu_child:
                cmp     menu_locked,1
                jne     _ret

                mov     eax,menu_child
                call    eax

                ret

; draw_load_rom ------------------------------------------------------
; draw the "load rom" window

draw_load_rom:
                mov     eax,0878h
                mov     ebx,0A34Ah
                call    draw_box

                call    draw_scroll_bar

                call    search_directory

                call    draw_load_rom_mouse

                mov     edx,0
                mov     ebp,firstrom
                mov     ebx,01080h

draw_load_rom_loop:

                ; fill the name buffer with 0s
                mov     edi,offset name_buffer
                mov     ecx,16/4
                mov     eax,0
                rep     stosd

                ; copy the name of file to name buffer
                mov     ecx,8
                mov     edi,offset name_buffer
                mov     esi,filenamelist
                lea     esi,[esi+ebp*8]
                rep     movsb

                ; print the name of file
                mov     eax,offset name_buffer
                call    printgr_shaded

                add     ebx,0A00h
                inc     ebp
                inc     edx
                cmp     edx,totalrom
                je      _ret
                cmp     edx,15
                jne     draw_load_rom_loop

                ret

draw_load_rom_mouse:
                ; check X boundaries
                cmp     mousex,078h
                jb      draw_load_rom_ret
                cmp     mousex,078h+038h
                ja      draw_load_rom_scroll

                ; check Y boundaries
                mov     eax,mousey
                add     eax,3
                sub     eax,10h
                jc      draw_load_rom_ret
                cmp     eax,093h
                ja      draw_load_rom_ret

                mov     edx,0
                mov     ebx,10
                div     ebx
                mov     load_rom_selected,eax

                cmp     eax,totalrom
                jae     draw_load_rom_none

                mov     ecx,040h/4-1
                lea     edi,[eax+eax*4]
                lea     edi,[edi*2+0eh]
                shl     edi,8
                add     edi,blitbuffer
                add     edi,078h+2
                mov     eax,0D2D2D2D2h
                mov     edx,10

draw_load_rom_mouse_loop:
                rep     stosd
                add     edi,256-040h+4
                mov     ecx,040h/4-1
                dec     edx
                jnz     draw_load_rom_mouse_loop

                mov     eax,load_rom_selected
                inc     eax
                mov     load_rom_selected,eax

draw_load_rom_update:
                cmp     eax,load_rom_last
                je      _ret

                mov     load_rom_last,eax
                mov     firstscreen,1

                ret

draw_load_rom_none:
                mov     eax,0
                mov     load_rom_selected,eax
                jmp     draw_load_rom_update

draw_load_rom_scroll:
                mov     eax,mousex
                sub     eax,078h+048h-08h-2
                jc      draw_load_rom_ret
                cmp     eax,08h
                ja      draw_load_rom_ret

                mov     eax,mousey
                sub     eax,0Eh
                jc      draw_load_rom_ret
                cmp     eax,08h
                ja      draw_load_rom_scroll_down

                mov     load_rom_scroll,2
                ret

draw_load_rom_scroll_down:
                mov     eax,mousey
                sub     eax,0Eh+096h-08h
                jc      draw_load_rom_ret
                cmp     eax,08h
                ja      draw_load_rom_ret

                mov     load_rom_scroll,1
                ret

draw_load_rom_ret:
                mov     load_rom_selected,0
                mov     load_rom_scroll,0
                mov     eax,0
                jmp     draw_load_rom_update

; draw_scroll_bar ----------------------------------------------------
; draw the scroll bar of load_rom menu

draw_scroll_bar:
                mov     edi,0Eh*256+(078h+048h-08h-2)
                add     edi,blitbuffer
                mov     eax,0D1D1D1D1h
                mov     ecx,096h

draw_scroll_bar_loop:
                mov     [edi],eax
                mov     [edi+4],eax
                add     edi,256
                dec     ecx
                jnz     draw_scroll_bar_loop

                mov     ecx,8
                mov     esi,offset scroll_up_icon
                mov     edi,0Eh*256+(078h+048h-08h-2)
                add     edi,blitbuffer

draw_scroll_bar_up_loop:
                mov     eax,[esi]
                mov     ebx,[esi+4]
                mov     [edi],eax
                mov     [edi+4],ebx
                add     esi,8
                add     edi,256
                dec     ecx
                jnz     draw_scroll_bar_up_loop

                mov     ecx,8
                mov     esi,offset scroll_up_icon+7*8
                mov     edi,0Eh*256+(078h+048h-08h-2)+(096h-08h)*256
                add     edi,blitbuffer

draw_scroll_bar_down_loop:
                mov     eax,[esi]
                mov     ebx,[esi+4]
                mov     [edi],eax
                mov     [edi+4],ebx
                sub     esi,8
                add     edi,256
                dec     ecx
                jnz     draw_scroll_bar_down_loop

                ret

; unpause_cpu --------------------------------------------------------
; called when the user clicks outside of the menu,
; turns off the gui and restart emulation

unpause_cpu:
                mov     cpupaused,0
                jmp     release_button

; release_button -----------------------------------------------------
; wait until the user release the mouse button

release_button:
                call    read_mouse
                cmp     mouseleft,0
                je      _ret

                jmp     release_button

; search_directory ---------------------------------------------------
; search the directory for ROM files
; and put their names in the filenamelist buffer

search_directory:
                
                mov     ebx,0
                mov     ebp,filenamelist
                mov     edi,offset rom_mask
                mov     edx,offset name_buffer
                call    find_first

search_directory_next:
                
                jc      search_directory_ret

                mov     ecx,8/4
                lea     edi,[ebp+ebx*8]
                mov     eax,0
                rep     stosd

                mov     ecx,8
                lea     edi,[ebp+ebx*8]
                mov     esi,offset name_buffer

search_directory_loop:
                mov     al,[esi]
                cmp     al,'.'
                je      search_directory_point
                movsb
                dec     ecx
                jnz     search_directory_loop
                jmp     search_directory_no_point

search_directory_point:
                mov     byte ptr [edi],0

search_directory_no_point:
                inc     ebx
                mov     edi,offset rom_mask
                mov     edx,offset name_buffer
                call    find_next

                jmp     search_directory_next

search_directory_ret:
                mov     totalrom,ebx
                ret

; reset_cpu_now ------------------------------------------------------
; reset the msx and disable gui

reset_cpu_now:
                call    release_button
                call    reset_cpu
                mov     cpupaused,0
                ret

; change_psggraph ----------------------------------------------------
; turns on/off the psg bar graph

change_psggraph:
                xor     psggraph,1
                ret

; quit_emulator ------------------------------------------------------
; quit the emulator and exit to dos

quit_emulator:
                call    release_button
                mov     quitnow,1
                mov     exit_now,1
                mov     cpupaused,0
                ret

; save_sta -----------------------------------------------------------
; save the current state in a file called BRMSX.STA     

save_sta:
                call    release_button
                mov     reset_flag,1
                mov     cpupaused,0
                jmp     save_state

; load_sta -----------------------------------------------------------
; load the current state from a file called BRMSX.STA     

load_sta:
                call    release_button
                mov     reset_flag,1
                mov     cpupaused,0
                jmp     load_state

; --------------------------------------------------------------------

code32          ends
                end


