	.686p
        .MMX
	.MODEL	FLAT
; --------------------------------------------------------------------

       	.DATA

extrn _line: dword
extrn _vram: dword
extrn _drawbuffer: dword
extrn _vdpreg: dword
extrn _windowcolor: dword
extrn _drawpitch: dword
extrn _tvborder: near
extrn _scanline_intensity: dword

include scr2fore.inc
include scr2frmx.inc
include scr2bkmx.inc

align 8
minibuffer:     db      592 dup(0)
mask10          dq      1010101010101010h
mask0F          dq      0F0F0F0F0F0F0F0Fh
mask80          dq      8080808080808080h
mask_X          dq      0102040810204080h

totalsprites    dd      0
sprite_lines    dd      0
sprite_mask     dd      0FFh

public  _bitdepth
_bitdepth        dd      0


RGB macro q1,q2,q3
  db q3,q2,q1,0,q3,q2,q1,0
endm

RGB16 macro q1,q2,q3
  lq1 = (q1+4)
  lq2 = (q2+2)
  lq3 = (q3+4)
  if lq1 gt 255
    lq1=255
  endif
  if lq2 gt 255
    lq2=255
  endif
  if lq3 gt 255
    lq3=255
  endif
  dw ((lq1 SHR 3) SHL 11) + ((lq2 SHR 2) SHL 5) + ((lq3 SHR 3))
  dw ((lq1 SHR 3) SHL 11) + ((lq2 SHR 2) SHL 5) + ((lq3 SHR 3))
endm

public _palette32
_palette32:
palette32:
;        RGB       0,0,0
;        RGB       0,0,0
;        RGB       33,200,66
;        RGB       94,220,120
;        RGB       84,85,237
;        RGB       125,118,252
;        RGB       212,82,77
;        RGB       66,235,245
;        RGB       252,85,84
;        RGB       255,121,120
;        RGB       212,193,84
;        RGB       230,206,128
;        RGB       33,176,59
;        RGB       201,91,186
;        RGB       204,204,204
;        RGB       255,255,255

RGB     0       ,0       ,0
RGB     0       ,0       ,0
RGB     0       ,137     ,10
RGB     43      ,158     ,56
RGB     36      ,25      ,184
RGB     82      ,61      ,206
RGB     168     ,24      ,18
RGB     23      ,179     ,195
RGB     217     ,31      ,26
RGB     255     ,68      ,60
RGB     168     ,141     ,26
RGB     184     ,154     ,69
RGB     0       ,104     ,5
RGB     163     ,38      ,132
RGB     163     ,168     ,152
RGB     217     ,212     ,206

public _palette16
_palette16:
palette16:
RGB16     0       ,0       ,0
RGB16     0       ,0       ,0
RGB16     0       ,137     ,10
RGB16     43      ,158     ,56
RGB16     36      ,25      ,184
RGB16     82      ,61      ,206
RGB16     168     ,24      ,18
RGB16     23      ,179     ,195
RGB16     217     ,31      ,26
RGB16     255     ,68      ,60
RGB16     168     ,141     ,26
RGB16     184     ,154     ,69
RGB16     0       ,104     ,5
RGB16     163     ,38      ,132
RGB16     163     ,168     ,152
RGB16     217     ,212     ,206

; --------------------------------------------------------------------

        .CODE

public _runVDP

_runVDP:
        pushad

        ; adjust the border color
        movzx   eax,byte ptr [offset _vdpreg+7]
        and     eax,15
        jnz     border_skip
        mov     eax,1
border_skip:
        cmp     _bitdepth,16
        je      border_16
        movq    mm0,[offset palette32+eax*8]
        movq    qword ptr [offset palette32],mm0
        jmp     border_exit
border_16:
        mov     eax,[offset palette16+eax*4]
        mov     dword ptr [offset palette16],eax
border_exit:
        ; check for visible line
        mov     ecx,_line
        cmp     ecx,192
        jae     render_disabled

        ; test for screen disabled
        test    byte ptr [offset _vdpreg+1],64
        jz      render_disabled

        test    byte ptr [offset _vdpreg],2
        jnz     render_screen2

        test    byte ptr [offset _vdpreg+1],16
        jnz     render_screen0

        ; fall through

; --------------------------------------------------------------------

render_screen1:
        ; screen 1 render
        mov     ebp,ecx
        and     ebp,7
        ; ebp = subline

        shr     ecx,3
        shl     ecx,5
        ; ecx = block line

        ; retrieve pattern table
        movzx   esi,byte ptr [offset _vdpreg+4]
        shl     esi,11
        add     esi,ebp
        add     esi,_vram

        ; retrieve color table
        movzx   eax,byte ptr [offset _vdpreg+3]
        shl     eax,6
        add     eax,_vram

        ; retrieve name table
        movzx   edi,byte ptr [offset _vdpreg+2]
        and     edi,0Fh
        shl     edi,10
        add     edi,ecx
        add     edi,_vram

        mov     ecx,eax
        xor     edx,edx
screen1_loop:
        ; get character
        movzx   ebx,byte ptr [edi+edx]

        ; get pattern
        movzx   eax,byte ptr [esi+ebx*8]

        ; get color
        shr     ebx,3
        movzx   ebx,byte ptr [ecx+ebx]

        ; draw eight pixels
        movq    mm0,[offset foregroundmask+eax*8]
        movq    mm1,mm0
        pand    mm0,[offset foregroundcolor_MMX+ebx*8]
        pandn   mm1,[offset backgroundcolor_MMX+ebx*8]
        por     mm0,mm1
        movq    [offset minibuffer+40+edx*8],mm0

        inc     edx
        cmp     edx,32
        jnz     screen1_loop

        jmp     draw_sprite

; --------------------------------------------------------------------

DRAW_SPRITE_SLICE macro size

        push    edx
        mov     edx,ebx

        irp     i,<0,1>

        mov     eax,edx

        ; get pattern number of sprite
        movzx   ebx,byte ptr [ebp+esi+2]
        and     ebx,sprite_mask

        ; get pattern of sprite subline
        lea     ebx,[eax+ebx*8]
        add     ebx,edi
        movzx   eax,byte ptr [ebp+ebx+16*i]
        movq    mm0,[offset foregroundmask+eax*8]

        ; get background
        movzx   eax,byte ptr [ebp+esi+1]
        lea     eax,[minibuffer+40+eax+8*i]
        movzx   ebx,byte ptr [ebp+esi+3]
        and     ebx,128
        shr     ebx,2
        sub     eax,ebx
        movq    mm5,qword ptr [eax]

        ; generate sprite priority mask
        movq    mm4,mm5
        pcmpgtb mm4,mm6
        pandn   mm4,mm0

        ; get color
        movq    mm1,[offset backgroundcolor_MMX+ecx*8]
        por     mm1,mm7
        pand    mm1,mm4

        ; mix and draw
        pandn   mm4,mm5
        por     mm4,mm1
        movq    qword ptr [eax],mm4

        if      i eq 0
        test    byte ptr [offset _vdpreg+1],2
        jz      sprite_8x8_exit
        else
sprite_8x8_exit:
        endif

        endm
        pop     edx

        endm

; --------------------------------------------------------------------

render_screen2:
        ; enter with ecx = current line

        mov     ebp,ecx
        and     ebp,7
        ; ebp = subline

        mov     edi,ecx
        and     edi,11000000b
        shl     edi,2+3
        ; edi = section (third)

        shr     ecx,3
        shl     ecx,5
        ; ecx = block line

        ; retrieve pattern table
        movzx   esi,byte ptr [offset _vdpreg+4]
        and     esi,04h
        shl     esi,11
        add     esi,ebp
        add     esi,edi
        add     esi,_vram

        ; retrieve color table
        movzx   eax,byte ptr [offset _vdpreg+3]
        and     eax,128
        shl     eax,6
        add     eax,ebp
        add     eax,edi
        add     eax,_vram

        ; retrieve name table
        movzx   edi,byte ptr [offset _vdpreg+2]
        and     edi,0Fh
        shl     edi,10
        add     edi,ecx
        add     edi,_vram

        ;
        movq    mm2,mask0F
        movq    mm6,mask_X
        pxor    mm7,mm7
        ;

        mov     ecx,eax
        xor     edx,edx
screen2_loop:
        ; get character
        movzx   ebx,byte ptr [edi+edx]

        ; get pattern
        ; get color
        movq    mm0,[esi+ebx*8]
        movq    mm3,[ecx+ebx*8]
        punpcklbw mm0,mm0
        punpcklbw mm3,mm3
        punpcklbw mm0,mm0
        punpcklbw mm3,mm3
        punpcklbw mm0,mm0
        punpcklbw mm3,mm3
        pand    mm0,mm6
        movq    mm4,mm3
        pcmpeqb mm0,mm7
        pand    mm3,mm2
        psrlq   mm4,4
        movq    mm1,mm0
        pand    mm4,mm2
        pand    mm0,mm3
        pandn   mm1,mm4
        por     mm0,mm1
        movq    [offset minibuffer+40+edx*8],mm0

        inc     edx
        cmp     edx,32
        jnz     screen2_loop

        ; fall through

; --------------------------------------------------------------------

draw_sprite:
        mov     ebp,_vram
        xor     edx,edx
        mov     totalsprites,edx
        movq    mm7,mask10
        movq    mm6,mask0F
        pxor    mm2,mm2
draw_sprite_loop:
        ; sprite attribute table
        movzx   esi,byte ptr [offset _vdpreg+5]
        and     esi,07Fh
        shl     esi,7
        lea     esi,[esi+edx*4]

        ; sprite pattern table
        movzx   edi,byte ptr [offset _vdpreg+6]
        and     edi,07h
        shl     edi,11

        ; check for end of sprites
        movzx   eax,byte ptr [ebp+esi]
        cmp     eax,0D0h
        je      color32

        ; check for sprites entering screen from top
        cmp     al,0BEh
        jbe     sprite_inside_screen
        movsx   eax,al
sprite_inside_screen:

        ; check for 8x8 sprites
        mov     sprite_lines,16
        mov     sprite_mask,0FCh
        test    byte ptr [offset _vdpreg+1],2
        jnz     sprite_16x16
        mov     sprite_lines,8
        mov     sprite_mask,0FFh
sprite_16x16:

        ; check for visible sprites
        mov     ebx,_line
        dec     ebx
        cmp     ebx,eax
        jl      draw_sprite_next

        sub     ebx,eax
        cmp     ebx,sprite_lines
        jae     draw_sprite_next

        ; check for transparent sprite
        movzx   ecx,byte ptr [ebp+esi+3]
        and     ecx,0Fh
        jz      draw_sprite_count

        ; eax = subline
        DRAW_SPRITE_SLICE 1

draw_sprite_count:
        mov     eax,totalsprites
        inc     eax
        cmp     eax,4
        je      color32
        mov     totalsprites,eax

draw_sprite_next:
        inc     edx
        cmp     edx,32
        jnz     draw_sprite_loop

        jmp     color32

; --------------------------------------------------------------------

public _render_lastline
_render_lastline:
        pushad
color32:
        cmp     _bitdepth,16
        je      color16

        pxor    mm0,mm0

        irp     i,<0,1,2>
        movq    qword ptr [offset minibuffer+20-4+i*8],mm0
        movq    qword ptr [offset minibuffer+40+256+i*8],mm0
        endm

        mov     esi,offset minibuffer+20
        mov     edi,_drawbuffer
        mov     ebp,256+40 ;256+80
        mov     ebx,0Fh
        mov     ecx,8
        mov     edx,offset palette32
        ;
        pxor    mm2,mm2
        movd    mm4,_scanline_intensity
        punpcklbw mm4,mm2
        ;
color32_loop:
        movzx   eax,byte ptr [esi]
        and     eax,ebx
        movq    mm0,[edx+eax*8]
        ;
        movq    mm1,mm0
        punpckhbw mm0,mm2
        punpckhbw mm1,mm2
        pmullw  mm0,mm4
        pmullw  mm1,mm4
        psrlw   mm0,7
        psrlw   mm1,7
        packuswb mm0,mm1
        ;
        movq    [edi],mm0
        inc     esi
        add     edi,ecx
        dec     ebp
        jnz     color32_loop

        popad
        emms
        ret

; --------------------------------------------------------------------
color16:

        pxor    mm0,mm0

        irp     i,<0,1,2>
        movq    qword ptr [offset minibuffer+20-4+i*8],mm0
        movq    qword ptr [offset minibuffer+40+256+i*8],mm0
        endm

        mov     esi,offset minibuffer+20
        mov     edi,_drawbuffer
        mov     ebp,256+40 ;256+80
        mov     ebx,0Fh
        mov     ecx,4
        mov     edx,offset palette16
        ;
        ;pxor    mm2,mm2
        ;movd    mm4,_scanline_intensity
        ;punpcklbw mm4,mm2
        pxor    mm1,mm1
        mov     eax,_scanline_intensity
        and     eax,0FFh
        cmp     eax,40h
        jb      color16_black
        pcmpeqb mm1,mm1
color16_black:
        ;
color16_loop:
        movzx   eax,byte ptr [esi]
        and     eax,ebx
        movd    mm0,[edx+eax*4]
        pand    mm0,mm1
        movd    eax,mm0
        ;mov     eax,[edx+eax*4]

        ;movzx   eax,byte ptr [esi+1]
        ;and     eax,ebx
        ;movd    mm3,[edx+eax*4]
        ;
        ;psrlq   mm0,32
        ;por     mm0,mm3
        ;
        ;movq    mm1,mm0
        ;punpckhbw mm0,mm2
        ;punpckhbw mm1,mm2
        ;pmullw  mm0,mm4
        ;pmullw  mm1,mm4
        ;psrlw   mm0,7
        ;psrlw   mm1,7
        ;packuswb mm0,mm1
        ;
        ;movq    [edi],mm0
        mov     [edi],eax
        ;add     esi,2
        inc     esi
        add     edi,ecx
        ;sub     ebp,2
        dec     ebp
        jnz     color16_loop

        popad
        emms
        ret

; --------------------------------------------------------------------

render_screen0:
        ; screen 0 render

        ; offset into pattern table
        mov     ebp,ecx
        and     ebp,7
        add     ebp,_vram
        movzx   eax,byte ptr [_vdpreg+4]
        and     eax,07h
        shl     eax,11
        add     ebp,eax

        ; offset into name table
        movzx   esi,byte ptr [_vdpreg+2]
        and     esi,0Fh
        shl     esi,10
        add     esi,_vram

        mov     edi,offset minibuffer+48
        shr     ecx,3
        lea     ecx,[ecx*4+ecx]
        shl     ecx,3
        mov     edx,40

        ; get foreground color
        movzx   eax,byte ptr [_vdpreg+7]
        shr     eax,4
        movd    mm1,eax
        punpcklbw mm1,mm1
        punpcklbw mm1,mm1
        punpcklbw mm1,mm1

        ; get background color
        movzx   eax,byte ptr [_vdpreg+7]
        and     eax,0Fh
        movd    mm2,eax
        punpcklbw mm2,mm2
        punpcklbw mm2,mm2
        punpcklbw mm2,mm2

screen0_loop:
        movzx   ebx,byte ptr [esi+ecx]
        movzx   ebx,byte ptr [ebp+ebx*8]
        movq    mm0,[offset foregroundmask+ebx*8]
        movq    mm3,mm0
        pand    mm0,mm1
        pandn   mm3,mm2
        por     mm0,mm3
        movq    [edi],mm0

        add     edi,6
        inc     ecx
        dec     edx
        jnz     screen0_loop

        pxor    mm0,mm0
        movq    qword ptr [offset minibuffer+40],mm0
        movq    qword ptr [offset minibuffer+48+40*6],mm0

        jmp     color32

; --------------------------------------------------------------------

render_disabled:
        ; render for blank screen = color 0
        mov     edi,offset minibuffer
        pxor    mm0,mm0
        mov     ecx,592/8
render_disabled_loop:
        movq    [edi],mm0

        add     edi,8
        dec     ecx
        jnz     render_disabled_loop

        jmp     color32

; --------------------------------------------------------------------

public _draw_border
_draw_border:
        pushad
        movd    mm0,_windowcolor
        pxor    mm7,mm7
        punpcklbw mm0,mm7
        mov     edx,20
        mov     ebx,_drawbuffer
        mov     ebp,_drawpitch
        mov     esi,offset _tvborder
draw_border_outer:
        mov     ecx,592/2/4
        mov     edi,ebx
draw_border_inner:
        movq    mm1,[esi]
        mov     eax,[edi]

        movq    mm2,mm1
        punpcklbw mm2,mm2
        movq    mm3,mm2
        punpcklbw mm2,mm2

        movq    mm4,mm2
        movq    mm6,mm2
        punpckhbw mm2,mm7
        pmullw  mm2,mm0
        psrlw   mm2,7
        punpcklbw mm4,mm7
        pmullw  mm4,mm0
        psrlw   mm4,7
        packuswb mm4,mm2

        ;movq mm2,[edi+0] ;;;
        movq    mm5,mask80
        psubusb mm5,mm6
        movq    mm6,mm5
        punpckhbw mm5,mm7
        pmullw  mm5,mm2 ;;[edi+0]
        psrlw   mm5,7
        punpcklbw mm6,mm7
        pmullw  mm6,mm2; [edi+0]
        psrlw   mm6,7
        packuswb mm6,mm5
        paddusb  mm4,mm6

        movq    [edi+0],mm4

        punpckhbw mm3,mm3
        movq    [edi+8],mm3

        movq    mm2,mm1
        punpckhbw mm2,mm2
        movq    mm3,mm2
        punpcklbw mm2,mm2
        movq    [edi+16],mm2

        punpckhbw mm3,mm3
        movq    [edi+24],mm3

        add     edi,32
        add     esi,8
        dec     ecx
        jnz     draw_border_inner

        add     ebx,ebp
        dec     edx
        jnz     draw_border_outer
        popad
        ret


        END