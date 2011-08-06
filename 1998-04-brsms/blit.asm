; --------------------------------------------------------------------
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: BLIT.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include pentium.inc
include pmode.inc
include vdp.inc
include io.inc
include vesa.inc
include bit.inc
include smartrep.inc
include blit_sg.inc
include gui.inc
include mouse.inc

extrn blitbuffer: dword
extrn redbuffer: dword
extrn bluebuffer: dword
extrn lcdbuffer: dword
extrn gamegear: dword
extrn staticbuffer: dword
extrn sg1000: dword
extrn __2xSaIBitmap__FPUiPUs: near

public blit
public xscrollbuf
public init_skip_buffer
public clear_left_column
public border_updated
public noborder
public palette_raster
public palette_sg1000
public direct_color
public bordercolor
public blit_linear_512_15_branch
public blit_linear_512_inter_branch
public blit_linear_512_2xsai_branch
public lightgun
public lcdfilter

; DATA ---------------------------------------------------------------

include monopal.inc

align 4

xscroll         dd      0

; these tables must be consecutive !!
xscrollbuf      db      512 dup (0)
xskipbuf        db      512 dup (0)
fakeline        db      256 dup (0)
my3dpalette     db      256 dup (0)
bordercolor     db      256 dup (0)

red_blue        dd      0
left_column     dd      0
palette_sg1000  dd      0
palette_sms     dd      0
palette_raster  dd      0
direct_color    dd      0
border_updated  dd      0
noborder        dd      1
lightgun        dd      0
lightcolor      dd      0
lcdfilter       dd      0

align 4

all40           dq      04040404040404040h
all3DEF         dq      03DEF3DEF3DEF3DEFh
all0000         dq      00000000000000000h
all0001         dq      00001000100010001h
all0002         dq      00002000200020002h
allFFFE         dq      0FFFEFFFEFFFEFFFEh
allFFFC         dq      0FFFCFFFCFFFCFFFCh
all0006         dq      00006000600060006h

fantasma        db      0-8,2-8,4-8,6-8,8-8,10-8,12-8,14-8
                db      16-8,14-8,12-8,10-8,8-8,6-8,4-8,2-8

gg_enabled:
                db      24 dup (0)
                db      144 dup (1)
                db      24 dup (0)

SYSTEM_SMS      EQU     0
SYSTEM_GG       EQU     1  

ENGINE_DOS      EQU     0
ENGINE_MMX      EQU     1
ENGINE_2XSAI    EQU     2

RES_320         EQU     0
RES_512         EQU     1
RES_400         EQU     2
RES_512_15      EQU     3

TABLE_DIFF      EQU     ((offset xskipbuf)-(offset xscrollbuf))

; CODE ---------------------------------------------------------------

; clear_left_column --------------------------------------------------
; clear the left column of the screen (used in h-scrolling games)

clear_left_column:
                cmp     linebyline,1
                je      _ret

                test    byte ptr [offset vdpregs+0],BIT_5
                jnz     clear_left_column_check

                mov     left_column,1
                ret

clear_left_column_check:
                cmp     left_column,0
                je      _ret

                mov     left_column,0
                
                cmp     videomode,2
                je      clear_left_column_vesa

                push    edi
                mov     eax,0
                mov     edi,0a0000h+32+4*320
                sub     edi,_code32a
                mov     ecx,192
                cmp     bargraphmode,1
                jne     clear_left_column_loop
                mov     ecx,192-7*8-1
                mov     edi,0a0000h+32+(7*8+1)*320+4*320
                sub     edi,_code32a
clear_left_column_loop:
                mov     [edi],eax
                mov     [edi+4],eax
                add     edi,320
                dec     ecx
                jnz     clear_left_column_loop
                pop     edi
                ret

clear_left_column_vesa:
                push    edi
                mov     eax,0
clear_left_column_vesa_outer: 
                call    set_vesa_bank
                mov     ecx,64
                mov     edi,0A0000h
                sub     edi,_code32a
                mov     ebx,0
                mov     esi,0
                cmp     eax,0
                jne     clear_left_column_vesa_loop
                cmp     bargraphmode,1
                jne     clear_left_column_vesa_loop
                mov     edi,0A0000h+(7*8+1)*1024
                sub     edi,_code32a
                mov     ecx,64-7*8-1
clear_left_column_vesa_loop:
                irp     i,<0,1,2,3>
                mov     [edi+i*4],ebx
                mov     [edi+i*4+512],esi
                endm
                add     edi,512*2
                dec     ecx
                jnz     clear_left_column_vesa_loop
                inc     eax
                cmp     eax,3
                jne     clear_left_column_vesa_outer
                pop     edi
                ret

; init_skip_buffer -------------------------------------------------
; init the skip buffer

init_skip_buffer:
                cmp     linebyline,1
                je      _ret

                ; X skip buffer
                mov     eax,0
                test    byte ptr [offset vdpregs+0],BIT_5
                jz      init_skip_buffer_nocrop
                mov     eax,08080808h
init_skip_buffer_nocrop:
                mov     edi,offset xskipbuf
                mov     ecx,256/4
                rep     stosd
                cmp     bargraphmode,1
                jne     _ret

                mov     ecx,7*8/4
                mov     eax,0
                mov     edi,offset xskipbuf
                rep     stosd
                mov     byte ptr [offset xskipbuf+7*8],0

                ret

; blit ---------------------------------------------------------------
; copy the contents of blit buffer to pentium video memory

blit:              
                cmp     sg1000,1
                je      blit_msx

                call    flush_border
                call    flush_palette
                call    clear_left_column
                call    draw_lightgun_cursor
                call    blit_engine
                call    clear_dirtytables
                ret

; clear_dirtytables --------------------------------------------------
; clear all the dirty tables after drawing the screen

clear_dirtytables:
                mov     edi,offset dirtyname
                mov     eax,0
                mov     ecx,32*28/4
                rep     stosd
                ret

; draw_lightgun_cursor -----------------------------------------------

draw_lightgun_cursor:
                cmp     lightgun,1
                jne     _ret
                
                mov     edi,mousey
                add     edi,8
                shl     edi,8
                add     edi,mousex
                add     edi,10

                cmp     videomode,4
                je      draw_lightgun_cursor_direct
                cmp     videomode,6
                je      draw_lightgun_cursor_direct
                cmp     videomode,8
                je      draw_lightgun_cursor_direct

                add     edi,blitbuffer
                mov     byte ptr [edi],0
                mov     eax,lightcolor
                add     eax,1
                and     eax,3
                or      eax,080h
                mov     lightcolor,eax
                irp     i,<-1,+1,-256,+256>
                mov     byte ptr [edi+i],al
                endm
                ret

draw_lightgun_cursor_direct:
                shl     edi,1
                add     edi,redbuffer
                mov     word ptr [edi],0
                mov     eax,lightcolor
                mov     eax,lightcolor
                add     eax,4
                and     eax,11111b
                mov     lightcolor,eax
                shl     eax,10
                irp     i,<-1,+1,-256,+256>
                mov     word ptr [edi+i*2],ax
                endm
                ret

; flush_palette ------------------------------------------------------
; update the palette before drawing the next frame

FLUSH_PAL_MACRO macro   system
                local   flush_palette_loop
                local   flush_palette_next
                
                mov     ebx,0
flush_palette_loop:
                cmp     byte ptr [offset dirty_palette+ebx],0
                je      flush_palette_next

                mov     byte ptr [offset dirty_palette+ebx],0
                if      system EQ SYSTEM_SMS
                  irp     i,<020h,060h,0A0h,0E0h>
                    mov     eax,ebx
                    or      eax,i
                    call    set_SMS_color
                  endm
                else
                  irp     i,<020h,060h,0A0h,0E0h>
                    mov     eax,ebx
                    or      eax,i
                    call    set_GG_color
                  endm
                endif

flush_palette_next:
                inc     ebx
                cmp     ebx,32
                jne     flush_palette_loop
                ret

                endm

flush_palette:
                cmp     videomode,4
                je      _ret

                cmp     videomode,6
                je      _ret

                cmp     videomode,8
                je      _ret

                cmp     palette_raster,1
                je      flush_palette_raster
                
                cmp     gamegear,1
                je      flush_palette_gg

                FLUSH_PAL_MACRO SYSTEM_SMS

flush_palette_gg:
                FLUSH_PAL_MACRO SYSTEM_GG

flush_palette_raster:
                cmp     palette_sms,1
                je      _ret

                mov     palette_sms,1
                jmp     set_SMS_palette

; flush_border -------------------------------------------------------

EXPAND_COLOR    macro

                mov     ah,al
                mov     ebx,eax
                shl     eax,16
                or      eax,ebx

                endm

flush_border:
                cmp     turnedoff,1                
                je      _ret

                cmp     noborder,1
                je      _ret

                cmp     videomode,0
                jne     _ret

                cmp     gamegear,1
                je      _ret

                cmp     sg1000,1
                je      _ret

                mov     edi,0A0000h
                sub     edi,_code32a
                movzx   eax,byte ptr [offset bordercolor]
                EXPAND_COLOR
                mov     ecx,(4*320)/4
                rep     stosd

                mov     ebp,0
                mov     edi,0A0000h+4*320
                sub     edi,_code32a
                mov     esi,offset bordercolor
flush_border_loop:
                movzx   eax,byte ptr [esi]
                inc     esi
                EXPAND_COLOR
                mov     ecx,32/4
                rep     stosd
                add     edi,256
                mov     ecx,32/4
                rep     stosd

                inc     ebp
                cmp     ebp,192
                jne     flush_border_loop
                
                mov     edi,0A0000h+(4+192)*320
                sub     edi,_code32a
                movzx   eax,byte ptr [offset bordercolor+191]
                EXPAND_COLOR
                mov     ecx,(4*320)/4
                rep     stosd

                ret

; blit ---------------------------------------------------------------

blit_engine:
                cmp     videomode,4
                je      blit_linear_512_inter_branch

                cmp     videomode,6
                je      blit_linear_512_15_branch

                cmp     videomode,8
                je      blit_linear_512_2xsai_branch

                call    video_vsync
                
                cmp     videomode,0
                je      blit_linear_320_branch

                cmp     videomode,1
                je      blit_linear_gg_400

                cmp     videomode,2
                je      blit_linear_512_branch

                ret

; linear 320x192 -----------------------------------------------------

blit_linear_512_branch:
                cmp     system3d,1
                je      blit_linear_3d
                
                cmp     linebyline,1
                je      blit_linebyline_512

                jmp     blit_linear_512

; draw eigth pixels in the screen using MMX --------------------------

OCTO_PIXEL      macro   resolution
                
                ;movq    MM0,[esi]
                movq
                db      00000110b

                ;movq    MM1,MM0
                movq
                db      11001000b

                ;movq    MM2,MM0
                movq
                db      11010000b

                ;punpcklbw MM0,MM1
                punpcklbw                
                db      11000001b

                ;movq    MM3,MM2
                movq
                db      11011010b

                ;movq_st  [edi],MM0
                movq_st
                db      00000111b

                ;punpckhbw MM2,MM3
                punpckhbw
                db      11010011b

                if      resolution EQ RES_512
                  ;por     MM0,MM4
                  por
                  db      11000100b
                endif

                ;movq_st  [edi+8],MM2
                movq_st
                db      10010111b
                dd      8
                
                if      resolution EQ RES_512
                  ;movq_st  [edi+512],MM0
                  movq_st
                  db      10000111b
                  dd      512
                
                  ;por     MM2,MM4
                  por     
                  db      11010100b

                else
                  ;movq_st  [edi+400],MM0
                  movq_st
                  db      10000111b
                  dd      400
                endif

                add     esi,8
                
                if      resolution EQ RES_512
                  ;movq_st  [edi+512+8],MM2
                  movq_st
                  db      10010111b
                  dd      512+8
                else
                  ;movq_st  [edi+400+8],MM2
                  movq_st
                  db      10010111b
                  dd      400+8
                endif

                add     edi,16

                endm

; draw one pixel in the screen ---------------------------------------

SINGLE_PIXEL    macro   resolution

                mov     al,[esi]
                mov     ah,al
                inc     esi
                mov     [edi],ax
                or      ax,4040h
                if      resolution EQ RES_512
                  mov     [edi+512],ax
                else
                  mov     [edi+400],ax
                endif
                add     edi,2
               
               endm

; draw two pixels in the screen --------------------------------------

DOUBLE_PIXEL    macro   resolution

                mov     al,[esi+1]
                mov     ah,al
                shl     eax,16
                mov     al,[esi]
                mov     ah,al
                add     esi,2
                mov     [edi],eax
                or      eax,40404040h
                if      resolution EQ RES_512
                  mov     [edi+512],eax
                else
                  mov     [edi+400],eax
                endif
                add     edi,4
               
               endm

; draw a unaligned slice of screen -----------------------------------

DRAW_LINEAR_SLICE macro engine,resolution
                local   small_loop
                local   do_nothing
                local   direct_color_loop
                local   label_exit

                if      resolution EQ RES_320
                  SMART_REP
                endif

                if      resolution EQ RES_512_15
                cmp     ecx,0
                je      label_exit
                
                push    ebx edx eax
                shr     ecx,1
                jnc     direct_color_loop
                inc     esi
                add     edi,2
direct_color_loop:
                mov     dword ptr [edi],07FFF7FFFh
                add     esi,2
                add     edi,4
                dec     ecx
                jnz     direct_color_loop
                pop    eax edx ebx
label_exit:
                endif

                if      resolution EQ RES_512

                  if engine EQ ENGINE_DOS
                  rept 1
                local   scale_2
                local   scale_out
                  

                  cmp     ecx,0
                  je      do_nothing

                  push    eax
                  
                  shr     ecx,1
                  jnc     scale_2
                  
                  SINGLE_PIXEL resolution
scale_2:
                  cmp     ecx,0
                  je      scale_out

small_loop:                  
                  DOUBLE_PIXEL resolution
                  dec     ecx                  
                  jnz     small_loop

scale_out:
                  pop    eax

                endm
                  else
                  rept 1
                local   scale_2
                local   scale_4
                local   scale_8
                local   scale_out
                  
                  cmp     ecx,0
                  je      do_nothing

                  push    eax
                  
                  shr     ecx,1
                  jnc     scale_2
                  SINGLE_PIXEL resolution
scale_2:
                  cmp     ecx,0
                  je      scale_out

                  shr     ecx,1
                  jnc     scale_4
                  DOUBLE_PIXEL resolution
scale_4:
                  cmp     ecx,0
                  je      scale_out

                  shr     ecx,1
                  jnc     scale_8
                  DOUBLE_PIXEL resolution
                  DOUBLE_PIXEL resolution
scale_8:
                  cmp     ecx,0
                  je      scale_out

small_loop:
                  OCTO_PIXEL resolution
                  dec     ecx
                  jnz     small_loop
scale_out:
                  pop    eax

                endm
                  endif
                
                endif
do_nothing:                

                endm

; linear 320x192 -----------------------------------------------------

blit_linear_320_branch:
                cmp     system3d,1
                je      blit_linear_3d
                
                cmp     linebyline,1
                je      blit_linebyline

                cmp     gamegear,1
                je      blit_linear_gg
                
                cmp     imagetype,1
                je      blit_dirty_320

                jmp     blit_linear_320

; linear 320x192 3D --------------------------------------------------

blit_linear_3d:
                call    build_3d_palette
                
                cmp     linebyline,1
                jne     blit_linear_3d_block 

                mov     eax,0
                mov     edi,offset xscrollbuf
                mov     ecx,256/4
                rep     stosd

blit_linear_3d_block:
                mov     esi,blitbuffer
                movzx   ebx,byte ptr [offset vdpregs+9]
                mov     eax,offset xscrollbuf
                cmp     ebx,28*8
                jb      blit_linear_3d_start
                sub     ebx,28*8
blit_linear_3d_start:
                mov     ecx,ebx
                shl     ecx,8
                add     esi,ecx

                call    select_color_buffer
                
                mov     edx,0
blit_linear_3d_0:
                push    eax edx
                movzx   eax,byte ptr [eax]
                ;
                movzx   edx,byte ptr [offset xskipbuf+edx]
                ;
                mov     ecx,eax
                add     esi,256
                mov     ebp,ecx
                sub     esi,eax
                ;
                cmp     ecx,edx
                jb      blit_linear_3d_skipline
                add     esi,edx
                add     edi,edx
                sub     ecx,edx
                ;
                shr     ecx,2
                and     ebp,3
                rep     movsd
                or      ebp,ebp
                jz      blit_3d_skip1
                mov     ecx,ebp
                SMART_REP
blit_3d_skip1:
                mov     ecx,256
                sub     esi,256
                sub     ecx,eax
                mov     ebp,ecx
                shr     ecx,2
                and     ebp,3
                rep     movsd
                or      ebp,ebp
                jz      blit_3d_skip2
                mov     ecx,ebp
                SMART_REP
blit_3d_skip2:
                add     esi,eax
                inc     ebx
                ;add     edi,64
                cmp     ebx,28*8
                jne     blit_linear_3d_1
                mov     ebx,0
                mov     esi,blitbuffer
blit_linear_3d_1:
                pop     edx eax
                inc     eax
                inc     edx
                cmp     edx,192
                jne     blit_linear_3d_0
                jmp     blit_blit_3d

blit_linear_3d_skipline:
                sub     esi,256-8
                mov     ecx,(256-8)/4
                add     edi,8
                rep     movsd
                jmp     blit_3d_skip2

blit_blit_3d:
                xor     red_blue,1                
                jz      _ret

                mov     esi,bluebuffer
                mov     ebx,redbuffer
                mov     edi,0a0000h+32+4*320
                sub     edi,_code32a
                mov     ecx,192
                mov     ebp,offset smspalette
                mov     edx,offset mono_palette
blit_blit_3d_loop:
                push    ecx
                mov     ecx,255
                mov     eax,0

blit_blit_3d_loop_loop:
                mov     al,[esi]
                and     al,01fh
                inc     edi
                mov     al,[eax+ebp]
                inc     esi
                mov     ch,[eax+edx]
                mov     al,[ebx]
                and     al,01fh
                inc     ebx
                mov     al,[eax+ebp]
                shl     ch,4
                mov     al,[eax+edx]
                or      al,ch
                mov     ch,0
                dec     ecx
                mov     [edi-1],al
                jns     blit_blit_3d_loop_loop

                pop     ecx

                add     edi,64
                dec     ecx
                jnz     blit_blit_3d_loop
                ret

select_color_buffer:                
                cmp     red_blue,1
                je      select_color_buffer_red
                mov     edi,bluebuffer
                ret

select_color_buffer_red:
                mov     edi,redbuffer
                ret

build_3d_palette:
                mov     ecx,256
                mov     esi,offset smspalette
                mov     edi,offset my3dpalette
                mov     eax,0

build_3d_palette_loop:
                mov     al,[esi]
                inc     esi
                mov     al,[eax+offset mono_palette]
                mov     [edi],al
                inc     edi
                dec     ecx
                jnz     build_3d_palette_loop

                ret

; linear 320x192 GAME GEAR VERSION -----------------------------------

blit_linear_gg:
                mov     esi,blitbuffer
                movzx   ebx,byte ptr [offset vdpregs+9]
                add     ebx,24
                mov     eax,offset xscrollbuf
                add     eax,24
                cmp     ebx,28*8
                jb      blit_linear_gg_start
                sub     ebx,28*8
blit_linear_gg_start:
                mov     ecx,ebx
                shl     ecx,8
                add     esi,ecx

                mov     edi,0a0000h+32+24*320+48
                sub     edi,_code32a
                mov     edx,24
blit_linear_gg_0:
                push    eax edx
                movzx   eax,byte ptr [eax]
                ;
                cmp     eax,48+160
                jae     blit_linear_gg_skipline2
                ;
                mov     ecx,eax
                add     esi,256
                sub     esi,eax
                ;
                cmp     ecx,48
                jb      blit_linear_gg_skipline
                ;

                push    esi
                sub     ecx,48
                add     esi,48
                SMART_REP       

                mov     ecx,160+48
                sub     ecx,eax
                sub     esi,256
                SMART_REP
                pop     esi


blit_gg_skip2:
                add     esi,eax
                inc     ebx
                add     edi,64+48+48
                cmp     ebx,28*8
                jne     blit_linear_gg_1
                mov     ebx,0
                mov     esi,blitbuffer
blit_linear_gg_1:
                pop     edx eax
                inc     eax
                inc     edx
                cmp     edx,192-24
                jne     blit_linear_gg_0
                
                cmp     bargraphmode,1
                je      draw_cpugraph_gg
                ret

blit_linear_gg_skipline:
                sub     esi,256-48
                mov     ecx,160/4 
                rep     movsd
                add     esi,48
                jmp     blit_gg_skip2

blit_linear_gg_skipline2:
                push    esi
                sub     esi,eax
                add     esi,256+48
                mov     ecx,160/4 
                rep     movsd
                pop     esi
                mov     eax,256
                jmp     blit_gg_skip2

; linear 400x300 GAME GEAR VERSION -----------------------------------

blit_linear_gg_400:
                movzx   ebx,byte ptr [offset vdpregs+9]
                cmp     linebyline,1
                jne     blit_linear_gg_400_block
                mov     edi,offset xscrollbuf
                mov     eax,0
                mov     ecx,192/4
                rep     stosd
                mov     ebx,0
blit_linear_gg_400_block:                
                mov     esi,blitbuffer
                add     ebx,24
                mov     eax,offset xscrollbuf
                add     eax,24
                cmp     ebx,28*8
                jb      blit_linear_gg_start_400
                sub     ebx,28*8
blit_linear_gg_start_400:
                mov     ecx,ebx
                shl     ecx,8
                add     esi,ecx

                mov     edi,redbuffer ;0a0000h+32+24*320+48
                ;sub     edi,_code32a
                mov     edx,24
blit_linear_gg_0_400:
                push    eax edx
                movzx   eax,byte ptr [eax]
                ;
                cmp     eax,48+160
                jae     blit_linear_gg_skipline2_400
                ;
                mov     ecx,eax
                add     esi,256
                sub     esi,eax
                ;
                cmp     ecx,48
                jb      blit_linear_gg_skipline_400
                ;

                push    esi
                sub     ecx,48
                add     esi,48
                SMART_REP       

                mov     ecx,160+48
                sub     ecx,eax
                sub     esi,256
                SMART_REP
                pop     esi


blit_gg_skip2_400:
                add     esi,eax
                inc     ebx
                add     edi,0 ;64+48+48
                cmp     ebx,28*8
                jne     blit_linear_gg_1_400
                mov     ebx,0
                mov     esi,blitbuffer
blit_linear_gg_1_400:
                pop     edx eax
                inc     eax
                inc     edx
                cmp     edx,192-24
                jne     blit_linear_gg_0_400
                
                jmp     blit_linear_gg_400_draw

blit_linear_gg_skipline_400:
                sub     esi,256-48
                mov     ecx,160/4 
                rep     movsd
                add     esi,48
                jmp     blit_gg_skip2_400

blit_linear_gg_skipline2_400:
                push    esi
                sub     esi,eax
                add     esi,256+48
                mov     ecx,160/4 
                rep     movsd
                pop     esi
                mov     eax,256
                jmp     blit_gg_skip2_400


DRAW_SLICE      macro
                local   inner_loop
inner_loop:
                mov     al,[esi+1]
                mov     ah,al
                shl     eax,16
                mov     al,[esi]
                mov     ah,al
                mov     [edi],eax
                add     esi,2
                add     edi,4
                dec     ecx
                jnz     inner_loop

                endm

blit_linear_gg_400_draw:
                irp     i,<0,1>
                local   blit_linear_gg_400_draw_loop
                local   blit_linear_gg_400_draw_inner
                local   blit_linear_gg_400_draw_inner_2
                local   blit_linear_gg_400_draw_inner_mmx
                local   blit_linear_gg_400_draw_continue
                
                mov     eax,i
                call    set_vesa_bank

                if      i EQ 1
                  mov     esi,redbuffer
                  add     esi,160*78+148
                  mov     edi,0A0000h
                  sub     edi,_code32a
                  mov     ecx,12/2
                  DRAW_SLICE
                endif

                if      i EQ 0
                  mov     ebx,78
                  mov     esi,redbuffer
                  mov     edi,0A0000h+40+6*400
                else
                  mov     ebx,65
                  mov     esi,redbuffer
                  add     esi,160*79
                  mov     edi,0A0000h+64+40
                endif
                sub     edi,_code32a

blit_linear_gg_400_draw_loop:
                mov     ebp,160/4
                cmp     enginetype,2
                je      blit_linear_gg_400_draw_inner_mmx
                
blit_linear_gg_400_draw_inner:
                mov     ecx,[esi]
                mov     al,ch
                mov     ah,ch
                shl     eax,16
                mov     al,cl
                mov     ah,cl
                mov     [edi],eax
                mov     [edi+400],eax
                shr     ecx,16
                mov     al,ch
                mov     ah,ch
                shl     eax,16
                mov     al,cl
                mov     ah,cl
                mov     [edi+4],eax
                mov     [edi+404],eax
                add     esi,4
                add     edi,8

                dec     ebp
                jnz     blit_linear_gg_400_draw_inner

                add     edi,480
                dec     ebx
                jnz     blit_linear_gg_400_draw_loop

                jmp     blit_linear_gg_400_draw_continue

blit_linear_gg_400_draw_inner_mmx:                
                OCTO_PIXEL RES_400
                sub     ebp,2
                jnz     blit_linear_gg_400_draw_inner_mmx
                
                add     edi,480
                dec     ebx
                jnz     blit_linear_gg_400_draw_loop

blit_linear_gg_400_draw_continue:
                
                if      i EQ 0

                mov     ecx,160/2
                DRAW_SLICE
                sub     esi,160
                mov     ecx,148/2
                add     edi,80
                DRAW_SLICE

                endif

                endm

                cmp     bargraphmode,1
                jne     _ret

                mov     eax,0
                call    set_vesa_bank
                mov     ebx,7*8+1
                mov     esi,staticbuffer
                mov     edi,0A0000h
                sub     edi,_code32a

draw_cpugraph_gg_loop2:
                mov     ecx,(6*8+4)/4
                rep     movsd
                add     esi,256-(6*8+4)
                add     edi,400-(6*8+4)
                dec     ebx
                jnz     draw_cpugraph_gg_loop2

                ret

; draw_cpugraph_gg ---------------------------------------------------

draw_cpugraph_gg:
                mov     ebx,7*8+1
                mov     esi,staticbuffer
                mov     edi,0A0000h+32
                sub     edi,_code32a

draw_cpugraph_gg_loop:
                mov     ecx,(6*8+4)/4
                rep     movsd
                add     esi,256-(6*8+4)
                add     edi,320-(6*8+4)
                dec     ebx
                jnz     draw_cpugraph_gg_loop

                ret

; dirty  320x192 -----------------------------------------------------

blit_dirty_320:
                cmp     system3d,1
                je      blit_linear_3d
                
                cmp     gamegear,1
                je      blit_linear_gg
                
                cmp     firstscreen,1
                je      blit_linear_320
                
                mov     esi,offset dirtyname
                mov     ecx,0
                mov     ebp,blitbuffer

                movzx   ebx,byte ptr [offset vdpregs+9]
                cmp     ebx,28*8
                jb      blit_dirty_320_below
                sub     ebx,28*8
blit_dirty_320_below:
                mov     yscroll,ebx

blit_dirty_320_outer:
                mov     edx,0

blit_dirty_320_inner:
                mov     al,[esi]
                cmp     al,0
                jne     blit_dirty_320_draw

blit_dirty_320_next:
                add     ebp,8
                inc     esi
                inc     edx
                cmp     edx,32
                jnz     blit_dirty_320_inner

                add     ebp,256*8-32*8
                inc     ecx
                cmp     ecx,28
                jnz     blit_dirty_320_outer

                ret

; --------------------------------------------------------------------

blit_dirty_320_draw:
                lea     eax,[ecx*8]
                sub     eax,yscroll
                jns     blit_dirty_320_draw_below
                add     eax,28*8
blit_dirty_320_draw_below:
                cmp     eax,24*8-7
                jae     blit_outside_320_draw

                push    ecx esi

                lea     esi,[offset xscrollbuf+eax]

                lea     edi,[eax+eax*4] 
                shl     edi,6 
                add     edi,0A0000h+32+4*320
                sub     edi,_code32a

                mov     ecx,0
blit_dirty_drawchar_loop:
                push    ebp edx
                shl     edx,3
                movzx   eax,byte ptr [esi]                
                add     edx,eax
                and     edx,255
                cmp     edx,256-8
                jae     blit_dirty_drawchar_slow
                cmp     edx,8
                jb      blit_dirty_drawchar_slow

                mov     eax,[ebp]
                mov     ebx,[ebp+4]
                mov     [edi+edx],eax
                mov     [edi+edx+4],ebx

blit_dirty_drawchar_skip:
                pop     edx ebp
                add     edi,320
                add     ebp,256
                inc     esi
                inc     ecx
                cmp     ecx,8
                jnz     blit_dirty_drawchar_loop
                sub     ebp,8*256

                pop     esi ecx
                jmp     blit_dirty_320_next

; --------------------------------------------------------------------

blit_dirty_drawchar_slow:
                push    ebp edx

                dec     dl
                mov     ebx,8

blit_dirty_drawchar_slow_loop:
                inc     dl
                cmp     dl,byte ptr [esi+TABLE_DIFF]
                jb      blit_dirty_drawchar_slow_skip
                mov     al,[ebp]
                mov     [edi+edx],al
blit_dirty_drawchar_slow_skip:
                inc     ebp
                dec     ebx
                jnz     blit_dirty_drawchar_slow_loop

                pop     edx ebp
                jmp     blit_dirty_drawchar_skip

; --------------------------------------------------------------------

blit_outside_320_draw:
                push    esi ecx
                lea     eax,[ecx*8]
                dec     eax
                mov     ebx,0

blit_outside_320_outer:
                inc     eax
                push    eax

                sub     eax,yscroll
                jns     blit_outside_320_draw_below
                add     eax,28*8
blit_outside_320_draw_below:
                
                cmp     eax,24*8
                jae     blit_outside_drawchar_next

                push    ebx edx

                lea     esi,[offset xscrollbuf+eax]

                lea     edi,[eax+eax*4] 
                shl     edi,6 
                add     edi,0A0000h+32+4*320
                sub     edi,_code32a

                shl     edx,3
                movzx   eax,byte ptr [esi]                
                add     edx,eax
                and     edx,255
                cmp     edx,256-8
                jae     blit_outside_drawchar_slow
                cmp     edx,8
                jb      blit_outside_drawchar_slow

                mov     eax,[ebp]
                mov     ebx,[ebp+4]
                mov     [edi+edx],eax
                mov     [edi+edx+4],ebx

blit_outside_drawchar_skip:
                pop     edx ebx

blit_outside_drawchar_next:
                pop     eax

                add     ebp,256
                inc     ebx
                cmp     ebx,8
                jnz     blit_outside_320_outer
                sub     ebp,8*256

                pop     ecx esi
                jmp     blit_dirty_320_next

; --------------------------------------------------------------------

blit_outside_drawchar_slow:
                push    ebp edx

                dec     dl
                mov     ebx,8

blit_outside_drawchar_slow_loop:
                inc     dl
                cmp     dl,byte ptr [esi+TABLE_DIFF]
                jb      blit_outside_drawchar_slow_skip
                mov     al,[ebp]
                mov     [edi+edx],al
blit_outside_drawchar_slow_skip:
                inc     ebp
                dec     ebx
                jnz     blit_outside_drawchar_slow_loop

                pop     edx ebp
                jmp     blit_outside_drawchar_skip

; draw a single line in the screen -----------------------------------

DRAW_SINGLE_LINE_320 macro engine
                local   small_loop

                if      engine EQ ENGINE_MMX

small_loop:                
                  ; movq MM0,[esi]
                  movq
                  db      00000110b

                  add   esi,8

                  ; movq_st [edi],MM0
                  movq_st
                  db      00000111b

                  add   edi,8
                  sub   ecx,2
                  jnz   small_loop

                else
                  rep     movsd
                endif

                endm

; draw a single line in the screen using pixel replication -----------

DRAW_SINGLE_LINE_512 macro engine
                local   small_loop_dos
                local   small_loop_mmx

                if      engine EQ ENGINE_DOS

                shl     ecx,1

small_loop_dos:
                mov     al,[esi+1]
                mov     ah,al
                shl     eax,16
                mov     al,[esi]
                mov     ah,al
                mov     [edi],eax
                or      eax,40404040h
                mov     [edi+512],eax
                add     esi,2
                add     edi,4

                dec     ecx
                jnz     small_loop_dos

                else

                ;movq    MM4,all40
                movq
                db      00100101b
                dd      offset all40

small_loop_mmx:
                OCTO_PIXEL RES_512
                sub     ecx,2
                jnz     small_loop_mmx

                endif

                endm

; generic linebyline engine ------------------------------------------

LINEBYLINE      macro   system,engine,resolution
                local   blit_linebyline_loop
                local   outer_loop

                if      resolution EQ RES_512
                  mov     ebp,0
                  mov     esi,blitbuffer
                endif

outer_loop:                
                if      resolution EQ RES_320
                  if      system EQ SYSTEM_SMS
                    mov     edi,0A0000h+32+4*320
                    sub     edi,_code32a
                    mov     esi,blitbuffer
                    mov     ebx,192
                  else
                    mov     edi,0A0000h+32+24*320+48
                    sub     edi,_code32a
                    mov     esi,blitbuffer
                    add     esi,24*256+48
                    mov     ebx,144 
                  endif
                else
                  mov     edi,0A0000h
                  sub     edi,_code32a
                  mov     ebx,192/3
                  mov     eax,ebp      
                  call    set_vesa_bank
                endif

blit_linebyline_loop:
                if      system EQ SYSTEM_SMS
                  mov     ecx,256/4
                else
                  mov     ecx,160/4
                endif

                if      resolution EQ RES_320
                  DRAW_SINGLE_LINE_320 engine
                else
                  DRAW_SINGLE_LINE_512 engine
                endif

                if      resolution EQ RES_320
                  if      system EQ SYSTEM_SMS
                    add     edi,64
                  else
                    add     edi,320-160 
                    add     esi,256-160
                  endif
                else
                  add   edi,512
                endif

                dec     ebx
                jnz     blit_linebyline_loop

                if      resolution EQ RES_512
                  inc     ebp
                  cmp     ebp,3
                  jne     outer_loop
                endif

                if      system EQ SYSTEM_GG
                  cmp     bargraphmode,1
                  je      draw_cpugraph_gg
                endif

                ret

                endm

; linebyline engine for 320x200 --------------------------------------

blit_linebyline:
                cmp     gamegear,1
                je      blit_linebyline_gamegear

                cmp     enginetype,2
                je      blit_linebyline_sms_mmx

                LINEBYLINE SYSTEM_SMS,ENGINE_DOS,RES_320

blit_linebyline_sms_mmx:

                LINEBYLINE SYSTEM_SMS,ENGINE_MMX,RES_320

blit_linebyline_gamegear:
                cmp     enginetype,2
                je      blit_linebyline_gg_mmx

                LINEBYLINE SYSTEM_GG,ENGINE_DOS,RES_320

blit_linebyline_gg_mmx:
                
                LINEBYLINE SYSTEM_GG,ENGINE_MMX,RES_320

; linebyline engine for 512x384 --------------------------------------

blit_linebyline_512:

                cmp     enginetype,2
                je      blit_linebyline_512_mmx

                LINEBYLINE SYSTEM_SMS,ENGINE_DOS,RES_512

blit_linebyline_512_mmx:
                
                LINEBYLINE SYSTEM_SMS,ENGINE_MMX,RES_512

; generic linear engine ----------------------------------------------

BLIT_LINEAR     macro   engine,resolution
                local   blit_linear_start
                local   blit_linear_loop
                local   blit_linear_overflow
                local   blit_linear_skipline
                local   blit_linear_continue
                local   blit_linear_outer
                
                mov     firstscreen,0
                
                if      engine EQ ENGINE_MMX
                  ;movq    MM4,all40
                  movq
                  db      00100101b
                  dd      offset all40
                endif
                
                mov     esi,blitbuffer
                movzx   ebx,byte ptr [offset vdpregs+9]
                mov     eax,offset xscrollbuf
                cmp     ebx,28*8
                jb      blit_linear_start
                sub     ebx,28*8
blit_linear_start:
                mov     ecx,ebx
                shl     ecx,8
                add     esi,ecx

                if      resolution EQ RES_512
                  mov     ebp,0
                endif

blit_linear_outer:
                if      resolution EQ RES_512
                  mov     edi,0a0000h
                  sub     edi,_code32a
                  mov     edx,0
                  push    eax
                  mov     eax,ebp
                  call    set_vesa_bank
                  pop     eax
                endif
                if      resolution EQ RES_320
                  mov     edi,0a0000h+32+4*320
                  sub     edi,_code32a
                  mov     edx,0
                endif
                if      resolution EQ RES_512_15
                  mov     edi,redbuffer
                  mov     edx,0
                endif
blit_linear_loop:
                push    eax edx
                movzx   eax,byte ptr [eax]
                ;
                if      resolution EQ RES_512
                  push    ebp
                  shl     ebp,6
                  movzx   edx,byte ptr [offset xskipbuf+edx+ebp]
                  pop     ebp
                else
                  movzx   edx,byte ptr [offset xskipbuf+edx]
                endif
                ;
                mov     ecx,eax
                add     esi,256
                sub     esi,eax
                ;
                cmp     ecx,edx
                jb      blit_linear_skipline

                add     esi,edx
                if      resolution EQ RES_320
                  add     edi,edx
                else
                  lea     edi,[edi+edx*2]
                endif
                sub     ecx,edx
                
                DRAW_LINEAR_SLICE engine,resolution
                
                mov     ecx,256
                sub     esi,256
                sub     ecx,eax
                
                DRAW_LINEAR_SLICE engine,resolution

blit_linear_continue:
                add     esi,eax
                inc     ebx
                
                if      resolution EQ RES_320
                  add     edi,64
                endif
                if      resolution EQ RES_512
                  add     edi,512
                endif
                
                cmp     ebx,28*8
                jne     blit_linear_overflow
                mov     ebx,0
                mov     esi,blitbuffer
blit_linear_overflow:

                pop     edx eax
                inc     eax
                inc     edx
                if      resolution EQ RES_512
                  cmp     edx,192/3
                else
                  cmp     edx,192
                endif
                jne     blit_linear_loop

                if      resolution EQ RES_512
                  inc     ebp
                  cmp     ebp,3
                  jne     blit_linear_outer
                endif

                ret

blit_linear_skipline:
                sub     esi,256-8
                mov     ecx,256-8
                if      resolution EQ RES_320
                  add     edi,8
                else
                  add     edi,8+8
                endif
                DRAW_LINEAR_SLICE engine,resolution
                jmp     blit_linear_continue

                endm

; linear 320x192 -----------------------------------------------------

blit_linear_320:                
                cmp     enginetype,2
                je      blit_linear_320_mmx
                
                BLIT_LINEAR ENGINE_DOS,RES_320

blit_linear_320_mmx:

                BLIT_LINEAR ENGINE_MMX,RES_320

; linear 512x384 -----------------------------------------------------

blit_linear_512:                
                cmp     enginetype,2
                je      blit_linear_512_mmx
                
                BLIT_LINEAR ENGINE_DOS,RES_512

blit_linear_512_mmx:

                BLIT_LINEAR ENGINE_MMX,RES_512

; AVERAGE_CORE -------------------------------------------------------
; core of the bilinear filtering

AVERAGE_CORE    macro engine

                if      engine EQ ENGINE_DOS

                mov     eax,dword ptr [esi]
                mov     ebx,eax
                mov     edx,eax
                and     eax,111101111011110b
                shr     edx,16
                and     edx,111101111011110b
                add     eax,edx
                shl     eax,15
                and     ebx,0FFFFh
                or      ebx,eax
                mov     dword ptr [edi],ebx

                push    ebx
                mov     eax,dword ptr [esi+512]
                mov     ebx,eax
                mov     edx,eax
                and     eax,111101111011110b
                shr     edx,16
                and     edx,111101111011110b
                add     eax,edx
                shl     eax,15
                and     ebx,0FFFFh
                or      eax,ebx

                and     eax,1111011110111100111101111011110b
                shr     eax,1
                pop     ebx
                and     ebx,1111011110111100111101111011110b
                shr     ebx,1
                add     ebx,eax

                add     esi,2
                mov     dword ptr [edi+1024],ebx
                add     edi,4
                dec     ecx

                else

                ; start here

                ; movq MM0,[esi]
                movq
                db      00000110b

                ; movq MM2,MM0
                movq                     
                db      11010000b

                ; movq MM1,[esi+2]
                movq
                db      10001110b
                dd      2

                ; psrlq MM2,1
                psrlq   
                db      11010010b
                db      1
                
                ; movq MM4,[esi+512]
                movq
                db      10100110b
                dd      512

                ; psrlq MM1,1
                psrlq
                db      11010001b
                db      1

                ; movq MM6,MM4
                movq                     
                db      11110100b

                ; pand MM1,MM3 
                pand
                db      11001011b

                ; movq MM5,[esi+2+512]
                movq
                db      10101110b
                dd      2+512

                ; pand MM2,MM3 
                pand
                db      11010011b

                ; psrlq MM5,1
                psrlq
                db      11010101b
                db      1

                ; paddw MM1,MM2
                paddw
                db      11001010b
                
                ; psrlq MM6,1
                psrlq   
                db      11010110b
                db      1
                
                ; pand MM5,MM3 
                pand
                db      11101011b

                ; pand MM6,MM3 
                pand
                db      11110011b

                ; movq MM2,MM0
                movq
                db      11010000b

                ; paddw MM5,MM6
                paddw
                db      11101110b
                
                ; punpcklwd MM0,MM1
                punpcklwd                
                db      11000001b

                ; movq_st [edi],MM0
                movq_st
                db      00000111b

                ; punpckhwd MM2,MM1
                punpckhwd
                db      11010001b

                ; movq_st [edi+8],MM2
                movq_st
                db      10010111b
                dd      8

                ; movq MM6,MM4
                movq
                db      11110100b

                ; punpcklwd MM4,MM5
                punpcklwd                
                db      11100101b

                ; punpckhwd MM6,MM5
                punpckhwd
                db      11110101b

                ; psrlq MM0,1
                psrlq
                db      11010000b
                db      1

                ; psrlq MM2,1
                psrlq
                db      11010010b
                db      1

                ; pand MM0,MM3 
                pand
                db      11000011b

                ; psrlq MM4,1
                psrlq   
                db      11010100b
                db      1
                
                ; pand MM2,MM3 
                pand
                db      11010011b

                ; psrlq MM6,1
                psrlq   
                db      11010110b
                db      1
                
                ; pand MM4,MM3 
                pand
                db      11100011b

                ; pand MM6,MM3 
                pand
                db      11110011b

                ; paddw MM0,MM4
                paddw
                db      11000100b
                
                add     edi,16
                
                ; paddw MM2,MM6
                paddw
                db      11010110b
                
                add     esi,8
                
                ; movq_st [edi+1024-16],MM0
                movq_st
                db      10000111b
                dd      1024-16

                sub     ecx,4
                
                ; movq_st [edi+1024+8-16],MM2
                movq_st
                db      10010111b
                dd      1024+8-16

                endif

                endm

; CHECK --------------------------------------------------------------
; load a value in ebx depending on the pixel and its neighbours

CHECK           macro   value
                local   check_equal
                local   check_exit

                je      check_equal
                add     ebx,value
                jmp     check_exit
check_equal:
                sub     ebx,value
check_exit:
                endm

; nonlinear_filter ---------------------------------------------------
; apply the nonlinear filter in the image

nonlinear_filter:
                cmp     enginetype,2
                je      nonlinear_filter_mmx

; nonlinear_filter_dos -----------------------------------------------

nonlinear_filter_dos:
                mov     esi,redbuffer
                mov     edi,bluebuffer

                mov     ecx,256*192

nonlinear_filter_loop:
                movzx   eax,word ptr [esi]
                mov     ebx,0

                cmp     ax,word ptr [esi+2]
                CHECK   2

                cmp     ax,word ptr [esi-2]
                CHECK   2

                cmp     ax,word ptr [esi+512]
                CHECK   1

                cmp     ax,word ptr [esi-512]
                CHECK   1

                cmp     ebx,6
                jne     nonlinear_filter_border

                shr     eax,1
                movzx   ebx,word ptr [esi+2]
                and     eax,11110111101111b
                shr     ebx,1
                and     ebx,11110111101111b
                add     eax,ebx
                mov     word ptr [edi],ax
                jmp     nonlinear_filter_next

nonlinear_filter_border:
                cmp     ebx,0
                jne     nonlinear_filter_copy

                movzx   edx,word ptr [esi-2]
                shr     edx,1
                movzx   ebx,word ptr [esi+2]
                and     edx,11110111101111b
                shr     ebx,1
                and     ebx,11110111101111b
                add     edx,ebx

                shr     eax,1
                and     eax,11110111101111b
                shr     edx,1
                and     edx,11110111101111b
                add     eax,edx

                mov     word ptr [edi],ax

                jmp     nonlinear_filter_next

nonlinear_filter_copy:
                mov     word ptr [edi],ax

nonlinear_filter_next:
                add     esi,2
                add     edi,2
                dec     ecx
                jnz     nonlinear_filter_loop

                ret

; lcd_filter_mmx -----------------------------------------------------

lcd_filter_mmx:                
                cmp     lcdfilter,1
                jne     _ret

                cmp     enginetype,2
                jne     lcd_filter_dos

                mov     esi,redbuffer
                mov     edi,bluebuffer
                mov     eax,lcdbuffer
                ;mov     ebx,red_blue
                ;inc     ebx
                ;and     ebx,63
                ;mov     red_blue,ebx
                ;shr     ebx,2
                ;mov     bl,byte ptr [offset fantasma+ebx]
                ;mov     byte ptr [offset quelixo],bl
                
                mov     ecx,256*192

                ; movq MM4,all3DEF
                movq
                db      00100101b
                dd      offset all3DEF

lcd_filter_mmx_loop:
                
                ; movq MM0,[esi]
                movq
                db      00000110b

                add     esi,8

                ; movq MM1,[eax]
                movq
                db      00001000b

                ; movq_st [eax],MM0
                movq_st
                db      00000000b
;                db      01000000b
;quelixo:        db      -8

                ; psrlq MM0,1
                psrlq
                db      11010000b
                db      1

                add     eax,8

                ; psrlq MM1,1
                psrlq
                db      11010001b
                db      1

                ; pand MM0,MM4
                pand
                db      11000100b

                ; pand MM1,MM4
                pand
                db      11001100b

                add     edi,8
                
                ; paddw MM0,MM1
                paddw
                db      11000001b

                sub     ecx,4
                
                ; movq_st [edi-8],MM0
                movq_st
                db      01000110b
                db      -8
                
                jnz     lcd_filter_mmx_loop

                ret

lcd_filter_dos:
                mov     esi,redbuffer
                mov     edi,bluebuffer
                mov     eax,lcdbuffer
                mov     ecx,256*192

lcd_filter_dos_loop:
                mov     ebx,dword ptr [esi]
                add     esi,4
                mov     edx,dword ptr [eax]
                mov     dword ptr [eax],ebx
                add     eax,4
                shr     ebx,1
                shr     ecx,1
                and     ebx,03DEF3DEFh
                and     edx,03DEF3DEFh
                add     ebx,edx
                sub     ecx,2
                mov     dword ptr [esi-4],ebx
                jnz     lcd_filter_dos_loop
                ret

; nonlinear_filter_mmx -----------------------------------------------

nonlinear_filter_mmx:
                mov     esi,redbuffer
                mov     edi,bluebuffer
                mov     eax,lcdbuffer

                mov     ecx,256*192

                ; movq MM4,all3DEF
                movq
                db      00100101b
                dd      offset all3DEF

nonlinear_filter_mmx_loop:

                ; movq MM0,[esi]
                movq
                db      00000110b

                ; movq MM1,MM0
                movq
                db      11001000b

                ; movq MM7,[esi+2]
                movq
                db      01111110b
                db      +2

                ; movq MM2,MM0
                movq
                db      11010000b

                ; movq MM5,[esi-2]
                movq
                db      01101110b
                db      -2

                ; movq MM6,MM0
                movq
                db      11110000b
                
                ; pcmpeqw MM1,[esi+512]
                pcmpeqw
                db      10001110b
                dd      512

                ; pcmpeqw MM6,MM5 
                pcmpeqw
                db      11110101b

                ; pand MM1,allFFFE
                pand
                db      00001101b
                dd      offset allFFFE

                ; movq MM3,MM0
                movq
                db      11011000b
                
                ; pcmpeqw MM2,[esi-512]
                pcmpeqw
                db      10010110b
                dd      -512

                ; pcmpeqw MM3,MM7
                pcmpeqw
                db      11011111b

                ; por MM1,all0001
                por
                db      00001101b
                dd      offset all0001

                ; psrlq MM7,1
                psrlq
                db      11010111b
                db      1

                ; pand MM2,allFFFE
                pand
                db      00010101b
                dd      offset allFFFE

                ; pand MM7,MM4
                pand
                db      11111100b

                ; por MM2,all0001
                por
                db      00010101b
                dd      offset all0001

                ; psrlq MM5,1
                psrlq
                db      11010101b
                db      1

                ; pand MM3,allFFFC
                pand
                db      00011101b
                dd      offset allFFFC

                ; paddw MM1,MM2
                paddw
                db      11001010b

                ; por MM3,all0002
                por
                db      00011101b
                dd      offset all0002

                ; pand MM5,MM4
                pand
                db      11101100b

                ; pand MM6,allFFFC
                pand
                db      00110101b
                dd      offset allFFFC

                ; paddw MM1,MM3
                paddw
                db      11001011b

                ; por MM6,all0002
                por
                db      00110101b
                dd      offset all0002

                ; movq MM3,MM0
                movq
                db      11011000b

                ; paddw MM5,MM7
                paddw
                db      11101111b

                ; paddw MM1,MM6
                paddw
                db      11001110b

                ; psrlq MM3,1
                psrlq
                db      11010011b
                db      1

                ; movq MM6,MM1
                movq
                db      11110001b
                
                ; pcmpeqw MM1,all0006
                pcmpeqw
                db      00001101b
                dd      offset all0006

                ; pand MM3,MM4
                pand
                db      11011100b

                ; movq MM2,MM1
                movq
                db      11010001b

                ; paddw MM7,MM3
                paddw
                db      11111011b

                ; pandn MM2,MM0
                pandn
                db      11010000b

                ; pand MM1,MM7
                pand
                db      11001111b

                ; pcmpeqw MM6,all0000
                pcmpeqw
                db      00110101b
                dd      offset all0000

                ; por MM1,MM2
                por
                db      11001010b

                ; psrlq MM5,1
                psrlq
                db      11010101b
                db      1

                ; movq MM2,MM6
                movq
                db      11010110b

                ; pand MM5,MM4
                pand
                db      11101100b

                ; pandn MM2,MM1
                pandn
                db      11010001b

                ; paddw MM5,MM3
                paddw
                db      11101011b

                add     edi,8
                
                ; pand MM6,MM5
                pand    
                db      11110101b

                add     esi,8
                
                ; por MM2,MM6
                por
                db      11010110b

                sub     ecx,4
                
                ; movq_st [edi-8],MM2
                movq_st
                db      01010111b
                db      -8
                
                jnz     nonlinear_filter_mmx_loop

                ret

CORE_2XSAI      macro

                push    eax ebx ebp esi edi
                push    esi
                push    edi
                call    __2xSaIBitmap__FPUiPUs
                pop     edi 
                pop     esi
                pop     edi esi ebp ebx eax
                add     esi,512
                add     edi,1024
                
                endm


; BLIT_LINEAR_512_GENERIC --------------------------------------------
; apply the bilinear filter in the image and copy to video memory

BLIT_LINEAR_512_GENERIC macro   engine
                local   blit_linear_512_15_outer
                local   blit_linear_512_15_inner
                local   blit_linear_512_15_loop
                local   blit_linear_512_15_next

                call    video_vsync
                
                if      engine EQ ENGINE_MMX                
                
                ; movq MM3,all3DEF
                movq
                db      00011101b
                dd      offset all3DEF

                endif
                
                mov     eax,0
                mov     ebx,0

blit_linear_512_15_outer:
                push    eax
                call    set_vesa_bank

                mov     edi,0A0000h
                sub     edi,_code32a

                mov     ebp,32

blit_linear_512_15_inner:
                ;cmp     byte ptr [offset gg_enabled+ebx],1
                ;jne     blit_linear_512_15_next

                
                if      engine EQ ENGINE_2XSAI

                CORE_2XSAI

                else

                push    ebx
                mov     ecx,256

blit_linear_512_15_loop:                
                AVERAGE_CORE engine

                jnz     blit_linear_512_15_loop

                pop     ebx

                endif
                
blit_linear_512_15_next:
                inc     ebx                
                add     edi,1024
                dec     ebp
                jnz     blit_linear_512_15_inner

                pop     eax
                inc     eax
                cmp     eax,6
                jne     blit_linear_512_15_outer

                ret

                endm

BLIT_LINEAR_512_15      macro engine
                        local   system_gg

                cmp     gamegear,1
                je      system_gg

                BLIT_LINEAR_512_GENERIC engine,SYSTEM_SMS

system_gg:
                BLIT_LINEAR_512_GENERIC engine,SYSTEM_GG

                endm

; deblockify ---------------------------------------------------------
; convert a screen generated by the block engine in 8-bit color
; to direct color mode

deblockify:
                cmp     linebyline,1
                je      _ret

                mov     esi,blitbuffer
                mov     edi,redbuffer
                mov     ecx,256*192/16

deblockify_loop:
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
                jnz     deblockify_loop

                ret

; blit_linear_512_15_branch ------------------------------------------
; 512x384x15 main core selector

blit_linear_512_15_branch:
                cmp     enginetype,2
                je      blit_linear_512_15_mmx

                ;BLIT_LINEAR ENGINE_DOS,RES_512_15
                ;call    deblockify
                call    lcd_filter_mmx
                call    nonlinear_filter
                mov     esi,bluebuffer
                BLIT_LINEAR_512_15 ENGINE_DOS

blit_linear_512_15_mmx:

                ;BLIT_LINEAR ENGINE_MMX,RES_512_15
                ;call    deblockify
                call    lcd_filter_mmx
                call    nonlinear_filter
                mov     esi,bluebuffer
                BLIT_LINEAR_512_15 ENGINE_MMX

blit_linear_512_inter_branch:
                cmp     enginetype,2
                je      blit_linear_512_inter_mmx

                ;call    deblockify
                call    lcd_filter_mmx
                ;BLIT_LINEAR ENGINE_DOS,RES_512_15
                mov     esi,redbuffer
                BLIT_LINEAR_512_15 ENGINE_DOS

blit_linear_512_inter_mmx:

                ;call    deblockify
                call    lcd_filter_mmx
                ;BLIT_LINEAR ENGINE_MMX,RES_512_15
                mov     esi,redbuffer
                BLIT_LINEAR_512_15 ENGINE_MMX

blit_linear_512_2xsai_branch:
                ;call    deblockify
                call    lcd_filter_mmx
                mov     esi,redbuffer
                BLIT_LINEAR_512_15 ENGINE_2XSAI

code32          ends
                end



