; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: VDP.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include pentium.inc
include bit.inc
include io.inc
include z80.inc
include v9938.inc

extrn msxvram: dword
extrn vdpregs: near
extrn blitbuffer: dword
extrn collisionfield: dword

public render_screen0
public render_screen1
public render_screen2
public render
public clear
public lastscreen
public actualscreen
public sprite_render
public imagetype
public nametable
public patterntable
public colortable
public sprattrtable
public sprpatttable
public eval_sprite_coords
public dirty_sprite
public firstscreen
public eval_base_address
public vrammapping
public screenselect 
public dirtyname
public dirtypattern
public enabled
public enginetype
public everyframe
public all_sprites
public no_collision
public render_col
public sprite_collision
public direct_color
public eval_base_address_msx2
public text_columns
public spriteenable
public foregroundmask
public backgroundmask
public backgroundcolor

; DATA ---------------------------------------------------------------

align 4

include screen0.inc
include scr2fore.inc
include scr2back.inc
include scr2frcl.inc
include scr2bkcl.inc
include scr2frmx.inc
include scr2bkmx.inc
include scr2frzm.inc
include scr2bkzm.inc
include scr2und.inc
include sprzoom.inc

align 4

DOS_ENGINE      EQU     0
WIN_ENGINE      EQU     1
MMX_ENGINE      EQU     2

BITMASK_YES     EQU     0
BITMASK_NO      EQU     1

enabled         dd      1
linenumber      dd      0
stacksave       dd      0
colorsave       dd      0
patternsave     dd      0
spriteenable    dd      0
imagetype       dd      1
nametable       dd      0
colortable      dd      0
patterntable    dd      0
sprattrtable    dd      0
sprpatttable    dd      0
firstscreen     dd      1
everyframe      dd      0
spr_occult      dd      255
all_sprites     dd      0
no_collision    dd      0
y_factor        dd      0
x_factor        dd      0
direct_color    dd      0
text_columns    dd      40
sprite_number   dd      0

scr2inc         dd      offset scr2undoc_table+3*12
scr2inc_color   dd      offset scr2undoc_table+3*12
scr2offset      dd      0
vrammapping     db      256 dup (0)
screenselect    dd      dirty_screen0_nothing ; nothing
                dd      dirty_screen0_nothing ; name table
                dd      dirty_screen0_nothing ; pattern table
                dd      dirty_screen0_nothing ; color table
                dd      dirty_screen0_nothing ; sprite attribute table
                dd      dirty_screen0_nothing ; sprite image table
dirtyname       db      32*24 dup (0)
dirtypattern    db      256*3 dup (0)
dirtysprite     db      256 dup (0)
dirtysprattr    db      32 dup (0)
dirtysprattrold db      32 dup (0)
falsesprite     db      32*32*2 dup (0)
prioritymask    db      32 dup (0)
spritemask      db      192 dup (01Fh)
spritecounter   db      192 dup (0)
lastscreen      db      0
actualscreen    db      0
bitmask         db      0
enginetype      dd      DOS_ENGINE

; render_screen0 -----------------------------------------------------
; render a screen 0 page

render_screen0:
                cmp     text_columns,80
                je      render_screen0_80

                mov     esi,msxvram                
                add     esi,nametable
                
                mov     ebx,msxvram
                add     ebx,patterntable
                
                mov     edi,blitbuffer
                add     edi,8

                mov     ecx,0
                mov     edx,0
                
                mov     ebp,24
                ; draw a screen

render06:
                push    ebp
                mov     ebp,40
                ; draw a line

render05:
                ; draw two chars

                mov     cl,[esi]
                mov     dl,[ebx+ecx*8]
                
                irp     i,<0,1,2,3,4,5,6,7>
                
                mov     eax,[offset screen0_table1+edx*8]
                mov     [edi+i*256],eax
                mov     eax,[offset screen0_table1+edx*8+4]
                mov     dl,[ebx+ecx*8+i+1]
                mov     [edi+4+i*256],eax

                endm

                mov     cl,[esi+1]
                mov     dl,[ebx+ecx*8]
                
                irp     i,<0,1,2,3,4,5,6,7>
                
                mov     eax,[offset screen0_table2+edx*8]
                mov     [edi+6+i*256],ax
                mov     eax,[offset screen0_table2+edx*8+4]
                mov     dl,[ebx+ecx*8+i+1]
                mov     [edi+8+i*256],eax

                endm

                add     esi,2
                add     edi,12
                sub     ebp,2
                jnz     render05

                pop     ebp
                add     edi,256*7+16
                dec     ebp
                jnz     render06

                mov     spriteenable,0

                ; clear a small portion of screen
                ; to prevent the last psggraph 
                ; to be displayed forever

                mov     edi,blitbuffer
                mov     ecx,32
render0_psgbugfix:
                mov     dword ptr [edi+31*8],0
                mov     dword ptr [edi+31*8+4],0
                add     edi,256
                dec     ecx
                jnz     render0_psgbugfix

                ret

; PIPE1 --------------------------------------------------------------
; this is the inner loop for render_screen1_* functions

PIPE1           macro

                ; fetch the character
                mov     al,[esi]

                ; fetch the color for that character
                xor     edx,edx
                mov     dl,al
                shr     dl,3
                mov     dl,[ecx+edx]

                push    ecx
                push    esi
                push    eax
                push    ebx
                
                lea     ebx,[ebx+eax*8]
                mov     eax,[offset foregroundcolor+edx*4]
                mov     ecx,[offset backgroundcolor+edx*4]

                ; for each subline

                ; fetch the pattern for that subline
                mov     dl,[ebx]
                
                irp     i,<0,1,2,3,4,5,6,7>

                ; get the foreground mask
                mov     ebp,[offset foregroundmask+edx*8]

                ; get the background mask
                mov     esi,[offset backgroundmask+edx*8]

                ; blend with the foreground color
                and     ebp,eax

                ; blend with the background color
                and     esi,ecx

                ; mix the colors
                or      ebp,esi
                mov     esi,[offset backgroundmask+edx*8+4]

                ; display the subline
                mov     [edi+i*256],ebp

                ; do it again for the next four pixels
                mov     ebp,[offset foregroundmask+edx*8+4]
                and     esi,ecx
                and     ebp,eax
                or      ebp,esi
                mov     dl,[ebx+i+1]
                mov     [edi+4+i*256],ebp

                endm

                pop     ebx
                pop     eax
                pop     esi
                pop     ecx
                
                endm

; render_screen1_dirty -----------------------------------------------
; render a screen 1 page using dirty blocks

render_screen1_dirty:

                call    wash_sprite
                
                ; esi = name table
                mov     esi,nametable
                add     esi,msxvram

                ; ebx = character pattern table
                
                mov     ebx,patterntable
                add     ebx,msxvram

                ; ecx = color table
                mov     ecx,colortable
                add     ecx,msxvram

                ; edi = blit buffer
                mov     edi,blitbuffer

                ; edx = dirty table
                mov     edx,offset dirtyname

                ; mask the temporary registers
                xor     eax,eax

                ; for each line
                mov     ebp,24
render10d:      push    ebp

                ; for each char
                mov     ebp,32
render11d:      
                mov     al,[edx]
                or      al,al
                jnz     render1_dirty_draw

                movzx   eax,byte ptr [esi]
                cmp     byte ptr [offset dirtypattern+eax],1
                jne     render1_dirty_next
                mov     byte ptr [edx],1

render1_dirty_draw:
                push    ebp edx
                PIPE1
                pop     edx ebp

render1_dirty_next:

                add     edi,8
                inc     esi
                inc     edx

                dec     ebp
                jnz     render11d

                add     edi,256*7

                pop     ebp
                dec     ebp
                jnz     render10d

                mov     spriteenable,1
                ret


; render_screen1 -----------------------------------------------------
; render a screen 1 page

render_screen1:
                cmp     everyframe,1
                je      render_screen1_linear

                cmp     imagetype,1
                je      render_screen1_dirty

render_screen1_linear:
                ; esi = name table
                mov     eax,nametable
                mov     esi,msxvram
                lea     esi,[esi+eax]

                ; ebx = character pattern table
                mov     eax,patterntable
                mov     ebx,msxvram
                lea     ebx,[ebx+eax]

                ; ecx = color table
                mov     eax,colortable
                mov     ecx,msxvram
                lea     ecx,[ecx+eax]

                ; edi = blit buffer
                mov     edi,blitbuffer

                ; mask the temporary registers
                xor     edx,edx
                xor     eax,eax

                ; for each line
                mov     ebp,24
render10:       push    ebp

                ; for each char
                mov     ebp,32
render11:       push    ebp

                PIPE1

                add     edi,8
                inc     esi

                pop     ebp
                dec     ebp
                jnz     render11

                add     edi,256*7

                pop     ebp
                dec     ebp
                jnz     render10

                mov     spriteenable,1
                ret

; PIPE2_DOS ----------------------------------------------------------
; this is the inner loop for render_screen2 function

PIPE2_DOS       macro   bitmask_type
                
                mov     ecx,colorsave
                
                lea     ebx,[ebx+eax*8] 

                if      bitmask_type EQ BITMASK_YES
                and     al,bitmask
                endif

                lea     eax,[ecx+eax*8] 

                ; fetch the pattern for that subline
                mov     dl,[ebx]
                movzx   ecx,byte ptr [eax]
                
                irp     i,<0,1,2,3,4,5,6,7>

                mov     ebp,[offset foregroundmask+edx*8]
                mov     esi,[offset backgroundmask+edx*8]

                and     ebp,[offset foregroundcolor+ecx*4]
                and     esi,[offset backgroundcolor+ecx*4]

                or      ebp,esi
                mov     dl,[ebx+i]

                mov     cl,[eax+i]
                mov     [edi+i*256],ebp
                
                mov     ebp,[offset foregroundmask+edx*8+4]
                mov     esi,[offset backgroundmask+edx*8+4]
                
                and     ebp,[offset foregroundcolor+ecx*4]
                and     esi,[offset backgroundcolor+ecx*4]
                
                or      ebp,esi
                mov     dl,[ebx+(i+1)]
                
                mov     cl,[eax+(i+1)]
                mov     [edi+4+i*256],ebp

                endm
                
                mov     eax,0
                
                endm

; PIPE2_MMX ----------------------------------------------------------
; this is the inner loop for render_screen2 function
; it uses the MMX instructions for better performance

PIPE2_MMX       macro   bitmask_type

                lea     esi,[ebx+eax*8]

                if      bitmask_type EQ BITMASK_YES
                and     al,bitmask
                endif

                lea     ebp,[ecx+eax*8]
                mov     eax,0
                
                ; pattern
                mov     dl,[esi]
                ; color
                mov     al,[ebp]
                
                irp     i,<0,1,2,3,4,5,6,7>

                ; foreground and background mask
                ;;movq    MM0,[offset foregroundmask+edx*8]
                movq
                db      00000100b
                db      11010101b
                dd      offset foregroundmask

                mov     dl,[esi+i+1]
                
                ;;movq    MM1,MM0
                movq
                db      11001000b

                ; blend with the foreground color
                ;;pand    MM0,[offset foregroundcolor_MMX+eax*8]
                pand
                db      00000100b
                db      11000101b
                dd      offset foregroundcolor_MMX
                
                ; blend with the background color
                ;;pandn    MM1,[offset backgroundcolor_MMX+eax*8]
                pandn
                db      00001100b
                db      11000101b
                dd      offset backgroundcolor_MMX
                
                ;;por     MM0,MM1
                por
                db      11000001b
                
                mov     al,[ebp+i+1]
                
                ;;movq    [edi+i*256],MM0
                movq_st
                db      10000111b
                dd      i*256
                
                endm

                endm

; render_screen2_dirty (macro version) -------------------------------

RENDER_SCREEN2_DIRTY_MACRO macro videoengine
                local   render23d
                local   render20d
                local   render21d
                local   render2d_draw
                local   render2d_next

                call    wash_sprite

                ; esi = name table
                mov     eax,nametable
                mov     esi,msxvram
                lea     esi,[esi+eax]

                ; ebx = character pattern table
                mov     eax,patterntable
                mov     ebx,msxvram
                lea     ebx,[ebx+eax]
                mov     patternsave,ebx

                ; ecx = color table
                mov     eax,colortable
                mov     ecx,msxvram
                lea     ecx,[ecx+eax]
                mov     colorsave,ecx

                ; edi = blit buffer
                mov     edi,blitbuffer

                ; edx = dirty table name
                ; ebx = dirty table pattern
                mov     edx,offset dirtyname
                mov     ebx,offset dirtypattern

                ; mask the temporary registers
                xor     eax,eax

                ; for each sector
                mov     ebp,3

render23d:

                push    ebp

                if      (videoengine EQ DOS_ENGINE)
                  xor   ecx,ecx
                else
                  mov   ecx,colorsave
                endif

                ; for each line
                mov     ebp,8

render20d:

                push    ebp

                ; for each char
                mov     ebp,32

render21d:

                mov     al,[edx]
                or      al,al
                jnz     render2d_draw

                mov     al,[esi]
                cmp     byte ptr [ebx+eax],0
                je      render2d_next
                mov     byte ptr [edx],1


render2d_draw:

                ; fetch the character
                mov     al,[esi]
                push    ebp
                push    esi

                push    ebx
                push    edx

                xor     edx,edx
                mov     ebx,patternsave

                if      (videoengine EQ DOS_ENGINE)
                  PIPE2_DOS BITMASK_NO
                else
                  PIPE2_MMX BITMASK_NO
                endif

                pop     edx
                pop     ebx

                pop     esi
                pop     ebp
                
render2d_next:

                inc     esi
                add     edi,8
                inc     edx
                dec     ebp
                jnz     render21d

                pop     ebp
                add     edi,256*7
                dec     ebp
                jnz     render20d

                add     ebx,256                                         
                add     patternsave,256*8
                add     colorsave,256*8

                pop     ebp
                dec     ebp
                jnz     render23d

                mov     spriteenable,1
                ret

                endm

; render_screen2_dirty -----------------------------------------------
; render a screen 2 page using dirty blocks
; WARNING: this function must ALWAYS be 
;          called with interrupts DISABLED

render_screen2_dirty:

                cmp     enginetype,0
                jne     render_screen2_dirty_mmx
                RENDER_SCREEN2_DIRTY_MACRO DOS_ENGINE

render_screen2_dirty_mmx:
                RENDER_SCREEN2_DIRTY_MACRO MMX_ENGINE

; render_screen2 (macro version) -------------------------------------

RENDER_SCREEN2_MACRO macro videoengine                
                local   render_screen2_next
                local   render23
                local   render20
                local   render21
                
                cmp     everyframe,1
                je      render_screen2_next
                
                cmp     imagetype,1
                je      render_screen2_dirty

render_screen2_next:

                ; esi = name table
                mov     eax,nametable
                mov     esi,msxvram
                lea     esi,[esi+eax]

                ; ebx = character pattern table
                mov     eax,patterntable
                mov     ebx,msxvram
                lea     ebx,[ebx+eax]

                ; ecx = color table
                mov     eax,colortable
                mov     ecx,msxvram
                lea     ecx,[ecx+eax]
                mov     colorsave,ecx

                mov     scr2offset,0

                ; edi = blit buffer
                mov     edi,blitbuffer

                ; mask the temporary registers
                xor     eax,eax
                xor     edx,edx

                ; for each sector
                mov     ebp,3

render23:

                push    ebp

                if   (videoengine EQ DOS_ENGINE)
                  xor   ecx,ecx
                else
                  mov   ecx,colorsave
                endif

                ; for each line
                mov     ebp,8

render20:
                
                push    ebp

                ; for each char
                mov     ebp,32

render21:
                
                ; fetch the character
                mov     al,[esi]
                push    ebp
                push    esi
                push    ebx

                if (videoengine EQ DOS_ENGINE)
                  PIPE2_DOS BITMASK_YES
                else
                  PIPE2_MMX BITMASK_YES
                endif

                add     edi,8

                pop     ebx
                pop     esi
                pop     ebp
                
                inc     esi
                dec     ebp
                jnz     render21

                pop     ebp
                add     edi,256*7
                dec     ebp
                jnz     render20

                ; perform the undocumented correction
                ; to find increment for image table
                push    eax
                mov     eax,scr2offset
                inc     eax
                mov     scr2offset,eax
                push    ebx
                mov     ebx,scr2inc
                mov     eax,[ebx+eax*4]
                pop     ebx

                sub     ebx,msxvram
                add     ebx,eax
                and     ebx,03FFFh
                add     ebx,msxvram

                ; perform the undocumented correction
                ; to find increment for color table

                mov     eax,scr2offset
                push    ebx
                mov     ebx,scr2inc_color
                mov     eax,[ebx+eax*4]
                pop     ebx

                add     eax,colorsave
                sub     eax,msxvram
                and     eax,03FFFh
                add     eax,msxvram
                mov     colorsave,eax
                pop     eax

                pop     ebp
                dec     ebp
                jnz     render23

                mov     spriteenable,1
                ret

                endm

; render_screen2 -----------------------------------------------------
; render a screen 2 page
; WARNING: this function must ALWAYS be 
;          called with interrupts DISABLED

render_screen2:
                
                cmp     enginetype,0
                jne     render_screen2_mmx
                RENDER_SCREEN2_MACRO DOS_ENGINE

render_screen2_mmx:
                RENDER_SCREEN2_MACRO MMX_ENGINE

; render_screen4 -----------------------------------------------------
; render a screen 4 page
; WARNING: this function must ALWAYS be 
;          called with interrupts DISABLED

render_screen4:
                call    render_screen2
                mov     spriteenable,2
                ret

; render_screen3 -----------------------------------------------------
; render a screen 3 page

render_screen3:
                mov     edi,blitbuffer

                mov     ecx,nametable
                add     ecx,msxvram

                mov     esi,patterntable
                add     esi,msxvram

                mov     eax,0
                mov     edx,0

                mov     ebp,6
render_screen3_outerloop:
                push    ebp

                irp     i,<0,1,2,3,4,5,6,7>
                local   render_screen3_innerloop

                mov     ebx,0
render_screen3_innerloop:
                
                mov     al,[ecx]
                
                mov     dl,[esi+eax*8+i]
                mov     ebp,[offset foregroundcolor+edx*4]
                irp     j,<0,1,2,3>
                mov     [edi+j*256],ebp
                endm
                
                mov     ebp,[offset backgroundcolor+edx*4]
                irp     j,<0,1,2,3>
                mov     [edi+j*256+4],ebp
                endm

                add     edi,8
                inc     ebx
                inc     ecx
                cmp     ebx,32
                jne     render_screen3_innerloop

                add     edi,3*256
                add     ecx,((i AND 1)*32)-32

                endm

                pop     ebp
                dec     ebp
                jnz     render_screen3_outerloop

                mov     spriteenable,1
                ret

; sprite_render ------------------------------------------------------
; draw the sprites directly on the blit buffer

align 4

sprite_render:
                ; check for sprites enabled
                cmp     spriteenable,1
                jb      _ret

                ; check for sprites mode 2
                cmp     spriteenable,2
                je      sprite_render_msx2

                ; check for screen enabled
                test    byte ptr [offset vdpregs+1],BIT_6
                jz      _ret

                call    sprite_collision

                ; esi = sprite attribute table
                mov     esi,msxvram
                add     esi,sprattrtable

                ; find last sprite
                mov     ebp,32
sprite_render_find_loop:
                mov     ah,[esi]
                cmp     ah,0D0h
                je      sprite_render_found

                add     esi,4
                dec     ebp
                jnz     sprite_render_find_loop
sprite_render_found:
                sub     esi,4
                mov     eax,32
                sub     eax,ebp
                mov     ebp,eax
                jz      _ret

                ; at this point
                ; esi = pointer to last sprite's attribute table
                ; ebp = number of sprites

sprite_render_outer:
                push    ebp

                ; check for transparent sprite
                mov     cl,byte ptr [esi+3]
                and     cl,0Fh
                jz      sprite_render_next

                ; draw sprite image in false sprite buffer
                call    draw_sprite_image

                ; eval sprite coordinates
                call    eval_sprite_coords
                mov     edi,eax
                sal     edi,8
                add     edi,ecx
                add     edi,blitbuffer

                ; check for unusual size
                cmp     edx,16
                jne     sprite_render_line_slow
                
                ; check for crop
                cmp     ecx,0
                jl      sprite_render_line_slow
                cmp     ecx,256-16
                jge     sprite_render_line_slow
                cmp     eax,0
                jl      sprite_render_line_slow
                cmp     eax,192-16
                jge     sprite_render_line_slow

                ; draw the sprite in blitbuffer
                
                mov     ecx,offset falsesprite
                push    esi
                sub     esi,msxvram
                sub     esi,sprattrtable
                shr     esi,2
                xchg    eax,esi

sprite_render_line:
                cmp     al,byte ptr [offset spritemask+esi]
                ja      sprite_render_next_line

                irp     i,<0,4,8,12>
                mov     ebx,[edi+i]              
                and     ebx,[ecx+i]
                or      ebx,[ecx+32+i]
                mov     [edi+i],ebx
                endm
sprite_render_next_line:
                inc     esi
                add     ecx,64
                add     edi,256
                dec     edx
                jnz     sprite_render_line

                pop     esi

sprite_render_next:
                pop     ebp
                sub     esi,4
                dec     ebp   
                jnz     sprite_render_outer

                ret

; --------------------------------------------------------------------

                ; pixel by pixel sprite engine
                ; used in case of crop or unusual sprites 
                ; (8x8 unzoomed or 16x16 zoomed)

sprite_render_line_slow:
                push    esi
                sub     esi,msxvram
                sub     esi,sprattrtable
                shl     esi,6
                mov     ebx,esi
                mov     esi,offset falsesprite
                mov     ebp,edx

                ; draw the sprite in blitbuffer
sprite_render_line_slow_outer:
                cmp     eax,0
                jl      sprite_render_line_slow_next
                cmp     eax,192
                jge     sprite_render_line_exit

                cmp     bh,byte ptr [offset spritemask+eax]
                ja      sprite_render_line_slow_next
                
                push    ecx ebp
sprite_render_line_slow_inner:
                cmp     ecx,0
                jl      sprite_render_line_slow_skip
                cmp     ecx,256
                jge     sprite_render_line_slow_skip

                mov     bl,[edi]              
                and     bl,[esi]
                or      bl,[esi+32]
                mov     [edi],bl

sprite_render_line_slow_skip:
                inc     edi
                inc     esi
                inc     ecx
                dec     ebp 
                jnz     sprite_render_line_slow_inner
                
                pop     ebp ecx
                sub     edi,ebp
                sub     esi,ebp

sprite_render_line_slow_next:
                inc     eax
                add     esi,64
                add     edi,256
                dec     edx
                jnz     sprite_render_line_slow_outer

sprite_render_line_exit:
                pop     esi
                jmp     sprite_render_next

; clear_sprite_buffer ------------------------------------------------
; clear the buffer for 5th sprite ocultation

clear_sprite_buffer:

                mov     eax,01F1F1F1Fh
                mov     ecx,192/4
                mov     edi,offset spritemask
                rep     stosd

                mov     eax,0
                mov     ecx,192/4
                mov     edi,offset spritecounter
                rep     stosd

                ret

; mark_sprite --------------------------------------------------------
; mark a sprite in the ocultation buffer
; enter: esi = attribute of current sprite
; must preserve esi and ebp

mark_sprite:
                ; eval number of rows of sprite
                
                ; 8x8 or 16x16
                mov     cl,byte ptr [offset vdpregs+1]
                shr     cl,1
                and     cl,1
                mov     edx,8
                shl     edx,cl

                ; zoomed/unzoomed
                mov     cl,byte ptr [offset vdpregs+1]
                and     cl,1
                shl     edx,cl

                ; at this point edx = number of rows
                ; now we will evaluate the y coord of sprite
                movzx   ecx,byte ptr [esi]
                cmp     ecx,0BEh                ;0F0h? 
                jbe     mark_sprite_positive
                movsx   ecx,cl
mark_sprite_positive:
                inc     ecx

                ; at this point
                ; edx = number of rows
                ; ecx = starting Y coord (signed)
mark_sprite_loop:

                cmp     ecx,0
                jl      mark_sprite_next
                cmp     ecx,192
                jge     mark_sprite_exit

                mov     al,[offset spritecounter+ecx]
                cmp     al,4
                jae     mark_sprite_ocult

                inc     al
                mov     [offset spritecounter+ecx],al
                mov     ebx,32
                sub     ebx,ebp             
                mov     [offset spritemask+ecx],bl

mark_sprite_next:
                inc     ecx
                dec     edx
                jnz     mark_sprite_loop

mark_sprite_exit:
                ret

mark_sprite_ocult:
                mov     ebx,32
                sub     ebx,ebp             
                mov     byte ptr [offset dirtysprattr+ebx],1
                cmp     spr_occult,255
                jne     mark_sprite_next
                mov     spr_occult,ebx
                and     vdpstatus,0F0h
                or      vdpstatus,bl
                or      vdpstatus,BIT_6
                jmp     mark_sprite_next

; sprite_collision ---------------------------------------------------
; check for sprite collision 

sprite_collision:
                cmp     no_collision,1                
                je      _ret
                
                ; clear sprite collision flag
                and     vdpstatus,NBIT_5

                ; esi = sprite attribute table
                mov     esi,msxvram
                add     esi,sprattrtable

                ; find last sprite
                mov     ebp,32
sprite_collision_loop:
                mov     ah,[esi]
                cmp     ah,0D0h
                je      _ret

                call    check_one_sprite

                test    vdpstatus,BIT_5
                jnz     sprite_collision_clear

                add     esi,4
                dec     ebp
                jnz     sprite_collision_loop

                jmp     sprite_collision_clear

; sprite_collision_clear ---------------------------------------------
; clear the collision field

sprite_collision_clear:
                ; esi = sprite attribute table
                mov     esi,msxvram
                add     esi,sprattrtable

                ; find last sprite
                mov     ebp,32
sprite_collision_clear_loop:
                mov     ah,[esi]
                cmp     ah,0D0h
                je      _ret

                call    clear_one_sprite

                add     esi,4
                dec     ebp
                jnz     sprite_collision_clear_loop
                
                ret

; check_one_sprite ---------------------------------------------------
; check a single sprite for collision
; this routine works for all sprite sizes (8x8 or 16x16, Z or NZ)

check_one_sprite:
                test    byte ptr [offset vdpregs+1],BIT_1
                jz      check_one_sprite_simple

                test    byte ptr [offset vdpregs+1],BIT_0
                jz      check_one_sprite_simple

check_one_sprite_complex:
                ; _1_  3
                ;  2   4
                mov     x_factor,0
                call    draw_binary_sprite
                mov     x_factor,0
                mov     y_factor,0
                call    collision_check
                ;  1   3
                ; _2_  4
                mov     x_factor,8
                call    draw_binary_sprite
                mov     x_factor,0
                mov     y_factor,16
                call    collision_check
                ;  1  _3_
                ;  2   4
                mov     x_factor,16
                call    draw_binary_sprite
                mov     x_factor,16
                mov     y_factor,0
                call    collision_check
                ;  1   3
                ;  2  _4_
                mov     x_factor,24
                call    draw_binary_sprite
                mov     x_factor,16
                mov     y_factor,16
                call    collision_check
                ret

check_one_sprite_simple:
                mov     y_factor,0
                mov     x_factor,0
                call    draw_binary_sprite
                call    collision_check
                ret

; draw_binary_sprite -------------------------------------------------
; draw a binary sprite in the false buffer
; esi points to spr attr table

draw_binary_sprite:
                test    byte ptr [offset vdpregs+1],BIT_1
                jnz     draw_binary_sprite_1616N

                jmp     draw_binary_sprite_88N


; --------------------------------------------------------------------

draw_binary_sprite_1616N:
                test    byte ptr [offset vdpregs+1],BIT_0
                jnz     draw_binary_sprite_1616Z

                ; 16x16 unzoomed
                movzx   eax,byte ptr [esi+2]
                and     eax,11111100b
                shl     eax,3
                add     eax,sprpatttable
                add     eax,msxvram

                mov     ecx,16
                mov     edi,offset falsesprite

draw_binary_sprite_1616N_loop:
                mov     bl,[eax]
                mov     [edi],bl
                mov     bl,[eax+16]
                mov     [edi+1],bl
                add     edi,2
                inc     eax
                dec     ecx
                jnz     draw_binary_sprite_1616N_loop

                ret

; --------------------------------------------------------------------

draw_binary_sprite_88N:
                test    byte ptr [offset vdpregs+1],BIT_0
                jnz     draw_binary_sprite_88Z

                ; 8x8 unzoomed
                movzx   eax,byte ptr [esi+2]
                shl     eax,3
                add     eax,sprpatttable
                add     eax,msxvram

                mov     ecx,8
                mov     edi,offset falsesprite

draw_binary_sprite_88N_loop:
                mov     bl,[eax]
                mov     byte ptr [edi],bl
                mov     byte ptr [edi+1],0
                add     edi,2
                inc     eax
                dec     ecx
                jnz     draw_binary_sprite_88N_loop

                ; fill the remaining 16 bytes 
                mov     ecx,16/4
                mov     eax,0
                rep     stosd

                ret

; --------------------------------------------------------------------

draw_binary_sprite_88Z:

                ; 8x8 zoomed
                movzx   eax,byte ptr [esi+2]
                shl     eax,3
                add     eax,sprpatttable
                add     eax,msxvram

                mov     ecx,8
                mov     edi,offset falsesprite

draw_binary_sprite_88Z_loop:
                movzx   ebx,byte ptr [eax]
                mov     bx,word ptr [offset binary_zoom+ebx*2]
                mov     word ptr [edi],bx
                mov     word ptr [edi+2],bx
                add     edi,4
                inc     eax
                dec     ecx
                jnz     draw_binary_sprite_88Z_loop

                ret

; --------------------------------------------------------------------

draw_binary_sprite_1616Z:

                ; 16x16 zoomed (just one quarter of it)
                movzx   eax,byte ptr [esi+2]
                shl     eax,3
                add     eax,sprpatttable
                add     eax,msxvram
                add     eax,x_factor

                mov     ecx,8
                mov     edi,offset falsesprite

draw_binary_sprite_1616Z_loop:
                movzx   ebx,byte ptr [eax]
                mov     bx,word ptr [offset binary_zoom+ebx*2]
                mov     word ptr [edi],bx
                mov     word ptr [edi+2],bx
                add     edi,4
                inc     eax
                dec     ecx
                jnz     draw_binary_sprite_1616Z_loop

                ret

; collision_check ----------------------------------------------------
; check for coincidence in the collision field
; don't touch esi and ebp

collision_check:
                call    eval_sprite_coords
                add     eax,y_factor
                add     ecx,x_factor

                push    ebp
                mov     ebp,eax

                ; eax = y  ; ecx =x
                cmp     ecx,16
                jl      collision_check_slow
                cmp     ecx,256-16
                jg      collision_check_slow

                mov     ebx,ecx
                shr     ebx,3
                sal     eax,5
                add     eax,ebx
                add     eax,collisionfield
                and     ecx,7
                mov     edi,offset falsesprite

                push    esi
                mov     esi,eax
                ; eax points to char 
                mov     ebx,16
collision_check_loop:
                cmp     ebp,0
                jl      collision_check_skip
                cmp     ebp,192
                jge     collision_check_skip

                irp     i,<0,1>
                movzx   eax,byte ptr [edi+i]
                shl     eax,8
                shr     eax,cl
                xchg    ah,al
                mov     edx,dword ptr [esi+i]
                and     edx,eax
                jnz     collision_found
                or      dword ptr [esi+i],eax
                endm

collision_check_skip:
                inc     ebp
                add     esi,256/8
                add     edi,2
                dec     ebx
                jnz     collision_check_loop
                pop     esi

collision_check_ret:
                pop     ebp
                ret

; --------------------------------------------------------------------

collision_found:
                or      vdpstatus,BIT_5
                pop     esi
                pop     ebp
                ret

; --------------------------------------------------------------------

collision_check_slow:                
                mov     edi,ecx
                sar     edi,3
                sal     eax,5
                add     eax,edi
                add     eax,collisionfield
                and     ecx,7

                push    esi
                mov     esi,eax
                ; eax points to char 
                mov     ebx,0 ;16
collision_check_loop_slow:
                cmp     ebp,0
                jl      collision_check_skip_slow
                cmp     ebp,192
                jge     collision_check_skip_slow

                irp     i,<0,1> 
                local   skip1,skip2
                movzx   eax,byte ptr [offset falsesprite+ebx*2+i] 
                shl     eax,8
                shr     eax,cl
                ;
                cmp     edi,-i
                jl      skip1
                cmp     edi,31-i
                jg      skip1
                mov     dl,byte ptr [esi+i]
                and     dl,ah
                jnz     collision_found
                or      byte ptr [esi+i],ah
                ;
skip1:
                cmp     edi,-(i+1)
                jl      skip2
                cmp     edi,31-(i+1)
                jg      skip2
                mov     dl,byte ptr [esi+i+1]
                and     dl,al
                jnz     collision_found
                or      byte ptr [esi+i+1],al
                ;
skip2:
                endm

collision_check_skip_slow:
                inc     ebp
                add     esi,256/8
                inc     ebx
                cmp     ebx,16
                jne     collision_check_loop_slow
                pop     esi

                jmp     collision_check_ret

; collision_clear ----------------------------------------------------
; clear one sprite from collision field
; don't touch esi and ebp

collision_clear:
                call    eval_sprite_coords
                add     eax,y_factor
                add     ecx,x_factor

                push    ebp
                mov     ebp,eax

                ; eax = y  ; ecx =x
                cmp     ecx,16
                jl      collision_clear_slow
                cmp     ecx,256-16
                jg      collision_clear_slow
                
                sar     ecx,3
                shl     eax,5
                add     eax,ecx
                add     eax,collisionfield

                mov     edx,eax
                mov     ebx,16
collision_clear_loop:
                cmp     ebp,0
                jl      collision_clear_skip
                cmp     ebp,192
                jge     collision_clear_skip
                mov     dword ptr [edx],0

collision_clear_skip:
                inc     ebp
                add     edx,256/8
                dec     ebx
                jnz     collision_clear_loop

collision_clear_ret:
                pop     ebp
                ret

; --------------------------------------------------------------------

collision_clear_slow:                
                mov     edi,ecx
                sar     edi,3
                sal     eax,5
                add     eax,edi
                add     eax,collisionfield
                and     ecx,7

                push    esi
                mov     esi,eax
                ; eax points to char 
                mov     ebx,0 ;16
collision_clear_loop_slow:
                cmp     ebp,0
                jl      collision_clear_skip_slow
                cmp     ebp,192
                jge     collision_clear_skip_slow

                irp     i,<0,1> 
                local   skip1,skip2
                ;
                cmp     edi,-i
                jl      skip1
                cmp     edi,31-i
                jg      skip1
                mov     byte ptr [esi+i],0
                ;
skip1:
                cmp     edi,-(i+1)
                jl      skip2
                cmp     edi,31-(i+1)
                jg      skip2
                mov     byte ptr [esi+i+1],0
                ;
skip2:
                endm

collision_clear_skip_slow:
                inc     ebp
                add     esi,256/8
                inc     ebx
                cmp     ebx,16
                jne     collision_clear_loop_slow
                pop     esi

                pop     ebp
                ret

; clear_one_sprite ---------------------------------------------------
; clear a single sprite from collision field
; this routine works for all sprite sizes (8x8 or 16x16, Z or NZ)

clear_one_sprite:
                test    byte ptr [offset vdpregs+1],BIT_1
                jz      clear_one_sprite_simple

                test    byte ptr [offset vdpregs+1],BIT_0
                jz      clear_one_sprite_simple

clear_one_sprite_complex:
                ; _1_  3
                ;  2   4
                mov     x_factor,0
                mov     y_factor,0
                call    collision_clear
                ;  1   3
                ; _2_  4
                mov     x_factor,0
                mov     y_factor,16
                call    collision_clear
                ;  1  _3_
                ;  2   4
                mov     x_factor,16
                mov     y_factor,0
                call    collision_clear
                ;  1   3
                ;  2  _4_
                mov     x_factor,16
                mov     y_factor,16
                call    collision_clear
                ret

clear_one_sprite_simple:
                mov     y_factor,0
                mov     x_factor,0
                call    collision_clear
                ret

; render_col ---------------------------------------------------------
; render the collision field

render_col:
                mov     edi,0A0000h
                sub     edi,_code32a
                add     edi,32
                mov     esi,collisionfield

                mov     ebp,192
render_col_outer:

                mov     edx,32
render_col_inner:
                mov     al,[esi]
                irp     i,<0,1,2,3,4,5,6,7>
                shl     al,1
                sbb     ah,ah
                and     ah,15
                mov     [edi],ah
                inc     edi
                endm

                inc     esi
                dec     edx
                jnz     render_col_inner

                add     edi,320-256
                dec     ebp
                jnz     render_col_outer

                ret

; render -------------------------------------------------------------
; render the MSX screen, based on VDP registers and VRAM

render:
                test    byte ptr [offset vdpregs+1],BIT_6
                jnz     render_enabled

                ; check if the SCREEN mode has changed
                mov     bl,actualscreen
                cmp     bl,lastscreen
                je      render_disabled

                ; SCREEN mode has changed
                mov     enabled,1

render_disabled:
                ; video is disabled
                cmp     enabled,0
                je      _ret

                mov     enabled,0
                mov     eax,01010101h
                mov     edi,offset dirtyname
                mov     ecx,32*24/4
                rep     stosd
                jmp     clear

render_enabled:
                ; video is enabled
                cmp     enabled,0
                jne     render_check_screen

                ; video is enabled after being disabled for a while
                ; now it must be fully restored
                mov     firstscreen,1

render_check_screen:
                mov     enabled,1
                
                ; check if the SCREEN mode has changed
                mov     bl,actualscreen
                cmp     bl,lastscreen
                je      render_check_first

                ; SCREEN mode has changed
                ; clear blitbuffer to avoid border problems
                ; also copy a new palette
                mov     lastscreen,bl
                call    clear
                call    set_correct_palette

render_check_first:
                cmp     firstscreen,1            
                jne     render_draw

                ; first screen after a major change in display
                ; must update all the display
                mov     firstscreen,0
                mov     eax,01010101h
                mov     edi,offset dirtyname
                mov     ecx,32*24/4
                rep     stosd

                ; check if the GUI is enabled
                cmp     cpupaused,1
                je      render_draw

                ; GUI is not enabled: update the border color
                call    set_border_color

render_draw:
                mov     bl,actualscreen

                cmp     bl,0
                je      render_screen0

                push    ebx
                call    prepare_ocultation
                pop     ebx

                cmp     bl,1
                je      render_screen1

                cmp     bl,2
                je      render_screen2

                cmp     bl,3
                je      render_screen3

                cmp     bl,4
                je      render_screen4

                cmp     bl,5
                je      render_screen5

                cmp     bl,6
                je      render_screen6

                cmp     bl,7
                je      render_screen7

                ret

; clear --------------------------------------------------------------
; clear the blit buffer
                
clear:
                push    es
                mov     ax,ds
                mov     es,ax
                mov     eax,0
                mov     edi,blitbuffer
                mov     ecx,512*384/4
                rep     stosd
                pop     es
                ret

; eval_sprite_coords -------------------------------------------------
; evaluate sprite coordinates
; enter: esi = start of sprite attribute in vram
; exit: eax = offset y ; ecx = offset x (both are signed numbers)

eval_sprite_coords:
                xor     ecx,ecx
                mov     al,[esi+3]      ; "early clock" attribute
                mov     cl,[esi+1]      ; x coordinate
                and     eax,080h
                shr     eax,2
                sub     ecx,eax

                mov     al,[esi]        ; y coordinate
                cmp     al,0BEh         ; 0F0h ??
                jbe     eval_sprite_coords1
                movsx   eax,al

eval_sprite_coords1:
                inc     eax
                ret
                
; draw_sprite_image --------------------------------------------------
; draw a sprite image in the false buffer
; enter: esi = start of sprite attribute in vram
; exit: false sprite buffer filled with sprite image
;       edx = number of lines/rows of sprite

draw_sprite_image:
                test    byte ptr [offset vdpregs+1],BIT_1
                jz      draw_sprite_image_8

draw_sprite_image_16:       
                test    byte ptr [offset vdpregs+1],BIT_0
                jnz     draw_sprite_image_16Z
                
; --------------------------------------------------------------------

draw_sprite_image_16N:

                ; eval address of sprite image
                movzx   eax,byte ptr [esi+2]
                and     eax,11111100b
                mov     ecx,msxvram
                add     ecx,sprpatttable
                lea     ecx,[ecx+eax*8]

                ; eval color mask of sprite
                mov     al,[esi+3]
                mov     eax,[offset backgroundcolor+eax*4]

                mov     edx,16
                mov     edi,offset falsesprite
                mov     ebx,0

                push    esi
                
draw_sprite_image_16N_loop:                     
                ; fetch the image for the subline
                mov     bl,[ecx]

                ; get the sprite mask
                mov     esi,[offset backgroundmask+ebx*8]

                ; get the sprite color
                mov     ebp,eax

                ; blend with the sprite image
                and     ebp,[offset foregroundmask+ebx*8]

                ; put back to screen
                mov     [edi],esi
                mov     [edi+32],ebp

                ; do it again for the next four pixels
                
                mov     esi,[offset backgroundmask+ebx*8+4]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8+4]
                mov     [edi+4],esi
                mov     [edi+4+32],ebp
                
                ; do it again for the next eight pixels
                
                mov     bl,[ecx+16]
                
                mov     esi,[offset backgroundmask+ebx*8]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8]
                mov     [edi+8],esi
                mov     [edi+8+32],ebp
                
                mov     esi,[offset backgroundmask+ebx*8+4]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8+4]
                mov     [edi+12],esi
                mov     [edi+12+32],ebp
                
                add     edi,64
                inc     ecx
                dec     edx
                jnz     draw_sprite_image_16N_loop

                pop     esi
                mov     edx,16
                ret

; --------------------------------------------------------------------

draw_sprite_image_16Z:

                ; eval address of sprite image
                movzx   eax,byte ptr [esi+2]
                and     eax,11111100b
                mov     ecx,msxvram
                add     ecx,sprpatttable
                lea     ecx,[ecx+eax*8]

                ; eval color mask of sprite
                mov     al,[esi+3]
                mov     eax,[offset backgroundcolor+eax*4]

                mov     edx,16
                mov     edi,offset falsesprite
                mov     ebx,0

                push    esi
                
draw_sprite_image_16Z_loop:                     
                ; fetch the image for the subline
                movzx   ebx,byte ptr [ecx]
                shl     ebx,4

                irp     i,<0,4,8,12>
                mov     esi,[offset background_zoom+ebx+i]
                mov     ebp,eax
                and     ebp,[offset foreground_zoom+ebx+i]
                mov     [edi+i],esi
                mov     [edi+i+32],ebp
                mov     [edi+i+64],esi
                mov     [edi+i+32+64],ebp
                endm

                ; do it again for the next eight pixels
                
                movzx   ebx,byte ptr [ecx+16]
                shl     ebx,4

                irp     i,<0,4,8,12>
                mov     esi,[offset background_zoom+ebx+i]
                mov     ebp,eax
                and     ebp,[offset foreground_zoom+ebx+i]
                mov     [edi+i+16],esi
                mov     [edi+i+16+32],ebp
                mov     [edi+i+16+64],esi
                mov     [edi+i+16+32+64],ebp
                endm

                add     edi,128
                inc     ecx
                dec     edx
                jnz     draw_sprite_image_16Z_loop

                pop     esi
                mov     edx,32
                ret

; --------------------------------------------------------------------

draw_sprite_image_8:       
                test    byte ptr [offset vdpregs+1],BIT_0
                jnz     draw_sprite_image_8Z 
                
draw_sprite_image_8N:

                ; eval address of sprite image
                movzx   eax,byte ptr [esi+2]
                mov     ecx,msxvram
                add     ecx,sprpatttable
                lea     ecx,[ecx+eax*8]

                ; eval color mask of sprite
                mov     al,[esi+3]
                mov     eax,[offset backgroundcolor+eax*4]

                mov     edx,8
                mov     edi,offset falsesprite
                mov     ebx,0

                push    esi
                
draw_sprite_image_8N_loop:                     
                ; fetch the image for the subline
                mov     bl,[ecx]

                irp     i,<0,4>
                mov     esi,[offset backgroundmask+ebx*8+i]
                mov     ebp,eax
                and     ebp,[offset foregroundmask+ebx*8+i]
                mov     [edi+i],esi
                mov     [edi+i+32],ebp
                endm

                add     edi,64
                inc     ecx
                dec     edx
                jnz     draw_sprite_image_8N_loop

                pop     esi
                mov     edx,8
                ret

; --------------------------------------------------------------------

draw_sprite_image_8Z:

                ; eval address of sprite image
                movzx   eax,byte ptr [esi+2]
                mov     ecx,msxvram
                add     ecx,sprpatttable
                lea     ecx,[ecx+eax*8]

                ; eval color mask of sprite
                mov     al,[esi+3]
                mov     eax,[offset backgroundcolor+eax*4]

                mov     edx,8
                mov     edi,offset falsesprite
                mov     ebx,0

                push    esi
                
draw_sprite_image_8Z_loop:                     
                ; fetch the image for the subline
                movzx   ebx,byte ptr [ecx]
                shl     ebx,4

                irp     i,<0,4,8,12>
                mov     esi,[offset background_zoom+ebx+i]
                mov     ebp,eax
                and     ebp,[offset foreground_zoom+ebx+i]
                mov     [edi+i],esi
                mov     [edi+i+32],ebp
                mov     [edi+i+64],esi
                mov     [edi+i+32+64],ebp
                endm

                add     edi,128
                inc     ecx
                dec     edx
                jnz     draw_sprite_image_8Z_loop

                pop     esi
                mov     edx,16
                ret

; CHECK --------------------------------------------------------------
; mark one block as dirty

CHECK           macro   offx,offy,name
                local   check_sprite_exit

                push    ecx eax

                add     eax,offy
                js      check_sprite_exit
                cmp     eax,24
                jge     check_sprite_exit
                add     ecx,offx
                js      check_sprite_exit
                cmp     ecx,32
                jge     check_sprite_exit
                shl     eax,5
                add     eax,ecx
                add     eax,offset dirtyname
                mov     byte ptr [eax],1

check_sprite_exit:
                pop     eax ecx

                endm

; dirty_sprite -------------------------------------------------------
; make the screen behind the sprite dirty
; enter: eax = offset y ; ecx = offset x (both are signed numbers)

dirty_sprite:
                sar     eax,3
                js      dirty_sprite_crop_ecx
                cmp     eax,23-3
                jg      dirty_sprite_crop_ecx
                sar     ecx,3
                js      dirty_sprite_crop_all
                cmp     ecx,31-3
                jg      dirty_sprite_crop_all

dirty_sprite_fast:
                shl     eax,5
                add     eax,ecx
                add     eax,offset dirtyname
                or      dword ptr [eax],000010101h
                or      dword ptr [eax+32],000010101h
                or      dword ptr [eax+64],000010101h
                ret
                
dirty_sprite_crop_ecx:
                sar     ecx,3
dirty_sprite_crop_all:

                CHECK   0,0
                CHECK   1,0
                CHECK   2,0
                CHECK   0,1
                CHECK   1,1
                CHECK   2,1
                CHECK   0,2
                CHECK   1,2
                CHECK   2,2

                ret

; eval_base_address --------------------------------------------------
; evaluate the new bases for vdp tables

eval_base_address:

                mov     everyframe,0

                ; zoomed sprites always turn off the video cache
                test    byte ptr [offset vdpregs+1],BIT_0
                jz      eval_base_address_begin

                mov     everyframe,1

eval_base_address_begin:
                ; first we need to determine the actual screen
                mov     al,byte ptr [offset vdpregs+0]
                shr     al,1
                and     al,1
                mov     ah,byte ptr [offset vdpregs+1]
                shr     ah,2
                and     ah,110b
                or      al,ah

                cmp     al,0
                je      eval_screen1
                cmp     al,1
                je      eval_screen2
                cmp     al,2
                je      eval_screen3
                jmp     eval_screen0

; eval_base_address_msx2 ---------------------------------------------
; evaluate the new bases for vdp tables 
; MSX2 version

eval_base_address_msx2:

                mov     everyframe,0

                ; zoomed sprites always turn off the video cache
                test    byte ptr [offset vdpregs+1],BIT_0
                jz      eval_base_address_begin_msx2

                mov     everyframe,1

eval_base_address_begin_msx2:
                mov     text_columns,40

                ; first we need to determine the actual screen
                mov     al,byte ptr [offset vdpregs+0]
                shr     al,1
                and     al,7
                mov     ah,byte ptr [offset vdpregs+1]
                and     ah,11000b
                or      al,ah

                cmp     al,10000b
                je      eval_screen0_msx2    ; 40 columns
                
                cmp     al,10010b
                je      eval_screen0_80_msx2 ; 80 columns
                
                cmp     al,01000b
                je      eval_screen3

                cmp     al,00000b
                je      eval_screen1

                cmp     al,00001b
                je      eval_screen2_msx2
                
                cmp     al,00010b
                je      eval_screen4
                
                cmp     al,00011b
                je      eval_screen5
                
                cmp     al,00100b
                je      eval_screen6
                
                cmp     al,00101b
                je      eval_screen7
                
                jmp     eval_screen0_msx2

; --------------------------------------------------------------------

eval_screen2:
                ; M3 set - screen 2

                mov     actualscreen,2

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,0Fh
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                and     al,80h
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,04h
                shl     eax,11
                mov     patterntable,eax

                movzx   eax,byte ptr [offset vdpregs+5]
                and     al,07Fh
                shl     eax,7
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,07h
                shl     eax,11
                mov     sprpatttable,eax
                
                push    eax ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,01010101h
                mov     edi,nametable
                shr     edi,6
                mov     ecx,32*24/64 
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,02020202h
                mov     ecx,32*24*8/64 
                mov     edi,patterntable
                shr     edi,6
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,03030303h
                mov     ecx,32*24*8/64 
                mov     edi,colortable
                shr     edi,6
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,05050505h
                mov     edi,sprpatttable
                shr     edi,6
                mov     ecx,256*8/64 
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,04040404h
                mov     edi,sprattrtable
                shr     edi,6
                add     edi,offset vrammapping
                mov     ecx,2
                call    fill_vram_table

                mov     eax,offset dirty_screen2_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen2_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen2_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen2_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen2_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen2_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax

                mov     eax,offset scr2undoc_table+3*12
                mov     scr2inc,eax
                mov     scr2inc_color,eax

                ; perform undocumented correction in color table
                ; used in the "atselous" demo
                mov     al,byte ptr [offset vdpregs+3]
                and     al,3
                mov     bitmask,al
                
                mov     al,byte ptr [offset vdpregs+3]
                shr     al,2
                and     al,7
                shl     al,5
                or      al,00011100b
                
                or      bitmask,al

                ; check for the undocumented feature in image table
                movzx   eax,byte ptr [offset vdpregs+4]
                and     eax,3
                cmp     eax,3
                je      eval_base_address_scr2_check_color

                ; undocumented mode is on
                mov     everyframe,1

                lea     eax,[eax+eax*2]
                lea     ecx,[offset scr2undoc_table+eax*4]
                mov     scr2inc,ecx

eval_base_address_scr2_check_color:
                ; check for the undocumented feature in color table
                movzx   eax,byte ptr [offset vdpregs+3]
                and     eax,127
                cmp     eax,127
                je      eval_base_address_scr2_doc

                ; undocumented mode is on
                mov     everyframe,1

                shr     eax,5
                lea     eax,[eax+eax*2]
                lea     ecx,[offset scr2undoc_table+eax*4]
                mov     scr2inc_color,ecx

eval_base_address_scr2_doc:
                
                pop     edi ecx eax

                xor     eax,eax
                ret

; --------------------------------------------------------------------

eval_screen2_msx2:
                ; M3 set - screen 2

                mov     actualscreen,2

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,07Fh
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                and     al,80h
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,04h
                shl     eax,11
                mov     patterntable,eax

                mov     al,byte ptr [offset vdpregs+5]
                mov     ah,byte ptr [offset vdpregs+11]
                and     eax,03F8h
                shl     eax,7
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,03Fh
                shl     eax,11
                mov     sprpatttable,eax
                
                push    eax ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,01010101h
                mov     edi,nametable
                shr     edi,6
                mov     ecx,32*24/64 
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,02020202h
                mov     ecx,32*24*8/64 
                mov     edi,patterntable
                shr     edi,6
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,03030303h
                mov     ecx,32*24*8/64 
                mov     edi,colortable
                shr     edi,6
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,05050505h
                mov     edi,sprpatttable
                shr     edi,6
                mov     ecx,256*8/64 
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,04040404h
                mov     edi,sprattrtable
                shr     edi,6
                add     edi,offset vrammapping
                mov     ecx,2
                call    fill_vram_table

                mov     eax,offset dirty_screen2_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen2_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen2_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen2_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen2_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen2_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax

                mov     eax,offset scr2undoc_table+3*12
                mov     scr2inc,eax
                mov     scr2inc_color,eax

                ; perform undocumented correction in color table
                ; used in the "atselous" demo
                mov     al,byte ptr [offset vdpregs+3]
                and     al,3
                mov     bitmask,al
                
                mov     al,byte ptr [offset vdpregs+3]
                shr     al,2
                and     al,7
                shl     al,5
                or      al,00011100b
                
                or      bitmask,al

                ; check for the undocumented feature in image table
                movzx   eax,byte ptr [offset vdpregs+4]
                and     eax,3
                cmp     eax,3
                je      eval_base_address_scr2_check_color_msx2

                ; undocumented mode is on
                mov     everyframe,1

                lea     eax,[eax+eax*2]
                lea     ecx,[offset scr2undoc_table+eax*4]
                mov     scr2inc,ecx

eval_base_address_scr2_check_color_msx2:
                ; check for the undocumented feature in color table
                movzx   eax,byte ptr [offset vdpregs+3]
                and     eax,127
                cmp     eax,127
                je      eval_base_address_scr2_doc_msx2

                ; undocumented mode is on
                mov     everyframe,1

                shr     eax,5
                lea     eax,[eax+eax*2]
                lea     ecx,[offset scr2undoc_table+eax*4]
                mov     scr2inc_color,ecx

eval_base_address_scr2_doc_msx2:
                
                pop     edi ecx eax

                xor     eax,eax
                ret

; --------------------------------------------------------------------

eval_screen4:
                ; screen 4

                mov     actualscreen,4

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,07Fh
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                and     al,80h
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,04h
                shl     eax,11
                mov     patterntable,eax

                mov     al,byte ptr [offset vdpregs+5]
                mov     ah,byte ptr [offset vdpregs+11]
                and     eax,03FCh
                shl     eax,7
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,03Fh
                shl     eax,11
                mov     sprpatttable,eax
                
                push    eax ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,01010101h
                mov     edi,nametable
                shr     edi,6
                mov     ecx,32*24/64 
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,02020202h
                mov     ecx,32*24*8/64 
                mov     edi,patterntable
                shr     edi,6
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,03030303h
                mov     ecx,32*24*8/64 
                mov     edi,colortable
                shr     edi,6
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,05050505h
                mov     edi,sprpatttable
                shr     edi,6
                mov     ecx,256*8/64 
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     eax,04040404h
                mov     edi,sprattrtable
                shr     edi,6
                add     edi,offset vrammapping
                mov     ecx,2
                call    fill_vram_table

                mov     eax,offset dirty_screen2_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen2_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen2_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen2_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen2_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen2_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax

                mov     eax,offset scr2undoc_table+3*12
                mov     scr2inc,eax
                mov     scr2inc_color,eax

                ; perform undocumented correction in color table
                ; used in the "atselous" demo
                mov     al,byte ptr [offset vdpregs+3]
                and     al,3
                mov     bitmask,al
                
                mov     al,byte ptr [offset vdpregs+3]
                shr     al,2
                and     al,7
                shl     al,5
                or      al,00011100b
                
                or      bitmask,al

                ; check for the undocumented feature in image table
                movzx   eax,byte ptr [offset vdpregs+4]
                and     eax,3
                cmp     eax,3
                je      eval_base_address_scr4_check_color

                ; undocumented mode is on
                mov     everyframe,1

                lea     eax,[eax+eax*2]
                lea     ecx,[offset scr2undoc_table+eax*4]
                mov     scr2inc,ecx

eval_base_address_scr4_check_color:
                ; check for the undocumented feature in color table
                movzx   eax,byte ptr [offset vdpregs+3]
                and     eax,127
                cmp     eax,127
                je      eval_base_address_scr4_doc

                ; undocumented mode is on
                mov     everyframe,1

                shr     eax,5
                lea     eax,[eax+eax*2]
                lea     ecx,[offset scr2undoc_table+eax*4]
                mov     scr2inc_color,ecx

eval_base_address_scr4_doc:
                
                pop     edi ecx eax

                xor     eax,eax
                ret

; --------------------------------------------------------------------

eval_screen1:
                ; M3,M2,M1 reset - screen 1

                mov     actualscreen,1

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,0Fh
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                shl     eax,6
                mov     colortable,eax
                
                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,07h
                shl     eax,11
                mov     patterntable,eax

                movzx   eax,byte ptr [offset vdpregs+5]
                and     al,07Fh
                shl     eax,7
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,07h
                shl     eax,11
                mov     sprpatttable,eax
                
                push    eax ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,01010101h
                mov     edi,nametable
                shr     edi,6
                mov     ecx,32*24/64 
                add     edi,offset vrammapping
                call    fill_vram_table
                
                mov     eax,02020202h
                mov     edi,patterntable
                shr     edi,6
                mov     ecx,256*8/64 
                add     edi,offset vrammapping
                call    fill_vram_table

                mov     al,03h
                mov     edi,colortable
                shr     edi,6
                add     edi,offset vrammapping
                mov     ecx,1
                call    fill_vram_table

                mov     eax,05050505h
                mov     edi,sprpatttable
                shr     edi,6
                mov     ecx,256*8/64 
                add     edi,offset vrammapping
                call    fill_vram_table
                
                mov     eax,04040404h
                mov     edi,sprattrtable
                shr     edi,6
                add     edi,offset vrammapping
                mov     ecx,2
                call    fill_vram_table

                mov     eax,offset dirty_screen1_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen1_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen1_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen1_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen1_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen1_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx eax

                xor     eax,eax
                ret

; --------------------------------------------------------------------

eval_screen0:
                ; M3,M1 set, M2 reset - screen 0

                mov     actualscreen,0

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,0Fh
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,07h
                shl     eax,11
                mov     patterntable,eax

                movzx   eax,byte ptr [offset vdpregs+5]
                and     al,07Fh
                shl     eax,7
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,07h
                shl     eax,11
                mov     sprpatttable,eax
                
                push    ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,offset dirty_screen0_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen0_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen0_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen0_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen0_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen0_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx

                xor     eax,eax
                ret

; --------------------------------------------------------------------

eval_screen0_msx2:
                ; screen 0, 40 columns, MSX2 version

                mov     actualscreen,0

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,07Fh
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,03Fh
                shl     eax,11
                mov     patterntable,eax

                movzx   eax,byte ptr [offset vdpregs+5]
                and     al,07Fh
                shl     eax,7
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,07h
                shl     eax,11
                mov     sprpatttable,eax
                
                push    ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,offset dirty_screen0_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen0_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen0_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen0_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen0_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen0_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx

                xor     eax,eax
                ret

; --------------------------------------------------------------------

eval_screen0_80_msx2:
                ; screen 0, 80 columns, MSX2 version

                mov     actualscreen,0
                mov     text_columns,80

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,01111100b
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,03Fh
                shl     eax,11
                mov     patterntable,eax

                movzx   eax,byte ptr [offset vdpregs+5]
                and     al,07Fh
                shl     eax,7
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,07h
                shl     eax,11
                mov     sprpatttable,eax
                
                push    ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,offset dirty_screen0_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen0_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen0_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen0_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen0_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen0_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx

                xor     eax,eax
                ret

; --------------------------------------------------------------------

eval_screen5:
                ; screen 5

                mov     actualscreen,5

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,01100000b
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,03Fh
                shl     eax,11
                mov     patterntable,eax

                mov     al,byte ptr [offset vdpregs+5]
                mov     ah,byte ptr [offset vdpregs+11]
                and     eax,03FCh
                shl     eax,7
                ;mov     eax,0F600h
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,03Fh
                shl     eax,11
                mov     sprpatttable,eax
                
                push    ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,offset dirty_screen0_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen0_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen0_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen0_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen0_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen0_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx

                xor     eax,eax
                ret

; --------------------------------------------------------------------

eval_screen6:
                ; screen 6

                mov     actualscreen,6

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,01100000b
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,03Fh
                shl     eax,11
                mov     patterntable,eax

                mov     al,byte ptr [offset vdpregs+5]
                mov     ah,byte ptr [offset vdpregs+11]
                and     eax,03FCh
                shl     eax,7
                ;mov     eax,0F600h
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,03Fh
                shl     eax,11
                mov     sprpatttable,eax
                
                push    ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,offset dirty_screen0_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen0_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen0_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen0_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen0_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen0_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx

                xor     eax,eax
                ret

; --------------------------------------------------------------------

eval_screen7:
                ; screen 7

                mov     actualscreen,7

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,01000000b
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,03Fh
                shl     eax,11
                mov     patterntable,eax

                mov     al,byte ptr [offset vdpregs+5]
                mov     ah,byte ptr [offset vdpregs+11]
                and     eax,03FCh
                shl     eax,7
                ;mov     eax,0F600h
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,03Fh
                shl     eax,11
                mov     sprpatttable,eax
                
                push    ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,offset dirty_screen0_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen0_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen0_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen0_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen0_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen0_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx

                xor     eax,eax
                ret

; --------------------------------------------------------------------

eval_screen3:
                
                ; M3,M2 set, M1 reset - screen 3
                
                mov     actualscreen,3

                movzx   eax,byte ptr [offset vdpregs+2]
                and     al,0Fh
                shl     eax,10
                mov     nametable,eax

                movzx   eax,byte ptr [offset vdpregs+3]
                shl     eax,6
                mov     colortable,eax

                movzx   eax,byte ptr [offset vdpregs+4]
                and     al,07h
                shl     eax,11
                mov     patterntable,eax

                movzx   eax,byte ptr [offset vdpregs+5]
                and     al,07Fh
                shl     eax,7
                mov     sprattrtable,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                and     al,07h
                shl     eax,11
                mov     sprpatttable,eax
                
                push    ecx edi
                
                mov     eax,0
                mov     ecx,256/4
                mov     edi,offset vrammapping
                rep     stosd

                mov     eax,offset dirty_screen3_nothing
                mov     dword ptr [offset screenselect+0*4],eax
                mov     eax,offset dirty_screen3_name
                mov     dword ptr [offset screenselect+1*4],eax
                mov     eax,offset dirty_screen3_pattern
                mov     dword ptr [offset screenselect+2*4],eax
                mov     eax,offset dirty_screen3_color
                mov     dword ptr [offset screenselect+3*4],eax
                mov     eax,offset dirty_screen3_sprattr
                mov     dword ptr [offset screenselect+4*4],eax
                mov     eax,offset dirty_screen3_sprpatt
                mov     dword ptr [offset screenselect+5*4],eax
                
                pop     edi ecx
                xor     eax,eax
                ret

; --------------------------------------------------------------------
; these are the functions to perform dirty operations on screen 2

dirty_screen2_nothing:
                mov     [ecx+esi],bl
                ret

dirty_screen2_name:
                mov     eax,ecx
                sub     ecx,nametable
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtyname+ecx],1
                xor     eax,eax
                ret

dirty_screen2_pattern:
                mov     eax,ecx
                sub     ecx,patterntable
                mov     [eax+esi],bl
                shr     ecx,3
                xor     eax,eax
                mov     byte ptr [offset dirtypattern+ecx],1
                ret

dirty_screen2_color:
                mov     eax,ecx
                sub     ecx,colortable
                mov     [eax+esi],bl
                shr     ecx,3
                xor     eax,eax
                mov     byte ptr [offset dirtypattern+ecx],1
                ret

dirty_screen2_sprattr:                
                mov     eax,ecx
                and     eax,03h
                jnz     dirty_screen2_sprattr2
                cmp     bl,0D0h
                jne     dirty_screen2_sprattr2
                mov     firstscreen,1
                mov     [ecx+esi],bl
                mov     eax,0
                ret
dirty_screen2_sprattr2:
                mov     eax,ecx
                and     ecx,0FFFFFFFCh
                push    esi eax ecx
                add     esi,ecx
                call    eval_sprite_coords
                call    dirty_sprite
                pop     ecx eax esi
                mov     [esi+eax],bl
                add     esi,ecx
                call    eval_sprite_coords
                call    dirty_sprite
                xor     eax,eax
                ret

dirty_screen2_sprpatt:
                mov     eax,ecx
                sub     ecx,sprpatttable
                mov     [eax+esi],bl
                shr     ecx,5
                xor     eax,eax
                mov     byte ptr [offset dirtysprite+ecx],1
                ret

; --------------------------------------------------------------------
; these are the functions to perform dirty operations on screen 1

dirty_screen1_nothing:
                mov     [ecx+esi],bl
                ret

dirty_screen1_name:
                mov     eax,ecx
                sub     ecx,nametable
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtyname+ecx],1
                xor     eax,eax
                ret

dirty_screen1_pattern:
                mov     eax,ecx
                sub     ecx,patterntable
                shr     ecx,3
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtypattern+ecx],1
                xor     eax,eax
                ret

dirty_screen1_color:
                mov     eax,ecx
                sub     ecx,colortable
                shl     ecx,3
                mov     [eax+esi],bl
                mov     ebx,01010101h
                ; there is no problem because the two upper
                ; dirty pattern tables aren't used in scr1
                mov     dword ptr [offset dirtypattern+ecx],ebx
                mov     dword ptr [offset dirtypattern+ecx+4],ebx
                xor     eax,eax
                ret

dirty_screen1_sprattr:
                mov     eax,ecx
                and     eax,03h
                jnz     dirty_screen1_sprattr2
                cmp     bl,0D0h
                jne     dirty_screen1_sprattr2
                mov     firstscreen,1
                mov     [ecx+esi],bl
                ret
dirty_screen1_sprattr2:
                mov     eax,ecx
                and     ecx,0FFFFFFFCh
                push    esi eax ecx
                add     esi,ecx
                call    eval_sprite_coords
                call    dirty_sprite
                pop     ecx eax esi
                mov     [esi+eax],bl
                add     esi,ecx
                call    eval_sprite_coords
                call    dirty_sprite
                xor     eax,eax
                ret

dirty_screen1_sprpatt:
                mov     eax,ecx
                sub     ecx,sprpatttable
                shr     ecx,5
                mov     [eax+esi],bl
                mov     byte ptr [offset dirtysprite+ecx],1
                xor     eax,eax
                ret

; --------------------------------------------------------------------
; these are the functions to perform dirty operations on screen 0

dirty_screen0_nothing:
dirty_screen0_name:
dirty_screen0_color:
dirty_screen0_pattern:
dirty_screen0_sprpatt:
dirty_screen0_sprattr:
                mov     [ecx+esi],bl
                ret

; --------------------------------------------------------------------
; these are the functions to perform dirty operations on screen 3

dirty_screen3_nothing:
dirty_screen3_name:
dirty_screen3_color:
dirty_screen3_pattern:
dirty_screen3_sprpatt:
dirty_screen3_sprattr:
                mov     [ecx+esi],bl
                ret

; fill_vram_table ----------------------------------------------------
; this is like a "rep stosd" but check for overlap

fill_vram_table:
                test    ecx,3
                jnz     fill_vram_table_slow

                shr     ecx,2
fill_vram_table_fast:
                cmp     dword ptr [edi],0
                jne     fill_vram_table_overlap
                mov     dword ptr [edi],eax
                add     edi,4
                dec     ecx
                jnz     fill_vram_table_fast
                ret

fill_vram_table_slow:
                cmp     byte ptr [edi],0
                jne     fill_vram_table_overlap
                mov     byte ptr [edi],al
                inc     edi
                dec     ecx
                jnz     fill_vram_table_slow
                ret

fill_vram_table_overlap:
                mov     everyframe,1
                ret

; wash_sprite --------------------------------------------------------
; this function removes the "dirty" conditions of sprite 
; by passing the condition to the screen behind it

wash_sprite:
                mov     spr_occult,255
                mov     edx,32
                mov     esi,sprattrtable
                add     esi,msxvram
                mov     eax,0
                mov     ebx,0

wash_sprite_loop:
                cmp     byte ptr [offset dirtysprattr+ebx],1
                je      wash_sprite_now
                cmp     byte ptr [offset dirtysprattrold+ebx],1
                je      wash_sprite_now
                mov     al,[esi+2]
                shr     al,2
                cmp     byte ptr [offset dirtysprite+eax],1
                jne     wash_sprite_next

wash_sprite_now:
                push    ebx
                call    eval_sprite_coords
                call    dirty_sprite
                pop     ebx

wash_sprite_next:
                add     esi,4
                inc     ebx
                dec     edx
                jnz     wash_sprite_loop

wash_sprite_end:
                mov     edi,offset dirtysprite
                mov     eax,0
                mov     ecx,256/4
                rep     stosd
                
                ; the double buffering is used when a sprite 
                ; was occulted, but one sprite before it
                ; has moved and unocculted it
                mov     edi,offset dirtysprattrold
                mov     esi,offset dirtysprattr
                mov     ecx,32/4
                rep     movsd
                
                mov     edi,offset dirtysprattr
                mov     eax,0
                mov     ecx,32/4
                rep     stosd
                
                ret

; prepare_ocultation -------------------------------------------------
; this function init the ocultation tables
; and mark all ocultated sprites as "dirty"
; must be called before wash_sprite

prepare_ocultation:
                cmp     all_sprites,1
                je      _ret

                call    clear_sprite_buffer

                ; esi = sprite attribute table
                mov     esi,msxvram
                add     esi,sprattrtable

                ; find last sprite
                mov     ebp,32
prepare_ocultation_loop:
                mov     ah,[esi]
                cmp     ah,0D0h
                je      _ret

                call    mark_sprite

                add     esi,4
                dec     ebp
                jnz     prepare_ocultation_loop
                
                ret

; --------------------------------------------------------------------

code32          ends
                end

