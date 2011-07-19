; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: V9958.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include z80core.inc
include v9938.inc
include vdp.inc
include bit.inc
include io.inc

extrn msxvram: dword

public render_screen5_msx2p
public render_screen6_msx2p
public render_screen2_msx2p
public saveline

; DATA ---------------------------------------------------------------

savescroll      dd      0
saveline        dd      0

; render_screen5_msx2p -----------------------------------------------
; render the SCREEN 5 with horizontal scroll

render_screen5_msx2p:
                call    set_adjust

                mov     edi,adjustbuffer
                mov     esi,first_line
                shl     esi,7
                lea     edi,[edi+esi*2]
                add     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,7
                mov     edx,esi
                add     esi,eax
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                test    byte ptr [offset vdpregs+2],BIT_5
                jz      render_screen5_single

                test    byte ptr [offset save_vdpregs+25],BIT_0
                jnz     render_screen5_dual

render_screen5_single:                
                movzx   ecx,byte ptr [offset vdpregs+26]
                and     ecx,03Fh
                cmp     ecx,32
                jbe     render_screen5_correct_limited
                and     ecx,01Fh
render_screen5_correct_limited:
                shl     ecx,3
                movzx   eax,byte ptr [offset vdpregs+27]
                and     eax,7
                sub     ecx,eax
                mov     savescroll,ecx
                cmp     ecx,0
                jge     render_screen5_correct
                mov     savescroll,0

render_screen5_correct:

                mov     ebp,msxvram
                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx

render_screen5_outer:
                push    ecx
                mov     edx,32

                push    edi
                mov     edi,saveline

render_screen5_inner:
                mov     eax,dword ptr [esi+ebp]
                mov     ecx,eax
                and     eax,0F0F0F0Fh
                mov     bh,ah
                shr     ecx,4
                and     ecx,0F0F0F0Fh
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                shr     eax,16
                mov     bl,cl
                shr     ecx,16
                or      ebx,10101010h
                mov     dword ptr [edi],ebx
                mov     bh,ah
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                mov     bl,cl
                or      ebx,10101010h
                mov     dword ptr [edi+4],ebx

                add     esi,4
                add     edi,8
                dec     edx
                jnz     render_screen5_inner

                pop     edi

                push    esi
                mov     esi,saveline
                add     esi,savescroll
                mov     ecx,256
                sub     ecx,savescroll
                rep     movsb
                mov     ecx,savescroll
                sub     esi,256
                rep     movsb
                pop     esi

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen5_outer

                mov     spriteenable,2

                ret

; --------------------------------------------------------------------

render_screen5_dual:                
                movzx   ecx,byte ptr [offset vdpregs+26]
                and     ecx,03Fh
                shl     ecx,3
                movzx   eax,byte ptr [offset vdpregs+27]
                and     eax,7
                sub     ecx,eax
                mov     savescroll,ecx
                cmp     ecx,0
                jge     render_screen5_correct_dual
                mov     savescroll,0

render_screen5_correct_dual:

                mov     ebp,msxvram
                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx

                and     esi,0FFFF7FFFh

render_screen5_outer_dual:
                push    ecx

                push    edi
                mov     edi,saveline
                mov     edx,32

render_screen5_inner_dual_1:
                mov     eax,dword ptr [esi+ebp]
                mov     ecx,eax
                and     eax,0F0F0F0Fh
                mov     bh,ah
                shr     ecx,4
                and     ecx,0F0F0F0Fh
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                shr     eax,16
                mov     bl,cl
                shr     ecx,16
                or      ebx,10101010h
                mov     dword ptr [edi],ebx
                mov     bh,ah
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                mov     bl,cl
                or      ebx,10101010h
                mov     dword ptr [edi+4],ebx

                add     esi,4
                add     edi,8
                dec     edx
                jnz     render_screen5_inner_dual_1

                add     esi,08000h
                sub     esi,128
                mov     edx,32

render_screen5_inner_dual_2:
                mov     eax,dword ptr [esi+ebp]
                mov     ecx,eax
                and     eax,0F0F0F0Fh
                mov     bh,ah
                shr     ecx,4
                and     ecx,0F0F0F0Fh
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                shr     eax,16
                mov     bl,cl
                shr     ecx,16
                or      ebx,10101010h
                mov     dword ptr [edi],ebx
                mov     bh,ah
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                mov     bl,cl
                or      ebx,10101010h
                mov     dword ptr [edi+4],ebx

                add     esi,4
                add     edi,8
                dec     edx
                jnz     render_screen5_inner_dual_2

                sub     esi,08000H

                pop     edi

                ; perform horiz scroll correction
                push    esi

                push    edi
                mov     esi,saveline
                mov     edi,512
                add     edi,esi
                mov     ecx,256/4
                rep     movsd
                pop     edi
                
                mov     esi,saveline
                add     esi,savescroll
                mov     ecx,256/4
                rep     movsd

                pop     esi
                ;

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen5_outer_dual

                mov     spriteenable,2

                ret

; render_screen6_msx2p -----------------------------------------------
; render the SCREEN 6 with horizontal scroll

render_screen6_msx2p:
                call    set_adjust

                cmp     videomode,7
                je      render_screen6_sizedown

                mov     edi,adjustbuffer
                mov     esi,first_line
                shl     esi,7
                lea     edi,[edi+esi*4]
                add     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,7
                mov     edx,esi
                add     esi,eax
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx
                
                movzx   ecx,byte ptr [offset vdpregs+26]
                and     ecx,03Fh
                shl     ecx,3
                movzx   eax,byte ptr [offset vdpregs+27]
                and     eax,7
                sub     ecx,eax
                add     ecx,ecx
                mov     savescroll,ecx
                cmp     ecx,0
                jge     render_screen6_correct
                mov     savescroll,0
render_screen6_correct:

                mov     ebp,msxvram
                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx
                mov     eax,0

                and     esi,0FFFF7FFFh

render_screen6_outer:
                push    ecx
                mov     edx,128/4
                push    edi
                mov     edi,saveline

render_screen6_inner_1:
                mov     ebx,dword ptr [esi+ebp]
                add     esi,4

                mov     al,bh
                mov     ecx,dword ptr [offset screen6_table+eax*4]
                mov     [edi+4],ecx
                mov     al,bl
                mov     ecx,dword ptr [offset screen6_table+eax*4]
                mov     [edi+0],ecx
                shr     ebx,16
                mov     al,bh
                mov     ecx,dword ptr [offset screen6_table+eax*4]
                mov     [edi+12],ecx
                mov     al,bl
                mov     ecx,dword ptr [offset screen6_table+eax*4]
                mov     [edi+8],ecx
                add     edi,16

                dec     edx
                jnz     render_screen6_inner_1

                add     esi,08000h
                sub     esi,128
                mov     edx,32

render_screen6_inner_2:
                mov     ebx,dword ptr [esi+ebp]
                add     esi,4

                mov     al,bh
                mov     ecx,dword ptr [offset screen6_table+eax*4]
                mov     [edi+4],ecx
                mov     al,bl
                mov     ecx,dword ptr [offset screen6_table+eax*4]
                mov     [edi+0],ecx
                shr     ebx,16
                mov     al,bh
                mov     ecx,dword ptr [offset screen6_table+eax*4]
                mov     [edi+12],ecx
                mov     al,bl
                mov     ecx,dword ptr [offset screen6_table+eax*4]
                mov     [edi+8],ecx
                add     edi,16

                dec     edx
                jnz     render_screen6_inner_2

                pop     edi
                
                sub     esi,08000H

                ; perform horiz scroll correction
                push    esi

                push    edi
                mov     esi,saveline
                mov     edi,512*2
                add     edi,esi
                mov     ecx,512/4
                rep     movsd
                pop     edi
                
                mov     esi,saveline
                add     esi,savescroll
                mov     ecx,512/4
                rep     movsd

                pop     esi
                ;

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                pop     ecx
                dec     ecx
                jnz     render_screen6_outer

                mov     spriteenable,0

                ret

; --------------------------------------------------------------------

render_screen6_sizedown:
                mov     edi,adjustbuffer
                mov     esi,first_line
                shl     esi,7
                lea     edi,[edi+esi*2]
                add     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,7
                mov     edx,esi
                add     esi,eax
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                movzx   ecx,byte ptr [offset vdpregs+26]
                and     ecx,03Fh
                shl     ecx,3
                movzx   eax,byte ptr [offset vdpregs+27]
                and     eax,7
                sub     ecx,eax
                mov     savescroll,ecx
                cmp     ecx,0
                jge     render_screen6_correct_sizedown
                mov     savescroll,0
render_screen6_correct_sizedown:

                mov     ebp,msxvram
                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx

                and     esi,0FFFF7FFFh

render_screen6_outer_sizedown:
                push    ecx
                mov     edx,32
                
                push    edi
                mov     edi,saveline

render_screen6_inner_sizedown_1:
                mov     eax,dword ptr [esi+ebp]
                mov     ecx,eax
                and     eax,0F0F0F0Fh
                mov     bh,ah
                shr     ecx,4
                and     ecx,0F0F0F0Fh
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                shr     eax,16
                mov     bl,cl
                shr     ecx,16
                and     ebx,03030303h
                or      ebx,10101010h
                mov     dword ptr [edi],ebx
                mov     bh,ah
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                mov     bl,cl
                and     ebx,03030303h
                or      ebx,10101010h
                mov     dword ptr [edi+4],ebx

                add     esi,4
                add     edi,8
                dec     edx
                jnz     render_screen6_inner_sizedown_1
                
                add     esi,08000h
                sub     esi,128
                mov     edx,32

render_screen6_inner_sizedown_2:
                mov     eax,dword ptr [esi+ebp]
                mov     ecx,eax
                and     eax,0F0F0F0Fh
                mov     bh,ah
                shr     ecx,4
                and     ecx,0F0F0F0Fh
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                shr     eax,16
                mov     bl,cl
                shr     ecx,16
                and     ebx,03030303h
                or      ebx,10101010h
                mov     dword ptr [edi],ebx
                mov     bh,ah
                mov     bl,ch
                shl     ebx,16
                mov     bh,al
                mov     bl,cl
                and     ebx,03030303h
                or      ebx,10101010h
                mov     dword ptr [edi+4],ebx

                add     esi,4
                add     edi,8
                dec     edx
                jnz     render_screen6_inner_sizedown_2
                
                pop     edi

                sub     esi,08000H

                ; perform horiz scroll correction
                push    esi
                ;
                push    edi
                mov     esi,saveline
                mov     edi,256*2
                add     edi,esi
                mov     ecx,256/4
                rep     movsd
                pop     edi
                ;
                mov     esi,saveline
                add     esi,savescroll
                mov     ecx,256/4
                rep     movsd
                ;
                pop     esi
                ;

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                pop     ecx
                dec     ecx
                jnz     render_screen6_outer_sizedown

                mov     spriteenable,0

                ret

; render_screen2_msx2p -----------------------------------------------
; render the SCREEN 2 with support to horizontal scroll
; MSX2 version

render_screen2_msx2p:
                call    set_adjust

                mov     edi,adjustbuffer
                mov     eax,first_line
                shl     eax,7
                lea     edi,[edi+eax*2]

                mov     esi,first_line
                movzx   eax,byte ptr [offset vdpregs+23]
                add     esi,eax
                and     esi,0FFh

                movzx   ecx,byte ptr [offset vdpregs+26]
                and     ecx,03Fh
                cmp     ecx,32
                jbe     render_screen2_correct_limited
                and     ecx,01Fh
render_screen2_correct_limited:
                shl     ecx,3
                movzx   eax,byte ptr [offset vdpregs+27]
                and     eax,7
                sub     ecx,eax
                mov     savescroll,ecx
;                cmp     ecx,0
;                jge     render_screen2_correct
;                mov     savescroll,0
;
;render_screen2_correct:
                mov     ebp,msxvram
                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx

                mov     eax,colortable
                sub     eax,patterntable
                mov     scr2_pat2col,eax

                mov     eax,patterntable
                sub     eax,colortable
                mov     scr2_col2pat,eax

render_screen2_outer:
                mov     edx,esi
                and     edx,0F8h
                shl     edx,2
                add     edx,nametable
                push    ecx esi ebp

                mov     ecx,32
                mov     eax,esi
                shr     eax,6
                shl     eax,8+3
                and     esi,7
                add     esi,ebp
                add     esi,eax
                add     edx,ebp

                add     esi,patterntable
                
                push    edi
                mov     edi,saveline

render_screen2_inner:
                movzx   eax,byte ptr [edx]

                movzx   ebp,byte ptr [esi+eax*8]
                add     esi,scr2_pat2col
                mov     ebx,dword ptr [offset foregroundmask+ebp*8]
                mov     ebp,dword ptr [offset backgroundmask+ebp*8]
                
                movzx   eax,byte ptr [esi+eax*8]
                add     esi,scr2_col2pat
                and     ebx,dword ptr [offset foregroundcolor+eax*4]
                and     ebp,dword ptr [offset backgroundcolor+eax*4]
                
                or      ebx,ebp
                or      ebx,10101010h
                
                mov     dword ptr [edi],ebx
                
                movzx   eax,byte ptr [edx]
                
                movzx   ebp,byte ptr [esi+eax*8]
                add     esi,scr2_pat2col
                mov     ebx,dword ptr [offset foregroundmask+ebp*8+4]
                mov     ebp,dword ptr [offset backgroundmask+ebp*8+4]
                
                movzx   eax,byte ptr [esi+eax*8]
                add     esi,scr2_col2pat
                and     ebx,dword ptr [offset foregroundcolor+eax*4]
                and     ebp,dword ptr [offset backgroundcolor+eax*4]
                
                or      ebx,ebp
                or      ebx,10101010h
                
                mov     dword ptr [edi+4],ebx
                
                add     edi,8
                inc     edx

                dec     ecx
                jnz     render_screen2_inner
                pop     edi
                
                pop     ebp esi ecx

                push    ecx
                push    esi

                cmp     savescroll,0
                jl      screen2_msx2p_negative

                mov     esi,saveline
                add     esi,savescroll
                mov     ecx,256
                sub     ecx,savescroll
                rep     movsb
                mov     ecx,savescroll
                sub     esi,256
                rep     movsb
                jmp     screen2_msx2p_continue

screen2_msx2p_negative:
                mov     esi,saveline
                add     esi,savescroll
                mov     ecx,256/4
                rep     movsd

screen2_msx2p_continue:

                pop     esi
                pop     ecx

                ; adjust scroll wraparound
                inc     esi
                and     esi,0FFh

                dec     ecx
                jnz     render_screen2_outer

                mov     spriteenable,1

                ret

; --------------------------------------------------------------------

code32          ends
                end


