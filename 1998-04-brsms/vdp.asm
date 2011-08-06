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
include blit.inc
include gui.inc
include z80.inc
include smartrep.inc
include vdp_sg.inc

extrn msxvram: dword
extrn vdpregs: near
extrn blitbuffer: dword
extrn tilecache: dword
extrn gamegear: dword
extrn sg1000: dword
extrn redbuffer: dword

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
public firstscreen
public dirtyname
public dirtypattern
public enabled
public enginetype
public force_dirty
public dirty_sprite
public yscroll
public dirty_all_sprites
public system3d
public update_oldtables
public linebyline
public refresh_line_engine
public vram_touched
public display_enabled
public dynamic_palette
public update_attr
public do_collision
public dirtysprite
public direct_palette
public update_tilecache

; DATA ---------------------------------------------------------------

align 4

include expand.inc
include expandf.inc
include sprite.inc
include render.inc

align 4

enabled         dd      1
linenumber      dd      0
patternsave     dd      0
spriteenable    dd      0
imagetype       dd      1
nametable       dd      0
colortable      dd      0
patterntable    dd      0
sprattrtable    dd      03F00h
sprpatttable    dd      0
sprpattskip     dd      0
yscroll         dd      0
bg_mask         dd      0
sprite_mask     dd      0
sprite_lines    dd      0
sprite_shift    dd      0
refresh_next    dd      0
firstscreen     dd      1
display_enabled dd      0
dirtyname       db      32*32 dup (0)
dirtypattern    db      768 dup (1)
dirtysprite     db      256 dup (0) ; 64
old_spritetable db      256 dup (0)
old_xscrollbuf  db      256 dup (0)
old_dirtysprite db      64 dup (0)
falseline       db      300 dup (0)
falseline2      db      300 dup (0)
old_yscroll     dd      0
enginetype      dd      0
wipenow         dd      1
system3d        dd      0

linebyline      dd      0
vram_touched    dd      0
local_tilecache dd      0
line_offset     dd      0

do_collision    dd      0

align 4

falsesprite     db      32*32*2 dup (0)
spritemask      db      192 dup (01Fh)
dynamic_palette db      256 dup (080h)
direct_palette  db      32*2 dup (0)


all00           dq      02020202020202020h
all10           dq      01010101010101010h
all80           dq      0A0A0A0A0A0A0A0A0h
allFF           dq      0FFFFFFFFFFFFFFFFh

lastscreen      db      0
actualscreen    db      0

align 4
update_attr     dd      1
sprite_ebx      dd      0
sprite_ecx      dd      0
sprite_esi      dd      0
sprite_ebp      dd      0

DOS_ENGINE      EQU     0
WIN_ENGINE      EQU     1
MMX_ENGINE      EQU     2

SPRITES_NORMAL  EQU     0
SPRITES_ZOOMED  EQU     1

scr2inc         dd      offset scr2undoc_table+3*12
scr2inc_color   dd      offset scr2undoc_table+3*12
scr2offset      dd      0
bitmask         db      0

scr2undoc_table: 
                ; 0 (LIKE)
                dd      0
                dd      0
                dd      0

                ; 1 (marujo)
                dd      0
                dd      800h
                dd      -800h

                ; 2 (Thing Bounces Back)
                dd      0
                dd      0
                dd      1000h

                ; 3 (common)
                dd      0
                dd      800h
                dd      800h


; force_dirty --------------------------------------------------------
; fill all the dirty tables with 1
; to ensure the next screen will all be drawed

force_dirty:
                mov     edi,offset dirtyname
                mov     ecx,32*28/4
                mov     eax,01010101h
                rep     stosd

                mov     edi,offset dirtysprite
                mov     ecx,64/4
                mov     eax,01010101h
                rep     stosd

                mov     border_updated,1
                ret

; dirty_sprite -------------------------------------------------------
; dirty a sprite and the screen behind it
; enter: esi=offset in the sprite attribute table

dirty_sprite:
                mov     eax,esi
                cmp     eax,40h
                jb      dirty_sprite_start
                sub     eax,80h
                jc      _ret
                shr     eax,1
dirty_sprite_start:
                mov     byte ptr [offset dirtysprite+eax],1
                mov     update_attr,1
                ret

; dirty_all_sprites --------------------------------------------------
; dirty all the sprites, used when a scroll register is modified

dirty_all_sprites:
                mov     wipenow,1
                mov     firstscreen,1

                push    edi
                mov     eax,01010101h
                mov     ecx,64/4
                mov     edi,offset dirtysprite
                rep     stosd
                pop     edi

                mov     eax,0
                ret

; update_oldtables ---------------------------------------------------
; copy the new dirty tables over the old ones

update_oldtables:
                mov     esi,sprattrtable 
                add     esi,msxvram
                mov     edi,offset old_spritetable
                mov     ecx,256/4
                rep     movsd

                mov     esi,offset xscrollbuf
                mov     edi,offset old_xscrollbuf
                mov     ecx,256/4
                rep     movsd

                mov     esi,offset dirtysprite
                mov     edi,offset old_dirtysprite
                mov     ecx,64/4
                rep     movsd

                ;mov     edi,offset dirtysprite
                ;mov     ecx,64/4
                ;mov     eax,0
                ;rep     stosd

                movzx   eax,byte ptr [offset vdpregs+9]
                mov     old_yscroll,eax

                ret

; wash_sprite_patterns -----------------------------------------------
; check for changes in sprite patterns and pass the dirty condition
; to the sprite's attributes

wash_sprite_patterns:
                mov     edi,0
                
                mov     esi,sprattrtable
                add     esi,msxvram
                add     esi,081h
                
                movzx   ebx,byte ptr [offset vdpregs+6]
                shr     ebx,2
                and     ebx,1
                shl     ebx,8
                
                mov     ecx,64

wash_sprites_loop:
                movzx   eax,byte ptr [esi]
                add     eax,ebx
                cmp     byte ptr [offset dirtypattern+eax],1
                sete    dl
                or      byte ptr [offset dirtysprite+edi],dl

                add     esi,2
                inc     edi
                dec     ecx
                jnz     wash_sprites_loop

                ret

; wash_sprites -------------------------------------------------------
; clean the sprites, passing its dirty condition
; to the screen behind it

wash_sprites:

                mov     esi,offset old_dirtysprite
                mov     edx,0
                mov     ecx,64

wash_sprite_outer:
                ;;;
                ;cmp     byte ptr [esi],1
                ;jne     wash_sprite_next
                ;;;

                movzx   eax,byte ptr [offset old_spritetable+edx]
                inc     eax
                cmp     eax,209
                jb      wash_sprite_positive
                movsx   eax,al
wash_sprite_positive:
                lea     ebp,[offset old_xscrollbuf+eax]
                add     eax,old_yscroll
                mov     ebx,16
wash_sprite_inner:
                cmp     eax,0
                jl      wash_sprite_skip
                cmp     eax,28*8
                jb      wash_sprite_nocrop
                sub     eax,28*8
wash_sprite_nocrop:
                push    eax
                and     eax,11111000b
                lea     edi,[offset dirtyname+eax*4]
                mov     al,byte ptr [offset old_spritetable+edx*2+80h]
                sub     al,byte ptr [ebp]
                and     eax,0FFh
                shr     eax,3
                mov     byte ptr [edi+eax],1
                inc     eax
                and     eax,11111b
                mov     byte ptr [edi+eax],1
                pop     eax
wash_sprite_skip:
                inc     eax
                inc     ebp
                dec     ebx
                jnz     wash_sprite_inner

wash_sprite_next:
                inc     edx
                inc     esi
                dec     ecx
                jnz     wash_sprite_outer

                ret

; SEARCH_SPRITE ------------------------------------------------------
; search for the last sprite in sprite attribute table
; enter: esi = start of sprite attr table

SEARCH_SPRITE   macro   exit_label
                local   L1,L2
                local   use_previous_values
                local   search_sprite_exit

                cmp     update_attr,1
                jne     use_previous_values
                
                cmp     byte ptr [esi],208
                je      exit_label

                mov     dl,[esi+040h]
                mov     ebp,7

                mov     eax,esi
                mov     byte ptr [esi+040h],208
                
                add     ebp,eax
                mov     ebx,[eax]
                add     eax,4
                xor     ebx,0D0D0D0D0h
L1:
                lea     ecx,[ebx-01010101h]
                xor     ebx,-1
                and     ecx,ebx
                mov     ebx,[eax]
                add     eax,4
                xor     ebx,0D0D0D0D0h
                and     ecx,080808080h
                jz      L1
                test    ecx,00008080h
                jnz     short L2
                shr     ecx,16
                add     eax,2
L2:
                shl     cl,1
                sbb     eax,ebp

                mov     ebp,eax
                lea     edi,[eax-1]

                mov     [esi+040h],dl

                lea     ecx,[esi+edi*2+080h]
                add     esi,edi
                lea     ebx,[edi+offset dirtysprite]

                mov     sprite_ebp,ebp
                mov     sprite_ecx,ecx
                mov     sprite_esi,esi
                mov     sprite_ebx,ebx
                mov     update_attr,0

                jmp     search_sprite_exit

use_previous_values:
                mov     ebp,sprite_ebp
                mov     ecx,sprite_ecx
                mov     esi,sprite_esi
                mov     ebx,sprite_ebx

search_sprite_exit:
               
                endm

; EVAL_Y_COORD -------------------------------------------------------
; evaluate vertical coord of a sprite
; enter: esi = sprite attr table
; exit: ebx = signed Y coord

EVAL_Y_COORD    macro   exit_label
                local   sprite_outer_positive

                ; remember to add 1 to coordinate
                movzx   ebx,byte ptr [esi]
                inc     ebx
                cmp     ebx,209
                jb      sprite_outer_positive
                movsx   ebx,bl
sprite_outer_positive:

                endm

; CHECK_SPRITE_SIZE --------------------------------------------------
; adjust the global vars to the sprite size

CHECK_SPRITE_SIZE macro                
                  local sprite_render_8
                  local sprite_render_go
                  local sprite_render_no_zoom

                test    byte ptr [offset vdpregs+1],BIT_1
                jz      sprite_render_8

                mov     sprite_mask,0FFFFFFFEh
                mov     sprite_lines,16
                jmp     sprite_render_go

sprite_render_8:
                mov     sprite_mask,0FFFFFFFFh
                mov     sprite_lines,8

sprite_render_go:
                test    byte ptr [offset vdpregs+1],BIT_0
                jz      sprite_render_no_zoom
                shl     sprite_lines,1

sprite_render_no_zoom:

                endm

; INIT_MMX_SPRITE ----------------------------------------------------
; init the MMX registers to the MMX sprite drawing routine

INIT_MMX_SPRITE macro
                
                ;movq    MM4,all00
                movq
                db      00100101b
                dd      offset all00

                ;movq    MM5,all80
                movq
                db      00101101b
                dd      offset all80

                ;movq    MM6,all10 
                movq
                db      00110101b
                dd      offset all10 

                ;movq    MM7,allFF
                movq
                db      00111101b
                dd      offset allFF

                endm

; SPRITE_DRAW_LINE_FULL ----------------------------------------------
; draw a single line of a sprite in the background
; enter: edi -> pointer to background
;        esi -> pointer to sprite

SPRITE_DRAW_LINE_FULL macro

                push    ecx
                irp     i,<0,1,2,3,4,5,6,7>
                local   sprite_draw_line_full_go
                local   sprite_draw_line_full_next

                mov     cl,[edi+i]
                cmp     cl,0A0h
                jbe     sprite_draw_line_full_go
                cmp     cl,0B0h
                jne     sprite_draw_line_full_next
sprite_draw_line_full_go:
                mov     cl,[esi+i]
                cmp     cl,020h
                jz      sprite_draw_line_full_next
                or      cl,10h
                mov     [edi+i],cl
sprite_draw_line_full_next:
                endm
                pop     ecx

                endm

; SPRITE_DRAW_LINE_FULL_MMX ------------------------------------------
; draw a single line of a sprite in the background using MMX
; enter: edi -> pointer to background
;        esi -> pointer to sprite

SPRITE_DRAW_LINE_FULL_MMX macro                
                
                ; movq MM0,[edi]         
                movq
                db      00000111b

                ; movq MM2,MM6 ;all10
                movq
                db      11010110b

                ; movq MM1,MM0
                movq
                db      11001000b

                ; pandn MM2,MM0
                pandn
                db      11010000b

                ; pcmpgtb MM1,MM7 ;allFF
                pcmpgtb
                db      11001111b

                ; pcmpeqb MM2,MM5 ;all80
                pcmpeqb
                db      11010101b

                ; movq MM3,[esi]
                movq
                db      00011110b

                ; por MM2,MM1
                por
                db      11010001b

                ; pxor MM2,MM7 ;allFF
                pxor
                db      11010111b

                ; movq MM1,MM3
                movq
                db      11001011b

                ; pcmpeqb MM1,MM4 ;all00
                pcmpeqb
                db      11001100b

                ; por MM2,MM1
                por
                db      11010001b

                ; por MM3,MM6 ;all10
                por
                db      11011110b

                ; pand MM0,MM2
                pand    
                db      11000010b

                ; pandn MM2,MM3
                pandn
                db      11010011b

                ; por MM0,MM2
                por
                db      11000010b

                ; movq [edi],MM0
                movq_st
                db      00000111b

                endm

; SPRITE_DRAW_LINE_ZOOMED --------------------------------------------
; draw a single line of a sprite in the background (zoomed)
; enter: edi -> pointer to background
;        esi -> pointer to sprite

SPRITE_DRAW_LINE_ZOOMED macro

                push    ecx
                irp     i,<0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15>
                local   sprite_draw_line_full_go
                local   sprite_draw_line_full_next

                mov     cl,[edi+i]
                cmp     cl,0A0h
                jbe     sprite_draw_line_full_go
                cmp     cl,0B0h
                jne     sprite_draw_line_full_next
sprite_draw_line_full_go:
                mov     cl,[esi+(i/2)]
                cmp     cl,020h
                jz      sprite_draw_line_full_next
                or      cl,10h
                mov     [edi+i],cl
sprite_draw_line_full_next:
                endm
                pop     ecx

                endm

; sprite_render_macro ------------------------------------------------
; draw the sprites directly on the blit buffer (macro version)

sprite_render_macro     macro engine_type
                local   sprite_outer
                local   sprite_loop
                local   sprite_draw_above
                local   sprite_draw_split
                local   sprite_nextline
                local   sprite_nofix
                local   sprite_next
                local   sprite_render_ret
                local   sprite_outer_loop
                local   sprite_outer_nocrop
                local   sprite_outer_next
                local   sprite_outer_end
                local   sprite_outer_go

                ;------- 

                if      engine_type EQ MMX_ENGINE
                  INIT_MMX_SPRITE
                endif

                ; test for screen enable
                cmp     display_enabled,1
                jne     sprite_render_ret
                
                ; test for 8x8 sprites
                CHECK_SPRITE_SIZE

                movzx   eax,byte ptr [offset vdpregs+9]
                mov     yscroll,eax
                
                movzx   eax,byte ptr [offset vdpregs+0]                
                and     eax,08h                
                mov     sprite_shift,eax

                movzx   eax,byte ptr [offset vdpregs+6]
                mov     esi,eax
                shl     eax,11
                and     eax,2000h
                add     eax,msxvram
                mov     sprpatttable,eax
                and     esi,100b
                shl     esi,6
                mov     sprpattskip,esi

                mov     esi,msxvram
                add     esi,sprattrtable 
                
                SEARCH_SPRITE sprite_render_ret

                ; at this point
                ; ebp = number of sprites to be draw
                ; ecx = start of sprite X+P table
                ; esi = start of sprite Y table 
                ; ebx = dirty sprite table

sprite_outer:
                push    ebp ecx esi ebx
                
                ;cmp     imagetype,0                
                ;je      sprite_outer_go

                ;cmp     byte ptr [ebx],0
                ;je      sprite_outer_end

sprite_outer_go:

                ;; --- 

                ; evaluate the vertical coord of sprite
                ; remember to add 1 to coordinate

                EVAL_Y_COORD sprite_outer_end   

                ; at this point ebx is a signed number

                ; contents of esi are obsolete
                ; let's make esi become the address of sprite
                ; eax will have the original horiz coord of sprite

                movzx   esi,byte ptr [ecx+1]
                and     esi,sprite_mask
                add     esi,sprpattskip
                movzx   eax,byte ptr [ecx]
                shl     esi,7
                sub     eax,sprite_shift
                jc      sprite_outer_end

                ; contents of ecx are obsolete
                ; it'll become the loop counter
                mov     ecx,0
                add     esi,tilecache

sprite_outer_loop:

                ; check if the line is on screen
                cmp     ebx,0
                mov     edi,ebx
                jl      sprite_outer_next

                ; and edi will become the address in blitbuffer
                ; now edx will have the horiz shift
                add     edi,yscroll
                movzx   edx,byte ptr [offset xscrollbuf+ebx]
                cmp     edi,28*8
                jl      sprite_outer_nocrop
                sub     edi,28*8
sprite_outer_nocrop:
                sal     edi,8
                add     edi,blitbuffer

                ; at last, draw the line
                cmp     eax,edx                           
                jae     sprite_draw_above

                lea     ebp,[eax+8]
                cmp     ebp,edx
                ja      sprite_draw_split

                lea     edi,[edi+eax+256]
                sub     edi,edx
                if      engine_type EQ MMX_ENGINE
                  SPRITE_DRAW_LINE_FULL_MMX
                else
                  SPRITE_DRAW_LINE_FULL
                endif
                jmp     sprite_outer_next

sprite_draw_split:
                call    sprite_draw_line_split
                jmp     sprite_outer_next

sprite_draw_above:
                add     edi,eax
                sub     edi,edx
                if      engine_type EQ MMX_ENGINE
                  SPRITE_DRAW_LINE_FULL_MMX
                else
                  SPRITE_DRAW_LINE_FULL
                endif

sprite_outer_next:
                inc     ebx
                cmp     ebx,28*8
                jge     sprite_outer_end

                add     esi,dword ptr [offset sprite_table+ecx*4]
                
                inc     ecx
                cmp     ecx,sprite_lines
                jne     sprite_outer_loop

sprite_outer_end:
                ;; ---

                pop     ebx esi ecx ebp
                dec     esi
                sub     ecx,2
                dec     ebx
                dec     ebp
                jnz     sprite_outer

sprite_render_ret:
                mov     ecx,64/4
                mov     edi,offset dirtysprite
                mov     eax,0
                rep     stosd
                ret

                endm

; sprite_render ------------------------------------------------------
; draw the sprites directly on the blit buffer

align 4

sprite_render:
                cmp     sg1000,1
                je      sprite_render_msx
                
                cmp     linebyline,1
                je      _ret
                
                cmp     enginetype,2
                je      sprite_render_MMX

                sprite_render_macro DOS_ENGINE

sprite_render_MMX:
                sprite_render_macro MMX_ENGINE
                
; --------------------------------------------------------------------
                
sprite_draw_line_split:
                push    ecx edi
                ; first step
                mov     ecx,edx 
                sub     ecx,eax 
                push    edi
                lea     edi,[edi+eax+256] 
                sub     edi,edx 
sprite_draw_line_split_loop1:
                mov     ch,[edi]
                ;
                cmp     ch,0A0h
                jbe     sprite_draw_line_split_loop1_go
                cmp     ch,0B0h
                jne     sprite_draw_line_split_loop1_skip
sprite_draw_line_split_loop1_go:
                mov     ch,[esi]
                cmp     ch,020h
                jz      sprite_draw_line_split_loop1_skip
                or      ch,10h
                mov     [edi],ch
                ;
sprite_draw_line_split_loop1_skip:
                ;
                inc     edi
                inc     esi
                dec     cl
                jnz     sprite_draw_line_split_loop1
                ; second step
                pop     edi
                lea     ecx,[eax+8]
                sub     ecx,edx
sprite_draw_line_split_loop2:
                mov     ch,[edi]
                ;
                cmp     ch,0A0h
                jbe     sprite_draw_line_split_loop2_go
                cmp     ch,0B0h
                jne     sprite_draw_line_split_loop2_skip
sprite_draw_line_split_loop2_go:
                ;
                mov     ch,[esi]
                cmp     ch,020h
                jz      sprite_draw_line_split_loop2_skip
                or      ch,10h
                mov     [edi],ch
                ;
sprite_draw_line_split_loop2_skip:
                ;
                inc     edi
                inc     esi
                dec     cl
                jnz     sprite_draw_line_split_loop2
                pop     edi ecx
                sub     esi,8
                ret

; render -------------------------------------------------------------
; render the SMS screen, based on VDP registers and VRAM
; this version is video cache optimized

render:
                ; check for SG1000 emulation
                cmp     sg1000,1                
                je      render_msx

                cmp     linebyline,1
                je      _ret

                call    check_top_score
                call    check_shift_8
                call    refresh_raster

                cmp     imagetype,0
                je      render_nocache

                cmp     display_enabled,1
                jne     render_off

                call    wash_sprites
                call    wash_sprite_patterns
                call    update_oldtables
                call    wash_sprites
                call    update_tilecache

                cmp     enabled,0
                jne     render_was_enabled_before

                mov     edi,offset dirtyname
                mov     ecx,32*28/4
                mov     eax,01010101h
                rep     stosd
                mov     firstscreen,1

render_was_enabled_before:                
                mov     enabled,1
                mov     edi,blitbuffer
                mov     esi,msxvram
                add     esi,nametable
                mov     ecx,offset dirtyname
                mov     ebx,28
render_screen:
                mov     ebp,32
render_line:
                mov     al,byte ptr [ecx]
                or      al,al
                jnz     render_drawchar
                
                movzx   eax,word ptr [esi]
                and     eax,01FFh
                cmp     byte ptr [offset dirtypattern+eax],1
                je      render_drawchar

render_next:                
                add     esi,2
                add     edi,8
                inc     ecx
                dec     ebp
                jnz     render_line

                add     edi,256*8-32*8
                dec     ebx
                jnz     render_screen

                mov     edi,offset dirtypattern
                mov     ecx,512/4
                mov     eax,0
                rep     stosd

                ret

; --------------------------------------------------------------------

render_drawchar:
                push    ecx ebx
                
                ; dirty the name table
                mov     byte ptr [ecx],1
                
                movzx   ecx,byte ptr [esi+1]
                movzx   edx,byte ptr [esi]

                shl     edx,7
                mov     ebx,[offset render_table+ecx*8+4]
                add     edx,tilecache
                mov     eax,[offset render_table+ecx*8]
                add     edx,ebx
                test    ecx,BIT_2
                jnz     render_yflip

                irp     i,<0,1,2,3,4,5,6,7>
                mov     ebx,[edx+i*8]
                mov     ecx,[edx+i*8+4]
                or      ebx,eax
                or      ecx,eax
                mov     [edi+i*256],ebx
                mov     [edi+i*256+4],ecx
                endm
                jmp     render_continue

render_yflip:
                irp     i,<0,1,2,3,4,5,6,7>
                mov     ebx,[edx+(7-i)*8]
                mov     ecx,[edx+(7-i)*8+4]
                or      ebx,eax
                or      ecx,eax
                mov     [edi+i*256],ebx
                mov     [edi+i*256+4],ecx
                endm

render_continue:
                pop     ebx ecx
                jmp     render_next

render_off:
                mov     edi,offset dirtyname
                mov     eax,01010101h
                mov     ecx,32*28/4
                rep     stosd
                jmp     render_off_nocache

; render_nocache -----------------------------------------------------
; render the SMS screen, based on VDP registers and VRAM
; video cache is disabled in this renderer

render_nocache:
                cmp     display_enabled,1
                jne     render_off_nocache

                call    update_tilecache
                mov     enabled,1
                mov     edi,blitbuffer
                mov     esi,msxvram
                add     esi,nametable
                mov     ecx,offset dirtyname
                mov     ebx,28
render_screen_nocache:
                mov     ebp,32
render_line_nocache:
                jmp     render_drawchar_nocache

render_next_nocache:                
                add     esi,2
                add     edi,8
                inc     ecx
                dec     ebp
                jnz     render_line_nocache

                add     edi,256*8-32*8
                dec     ebx
                jnz     render_screen_nocache

                mov     edi,offset dirtypattern
                mov     ecx,512/4
                mov     eax,0
                rep     stosd

                ret

render_drawchar_nocache:
                push    ecx ebx
                mov     byte ptr [ecx],0
                movzx   ecx,byte ptr [esi+1]
                movzx   edx,byte ptr [esi]

                shl     edx,7
                mov     ebx,[offset render_table+ecx*8+4]
                add     edx,tilecache
                mov     eax,[offset render_table+ecx*8]
                add     edx,ebx
                test    ecx,BIT_2
                jnz     render_yflip_nocache

                irp     i,<0,1,2,3,4,5,6,7>
                mov     ebx,[edx+i*8]
                mov     ecx,[edx+i*8+4]
                or      ebx,eax
                or      ecx,eax
                mov     [edi+i*256],ebx
                mov     [edi+i*256+4],ecx
                endm
                jmp     render_continue_nocache

render_yflip_nocache:
                irp     i,<0,1,2,3,4,5,6,7>
                mov     ebx,[edx+(7-i)*8]
                mov     ecx,[edx+(7-i)*8+4]
                or      ebx,eax
                or      ecx,eax
                mov     [edi+i*256],ebx
                mov     [edi+i*256+4],ecx
                endm

render_continue_nocache:
                pop     ebx ecx
                jmp     render_next_nocache

; --------------------------------------------------------------------

render_off_nocache:
                cmp     wipenow,0
                je      _ret

                mov     wipenow,0
                mov     edi,blitbuffer
                mov     eax,010101010h
                mov     ecx,256*(28*8)/4
                rep     stosd
                mov     firstscreen,1
                mov     enabled,0
                ret

; clear --------------------------------------------------------------
; clear the blit buffer
                
clear:
                mov     eax,0
                mov     edi,blitbuffer
                mov     ecx,320*200/4
                rep     stosd

                cmp     videomode,0
                jne     _ret

                mov     eax,0
                mov     edi,0A0000h
                sub     edi,_code32a
                mov     ecx,320*200/4
                rep     stosd

                ret

; update_tilecache ---------------------------------------------------
; update the tile cache by redrawing every changed character

update_tilecache:
                cmp     wipenow,0
                jne     update_tilecache_go

update_tilecache_go:
                mov     wipenow,1
                
                cmp     vram_touched,1
                jne     _ret

                mov     edx,offset expansion  
                mov     ebx,0
                mov     ebp,256+256
                mov     ecx,offset dirtypattern
                mov     esi,msxvram
                mov     edi,tilecache

update_tilecache_loop:
                cmp     dword ptr [ecx],0
                jne     update_tilecache_check

                add     edi,128*4
                add     esi,4*8*4
                add     ecx,4
                sub     ebp,4
                jnz     update_tilecache_loop
                ret

update_tilecache_check:
                irp     i,<0,1,2,3>
                local   update_tilecache_next

                cmp     byte ptr [ecx],1
                jne     update_tilecache_next

                call    update_tilecache_draw

update_tilecache_next:
                add     edi,128
                add     esi,4*8
                inc     ecx
                dec     ebp

                endm

                jnz     update_tilecache_loop
                ret

update_tilecache_draw:

                push    ecx ebp
                
                mov     edx,offset expansion
                movzx   ecx,byte ptr [esi]
                irp     i,<0,1,2,3,4,5,6,7>
                mov     bl,[esi+1+i*4]
                mov     eax,[edx+ecx*8]
                mov     ebp,[edx+ecx*8+4]
                mov     cl,[esi+2+i*4]
                or      eax,[edx+ebx*8+2048*1]
                or      ebp,[edx+ebx*8+4+2048*1]
                mov     bl,[esi+3+i*4]
                or      eax,[edx+ecx*8+2048*2]
                or      ebp,[edx+ecx*8+4+2048*2]
                if      (i LT 7)
                mov     cl,[esi+(i+1)*4]
                endif
                or      eax,[edx+ebx*8+2048*3]
                or      ebp,[edx+ebx*8+4+2048*3]
                mov     [edi+i*8],eax
                mov     [edi+4+i*8],ebp
                endm

                mov     edx,offset expansion_flipped

                mov     cl,byte ptr [esi]
                irp     i,<0,1,2,3,4,5,6,7>
                mov     bl,[esi+1+i*4]
                mov     eax,[edx+ecx*8]
                mov     ebp,[edx+ecx*8+4]
                mov     cl,[esi+2+i*4]
                or      eax,[edx+ebx*8+2048*1]
                or      ebp,[edx+ebx*8+4+2048*1]
                mov     bl,[esi+3+i*4]
                or      eax,[edx+ecx*8+2048*2]
                or      ebp,[edx+ecx*8+4+2048*2]
                if      (i LT 7)
                mov     cl,[esi+(i+1)*4]
                endif
                or      eax,[edx+ebx*8+2048*3]
                or      ebp,[edx+ebx*8+4+2048*3]
                mov     [edi+i*8+64],eax
                mov     [edi+4+i*8+64],ebp
                endm

                pop     ebp ecx

                mov     eax,linebyline
                xor     eax,1
                and     byte ptr [ecx],al

                ret

                
; check_top_score ----------------------------------------------------
; check if the top 2 lines should be static

check_top_score:                
                test    byte ptr [offset vdpregs+0],BIT_6
                jz      _ret

                mov     eax,0
                irp     i,<0,1,2,3>
                mov     dword ptr [offset xscrollbuf+i*4],eax
                endm
                ret

; check_shift_8 ------------------------------------------------------
; disable video cache if the "shift 8 pixels" bit is enabled

check_shift_8:
                test    byte ptr [offset vdpregs+0],BIT_3
                jz      _ret

                mov     firstscreen,1
                mov     edi,offset dirtyname
                mov     eax,01010101h
                mov     ecx,32*28/4
                rep     stosd
                ret

; refresh_raster -----------------------------------------------------
; force the entire screen to redraw if:
; (1) a raster scroll effect happened in this frame
; (2) a raster scroll effect happened in the last frame

refresh_raster:
                cmp     refresh_next,1
                jne     refresh_raster_check
                
                mov     refresh_next,0
                mov     firstscreen,1

refresh_raster_check:
                cmp     raster_scroll,1
                jne     _ret

                mov     refresh_next,1
                mov     firstscreen,1
                mov     raster_scroll,0

                ret

; update_one_tile ----------------------------------------------------
; update a single tile from the tilecache
; enter esi = tile

update_one_tile:
                pushad
                
                lea     ecx,[offset dirtypattern+esi]

                mov     edx,offset expansion  
                mov     ebx,0

                mov     edi,esi
                shl     edi,7
                add     edi,tilecache

                shl     esi,5
                add     esi,msxvram

                call    update_tilecache_draw

                popad
                ret

; DRAW_FALSE_LINE ----------------------------------------------------
; draw a single line pointed by esi in the falseline

DRAW_FALSE_LINE macro
                local   draw_false_line_loop
                local   draw_false_line_noflip

                mov     edx,esi
                and     edx,0FFFFFFF8h
                shl     edx,3
                add     edx,nametable
                add     edx,msxvram

                mov     ebx,esi
                and     ebx,7
                shl     ebx,3

                mov     ecx,32

draw_false_line_loop:
                movzx   esi,byte ptr [edx]
                movzx   ebp,byte ptr [edx+1]
                mov     eax,ebx

                shl     esi,7
                add     esi,tilecache

                test    ebp,BIT_2
                jz      draw_false_line_noflip
                xor     eax,7*8
draw_false_line_noflip:
                add     esi,eax

                mov     eax,dword ptr [offset render_table+ebp*8+4]
                mov     ebp,dword ptr [offset render_table+ebp*8]
                add     esi,eax
                
                mov     eax,[esi]
                or      eax,ebp
                mov     [edi],eax
                mov     eax,[esi+4]
                or      eax,ebp
                add     edx,2
                mov     [edi+4],eax

                add     edi,8
                dec     ecx
                jnz     draw_false_line_loop

                endm

; DRAW_ALL_SPRITES ---------------------------------------------------
; draw all the sprites

DRAW_ALL_SPRITES macro engine,sprite_cond
                local draw_all_sprites_outer
                local draw_all_sprites_next
                local draw_all_sprites_tryagain

draw_all_sprites_outer:

                mov     eax,currentline
                
                EVAL_Y_COORD draw_all_sprites_next

                sub     eax,ebx
                jl      draw_all_sprites_next
                cmp     eax,sprite_lines
                jge     draw_all_sprites_next

                push    esi edi

                movzx   esi,byte ptr [ecx]
                add     edi,esi
                
                movzx   esi,byte ptr [ecx+1]
                and     esi,sprite_mask
                shl     esi,7
                
                if      (sprite_cond EQ SPRITES_NORMAL)
                  mov     eax,[offset sprite_line_raster+eax*4]
                else
                  mov     eax,[offset sprite_line_zoomed+eax*4]
                endif                  
                
                add     esi,local_tilecache
                add     esi,eax

                if      (sprite_cond EQ SPRITES_ZOOMED)
                  SPRITE_DRAW_LINE_ZOOMED
                else
                  if      (engine EQ MMX_ENGINE)
                    SPRITE_DRAW_LINE_FULL_MMX                
                  else
                    SPRITE_DRAW_LINE_FULL                
                  endif
                endif

                pop     edi esi

draw_all_sprites_next:
                sub     ecx,2
                dec     esi
                dec     ebp
                jnz     draw_all_sprites_outer

                endm

; DRAW_ALL_SPRITES_ENGINE --------------------------------------------
; select a video engine and draw all the sprites

DRAW_ALL_SPRITES_ENGINE macro sprite_cond
                local   draw_all_sprites_mmx
                local   draw_all_sprites_exit
                
                cmp     enginetype,2
                je      draw_all_sprites_mmx

                DRAW_ALL_SPRITES DOS_ENGINE sprite_cond

                jmp     draw_all_sprites_exit

draw_all_sprites_mmx:

                DRAW_ALL_SPRITES MMX_ENGINE sprite_cond

draw_all_sprites_exit:

                endm

; LOAD_X_SCROLL ------------------------------------------------------
; load the x scroll value into eax
; taking into account the top score

LOAD_X_SCROLL   macro
                local   load_x_scroll_exit

                ; x scroll
                movzx   eax,byte ptr [offset vdpregs+8]
                
                ; check for top score
                test    byte ptr [offset vdpregs+0],BIT_6
                jz      load_x_scroll_exit

                cmp     currentline,16
                jae     load_x_scroll_exit

                mov     eax,0

load_x_scroll_exit:

                endm

; refresh_line_engine ------------------------------------------------
; core of the line by line engine
; draw a single line on blitbuffer

refresh_line_engine:
                cmp     gamegear,1                
                je      refresh_line_engine_gamegear
                
                cmp     currentline,192
                jae     _ret
                
                jmp     refresh_line_engine_start

refresh_line_engine_gamegear:
                cmp     currentline,168
                jae     _ret

                cmp     currentline,24
                jb      _ret
                
refresh_line_engine_start:                
                pushad

; --------------------------------------------------------------------
; save border color

                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                or      eax,010h
                mov     edx,currentline
                movzx   ebx,byte ptr [offset dynamic_palette+eax]
                mov     byte ptr [offset bordercolor+edx],bl

; --------------------------------------------------------------------
; update the tile cache and draw the background

                test    byte ptr [offset vdpregs+1],BIT_6
                jz      refresh_line_engine_video_disabled
                
                call    update_tilecache

                mov     edi,offset falseline

                ; yscroll
                movzx   eax,byte ptr [offset vdpregs+9]

                mov     esi,currentline
                add     esi,eax
                cmp     esi,28*8
                jb      refresh_line_engine_nowrap
                sub     esi,28*8
refresh_line_engine_nowrap:

                DRAW_FALSE_LINE

                ; copy false line to final destination

; --------------------------------------------------------------------
; evaluate the correct X scroll position

                LOAD_X_SCROLL                

; --------------------------------------------------------------------
; perform the copy from falseline to blitbuffer
; taking the X scroll into account

                mov     edi,currentline
                mov     esi,offset falseline
                shl     edi,8
                add     esi,256
                add     edi,blitbuffer
                sub     esi,eax
                mov     line_offset,edi

                mov     ecx,eax
                SMART_REP

                mov     esi,offset falseline
                mov     ecx,256
                sub     ecx,eax
                SMART_REP
                
; --------------------------------------------------------------------
; draw the right score if needed
                
                test    byte ptr [offset vdpregs+0],BIT_7
                jz      refresh_line_engine_no_right_score

                mov     edi,offset falseline
                mov     esi,currentline
                DRAW_FALSE_LINE
                
                LOAD_X_SCROLL
                
                mov     esi,offset falseline
                add     esi,256
                sub     esi,eax
                mov     edi,offset falseline2

                mov     ecx,eax
                SMART_REP

                mov     esi,offset falseline
                mov     ecx,256
                sub     ecx,eax
                SMART_REP
                
                mov     edi,line_offset
                mov     esi,offset falseline2+(32-8)*8
                add     edi,(32-8)*8
                mov     ecx,(8*8)/4
                rep     movsd

refresh_line_engine_no_right_score:     

; --------------------------------------------------------------------
; draw the sprites

                cmp     enginetype,2
                jne     refresh_line_engine_init_nommx

                INIT_MMX_SPRITE

refresh_line_engine_init_nommx:
                
                CHECK_SPRITE_SIZE

                movzx   esi,byte ptr [offset vdpregs+5]
                and     esi,07Eh
                shl     esi,7
                add     esi,msxvram
                
                SEARCH_SPRITE refresh_line_engine_no_sprites
                
                ; at this point
                ; ebp = number of sprites to be draw
                ; ecx = start of sprite X+P table
                ; esi = start of sprite Y table 
                ; ebx = dirty sprite table

                movzx   eax,byte ptr [offset vdpregs+6]
                and     eax,BIT_2
                mov     edi,line_offset
                shl     eax,6+7
                add     eax,tilecache
                mov     local_tilecache,eax

                test    byte ptr [offset vdpregs+1],BIT_0
                jnz     refresh_line_engine_zoomed
                
                DRAW_ALL_SPRITES_ENGINE SPRITES_NORMAL
                jmp     refresh_line_engine_no_sprites

refresh_line_engine_zoomed:                

                DRAW_ALL_SPRITES_ENGINE SPRITES_ZOOMED

refresh_line_engine_no_sprites:

; --------------------------------------------------------------------
; convert the palette to fixed values (raster palette effects)
; works only in SMS mode

                cmp     palette_raster,1
                jne     convert_palette_exit

                cmp     direct_color,1
                je      convert_palette_exit
                
                mov     esi,line_offset
                mov     ecx,256/4/4

convert_palette_loop:
                irp     i,<0,4,8,12>
                mov     edx,dword ptr [esi+i]
                mov     ebx,edx
                shr     edx,16
                movzx   edi,dh
                movzx   ebp,bh
                mov     al,byte ptr [offset dynamic_palette+edi]
                movzx   edi,dl
                shl     eax,8
                mov     al,byte ptr [offset dynamic_palette+edi]
                shl     eax,8
                mov     al,byte ptr [offset dynamic_palette+ebp]
                movzx   ebp,bl
                shl     eax,8
                mov     al,byte ptr [offset dynamic_palette+ebp]
                mov     dword ptr [esi+i],eax
                endm
                add     esi,16
                dec     ecx
                jnz     convert_palette_loop

convert_palette_exit:

; --------------------------------------------------------------------
; disable the leftmost column if needed
                
                test    byte ptr [offset vdpregs+0],BIT_5
                jz      disable_leftmost_exit

                cmp     direct_color,1
                jne     disable_leftmost_raster

                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                or      eax,10h
                mov     ah,al
                mov     ebx,eax
                shl     eax,16
                or      eax,ebx
                mov     edi,line_offset
                mov     dword ptr [edi],eax
                mov     dword ptr [edi+4],eax
                jmp     disable_leftmost_exit

disable_leftmost_raster:

                cmp     palette_raster,1
                jne     disable_leftmost_paletted
                
                mov     edi,currentline
                movzx   eax,byte ptr [offset bordercolor+edi]
                mov     ah,al
                mov     ebx,eax
                shl     eax,16
                or      eax,ebx
                mov     edi,line_offset
                mov     dword ptr [edi],eax
                mov     dword ptr [edi+4],eax
                jmp     disable_leftmost_exit

disable_leftmost_paletted:

                mov     edi,line_offset
                mov     eax,0
                mov     dword ptr [edi],eax
                mov     dword ptr [edi+4],eax

disable_leftmost_exit:

; --------------------------------------------------------------------
; convert the palette to direct color

                cmp     direct_color,1
                jne     direct_color_exit
                
                mov     esi,line_offset
                mov     ecx,256/2/8
                mov     edi,currentline
                shl     edi,9
                add     edi,redbuffer
                mov     eax,0

direct_color_loop:
                irp     i,<0,1,2,3,4,5,6,7>
                movzx   edx,byte ptr [esi+i*2+1]
                movzx   eax,byte ptr [esi+i*2]
                and     edx,01Fh
                and     eax,01Fh
                movzx   ebx,word ptr [offset direct_palette+eax*2]
                movzx   eax,word ptr [offset direct_palette+edx*2]
                shl     eax,16
                or      ebx,eax
                mov     dword ptr [edi+i*4],ebx
                endm
                add     esi,8*2
                add     edi,8*4
                dec     ecx
                jnz     direct_color_loop

                cmp     gamegear,1
                jne     direct_color_exit

                mov     eax,0
                mov     edi,currentline
                shl     edi,9
                add     edi,redbuffer
                mov     ecx,(48/4)*2
                rep     stosd
                add     edi,160*2
                mov     ecx,(48/4)*2
                rep     stosd

direct_color_exit:

; --------------------------------------------------------------------
; check sprite collision

                cmp     do_collision,1
                jne     check_sprite_collision_exit
                
                mov     edi,offset falseline
                mov     ecx,(256+8)/8
                mov     eax,0
                rep     stosd

                SEARCH_SPRITE check_sprite_collision_exit

check_sprite_collision_loop:
                mov     eax,currentline
                
                EVAL_Y_COORD check_sprite_collision_next

                sub     eax,ebx
                jl      check_sprite_collision_next
                cmp     eax,sprite_lines
                jge     check_sprite_collision_next

                push    esi edi

                movzx   esi,byte ptr [ecx]
                add     edi,esi
                
                movzx   esi,byte ptr [ecx+1]
                and     esi,sprite_mask
                shl     esi,7
                
                add     esi,local_tilecache
                add     esi,eax

                mov     eax,dword ptr [edi]
                and     eax,dword ptr [esi]
                test    eax,20202020h
                jnz     collision_detected
                mov     eax,dword ptr [edi+4]
                and     eax,dword ptr [esi+4]
                test    eax,20202020h
                jz      collision_not_detected

collision_detected:
                mov     collision_found,BIT_5
collision_not_detected:
                mov     eax,dword ptr [esi]
                mov     dword ptr [edi],eax
                mov     eax,dword ptr [esi+4]
                mov     dword ptr [edi+4],eax

                pop     edi esi

check_sprite_collision_next:
                sub     ecx,2
                dec     esi
                dec     ebp
                jnz     check_sprite_collision_loop

check_sprite_collision_exit:

; --------------------------------------------------------------------
; mark the vram as untouched and exit
                
                mov     vram_touched,0
                
                popad
                ret

; --------------------------------------------------------------------
; draw a blank line when the video is disabled
                
refresh_line_engine_video_disabled:
                cmp     direct_color,1
                je      refresh_line_engine_video_disabled_direct

                cmp     palette_raster,1
                je      refresh_line_engine_video_disabled_raster

                mov     edi,currentline
                mov     eax,0
                shl     edi,8
                mov     ecx,256/4
                add     edi,blitbuffer

                rep     stosd

                popad   
                ret

refresh_line_engine_video_disabled_direct:
                mov     edi,currentline
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                or      eax,10h
                movzx   eax,word ptr [offset direct_palette+eax*2]
                mov     ebx,eax
                shl     eax,16
                or      eax,ebx
                shl     edi,9
                mov     ecx,512/4
                add     edi,redbuffer

                rep     stosd

                cmp     gamegear,1
                jne     refresh_line_engine_video_disabled_exit

                mov     eax,0
                sub     edi,512
                mov     ecx,48*2/4
                rep     stosd
                add     edi,160*2
                mov     ecx,48*2/4
                rep     stosd

refresh_line_engine_video_disabled_exit:
                popad   
                ret

refresh_line_engine_video_disabled_raster:
                mov     edi,currentline
                movzx   eax,byte ptr [offset bordercolor+edi]
                mov     ah,al
                mov     ebx,eax
                shl     eax,16
                or      eax,ebx
                mov     edi,currentline
                shl     edi,8
                mov     ecx,256/4
                add     edi,blitbuffer
                rep     stosd
                popad
                ret


code32          ends
                end
