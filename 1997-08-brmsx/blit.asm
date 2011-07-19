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

extrn blitbuffer: dword
extrn redbuffer: dword
extrn bluebuffer: dword
extrn msxmodel: dword

public blit
public total_lines
public clear_bottom_field

; DATA ---------------------------------------------------------------

align 4
include blit640.inc

all40           dq      04040404040404040h
all3DEF         dq      03DEF3DEF3DEF3DEFh
all0000         dq      00000000000000000h
all0001         dq      00001000100010001h
all0002         dq      00002000200020002h
allFFFE         dq      0FFFEFFFEFFFEFFFEh
allFFFC         dq      0FFFCFFFCFFFCFFFCh
all0006         dq      00006000600060006h
all001F         dq      0001F001F001F001Fh

ENGINE_DOS      EQU     0
ENGINE_MMX      EQU     2

                        db      32 dup (0)
dirtyname_parrot        db      32*24+32 dup (0)

align 4
total_lines             dd      192
clear_bottom_field      dd      0

high_palette            dd      32*4 dup (0)

; CODE ---------------------------------------------------------------

; blit ---------------------------------------------------------------
; copy the contents of blit buffer to pentium video memory

blit:              
                cmp     videomode,0
                je      blit0

                cmp     videomode,2
                je      blit2

                cmp     videomode,6
                je      blit6

                cmp     videomode,7
                je      blit7

                cmp     videomode,8
                je      blit8

                cmp     videomode,9
                je      blit9

                cmp     videomode,11
                je      blit11

                cmp     videomode,12
                je      blit12

                cmp     imagetype,1
                je      blit_dirty_256

; linear 256x192 -----------------------------------------------------

blit_linear_256:
                ; blit linear 256
                mov     edi,0a0000h
                mov     esi,blitbuffer
                sub     edi,_code32a
                mov     ecx,256*192/4
                rep     movsd                
                ret

blit0:

                cmp     imagetype,1
                je      blit_dirty_320

; linear 320x192 -----------------------------------------------------

blit_linear_320:
                mov     esi,blitbuffer
                mov     edi,0a0000h+32
                sub     edi,_code32a
                mov     edx,192
blit_linear_320_0:
                mov     ecx,256/4
                rep     movsd
                add     edi,64
                dec     edx
                jnz     blit_linear_320_0
                ret

; dirty 320x192 ------------------------------------------------------

blit_dirty_320:
                cmp     lastscreen,0
                je      blit_linear_320
                cmp     lastscreen,3
                je      blit_linear_320
                cmp     everyframe,1
                je      blit_linear_320
                mov     ebx,offset dirtyname
                mov     esi,blitbuffer
                mov     edi,0a0000h+32
                sub     edi,_code32a
                mov     ecx,24

blit_dirty_320_line:
                mov     edx,32

blit_dirty_320_char:

                mov     al,[ebx]
                or      al,al
                jz      blit_dirty_320_next
                mov     byte ptr [ebx],0

                irp     i,<0,1,2,3,4,5,6,7>

                mov     eax,[esi+i*256]
                mov     ebp,[esi+i*256+4]
                mov     [edi+i*320],eax
                mov     [edi+i*320+4],ebp

                endm

blit_dirty_320_next:

                inc     ebx
                add     esi,8
                add     edi,8
                dec     edx
                jnz     blit_dirty_320_char

                add     esi,8*256-8*32
                add     edi,8*320-8*32
                dec     ecx
                jnz     blit_dirty_320_line

                mov     eax,0
                mov     edi,offset dirtypattern
                mov     ecx,256*3/4
                rep     stosd

                ret

; dirty 256x192 ------------------------------------------------------

blit_dirty_256:
                cmp     lastscreen,0
                je      blit_linear_256
                cmp     lastscreen,3
                je      blit_linear_256
                cmp     everyframe,1
                je      blit_linear_256
                mov     ebx,offset dirtyname
                mov     esi,blitbuffer
                mov     edi,0a0000h
                sub     edi,_code32a
                mov     ecx,24

blit_dirty_256_line:
                mov     edx,32

blit_dirty_256_char:

                mov     al,[ebx]
                or      al,al
                jz      blit_dirty_256_next
                mov     byte ptr [ebx],0

                irp     i,<0,1,2,3,4,5,6,7>

                mov     eax,[esi+i*256]
                mov     ebp,[esi+i*256+4]
                mov     [edi+i*256],eax
                mov     [edi+i*256+4],ebp

                endm

blit_dirty_256_next:

                inc     ebx
                add     esi,8
                add     edi,8
                dec     edx
                jnz     blit_dirty_256_char

                add     esi,8*256-8*32
                add     edi,8*256-8*32
                dec     ecx
                jnz     blit_dirty_256_line

                mov     eax,0
                mov     edi,offset dirtypattern
                mov     ecx,256*3/4
                rep     stosd

                ret

blit2:
                cmp     cpupaused,1
                je      blit2_slow
                
                cmp     imagetype,1
                je      blit2_dirty

; linear 512x384 -----------------------------------------------------

blit2_linear:
                mov     esi,blitbuffer
                mov     eax,0

blit2_linear_outer_loop:
                call    set_vesa_bank
                mov     ebp,192/3
                mov     edi,0a0000h
                sub     edi,_code32a
                push    eax

blit2_linear_loop:
                mov     ecx,256/2
                mov     edx,0
blit2_linear_inner_loop:
                
                ; esi = 0A0B0C0D

                mov     ebx,dword ptr [esi]
                mov     edx,ebx
                ; ebx=edx=0D0C0B0A

                shl     ebx,8
                and     ebx,000FF0000h
                ; ebx = 000B0000

                or      bl,dl
                mov     eax,ebx
                ; ebx=eax=000B000A

                shl     ebx,4
                or      eax,ebx
                ; ebx=00B000A0
                ; eax=00BB00AA

                shl     ebx,4
                or      eax,ebx
                ; ebx=0B000A00
                ; eax=0BBB0AAA

                shr     ebx,12
                or      eax,ebx
                ; ebx=0000B000
                ; eax=0BBBBAAA

                shl     edx,12
                ; edx=C0B0A000

                and     edx,0F0000000h
                ; edx=C0000000

                or      eax,edx
                ; eax=CBBBBAAA

                mov     dword ptr [edi],eax

                and     eax,0F0F0F0Fh
                or      eax,10101010h
                mov     dword ptr [edi+512],eax

                add     esi,2
                add     edi,4
                dec     ecx
                jnz     blit2_linear_inner_loop

                and     dword ptr [edi-4],00FFFFFFh
                and     dword ptr [edi-4+512],00FFFFFFh
                
                add     edi,512

                dec     ebp
                jnz     blit2_linear_loop

                pop     eax

                inc     eax
                cmp     eax,3
                jne     blit2_linear_outer_loop

                ret

; dirty 512x384 ------------------------------------------------------

blit2_dirty:
                cmp     lastscreen,0
                je      blit2_linear
                cmp     lastscreen,3
                je      blit2_linear
                cmp     everyframe,1
                je      blit2_linear

                mov     ebx,offset dirtyname
                mov     esi,blitbuffer
                mov     edi,0a0000h
                sub     edi,_code32a
                mov     ecx,24
                mov     eax,0
                call    set_vesa_bank

blit2_dirty_line:
                cmp     ecx,16
                jne     blit2_dirty_line1
                mov     eax,1
                call    set_vesa_bank
                mov     edi,0a0000h
                sub     edi,_code32a
                jmp     blit2_dirty_line_next

blit2_dirty_line1:
                cmp     ecx,8
                jne     blit2_dirty_line_next
                mov     eax,2
                call    set_vesa_bank
                mov     edi,0a0000h
                sub     edi,_code32a

blit2_dirty_line_next:
                mov     edx,32

blit2_dirty_char:
                mov     al,[ebx]
                or      al,al
                jz      blit2_dirty_next
                mov     byte ptr [ebx],0

                push    ebx edx

                cmp     edx,32
                je      blit2_dirty_char_border

                irp     j,<0,1,2,3,4,5,6,7>

                irp     i,<-2,0,2,4,6>
                
                mov     ebx,dword ptr [esi+j*256+i]
                mov     edx,ebx
                shl     ebx,8
                and     ebx,000FF0000h
                or      bl,dl
                mov     eax,ebx
                shl     ebx,4
                or      eax,ebx
                shl     ebx,4
                or      eax,ebx
                shr     ebx,12
                or      eax,ebx
                shl     edx,12
                and     edx,0F0000000h
                or      eax,edx
                mov     dword ptr [edi+j*512*2+i*2],eax
                and     eax,0F0F0F0Fh
                or      eax,10101010h
                mov     dword ptr [edi+j*512*2+i*2+512],eax

                endm

                endm

                jmp     blit2_dirty_char_end

blit2_dirty_char_border:
                
                irp     j,<0,1,2,3,4,5,6,7>

                irp     i,<0,2,4,6>
                
                mov     ebx,dword ptr [esi+j*256+i]
                mov     edx,ebx
                shl     ebx,8
                and     ebx,000FF0000h
                or      bl,dl
                mov     eax,ebx
                shl     ebx,4
                or      eax,ebx
                shl     ebx,4
                or      eax,ebx
                shr     ebx,12
                or      eax,ebx
                shl     edx,12
                and     edx,0F0000000h
                or      eax,edx
                mov     dword ptr [edi+j*512*2+i*2],eax
                and     eax,0F0F0F0Fh
                or      eax,10101010h
                mov     dword ptr [edi+j*512*2+i*2+512],eax

                endm

                endm

blit2_dirty_char_end:

                pop     edx ebx

blit2_dirty_next:

                inc     ebx
                add     esi,8
                add     edi,16
                dec     edx
                jnz     blit2_dirty_char

                add     esi,8*256-8*32
                add     edi,8*512*2-16*32

                irp     i,<0,1,2,3,4,5,6,7>
                mov     byte ptr [edi-8*512*2-1+i*512*2],0
                mov     byte ptr [edi-8*512*2+512-1+i*512*2],0
                endm

                dec     ecx
                jnz     blit2_dirty_line

                mov     eax,0
                mov     edi,offset dirtypattern
                mov     ecx,256*3/4
                rep     stosd

                ret

; linear 512x384 (without interpolation/scanlines) -------------------

blit2_slow:
                mov     esi,blitbuffer
                mov     eax,0

blit2_slow_outer_loop:
                call    set_vesa_bank
                mov     ebp,192/3
                mov     edi,0a0000h
                sub     edi,_code32a
                push    eax

blit2_slow_loop:
                mov     ecx,256/2
                mov     edx,0
blit2_slow_inner_loop:
                
                ; esi = 0A0B0C0D

                mov     ebx,dword ptr [esi]
                mov     edx,ebx
                ; ebx=edx=0D0C0B0A

                shl     ebx,8
                and     ebx,000FF0000h
                ; ebx = 000B0000

                or      bl,dl
                mov     eax,ebx
                ; ebx=eax=000B000A

                mov     ebx,eax
                shl     ebx,8
                ; ebx=0B000A00

                or      eax,ebx
                ; eax=0B0B0A0A

                mov     dword ptr [edi],eax
                mov     dword ptr [edi+512],eax

                add     esi,2
                add     edi,4
                dec     ecx
                jnz     blit2_slow_inner_loop

                and     dword ptr [edi-4],00FFFFFFh
                and     dword ptr [edi-4+512],00FFFFFFh
                
                add     edi,512

                dec     ebp
                jnz     blit2_slow_loop

                pop     eax

                inc     eax
                cmp     eax,3
                jne     blit2_slow_outer_loop

                ret

; blit6 --------------------------------------------------------------
; main pipeline selector for Parrot engine

blit6:
                call    expand_dirtyname

                cmp     cpupaused,1
                je      convert_direct
                
                cmp     lastscreen,0
                je      convert_direct_screen0

                cmp     everyframe,1
                je      convert_direct

                cmp     border_changed,1
                je      convert_direct

                cmp     imagetype,1
                je      convert_direct_dirty

expand_dirtyname:
                mov     edi,offset dirtyname_parrot
                mov     ecx,32*24/4
                mov     eax,0
                rep     stosd

                mov     ecx,32*24
                mov     esi,offset dirtyname
                mov     edi,offset dirtyname_parrot

expand_dirtyname_loop:
                mov     al,[esi]
                or      [edi],al
                or      [edi-1],al
                or      [edi+1],al
                or      [edi-32],al
                or      [edi+32],al
                inc     esi
                inc     edi
                dec     ecx
                jnz     expand_dirtyname_loop

                ret

; convert_direct -----------------------------------------------------
; convert blitbuffer to direct color (linear version)

convert_direct:
                mov     esi,blitbuffer
                mov     edi,redbuffer
                mov     ecx,256*192/8

                mov     edx,offset sg1000_high_palette
                cmp     cpupaused,1
                jne     convert_direct_gui

                mov     edx,offset gui_palette_high

convert_direct_gui:

                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                jnz     convert_direct_border

                mov     eax,1

convert_direct_border:
                mov     bx,word ptr [edx+eax*2]
                mov     word ptr [edx],bx

convert_direct_loop:
                irp     i,<0,1,2,3,4,5,6,7>
                movzx   eax,byte ptr [esi+i]
                mov     bx,word ptr [edx+eax*2]
                mov     word ptr [edi+i*2],bx
                endm
                add     esi,8
                add     edi,2*8
                dec     ecx
                jnz     convert_direct_loop

                jmp     blit_linear_512_15_branch

; convert_direct_dirty -----------------------------------------------
; convert blitbuffer to direct color (dirty version)

convert_direct_dirty:
                mov     esi,blitbuffer
                mov     edi,redbuffer
                mov     ecx,24
                mov     ebp,offset dirtyname_parrot

                mov     edx,offset sg1000_high_palette
                cmp     cpupaused,1
                jne     convert_direct_gui_dirty

                mov     edx,offset gui_palette_high

convert_direct_gui_dirty:

                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                jnz     convert_direct_border_dirty

                mov     eax,1

convert_direct_border_dirty:
                mov     bx,word ptr [edx+eax*2]
                mov     word ptr [edx],bx

convert_direct_loop_outer_dirty:
                mov     ebx,32
convert_direct_loop_inner_dirty:
                cmp     byte ptr [ebp],1
                je      convert_direct_dirty_unit

convert_direct_loop_inner_continue:
                inc     ebp
                add     esi,8
                add     edi,8*2
                dec     ebx
                jnz     convert_direct_loop_inner_dirty

                add     esi,8*256-256
                add     edi,8*256*2-256*2
                dec     ecx
                jnz     convert_direct_loop_outer_dirty

                jmp     blit_linear_512_15_branch

convert_direct_dirty_unit:
                push    ebx ecx
                mov     ecx,8

convert_direct_dirty_unit_loop:
                irp     i,<0,1,2,3,4,5,6,7>
                movzx   eax,byte ptr [esi+i]
                mov     bx,word ptr [edx+eax*2]
                mov     word ptr [edi+i*2],bx
                endm
                add     esi,256
                add     edi,512

                dec     ecx
                jnz     convert_direct_dirty_unit_loop

                sub     esi,256*8
                sub     edi,512*8

                pop     ecx ebx

                jmp     convert_direct_loop_inner_continue

; convert_direct_screen0 ---------------------------------------------
; convert blitbuffer to direct color in screen 0

convert_direct_screen0:
                mov     esi,blitbuffer
                mov     edi,redbuffer
                mov     ecx,256*192
                movzx   eax,byte ptr [offset vdpregs+7]
                mov     ebp,eax
                and     ebp,0Fh
                mov     edx,eax
                shr     edx,4
                and     edx,0Fh

convert_direct_screen0_loop:
                cmp     byte ptr [esi],0
                jz      convert_direct_screen0_color0
                mov     bx,word ptr [offset sg1000_high_palette+edx*2]
                jmp     convert_direct_screen0_draw

convert_direct_screen0_color0:
                mov     bx,word ptr [offset sg1000_high_palette+ebp*2]

convert_direct_screen0_draw:
                inc     esi
                mov     word ptr [edi],bx
                add     edi,2
                dec     ecx
                jnz     convert_direct_screen0_loop
                
                jmp     blit_linear_512_15_branch


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

; NONLINEAR_MACRO_DOS ------------------------------------------------

NONLINEAR_MACRO_DOS macro 
                local   nonlinear_filter_border
                local   nonlinear_filter_copy
                local   nonlinear_filter_next
                
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

                endm

; NONLINEAR_MACRO_MMX ------------------------------------------------

NONLINEAR_MACRO_MMX macro

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
                

                endm

; nonlinear_filter ---------------------------------------------------
; apply the nonlinear filter in the image

nonlinear_filter:
                cmp     everyframe,1
                je      nonlinear_filter_start

                cmp     border_changed,1
                je      nonlinear_filter_start

                cmp     lastscreen,0
                je      nonlinear_filter_start

                cmp     lastscreen,3
                je      nonlinear_filter_start

                cmp     imagetype,1
                je      nonlinear_filter_start_dirty
                
nonlinear_filter_start:                
                cmp     enginetype,2
                je      nonlinear_filter_mmx

; nonlinear_filter_dos -----------------------------------------------

nonlinear_filter_dos:
                mov     esi,redbuffer
                mov     edi,bluebuffer

                mov     ecx,256*192

nonlinear_filter_loop:
                NONLINEAR_MACRO_DOS
                
                add     esi,2
                add     edi,2
                dec     ecx
                jnz     nonlinear_filter_loop

                ret

; nonlinear_filter_mmx -----------------------------------------------

nonlinear_filter_mmx:
                mov     esi,redbuffer
                mov     edi,bluebuffer

                mov     ecx,256*192

                ; movq MM4,all3DEF
                movq
                db      00100101b
                dd      offset all3DEF

nonlinear_filter_mmx_loop:

                NONLINEAR_MACRO_MMX
                
                jnz     nonlinear_filter_mmx_loop

                ret

NONLINEAR_DIRTY_MACRO   macro engine
                local   nonlinear_filter_start_dirty_outer
                local   nonlinear_filter_start_dirty_inner
                local   nonlinear_filter_start_dirty_continue

                mov     esi,redbuffer
                mov     edi,bluebuffer
                mov     ebp,offset dirtyname_parrot

                if      engine EQ ENGINE_MMX
                
                ; movq MM4,all3DEF
                movq
                db      00100101b
                dd      offset all3DEF

                endif

                mov     ebx,24

nonlinear_filter_start_dirty_outer:

                mov     edx,32

nonlinear_filter_start_dirty_inner:

                cmp     byte ptr [ebp],1

                if      engine EQ ENGINE_MMX
                je      nonlinear_filter_start_dirty_unit_mmx
nonlinear_filter_start_dirty_continue_mmx:
                else
                je      nonlinear_filter_start_dirty_unit_dos
nonlinear_filter_start_dirty_continue_dos:
                endif

                inc     ebp

                add     esi,8*2
                add     edi,8*2
                dec     edx
                jnz     nonlinear_filter_start_dirty_inner

                add     esi,8*512-32*8*2
                add     edi,8*512-32*8*2
                dec     ebx
                jnz     nonlinear_filter_start_dirty_outer

                ret

                endm

; nonlinear_filter_start_dirty_unit_mmx ------------------------------

nonlinear_filter_start_dirty_unit_mmx:

                push    edi esi ebp

                mov     ebp,8

nonlinear_filter_start_dirty_unit_outer:
                NONLINEAR_MACRO_MMX
                NONLINEAR_MACRO_MMX

                add     edi,512-8*2
                add     esi,512-8*2

                dec     ebp
                jnz     nonlinear_filter_start_dirty_unit_outer

                pop     ebp esi edi
                jmp     nonlinear_filter_start_dirty_continue_mmx

; nonlinear_filter_start_dirty_unit_dos ------------------------------

nonlinear_filter_start_dirty_unit_dos:

                push    edi esi edx ebx ebp
                
                mov     ebp,8
nonlinear_filter_start_dirty_unit_dos_outer:

                mov     ecx,8
nonlinear_filter_start_dirty_unit_dos_inner:
                NONLINEAR_MACRO_DOS
                add     esi,2
                add     edi,2

                dec     ecx
                jnz     nonlinear_filter_start_dirty_unit_dos_inner
                
                add     esi,512-8*2
                add     edi,512-8*2
                dec     ebp
                jnz     nonlinear_filter_start_dirty_unit_dos_outer

                pop     ebp ebx edx esi edi
                jmp     nonlinear_filter_start_dirty_continue_dos

; nonlinear_filter_start_dirty ---------------------------------------

nonlinear_filter_start_dirty:
         
                cmp     enginetype,2
                je      nonlinear_filter_start_dirty_mmx
                
                NONLINEAR_DIRTY_MACRO ENGINE_DOS

nonlinear_filter_start_dirty_mmx:
                NONLINEAR_DIRTY_MACRO ENGINE_MMX

; BLIT_LINEAR_512 ----------------------------------------------------
; apply the bilinear filter in the image and copy to video memory

BLIT_LINEAR_512  macro   engine
                local   blit_linear_512_15_outer
                local   blit_linear_512_15_inner
                local   blit_linear_512_15_loop
                local   blit_linear_512_15_next

                ;call    video_vsync
                
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

                
                push    ebx
                mov     ecx,256

blit_linear_512_15_loop:                
                AVERAGE_CORE engine

                jnz     blit_linear_512_15_loop

                pop     ebx
                
blit_linear_512_15_next:
                inc     ebx                
                add     edi,1024
                dec     ebp
                jnz     blit_linear_512_15_inner

                pop     eax
                inc     eax
                cmp     eax,6
                jne     blit_linear_512_15_outer

                mov     edi,offset dirtyname
                mov     ecx,32*24
                mov     eax,0
                rep     stosd
                
                mov     border_changed,0

                ret

                endm
                
; BLIT_DIRTY_512 -----------------------------------------------------

BLIT_DIRTY_512  macro engine
                local   blit_dirty_vesabank
                local   blit_dirty_outer
                local   blit_dirty_inner
                local   blit_dirty_unit
                local   blit_dirty_unit_loop
                local   blit_dirty_continue
                local   blit_dirty_unit_loop_dos
                local   blit_dirty_unit_dos

                if      engine EQ ENGINE_MMX                
                
                ; movq MM3,all3DEF
                movq
                db      00011101b
                dd      offset all3DEF

                endif

                mov     eax,0
                mov     ebp,offset dirtyname_parrot

blit_dirty_vesabank:
                push    eax
                call    set_vesa_bank
                mov     edi,0A0000h
                sub     edi,_code32a

                mov     ebx,4
blit_dirty_outer:

                mov     ecx,32

blit_dirty_inner:
                cmp     byte ptr [ebp],1
                if      engine EQ ENGINE_MMX
                je      blit_dirty_unit
                else
                je      blit_dirty_unit_dos
                endif

blit_dirty_continue:

                add     esi,8*2
                add     edi,8*2*2
                inc     ebp
                dec     ecx
                jnz     blit_dirty_inner

                add     esi,256*2*8-32*8*2
                add     edi,256*2*2*2*8-32*8*2*2
                dec     ebx
                jnz     blit_dirty_outer

                pop     eax
                inc     eax
                cmp     eax,6
                jne     blit_dirty_vesabank

                mov     edi,offset dirtyname
                mov     ecx,32*24
                mov     eax,0
                rep     stosd
                
                mov     border_changed,0

                ret


blit_dirty_unit:
                push    eax ebx ecx esi edi
                mov     edx,8
blit_dirty_unit_loop:
                AVERAGE_CORE ENGINE_MMX
                AVERAGE_CORE ENGINE_MMX
                add     esi,512-8*2
                add     edi,1024*2-8*2*2
                dec     edx
                jnz     blit_dirty_unit_loop

                pop     edi esi ecx ebx eax
                jmp     blit_dirty_continue

blit_dirty_unit_dos:
                push    eax ebx ecx esi edi
                
                mov     edx,8
blit_dirty_unit_loop_dos:
                push    edx
                rept    8
                AVERAGE_CORE ENGINE_DOS
                endm                
                pop     edx
                add     esi,512-8*2
                add     edi,1024*2-8*2*2
                dec     edx
                jnz     blit_dirty_unit_loop_dos

                pop     edi esi ecx ebx eax
                jmp     blit_dirty_continue

                
                endm



; BLIT_LINEAR_512_GENERIC --------------------------------------------
; 512x384x15 main core selector

BLIT_LINEAR_512_GENERIC macro engine
                local   start
                local   dirty

                cmp     everyframe,1
                je      start

                cmp     border_changed,1
                je      start

                cmp     lastscreen,0
                je      start

                cmp     lastscreen,3
                je      start

                cmp     imagetype,1
                je      dirty

start:
                BLIT_LINEAR_512 engine

dirty:
                BLIT_DIRTY_512 engine

                endm

; blit_linear_512_15_branch ------------------------------------------
; 512x384x15 main core selector

blit_linear_512_15_branch:
                cmp     enginetype,2
                je      blit_linear_512_15_mmx

                ;BLIT_LINEAR ENGINE_DOS,RES_512_15
                call    nonlinear_filter
                mov     esi,bluebuffer
                BLIT_LINEAR_512_GENERIC ENGINE_DOS

blit_linear_512_15_mmx:

                ;BLIT_LINEAR ENGINE_MMX,RES_512_15
                call    nonlinear_filter
                mov     esi,bluebuffer
                BLIT_LINEAR_512_GENERIC ENGINE_MMX

blit_linear_512_inter_branch:
                cmp     enginetype,2
                je      blit_linear_512_inter_mmx

                ;BLIT_LINEAR ENGINE_DOS,RES_512_15
                mov     esi,redbuffer
                BLIT_LINEAR_512_GENERIC ENGINE_DOS

blit_linear_512_inter_mmx:

                ;BLIT_LINEAR ENGINE_MMX,RES_512_15
                mov     esi,redbuffer
                BLIT_LINEAR_512_GENERIC ENGINE_MMX

; linear 512x384 -----------------------------------------------------
; MSX2 VERSION

blit2_msx2:
                mov     esi,blitbuffer
                mov     eax,0

blit2_msx2_outer_loop:
                call    set_vesa_bank
                mov     edi,0a0000h
                sub     edi,_code32a

                mov     ecx,65536/4
                rep     movsd

                inc     eax
                cmp     eax,3
                jne     blit2_msx2_outer_loop

                ret

; linear 320x200 -----------------------------------------------------
; MSX2 VERSION

blit7:
                call    eval_bottom_field_7

                cmp     text_columns,80
                je      blit7_sizedown

blit7_start:
                mov     edx,200
                mov     esi,blitbuffer
                mov     edi,0A0000h+32
                sub     edi,_code32a

blit7_outer:
                mov     ecx,256/4
                rep     movsd

                add     edi,64
                dec     edx
                jnz     blit7_outer
                
                ret

; --------------------------------------------------------------------

blit7_sizedown:
                cmp     enginetype,0
                jne     blit7_sizedown_mmx

                mov     esi,blitbuffer
                mov     ecx,200
                mov     edi,0A0000h+32
                sub     edi,_code32a

blit7_sizedown_outer:
                mov     edx,64

blit7_sizedown_inner:
                mov     eax,[esi+4]
                add     edi,4
                mov     bl,al
                shr     eax,16
                mov     bh,al
                mov     eax,[esi]
                shl     ebx,16
                add     esi,8
                mov     bl,al
                shr     eax,16
                mov     bh,al
                mov     [edi-4],ebx

                dec     edx
                jnz     blit7_sizedown_inner

                add     edi,64
                dec     ecx
                jnz     blit7_sizedown_outer
                
                ret

; --------------------------------------------------------------------

blit7_sizedown_mmx:
                mov     esi,blitbuffer
                mov     ecx,200
                mov     edi,0A0000h+32
                sub     edi,_code32a

                ;movq    MM4,all001F
                movq
                db      00100101b
                dd      offset all001F


blit7_sizedown_outer_mmx:
                mov     edx,32

blit7_sizedown_inner_mmx:

                ;movq    MM0,[esi]
                movq
                db      00000110b

                add     edi,8

                ;movq    MM1,[esi+8]
                movq
                db      10001110b
                dd      8

                ;pand    MM0,MM4
                pand
                db      11000100b

                ;pand    MM1,MM4
                pand    
                db      11001100b

                add     esi,16

                ;packuswb MM0,MM1
                packuswb
                db      11000001b

                dec     edx

                ; movq_st [edi-8],MM0
                movq_st
                db      10000111b
                dd      -8

                jnz     blit7_sizedown_inner_mmx

                add     edi,64
                dec     ecx
                jnz     blit7_sizedown_outer_mmx
                
                ret

; --------------------------------------------------------------------

eval_bottom_field_7:
                test    byte ptr [offset vdpregs+9],BIT_7
                jnz     _ret

                cmp     text_columns,80
                je      eval_bottom_field_7_512

                mov     edi,blitbuffer
                add     edi,192*256
                mov     ecx,(200-192)*256/4
                mov     eax,0
                rep     stosd
                ret

eval_bottom_field_7_512:
                mov     edi,blitbuffer
                add     edi,192*512
                mov     ecx,(200-192)*512/4
                mov     eax,0
                rep     stosd
                ret

; linear 512x384 -----------------------------------------------------
; MSX2 VERSION

blit8:
                cmp     actualscreen,6
                je      blit8_single

                cmp     actualscreen,7
                je      blit8_single

                cmp     text_columns,80
                je      blit8_single


blit8_double:
                cmp     enginetype,0
                jne     blit8_double_mmx

                mov     esi,blitbuffer
                mov     eax,0

blit8_double_outer_loop:
                call    set_vesa_bank
                mov     ebp,192/3
                mov     edi,0a0000h
                sub     edi,_code32a
                push    eax

blit8_double_loop:
                mov     ecx,64
                mov     edx,0
blit8_double_inner_loop:
                mov     ebx,dword ptr [esi]                
                mov     dl,bh
                mov     dh,bh
                shl     edx,16
                mov     dl,bl
                mov     dh,bl
                mov     dword ptr [edi],edx
                mov     dword ptr [edi+512],edx
                shr     ebx,16
                mov     dl,bh
                mov     dh,bh
                shl     edx,16
                mov     dl,bl
                mov     dh,bl
                mov     dword ptr [edi+4],edx
                mov     dword ptr [edi+512+4],edx

                add     esi,4
                add     edi,8
                dec     ecx
                jnz     blit8_double_inner_loop

                add     edi,512

                dec     ebp
                jnz     blit8_double_loop

                pop     eax

                inc     eax
                cmp     eax,3
                jne     blit8_double_outer_loop

                ret

blit8_double_mmx:
                mov     esi,blitbuffer
                mov     eax,0

blit8_double_outer_loop_mmx:
                call    set_vesa_bank
                mov     ebp,192/3
                mov     edi,0a0000h
                sub     edi,_code32a
                push    eax

blit8_double_loop_mmx:
                mov     ecx,256/8
                mov     edx,0
blit8_double_inner_loop_mmx:
                ; movq MM0,[esi]
                movq
                db      00000110b

                add     esi,8

                ; movq    MM1,MM0
                movq
                db      11001000b

                add     edi,16
                
                ; punpckhbw MM0,MM0
                punpckhbw
                db      11000000b

                ; punpcklbw MM1,MM1
                punpcklbw
                db      11001001b

                dec     ecx

                ; movq_st [edi-8],MM0
                movq_st
                db      10000111b
                dd      -8

                ; movq_st [edi-16],MM1
                movq_st
                db      10001111b
                dd      -16

                ; movq_st [edi+512-8],MM0
                movq_st
                db      10000111b
                dd      512-8

                ; movq_st [edi+512-16],MM1
                movq_st
                db      10001111b
                dd      512-16

                jnz     blit8_double_inner_loop_mmx

                add     edi,512

                dec     ebp
                jnz     blit8_double_loop_mmx

                pop     eax

                inc     eax
                cmp     eax,3
                jne     blit8_double_outer_loop_mmx

                ret

blit8_single:
                cmp     enginetype,0
                jne     blit8_single_mmx

                mov     esi,blitbuffer
                mov     eax,0

blit8_outer_loop:
                call    set_vesa_bank
                mov     ebp,192/3
                mov     edi,0a0000h
                sub     edi,_code32a
                push    eax

blit8_loop:
                mov     ecx,256/2
                mov     edx,0
blit8_inner_loop:
                mov     eax,dword ptr [esi]
                mov     dword ptr [edi],eax
                mov     dword ptr [edi+512],eax
                
                add     esi,4
                add     edi,4
                dec     ecx
                jnz     blit8_inner_loop

                add     edi,512

                dec     ebp
                jnz     blit8_loop

                pop     eax

                inc     eax
                cmp     eax,3
                jne     blit8_outer_loop

                ret

blit8_single_mmx:
                mov     esi,blitbuffer
                mov     eax,0

blit8_outer_loop_mmx:
                call    set_vesa_bank
                mov     ebp,192/3
                mov     edi,0a0000h
                sub     edi,_code32a
                push    eax

blit8_loop_mmx:
                mov     ecx,256/4
                mov     edx,0
blit8_inner_loop_mmx:
                add     edi,8

                ; movq MM0,[esi]
                movq
                db      00000110b

                add     esi,8
                
                ; movq_st [edi-8],MM0
                movq_st
                db      10000111b
                dd      -8

                dec     ecx

                ; movq_st [edi+512-8],MM0
                movq_st
                db      10000111b
                dd      512-8
                
                jnz     blit8_inner_loop_mmx

                add     edi,512

                dec     ebp
                jnz     blit8_loop_mmx

                pop     eax

                inc     eax
                cmp     eax,3
                jne     blit8_outer_loop_mmx

                ret

; linear 512x384 with scanlines --------------------------------------
; MSX2 VERSION

blit9:
                cmp     actualscreen,6
                je      blit9_single

                cmp     actualscreen,7
                je      blit9_single

                cmp     text_columns,80
                je      blit9_single


blit9_double:
                cmp     enginetype,0
                jne     blit9_double_mmx

                mov     esi,blitbuffer
                mov     eax,0

blit9_double_outer_loop:
                call    set_vesa_bank
                mov     ebp,192/3
                mov     edi,0a0000h
                sub     edi,_code32a
                push    eax

blit9_double_loop:
                mov     ecx,64
                mov     edx,0
blit9_double_inner_loop:
                mov     ebx,dword ptr [esi]                
                mov     dl,bh
                mov     dh,bh
                shl     edx,16
                mov     dl,bl
                mov     dh,bl
                mov     dword ptr [edi],edx
                shr     ebx,16
                mov     dl,bh
                mov     dh,bh
                shl     edx,16
                mov     dl,bl
                mov     dh,bl
                mov     dword ptr [edi+4],edx

                add     esi,4
                add     edi,8
                dec     ecx
                jnz     blit9_double_inner_loop

                add     edi,512

                dec     ebp
                jnz     blit9_double_loop

                pop     eax

                inc     eax
                cmp     eax,3
                jne     blit9_double_outer_loop

                ret

blit9_double_mmx:
                mov     esi,blitbuffer
                mov     eax,0

blit9_double_outer_loop_mmx:
                call    set_vesa_bank
                mov     ebp,192/3
                mov     edi,0a0000h
                sub     edi,_code32a
                push    eax

blit9_double_loop_mmx:
                mov     ecx,256/8
                mov     edx,0
blit9_double_inner_loop_mmx:
                ; movq MM0,[esi]
                movq
                db      00000110b

                add     esi,8

                ; movq    MM1,MM0
                movq
                db      11001000b

                add     edi,16
                
                ; punpckhbw MM0,MM0
                punpckhbw
                db      11000000b

                ; punpcklbw MM1,MM1
                punpcklbw
                db      11001001b

                ; movq_st [edi-8],MM0
                movq_st
                db      10000111b
                dd      -8

                dec     ecx

                ; movq_st [edi-16],MM1
                movq_st
                db      10001111b
                dd      -16

                jnz     blit9_double_inner_loop_mmx

                add     edi,512

                dec     ebp
                jnz     blit9_double_loop_mmx

                pop     eax

                inc     eax
                cmp     eax,3
                jne     blit9_double_outer_loop_mmx

                ret

blit9_single:
                cmp     enginetype,0
                jne     blit9_single_mmx

                mov     esi,blitbuffer
                mov     eax,0

blit9_outer_loop:
                call    set_vesa_bank
                mov     ebp,192/3
                mov     edi,0a0000h
                sub     edi,_code32a
                push    eax

blit9_loop:
                mov     ecx,256/2
                mov     edx,0
blit9_inner_loop:
                mov     eax,dword ptr [esi]
                add     esi,4
                mov     dword ptr [edi],eax
                
                add     edi,4
                dec     ecx
                jnz     blit9_inner_loop

                add     edi,512

                dec     ebp
                jnz     blit9_loop

                pop     eax

                inc     eax
                cmp     eax,3
                jne     blit9_outer_loop

                ret

blit9_single_mmx:
                mov     esi,blitbuffer
                mov     eax,0

blit9_outer_loop_mmx:
                call    set_vesa_bank
                mov     ebp,192/3
                mov     edi,0a0000h
                sub     edi,_code32a
                push    eax

blit9_loop_mmx:
                mov     ecx,256/4
                mov     edx,0
blit9_inner_loop_mmx:
                add     edi,8

                ; movq MM0,[esi]
                movq
                db      00000110b

                add     esi,8
                
                ; movq_st [edi-8],MM0
                movq_st
                db      10000111b
                dd      -8

                dec     ecx
                
                jnz     blit9_inner_loop_mmx

                add     edi,512

                dec     ebp
                jnz     blit9_loop_mmx

                pop     eax

                inc     eax
                cmp     eax,3
                jne     blit9_outer_loop_mmx

                ret

; linear 640x480 with scanlines --------------------------------------
; MSX2 VERSION

blit11:
                call    eval_bottom_field_11

                cmp     actualscreen,6
                je      blit11_single

                cmp     actualscreen,7
                je      blit11_single

                cmp     text_columns,80
                je      blit11_single

blit11_double:
                cmp     enginetype,0
                jne     blit11_double_mmx
                
                mov     esi,blitbuffer
                mov     eax,0
                call    set_vesa_bank
                mov     ebp,0
                mov     edx,0

blit11_outer_loop_double:
                movzx   edi,word ptr [offset screen_640_table+ebp*4]
                add     edi,0a0000h
                sub     edi,_code32a
                movzx   eax,byte ptr [offset screen_640_table+ebp*4+2]
                cmp     eax,edx
                je      blit11_same_bank_double
                call    set_vesa_bank
                mov     edx,eax
blit11_same_bank_double:

                push    eax

                movzx   ecx,byte ptr [offset screen_640_table+ebp*4+3]
                shr     ecx,1
                push    edx
blit11_inner_loop_double:
                mov     ebx,dword ptr [esi]                
                mov     dl,bh
                mov     dh,bh
                shl     edx,16
                mov     dl,bl
                mov     dh,bl
                mov     dword ptr [edi],edx
                shr     ebx,16
                mov     dl,bh
                mov     dh,bh
                shl     edx,16
                mov     dl,bl
                mov     dh,bl
                mov     dword ptr [edi+4],edx

                add     esi,4
                add     edi,8
                dec     ecx
                jnz     blit11_inner_loop_double

                pop     edx

                cmp     byte ptr [offset screen_640_table+ebp*4+3],128
                je      blit11_skip_double

                movzx   eax,byte ptr [offset screen_640_table+ebp*4+2]
                inc     eax
                call    set_vesa_bank
                
                mov     ecx,128
                sub     cl,byte ptr [offset screen_640_table+ebp*4+3]
                mov     edi,0A0000h
                sub     edi,_code32a
                shr     ecx,1
                push    edx
blit11_inner_loop_2_double:
                mov     ebx,dword ptr [esi]                
                mov     dl,bh
                mov     dh,bh
                shl     edx,16
                mov     dl,bl
                mov     dh,bl
                mov     dword ptr [edi],edx
                shr     ebx,16
                mov     dl,bh
                mov     dh,bh
                shl     edx,16
                mov     dl,bl
                mov     dh,bl
                mov     dword ptr [edi+4],edx

                add     esi,4
                add     edi,8
                dec     ecx
                jnz     blit11_inner_loop_2_double
                pop     edx

blit11_skip_double:
                pop     eax

                inc     ebp
                cmp     ebp,212
                jnz     blit11_outer_loop_double

                ret

blit11_double_mmx:
                mov     esi,blitbuffer
                mov     eax,0
                call    set_vesa_bank
                mov     ebp,0
                mov     edx,0

blit11_outer_loop_double_mmx:
                movzx   edi,word ptr [offset screen_640_table+ebp*4]
                add     edi,0a0000h
                sub     edi,_code32a
                movzx   eax,byte ptr [offset screen_640_table+ebp*4+2]
                cmp     eax,edx
                je      blit11_same_bank_double_mmx
                call    set_vesa_bank
                mov     edx,eax
blit11_same_bank_double_mmx:

                push    eax

                movzx   ecx,byte ptr [offset screen_640_table+ebp*4+3]
                shr     ecx,2
blit11_inner_loop_double_mmx:
                ; movq MM0,[esi]
                movq
                db      00000110b

                add     esi,8

                ; movq    MM1,MM0
                movq
                db      11001000b

                add     edi,16
                
                ; punpckhbw MM0,MM0
                punpckhbw
                db      11000000b

                ; punpcklbw MM1,MM1
                punpcklbw
                db      11001001b

                ; movq_st [edi-8],MM0
                movq_st
                db      10000111b
                dd      -8

                dec     ecx

                ; movq_st [edi-16],MM1
                movq_st
                db      10001111b
                dd      -16

                jnz     blit11_inner_loop_double_mmx

                cmp     byte ptr [offset screen_640_table+ebp*4+3],128
                je      blit11_skip_double_mmx

                movzx   eax,byte ptr [offset screen_640_table+ebp*4+2]
                inc     eax
                call    set_vesa_bank
                
                mov     ecx,128
                sub     cl,byte ptr [offset screen_640_table+ebp*4+3]
                mov     edi,0A0000h
                sub     edi,_code32a
                shr     ecx,2
blit11_inner_loop_2_double_mmx:
                ; movq MM0,[esi]
                movq
                db      00000110b

                add     esi,8

                ; movq    MM1,MM0
                movq
                db      11001000b

                add     edi,16
                
                ; punpckhbw MM0,MM0
                punpckhbw
                db      11000000b

                ; punpcklbw MM1,MM1
                punpcklbw
                db      11001001b

                ; movq_st [edi-8],MM0
                movq_st
                db      10000111b
                dd      -8

                dec     ecx

                ; movq_st [edi-16],MM1
                movq_st
                db      10001111b
                dd      -16

                jnz     blit11_inner_loop_2_double_mmx

blit11_skip_double_mmx:
                pop     eax

                inc     ebp
                cmp     ebp,212
                jnz     blit11_outer_loop_double_mmx

                ret


blit11_single:
                cmp     enginetype,0
                jne     blit11_mmx
                
                mov     esi,blitbuffer
                mov     eax,0
                call    set_vesa_bank
                mov     ebp,0
                mov     edx,0

blit11_outer_loop:
                movzx   edi,word ptr [offset screen_640_table+ebp*4]
                add     edi,0a0000h
                sub     edi,_code32a
                movzx   eax,byte ptr [offset screen_640_table+ebp*4+2]
                cmp     eax,edx
                je      blit11_same_bank
                call    set_vesa_bank
                mov     edx,eax
blit11_same_bank:

                push    eax

                movzx   ecx,byte ptr [offset screen_640_table+ebp*4+3]
blit11_inner_loop:
                mov     eax,dword ptr [esi]
                mov     dword ptr [edi],eax
                
                add     esi,4
                add     edi,4
                dec     ecx
                jnz     blit11_inner_loop

                cmp     byte ptr [offset screen_640_table+ebp*4+3],128
                je      blit11_skip

                movzx   eax,byte ptr [offset screen_640_table+ebp*4+2]
                inc     eax
                call    set_vesa_bank
                
                mov     ecx,128
                sub     cl,byte ptr [offset screen_640_table+ebp*4+3]
                mov     edi,0A0000h
                sub     edi,_code32a
blit11_inner_loop_2:
                mov     eax,dword ptr [esi]
                mov     dword ptr [edi],eax
                
                add     esi,4
                add     edi,4
                dec     ecx
                jnz     blit11_inner_loop_2

blit11_skip:
                pop     eax

                inc     ebp
                cmp     ebp,212
                jnz     blit11_outer_loop

                ret

blit11_mmx:
                mov     esi,blitbuffer
                mov     eax,0
                call    set_vesa_bank
                mov     ebp,0
                mov     edx,0

blit11_outer_loop_mmx:
                movzx   edi,word ptr [offset screen_640_table+ebp*4]
                add     edi,0a0000h
                sub     edi,_code32a
                movzx   eax,byte ptr [offset screen_640_table+ebp*4+2]
                cmp     eax,edx
                je      blit11_same_bank_mmx
                call    set_vesa_bank
                mov     edx,eax
blit11_same_bank_mmx:

                push    eax

                movzx   ecx,byte ptr [offset screen_640_table+ebp*4+3]
                shr     ecx,1
blit11_inner_loop_mmx:
                add     edi,8

                ; movq MM0,[esi]
                movq
                db      00000110b

                add     esi,8
                
                ; movq_st [edi-8],MM0
                movq_st
                db      10000111b
                dd      -8

                dec     ecx
                
                jnz     blit11_inner_loop_mmx

                cmp     byte ptr [offset screen_640_table+ebp*4+3],128
                je      blit11_skip_mmx

                movzx   eax,byte ptr [offset screen_640_table+ebp*4+2]
                inc     eax
                call    set_vesa_bank
                
                mov     ecx,128
                sub     cl,byte ptr [offset screen_640_table+ebp*4+3]
                mov     edi,0A0000h
                sub     edi,_code32a
                shr     ecx,1
blit11_inner_loop_2_mmx:
                add     edi,8

                ; movq MM0,[esi]
                movq
                db      00000110b

                add     esi,8
                
                ; movq_st [edi-8],MM0
                movq_st
                db      10000111b
                dd      -8

                dec     ecx
                
                jnz     blit11_inner_loop_2_mmx

blit11_skip_mmx:
                pop     eax

                inc     ebp
                cmp     ebp,212
                jnz     blit11_outer_loop_mmx

                ret

; --------------------------------------------------------------------

eval_bottom_field_11:
                test    byte ptr [offset vdpregs+9],BIT_7
                jnz     _ret

                cmp     text_columns,80
                je      eval_bottom_field_11_512

                cmp     actualscreen,6
                je      eval_bottom_field_11_512

                cmp     actualscreen,7
                je      eval_bottom_field_11_512

                mov     edi,blitbuffer
                add     edi,192*256
                mov     ecx,(212-192)*256/4
                mov     eax,0
                rep     stosd
                ret

eval_bottom_field_11_512:
                mov     edi,blitbuffer
                add     edi,192*512
                mov     ecx,(212-192)*512/4
                mov     eax,0
                rep     stosd
                ret

; --------------------------------------------------------------------
; blit12 - 512x384x16

blit12:
                cmp     actualscreen,8
                je      blit12_screen8

                cmp     actualscreen,6
                jae     blit12_screen6

                cmp     text_columns,80
                je      blit12_screen6

                call    init_high_palette

                cmp     enginetype,2
                je      blit12_mmx

                mov     eax,0
                mov     esi,blitbuffer
blit12_double_bank:
                call    set_vesa_bank
                mov     edi,0a0000h
                sub     edi,_code32a

                push    eax
                mov     edx,192/6

blit12_double_outer:
                push    edx
                mov     ecx,256

blit12_double_inner:
                movzx   eax,byte ptr [esi]
                inc     esi
                mov     edx,dword ptr [offset high_palette+eax*4]
                mov     [edi],edx
                add     edi,4
                dec     ecx
                jnz     blit12_double_inner

                pop     edx
                add     edi,512*2
                dec     edx
                jnz     blit12_double_outer

                pop     eax
                inc     eax
                cmp     eax,6
                jnz     blit12_double_bank
                ret

blit12_mmx:
                mov     eax,0
                mov     esi,blitbuffer
blit12_double_bank_mmx:
                call    set_vesa_bank
                mov     edi,0a0000h
                sub     edi,_code32a

                push    eax
                mov     edx,192/6

blit12_double_outer_mmx:
                push    edx
                mov     ecx,256/4

blit12_double_inner_mmx:
                mov     ebx,dword ptr [esi]
                movzx   eax,bh
                mov     edx,dword ptr [offset high_palette+eax*4]

                ;movd    MM0,edx
                movd
                db      11000010b

                movzx   eax,bl

                ;psllq    MM0,32
                psllq   
                db      11110000b
                db      32

                add     esi,2
                mov     edx,dword ptr [offset high_palette+eax*4]

                ;movd    MM1,edx
                movd
                db      11001010b

                ;por     MM0,MM1
                por
                db      11000001b

                shr     ebx,16

                ; movq_st [edi],MM0
                movq_st
                db      00000111b

                add     edi,8

                movzx   eax,bh
                mov     edx,dword ptr [offset high_palette+eax*4]

                ;movd    MM0,edx
                movd
                db      11000010b

                movzx   eax,bl

                ;psllq    MM0,32
                psllq   
                db      11110000b
                db      32

                add     esi,2
                mov     edx,dword ptr [offset high_palette+eax*4]

                ;movd    MM1,edx
                movd
                db      11001010b

                ;por     MM0,MM1
                por
                db      11000001b

                ; movq_st [edi],MM0
                movq_st
                db      00000111b

                add     edi,8

                dec     ecx
                jnz     blit12_double_inner_mmx

                pop     edx
                add     edi,512*2
                dec     edx
                jnz     blit12_double_outer_mmx

                pop     eax
                inc     eax
                cmp     eax,6
                jnz     blit12_double_bank_mmx

                ret

; --------------------------------------------------------------------

blit12_screen6:
                call    init_high_palette

                mov     eax,0
                mov     esi,blitbuffer
blit12_double_bank_screen6:
                call    set_vesa_bank
                mov     edi,0a0000h
                sub     edi,_code32a

                push    eax
                mov     edx,192/6

blit12_double_outer_screen6:
                push    edx
                mov     ecx,256

blit12_double_inner_screen6:
                movzx   eax,byte ptr [esi+1]
                movzx   edx,word ptr [offset high_palette+eax*4]
                shl     edx,16
                movzx   eax,byte ptr [esi]
                add     esi,2
                mov     dx,word ptr [offset high_palette+eax*4]
                mov     [edi],edx
                add     edi,4
                dec     ecx
                jnz     blit12_double_inner_screen6

                pop     edx
                add     edi,512*2
                dec     edx
                jnz     blit12_double_outer_screen6

                pop     eax
                inc     eax
                cmp     eax,6
                jnz     blit12_double_bank_screen6
                ret

; --------------------------------------------------------------------

init_high_palette:
                ; init the msx1 palette
                mov     edi,offset high_palette
                mov     esi,offset sg1000_high_palette
                mov     ecx,16
init_msx1_high_palette:
                mov     ax,word ptr [esi]
                mov     word ptr [edi],ax
                mov     word ptr [edi+2],ax
                add     esi,2
                add     edi,4
                dec     ecx
                jnz     init_msx1_high_palette

                cmp     actualscreen,0
                je      init_high_palette_scr0

                mov     ebp,0
                mov     esi,offset msx2palette
                mov     edi,offset high_palette+16*4
init_msx2_high_palette:
                mov     ax,word ptr [esi]
                add     esi,2

                mov     bl,al
                shr     bl,4
                and     bl,7
                mov     bh,bl
                shr     bh,1
                shl     bl,2
                or      bl,bh
                and     ebx,31
                mov     edx,ebx

                mov     bl,ah
                and     bl,111b
                mov     bh,bl
                shr     bh,1
                shl     bl,2
                or      bl,bh
                shl     edx,5
                or      dl,bl

                mov     bl,al
                and     bl,111b
                mov     bh,bl
                shr     bh,1
                shl     bl,2
                or      bl,bh
                shl     edx,5
                or      dl,bl

                mov     ebx,edx
                shl     edx,16
                or      edx,ebx

                mov     dword ptr [edi],edx
                add     edi,4
                inc     ebp
                cmp     ebp,16
                jnz     init_msx2_high_palette

                test    byte ptr [offset vdpregs+8],BIT_5
                jnz     _ret

                ; init color 0
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,15
                mov     ebx,dword ptr [offset high_palette+eax*4]
                mov     dword ptr [offset high_palette],ebx
                mov     ebx,dword ptr [offset high_palette+eax*4+16*4]
                mov     dword ptr [offset high_palette+16*4],ebx

                ret

init_high_palette_scr0:
                movzx   eax,byte ptr [offset vdpregs+7]
                and     eax,0Fh
                mov     ebx,dword ptr [offset high_palette+eax*4]
                mov     dword ptr [offset high_palette+16*4],ebx

                movzx   eax,byte ptr [offset vdpregs+7]
                shr     eax,4
                and     eax,0Fh
                mov     ebx,dword ptr [offset high_palette+eax*4]
                mov     dword ptr [offset high_palette+16*4+4],ebx

                ret

; --------------------------------------------------------------------

blit12_screen8:
                test    byte ptr [offset vdpregs+25],BIT_3
                jnz     blit12_yjk

blit12_screen8_start:
                mov     eax,0
                mov     esi,blitbuffer
blit12_scr8_bank:
                call    set_vesa_bank
                mov     edi,0a0000h
                sub     edi,_code32a

                push    eax
                mov     edx,192/6

blit12_scr8_outer:
                push    edx
                mov     ecx,256

blit12_scr8_inner:
                movzx   eax,byte ptr [esi]

                mov     bl,al
                shr     bl,2
                and     ebx,7
                shl     ebx,2
                mov     edx,ebx

                mov     bl,al
                shr     bl,5
                and     ebx,7
                shl     ebx,2
                shl     edx,5
                or      edx,ebx

                mov     bl,al
                and     ebx,3
                shl     ebx,3
                shl     edx,5
                or      edx,ebx

                mov     ebx,edx
                shl     edx,16
                or      edx,ebx

                inc     esi
                mov     [edi],edx
                add     edi,4
                dec     ecx
                jnz     blit12_scr8_inner

                pop     edx
                add     edi,512*2
                dec     edx
                jnz     blit12_scr8_outer

                pop     eax
                inc     eax
                cmp     eax,6
                jnz     blit12_scr8_bank
                ret

; --------------------------------------------------------------------

blit12_yjk:
                cmp     msxmodel,2
                jb      blit12_screen8_start

                test    byte ptr [offset vdpregs+25],BIT_4
                jnz     blit12_scr11

                call    check_bargraph

                mov     eax,0
                mov     esi,blitbuffer
blit12_scr12_bank:
                call    set_vesa_bank
                mov     edi,0a0000h
                sub     edi,_code32a

                push    eax
                mov     edx,192/6

blit12_scr12_outer:
                push    edx
                mov     ecx,256/4

blit12_scr12_inner:
                ; ebx = K (signed)
                mov     bl,[esi+1]
                and     bl,7
                shl     bl,3
                mov     bh,[esi]
                and     bh,7
                or      bl,bh
                shl     bl,2
                movsx   ebx,bl
                sar     ebx,2

                ; edx = J (signed)
                mov     dl,[esi+3]
                and     dl,7
                shl     dl,3
                mov     dh,[esi+2]
                and     dh,7
                or      dl,dh
                shl     dl,2
                movsx   edx,dl
                sar     edx,2

                irp     i,<0,1,2,3>
                local   clipr_0,clipr_255
                local   clipg_0,clipg_255
                local   clipb_0,clipb_255

                mov     eax,0

                ; evaluate R=8Y+8J
                movzx   ebp,byte ptr [esi+i]
                and     ebp,0F8h
                lea     ebp,[ebp+edx*8]
                cmp     ebp,0
                jge     clipr_0
                mov     ebp,0        
clipr_0:
                cmp     ebp,255
                jle     clipr_255
                mov     ebp,255
clipr_255:
                shr     ebp,3
                shl     eax,5
                or      eax,ebp

                ; evaluate G=8Y+8K
                movzx   ebp,byte ptr [esi+i]
                and     ebp,0F8h
                lea     ebp,[ebp+ebx*8]
                cmp     ebp,0
                jge     clipg_0
                mov     ebp,0        
clipg_0:
                cmp     ebp,255
                jle     clipg_255
                mov     ebp,255
clipg_255:
                shr     ebp,3
                shl     eax,5
                or      eax,ebp

                ; evaluate B=10Y-4J-2K
                movzx   ebp,byte ptr [esi+i]
                and     ebp,0F8h
                shr     ebp,2
                lea     ebp,[ebp+ebp*4]
                neg     ebp
                lea     ebp,[ebp+edx*4]
                lea     ebp,[ebp+ebx*2]
                neg     ebp
                cmp     ebp,0
                jge     clipb_0
                mov     ebp,0        
clipb_0:
                cmp     ebp,255
                jle     clipb_255
                mov     ebp,255
clipb_255:
                shr     ebp,3
                shl     eax,5
                or      eax,ebp

                mov     ebp,eax
                shl     eax,16
                or      eax,ebp
                mov     [edi],eax
                add     edi,4

                endm
                add     esi,4

                dec     ecx
                jnz     blit12_scr12_inner

                pop     edx
                add     edi,512*2
                dec     edx
                jnz     blit12_scr12_outer

                pop     eax
                inc     eax
                cmp     eax,6
                jnz     blit12_scr12_bank
                ret

; --------------------------------------------------------------------

check_bargraph:
                cmp     bargraphmode,1
                jne     _ret

                mov     edi,blitbuffer
                mov     ecx,47

check_bargraph_outer:
                mov     ebx,52/4

check_bargraph_inner:
                mov     eax,[edi]
                shl     eax,4
                and     eax,0F0F0F0F0h
                mov     [edi],eax
                add     edi,4
                dec     ebx
                jnz     check_bargraph_inner

                add     edi,256-52
                dec     ecx
                jnz     check_bargraph_outer

                ret

; --------------------------------------------------------------------

blit12_scr11:
                call    init_high_palette
                call    check_bargraph

                mov     eax,0
                mov     esi,blitbuffer
blit12_scr11_bank:
                call    set_vesa_bank
                mov     edi,0a0000h
                sub     edi,_code32a

                push    eax
                mov     edx,192/6
           
blit12_scr11_outer:
                push    edx
                mov     ecx,256/4

blit12_scr11_inner:
                ; ebx = K (signed)
                mov     bl,[esi+1]
                and     bl,7
                shl     bl,3
                mov     bh,[esi]
                and     bh,7
                or      bl,bh
                shl     bl,2
                movsx   ebx,bl
                sar     ebx,2

                ; edx = J (signed)
                mov     dl,[esi+3]
                and     dl,7
                shl     dl,3
                mov     dh,[esi+2]
                and     dh,7
                or      dl,dh
                shl     dl,2
                movsx   edx,dl
                sar     edx,2

                irp     i,<0,1,2,3>
                local   clipr_0,clipr_255
                local   clipg_0,clipg_255
                local   clipb_0,clipb_255
                local   draw_yjk,draw_next

                test    byte ptr [esi+i],BIT_3
                jz      draw_yjk

                movzx   ebp,byte ptr [esi+i]
                shr     ebp,4
                mov     eax,[offset high_palette+16*4+ebp*4]
                mov     [edi],eax
                add     edi,4
                jmp     draw_next

draw_yjk:
                mov     eax,0

                ; evaluate R=8Y+8J
                movzx   ebp,byte ptr [esi+i]
                and     ebp,0F0h
                lea     ebp,[ebp+edx*8]
                cmp     ebp,0
                jge     clipr_0
                mov     ebp,0        
clipr_0:
                cmp     ebp,255
                jle     clipr_255
                mov     ebp,255
clipr_255:
                shr     ebp,3
                shl     eax,5
                or      eax,ebp

                ; evaluate G=8Y+8K
                movzx   ebp,byte ptr [esi+i]
                and     ebp,0F0h
                lea     ebp,[ebp+ebx*8]
                cmp     ebp,0
                jge     clipg_0
                mov     ebp,0        
clipg_0:
                cmp     ebp,255
                jle     clipg_255
                mov     ebp,255
clipg_255:
                shr     ebp,3
                shl     eax,5
                or      eax,ebp

                ; evaluate B=10Y-4J-2K
                movzx   ebp,byte ptr [esi+i]
                and     ebp,0F0h
                shr     ebp,2
                lea     ebp,[ebp+ebp*4]
                neg     ebp
                lea     ebp,[ebp+edx*4]
                lea     ebp,[ebp+ebx*2]
                neg     ebp
                cmp     ebp,0
                jge     clipb_0
                mov     ebp,0        
clipb_0:
                cmp     ebp,255
                jle     clipb_255
                mov     ebp,255
clipb_255:
                shr     ebp,3
                shl     eax,5
                or      eax,ebp

                mov     ebp,eax
                shl     eax,16
                or      eax,ebp
                mov     [edi],eax
                add     edi,4
draw_next:
                endm
                add     esi,4

                dec     ecx
                jnz     blit12_scr11_inner

                pop     edx
                add     edi,512*2
                dec     edx
                jnz     blit12_scr11_outer

                pop     eax
                inc     eax
                cmp     eax,6
                jnz     blit12_scr11_bank
                ret

code32          ends
                end


