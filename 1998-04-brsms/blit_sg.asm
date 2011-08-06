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
include vdp_sg.inc
include io.inc
include vesa.inc
include vdp.inc
include blit.inc

extrn blitbuffer: dword
extrn redbuffer: dword

public blit_msx

; DATA ---------------------------------------------------------------

callback_512    dd      0

; CODE ---------------------------------------------------------------

; blit ---------------------------------------------------------------
; copy the contents of blit buffer to pentium video memory

blit_msx:              
                cmp     videomode,0
                je      blit0

                cmp     videomode,2
                je      blit2

                cmp     videomode,4
                je      blit4

                cmp     videomode,6
                je      blit6

                cmp     videomode,8
                je      blit8

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


blit6:
                mov     callback_512,offset blit_linear_512_15_branch

blit6_start:                
                cmp     lastscreen,0
                je      convert_direct_screen0

                mov     esi,blitbuffer
                mov     edi,redbuffer
                mov     ecx,256*192
                movzx   eax,byte ptr [offset vdpregs+7]
                mov     bx,word ptr [offset sg1000_high_palette+eax*2]
                mov     word ptr [offset sg1000_high_palette],bx

convert_direct_loop:
                movzx   eax,byte ptr [esi]
                inc     esi
                mov     bx,word ptr [offset sg1000_high_palette+eax*2]
                mov     word ptr [edi],bx
                add     edi,2
                dec     ecx
                jnz     convert_direct_loop

                mov     ebx,callback_512
                jmp     ebx

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
                movzx   eax,byte ptr [esi]
                inc     esi
                or      eax,eax
                jz      convert_direct_screen0_color0
                mov     bx,word ptr [offset sg1000_high_palette+edx*2]
                jmp     convert_direct_screen0_draw

convert_direct_screen0_color0:
                mov     bx,word ptr [offset sg1000_high_palette+ebp*2]

convert_direct_screen0_draw:
                mov     word ptr [edi],bx
                add     edi,2
                dec     ecx
                jnz     convert_direct_screen0_loop

                mov     ebx,callback_512
                jmp     ebx

blit4:
                mov     callback_512,offset blit_linear_512_inter_branch
                jmp     blit6_start

blit8:
                mov     callback_512,offset blit_linear_512_2xsai_branch
                jmp     blit6_start

code32          ends
                end


