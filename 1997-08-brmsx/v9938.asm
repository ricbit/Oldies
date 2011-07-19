; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: V9938.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include z80core.inc
include vdp.inc
include bit.inc
include io.inc
include pmode.inc
include pentium.inc
include blit.inc
include render.inc
include v9958.inc

extrn msxvram: dword
extrn msxvram_swap: dword
extrn vdplog: dword
extrn blitbuffer: dword
extrn redbuffer: dword
extrn msxmodel: dword

public outemul98_msx2
public outemul99_msx2
public inemul99_msx2
public inemul98_msx2
public outemul9B_msx2
public outemul9A_msx2
public render_screen0_msx2
public render_screen1_msx2
public render_screen2_msx2
public render_screen3_msx2
public render_screen5
public render_screen6
public render_screen7
public render_screen8
public sprite_render_msx2
public dirty_palette
public render_msx2
public set_adjust_exit
public masterclocklow  
public masterclockhigh 
public vdptiming
public vram_interlace
public vram_deinterlace
public adjustbuffer
public set_adjust
public screen6_table
public scr2_pat2col    
public scr2_col2pat    

LOGIC_SINGLE  EQU 0
LOGIC_DOUBLE  EQU 1

; DATA ---------------------------------------------------------------

align 4
include screen0l.inc
include screen6.inc
include adjust.inc
include sprite8.inc

align 4

all0F           dq      0F0F0F0F0F0F0F0Fh
all10           dq      1010101010101010h

falsesprite     db      32*32*2 dup (0)
falsemask       db      32 dup (0)

sprite_color_mask dd 0

dirty_palette   db      16 dup (1)

save_ebp        dd      0
save_esi        dd      0
vdp_page        dd      0
adjustbuffer    dd      0
scr2_pat2col    dd      0
scr2_col2pat    dd      0

masterclocklow  dd      0
masterclockhigh dd      0

saveclocklow    dd      0
saveclockhigh   dd      0

vdptiming       dd      1
command_in_use  dd      0

size_hx         dd      0
and_hx          dd      0
and_x           dd      0
max_x           dd      0
max_y           dd      0
and_y           dd      0
pSX             dd      0
pSY             dd      0
pDX             dd      0
pDY             dd      0
pNX             dd      0
pNY             dd      0
pMIN            dd      0
pMAX            dd      0
shift_mask      dd      0
shift_factor    dd      0
logical_op      dd      0
h_direction     dd      0
inc_y           dd      0
shift_low_x     db      0
shift_high_y    db      0
pixel_mask      db      0

save_POS        dd      0
save_START      dd      0
save_XSIZE      dd      0
save_XOFFSET    dd      0
save_NX         dd      0
save_NY         dd      0
save_YINC       dd      0
store_XOFFSET   dd      0
callback_44     dd      _ret
callback_07     dd      _ret

callback_vdp:
                dd      vdp_command_STOP        ; STOP
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED
                dd      vdp_command_POINT       ; POINT
                dd      vdp_command_PSET        ; PSET
                dd      vdp_command_SEARCH      ; SEARCH
                dd      vdp_command_LINE        ; LINE
                dd      vdp_command_LMMV        ; LMMV
                dd      vdp_command_LMMM        ; LMMM
                dd      vdp_command_LMCM        ; LMCM
                dd      vdp_command_LMMC        ; LMMC
                dd      vdp_command_HMMV        ; HMMV
                dd      vdp_command_HMMM        ; HMMM
                dd      vdp_command_YMMM        ; YMMM
                dd      vdp_command_HMMC        ; HMMC

callback_logical:
                dd      write_pixel_imp         ; IMP
                dd      write_pixel_and         ; AND
                dd      write_pixel_or          ; OR
                dd      write_pixel_xor         ; XOR
                dd      write_pixel_not         ; NOT
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED
                dd      write_pixel_timp        ; TIMP
                dd      write_pixel_tand        ; TAND
                dd      write_pixel_tor         ; TOR
                dd      write_pixel_txor        ; TXOR
                dd      write_pixel_tnot        ; TNOT
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED
                dd      _ret                    ; RESERVED

paletteflag     db      0
vdpindirect     db      0
vdpindirectmode db      0

; --------------------------------------------------------------------
; VDP write value
; MSX2 version

outemul98_msx2:
                mov     eax,vdpaddresse
                mov     vdpcond,0
                mov     ecx,eax
                mov     esi,msxvram
                inc     eax
                and     eax,03FFFh
                mov     vdpaddresse,eax
                
                ; select page
                add     esi,vdp_page
                mov     [ecx+esi],bl

                cmp     eax,0
                jne     outemul98_msx2_exit
                movzx   eax,byte ptr [offset vdpregs+14]
                inc     eax
                and     eax,7
                mov     byte ptr [offset vdpregs+14],al
                shl     eax,14
                mov     vdp_page,eax

outemul98_msx2_exit:
                mov     eax,0
                ret

; --------------------------------------------------------------------
; VDP register select
; MSX2 version

outemul99_msx2:      
                cmp     vdpcond,0
                jne     outemul99a_msx2
                mov     vdpcond,1
                mov     vdptemp,bl
                ret

outemul99a_msx2:     
                mov     vdpcond,0
                test    bl,10000000b
                jnz     outemul99b_msx2
                cmp     bl,01000000b
                jb      outemul99_read_msx2
                and     bl,00111111b
                mov     vdpaddressh,bl
                mov     bl,vdptemp
                mov     vdpaddressl,bl
                mov     vdpaccess,1
                ret

outemul99_read_msx2:
                and     bl,00111111b
                mov     vdpaddressh,bl
                mov     bl,vdptemp
                mov     vdpaddressl,bl
                mov     esi,msxvram
                mov     ecx,vdpaddresse

                ; select page
                add     esi,vdp_page

                mov     bl,[esi+ecx]
                mov     vdplookahead,bl
                inc     ecx
                and     ecx,03FFFh
                mov     vdpaddresse,ecx
                mov     eax,0
                mov     vdpaccess,eax

                cmp     ecx,0
                jne     _ret

                movzx   eax,byte ptr [offset vdpregs+14]
                inc     eax
                and     eax,7
                mov     byte ptr [offset vdpregs+14],al
                shl     eax,14
                mov     vdp_page,eax
                mov     eax,0
                ret

outemul99b_msx2:     
                ; write directly to a VDP register
                and     ebx,00111111b
                mov     al,vdptemp
                mov     cl,byte ptr [offset vdpregs+ebx]
                mov     byte ptr [offset vdpregs+ebx],al

register_action:
                cmp     bl,7
                je      change_border_color
                ;cmp     bl,9
                ;je      change_total_lines
                ;cmp     bl,1
                ;je      outemul99_checkirq_msx2
                cmp     bl,17
                je      outemul99_indirect_msx2
                cmp     bl,16
                je      outemul99_palette_msx2
                cmp     bl,14
                je      outemul99_page_msx2
                cmp     bl,25
                je      outemul99_scroll_raster
                cmp     bl,26
                je      outemul99_scroll_raster
                cmp     bl,27
                je      outemul99_scroll_raster
                cmp     bl,44
                je      check_cpu_move 
                cmp     bl,46
                je      execute_vdp_command 
outemul99_update_msx2:
                mov     firstscreen,1
                jmp     eval_base_address_msx2

check_cpu_move:
                jmp     dword ptr [offset callback_44]

outemul99_scroll_raster:
                mov     force_raster,1 
                ret

outemul99_page_msx2:
                ; select page
                movzx   eax,byte ptr [offset vdpregs+14]
                and     eax,7
                shl     eax,14
                mov     vdp_page,eax
                mov     eax,0
                ret

change_border_color:
                mov     byte ptr [offset dirty_palette+0],1
                ret

outemul99_indirect_msx2:                
                mov     bl,al
                shr     bl,7
                mov     vdpindirectmode,bl
                and     al,03Fh
                mov     vdpindirect,al
                ret

outemul99_palette_msx2:
                mov     paletteflag,0
                ret

change_total_lines:
                mov     total_lines,212
                test    al,BIT_7
                jnz     _ret

                mov     total_lines,192
                xor     cl,al
                and     cl,al
                and     cl,BIT_7
                jz      _ret

                mov     clear_bottom_field,1
                ret

; --------------------------------------------------------------------
; VDP palette register write
; MSX2 version

outemul9A_msx2:
                cmp     paletteflag,1
                je      outemul9A_msx2_set

                movzx   eax,byte ptr [offset vdpregs+16]
                mov     byte ptr [offset msx2palette+eax*2],bl
                mov     paletteflag,1
                ret

outemul9A_msx2_set:
                movzx   eax,byte ptr [offset vdpregs+16]
                mov     byte ptr [offset msx2palette+eax*2+1],bl
                mov     byte ptr [offset dirty_palette+eax],1
                inc     byte ptr [offset vdpregs+16]
                mov     paletteflag,0
                ;jmp     set_palette_color
                ret

; --------------------------------------------------------------------
; VDP indirect register write
; MSX2 version

outemul9B_msx2:
                cmp     vdpindirectmode,0
                jnz     outemul9B_single
                
                ; auto increment
                movzx   eax,vdpindirect
                mov     byte ptr [offset vdpregs+eax],bl
                push    eax
                xchg    eax,ebx
                and     eax,0FFh
                and     ebx,03Fh
                call    register_action
                pop     eax
                inc     eax
                mov     vdpindirect,al
                ret

outemul9B_single:
                movzx   eax,vdpindirect
                mov     byte ptr [offset vdpregs+eax],bl
                push    eax
                xchg    eax,ebx
                and     eax,03Fh
                call    register_action
                pop     eax
                ret

; --------------------------------------------------------------------
; VDP read VRAM
; MSX2 version

inemul98_msx2:       
                mov     ecx,msxvram
                mov     bl,vdplookahead
                
                ; select page
                mov     esi,vdp_page

                add     esi,vdpaddresse

                mov     bh,[ecx+esi]
                and     esi,03FFFh
                inc     esi
                and     esi,03FFFh
                mov     vdpaddresse,esi
                mov     vdplookahead,bh
                mov     vdpcond,0

                cmp     esi,0                
                jne     _ret

                movzx   eax,byte ptr [offset vdpregs+14]
                inc     eax
                and     eax,7
                mov     byte ptr [offset vdpregs+14],al
                shl     eax,14
                mov     vdp_page,eax
                mov     eax,0
                ret

; --------------------------------------------------------------------
; VDP read status register
; MSX2 version

inemul99_msx2:       
                cmp     byte ptr [offset vdpregs+15],1
                je      inemul99_msx2_reg1

                cmp     byte ptr [offset vdpregs+15],2
                je      inemul99_msx2_reg2

                cmp     byte ptr [offset vdpregs+15],7
                je      inemul99_msx2_reg7

                cmp     byte ptr [offset vdpregs+15],0
                jne     inemul99_msx2_generic

                mov     bl,vdpstatus
                and     vdpstatus,00111111b
                ;;; msx2+ intro
                ;or      vdpstatus,BIT_5
                ;;;
                mov     vdpcond,0
                mov     iline,0
                ret

inemul99_msx2_reg2:
                mov     bl,byte ptr [offset vdpstatus+2]

                ; check for horizontal retrace
                and     bl,NBIT_5
                cmp     ebp,100
                ja      inemul99_msx2_reg2_nohretrace
                or      bl,BIT_5
inemul99_msx2_reg2_nohretrace:

                ; check for vertical retrace
                and     bl,NBIT_6
                cmp     current_line,211
                jbe     inemul99_msx2_reg2_novretrace
                or      bl,BIT_6

inemul99_msx2_reg2_novretrace:
                cmp     command_in_use,1
                jne     _ret

                or      bl,BIT_0
                mov     ecx,saveclocklow
                sub     ecx,masterclocklow
                mov     ecx,saveclockhigh
                sbb     ecx,masterclockhigh
                jnc     _ret

                mov     command_in_use,0
                and     bl,NBIT_0
                ret

inemul99_msx2_reg1:
                mov     bl,byte ptr [offset vdpstatus+1]
                and     byte ptr [offset vdpstatus+1],0FEh
                mov     iline,0
                cmp     msxmodel,2
                jb      _ret
                or      bl,BIT_2
                ret

inemul99_msx2_reg7:
                call    callback_07
                mov     bl,byte ptr [offset vdpstatus+7]
                ret

inemul99_msx2_generic:
                movzx   ecx,byte ptr [offset vdpregs+15]
                add     ecx,offset vdpstatus
                mov     bl,byte ptr [ecx]
                ret

; eval_screen_mask ---------------------------------------------------
; prepare the masks used in VDP command 

eval_screen_mask:
                mov     callback_44,offset _ret

                cmp     actualscreen,5
                je      eval_screen_mask_5

                cmp     actualscreen,6
                je      eval_screen_mask_6

                cmp     actualscreen,7
                je      eval_screen_mask_7

                cmp     actualscreen,8
                je      eval_screen_mask_8

                ret

eval_screen_mask_5:
                mov     size_hx,080h
                mov     and_hx,0FEh
                mov     and_x,0FFh
                mov     max_x,0100h
                mov     shift_low_x,1
                mov     and_y,03FFh
                mov     max_y,0400h
                mov     shift_high_y,7
                mov     pixel_mask,0Fh
                mov     shift_mask,1
                mov     shift_factor,2
                ret

eval_screen_mask_6:
                mov     size_hx,080h
                mov     and_hx,01FCh
                mov     and_x,01FFh
                mov     max_x,0200h
                mov     shift_low_x,2
                mov     and_y,03FFh
                mov     max_y,0400h
                mov     shift_high_y,7
                mov     pixel_mask,03h
                mov     shift_mask,3
                mov     shift_factor,1
                ret

eval_screen_mask_7:
                mov     size_hx,0100h
                mov     and_hx,01FEh
                mov     and_x,01FFh
                mov     max_x,0200h
                mov     shift_low_x,1
                mov     and_y,01FFh
                mov     max_y,0200h
                mov     shift_high_y,8
                mov     pixel_mask,0Fh
                mov     shift_mask,1
                mov     shift_factor,2
                ret

eval_screen_mask_8:
                mov     size_hx,0100h
                mov     and_hx,0FFh
                mov     and_x,0FFh
                mov     max_x,0100h
                mov     shift_low_x,0
                mov     and_y,01FFh
                mov     max_y,0200h
                mov     shift_high_y,8
                mov     pixel_mask,0FFh
                mov     shift_mask,0
                mov     shift_factor,0
                ret

; write_vdplog -------------------------------------------------------
; write the vdp commands to stdout

write_vdplog:
                cmp     vdplog,1
                jne     _ret

                cmp     vdplog_now,1
                jne     _ret

                pushad
                and     eax,0FFh
                call    crlf
                call    crlf
                call    printhex2
                mov     al,byte ptr [offset vdpregs+32]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+33]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+34]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+35]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+36]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+37]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+38]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+39]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+40]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+41]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+42]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+43]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+44]
                call    printhex2
                mov     al,byte ptr [offset vdpregs+45]
                call    printhex2

                popad

                ret

; execute_vdp_command ------------------------------------------------
; execute a vdp command
; enter: al = command
; this routine is called in HOT STATE 
; (shouldn't touch edi, ebp, edx, and leave high eax=0)

execute_vdp_command:
                call    write_vdplog
                call    eval_screen_mask

                movzx   ebx,al
                mov     ecx,ebx
                and     ebx,0Fh
                shr     ecx,4
                mov     logical_op,ebx
                jmp     dword ptr [offset callback_vdp+ecx*4]

; CHECK_VERTICAL -----------------------------------------------------
; check the consistency of a vertical parameter

CHECK_VERTICAL  macro   source,size
                local   consistent
                local   inverse
                
                test    byte ptr [offset vdpregs+45],1000b
                jnz     inverse

                ; check direct consistency
                mov     eax,source 
                add     eax,size   
                cmp     eax,max_y
                jbe     consistent 

                mov     eax,max_y
                sub     eax,source 
                mov     size,eax 
                jmp     consistent

inverse:
                ; check inverse consistency
                mov     eax,source
                sub     eax,size
                add     eax,1
                jns     consistent
                
                mov     eax,source
                mov     size,eax

consistent:
                endm

; CHECK_HORIZONTAL ---------------------------------------------------
; check the consistency of a horizontal parameter

CHECK_HORIZONTAL  macro   source,size
                local   consistent
                local   inverse
                
                test    byte ptr [offset vdpregs+45],100b
                jnz     inverse

                ; check direct consistency
                mov     eax,source 
                add     eax,size   
                cmp     eax,max_x
                jbe     consistent 

                mov     eax,max_x
                sub     eax,source 
                mov     size,eax 
                jmp     consistent

inverse:
                ; check inverse consistency
                ; there is no inverse horizontal consistency check
                ; (BURAI disk 1)
                ;mov     eax,source
                ;sub     eax,size
                ;cmp     eax,-1
                ;jge     consistent
                ;mov     eax,source
                ;add     eax,1
                ;mov     size,eax

consistent:
                endm

; CHECK_HORIZONTAL_SIZE ----------------------------------------------
; check the consistency of the horizontal size

CHECK_HORIZONTAL_SIZE macro                
                local   consistent,inverse
                
                ; check consistency
                cmp     pNX,0
                jne     consistent

                test    byte ptr [offset vdpregs+45],100b
                jnz     inverse

                mov     pDX,0
                mov     pSX,0
                mov     eax,max_x
                mov     pNX,eax
                jmp     consistent

inverse:                
                mov     eax,max_x
                dec     eax
                mov     pNX,eax
                mov     pDX,eax
                mov     pSX,eax

consistent:
                endm

; SET_HORIZONTAL_SIZE ------------------------------------------------
; set the horizontal size as the maximum possible

SET_HORIZONTAL_SIZE macro                
                local   consistent,inverse
                
                ; set NX = max_x - DX
                mov     eax,max_x
                sub     eax,pDX
                mov     pNX,eax

                endm

; LOAD_Y_INCREMENT ---------------------------------------------------
; set ebp as (size_hx) or (-size_hx) depending on DIY flag

LOAD_Y_INCREMENT macro
                local   inverse,direct

                test    byte ptr [offset vdpregs+45],1000b                
                jnz     inverse

                mov     ebp,size_hx
                jmp     direct

inverse:
                mov     ebp,0
                sub     ebp,size_hx

direct:
                endm

; LOAD_X_INCREMENT ---------------------------------------------------
; add or subtract (edx) from (ebp) depending on DIX flag
; also sets the h_direction

LOAD_X_INCREMENT macro
                local   inverse,direct

                test    byte ptr [offset vdpregs+45],100b
                jz      direct

                mov     h_direction,-1
                add     ebp,edx
                jmp     inverse
direct:
                mov     h_direction,+1
                sub     ebp,edx
inverse:

                endm

; PERFORM_X_INCREMENT-------------------------------------------------
; perform x increment/decrement on pixel-based commands 
; depending on DIX status

PERFORM_X_INCREMENT macro full,half
                local   left,next,skip

                test    byte ptr [offset vdpregs+45],100b
                jnz     left
                
                inc     half
                test    half,shift_mask
                jnz     next
                inc     full
                jmp     next

left:
                test    half,shift_mask
                jnz     skip
                dec     full
skip:
                dec     half
next:

                endm

; vdp_command_STOP ---------------------------------------------------

vdp_command_STOP:
                mov     command_in_use,0
                and     byte ptr [offset vdpstatus+2],NBIT_0
                ret

; vdp_command_HMMM ---------------------------------------------------

vdp_command_HMMM:
                pushad

                ; load SX
                movzx   eax,word ptr [offset vdpregs+32]
                and     eax,and_hx
                mov     pSX,eax

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_hx
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_hx
                mov     pNX,eax

                CHECK_HORIZONTAL_SIZE   

                CHECK_HORIZONTAL pSX,pNX
                CHECK_HORIZONTAL pDX,pNX

                ; load SY
                movzx   eax,word ptr [offset vdpregs+34]
                and     eax,and_y
                mov     pSY,eax
                
                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax

                CHECK_VERTICAL pSY,pNY
                CHECK_VERTICAL pDY,pNY
                
                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_HMMM_exit

                ; eval source start addresses                
                mov     esi,pSY
                mov     cl,shift_high_y
                shl     esi,cl
                mov     eax,pSX
                mov     cl,shift_low_x
                shr     eax,cl
                add     esi,eax
                add     esi,msxvram

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the X size
                mov     edx,pNX
                mov     cl,shift_low_x
                shr     edx,cl
                
                LOAD_Y_INCREMENT

                LOAD_X_INCREMENT

                ; begin the transfer
                mov     ebx,pNY
vdp_command_HMMM_outer:
                push    ebx

                mov     ecx,edx
                mov     ebx,h_direction

vdp_command_HMMM_inner:
                mov     al,[esi]
                add     esi,ebx
                mov     [edi],al
                add     edi,ebx
                dec     ecx
                jnz     vdp_command_HMMM_inner

                pop     ebx

                add     esi,ebp
                add     edi,ebp

                dec     ebx
                jnz     vdp_command_HMMM_outer

                cmp     vdptiming,1
                jne     vdp_command_HMMM_exit

                mov     command_in_use,1
                mov     eax,pNX
                mov     ecx,pNY
                mul     ecx
                mov     ecx,2078
                mul     ecx
                shr     eax,8
                add     eax,masterclocklow
                mov     saveclocklow,eax
                mov     eax,masterclockhigh
                adc     eax,0
                mov     saveclockhigh,eax

vdp_command_HMMM_exit:
                popad
                ret

; vdp_command_YMMM ---------------------------------------------------

vdp_command_YMMM:
                ; only DIX=0 is supported by now
                test    byte ptr [offset vdpregs+45],100b
                jnz     _ret

                pushad

                ; load DX=SX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_hx
                mov     pDX,eax
                mov     pSX,eax
                        
                SET_HORIZONTAL_SIZE

                ; load SY
                movzx   eax,word ptr [offset vdpregs+34]
                and     eax,and_y
                mov     pSY,eax
                
                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                CHECK_VERTICAL pSY,pNY
                CHECK_VERTICAL pDY,pNY

                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_YMMM_exit

                ; eval source start addresses                
                mov     esi,pSY
                mov     cl,shift_high_y
                shl     esi,cl
                mov     eax,pSX
                mov     cl,shift_low_x
                shr     eax,cl
                add     esi,eax
                add     esi,msxvram

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the X size
                mov     edx,pNX
                mov     cl,shift_low_x
                shr     edx,cl

                LOAD_Y_INCREMENT

                sub     ebp,edx


                ; begin the transfer
                mov     ebx,pNY
vdp_command_YMMM_outer:

                mov     ecx,edx
                rep     movsb

                add     esi,ebp
                add     edi,ebp

                dec     ebx
                jnz     vdp_command_YMMM_outer

vdp_command_YMMM_exit:
                popad
                ret

; vdp_command_HMMV ---------------------------------------------------

vdp_command_HMMV:
                ; only DIX=0 is supported by now
                test    byte ptr [offset vdpregs+45],100b
                jnz     _ret

                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_hx
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_hx
                mov     pNX,eax

                ; check NX consistency
                cmp     pNX,0
                jne     HMMV_NX_consistent

                mov     pDX,0
                mov     pSY,0
                mov     eax,max_x
                mov     pNX,eax

HMMV_NX_consistent:

                ; check DX consistency
                mov     eax,pDX
                add     eax,pNX                        
                cmp     eax,max_x
                jbe     HMMV_DX_consistent

                mov     eax,max_x
                sub     eax,pDX
                mov     pNX,eax

HMMV_DX_consistent:

                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                CHECK_VERTICAL pDY,pNY 

                ; check NY consistency (checked in kyokugen for direct)
                cmp     pNY,0
                jne     HMMV_NY_consistent

                mov     eax,max_y
                mov     pNY,eax
                mov     pDY,0

HMMV_NY_consistent:

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the X size
                mov     edx,pNX
                mov     cl,shift_low_x
                shr     edx,cl

                ;mov     ebp,size_hx
                LOAD_Y_INCREMENT
                
                sub     ebp,edx

                ; load the filling byte
                mov     al,byte ptr [offset vdpregs+44]

                ; begin the transfer
                mov     ebx,pNY
vdp_command_HMMV_outer:

                mov     ecx,edx
                rep     stosb

                add     edi,ebp

                dec     ebx
                jnz     vdp_command_HMMV_outer

vdp_command_HMMV_exit:
                popad
                ret

; vdp_command_HMMC ---------------------------------------------------

vdp_command_HMMC:
                ; only DIY=0 is supported by now
                ;test    byte ptr [offset vdpregs+45],1000b
                ;jnz     _ret

                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_hx
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_hx
                mov     pNX,eax

                CHECK_HORIZONTAL_SIZE   

                CHECK_HORIZONTAL pDX,pNX

                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                CHECK_VERTICAL pDY,pNY

                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_HMMC_exit

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the X size
                mov     edx,pNX
                mov     cl,shift_low_x
                shr     edx,cl

                ; prepare the transfer
                mov     save_POS,edi

                mov     eax,pNY
                mov     save_NY,eax

                mov     save_XSIZE,edx
                mov     save_NX,edx

                ;mov     ebp,size_hx
                LOAD_Y_INCREMENT
                
                LOAD_X_INCREMENT

                mov     save_XOFFSET,ebp

                or      byte ptr [offset vdpstatus+2],081h

                mov     callback_44,offset callback_HMMC
                call    dword ptr [offset callback_44]

vdp_command_HMMC_exit:
                popad
                ret

callback_HMMC:
                mov     al,byte ptr [offset vdpregs+44]
                mov     ecx,save_POS
                mov     [ecx],al
                add     ecx,h_direction
                mov     save_POS,ecx

                dec     save_NX
                jnz     _ret

                add     ecx,save_XOFFSET
                mov     save_POS,ecx

                mov     ecx,save_XSIZE
                mov     save_NX,ecx

                dec     save_NY
                jnz     _ret

                mov     callback_44,offset _ret
                and     byte ptr [offset vdpstatus+2],07Eh

                ret

; READ_PIXEL ---------------------------------------------------------
; read one pixel from VRAM
; enter: esi = vram byte
;        edx = select pixel
; exit:  al = pixel
; destroy edx

READ_PIXEL      macro

                push    ecx
                mov     ecx,shift_factor
                xor     edx,0FFFFFFFFh
                and     edx,shift_mask
                shl     edx,cl
                mov     ecx,edx
                mov     al,[esi]
                shr     al,cl
                and     al,pixel_mask
                pop     ecx

                endm

; WRITE_PIXEL --------------------------------------------------------
; write one pixel to VRAM
; enter: edi = vram byte
;        edx = select pixel
;        al = pixel
; destroy edx,ah

WRITE_PIXEL     macro

                push    ecx
                mov     ah,pixel_mask
                and     al,ah
                mov     ecx,shift_factor
                xor     edx,0FFFFFFFFh
                and     edx,shift_mask
                shl     edx,cl
                mov     ecx,edx
                shl     ah,cl
                xor     ah,255
                shl     al,cl
                mov     ecx,logical_op
                call    dword ptr [offset callback_logical+ecx*4]
                pop     ecx
                endm

; vdp_command_PSET ---------------------------------------------------

vdp_command_PSET:
                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_x
                mov     pDX,eax
                        
                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                        
                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; load the filling byte
                mov     al,byte ptr [offset vdpregs+44]
                mov     edx,pDX
                
                WRITE_PIXEL 

                popad
                ret

; vdp_command_POINT --------------------------------------------------

vdp_command_POINT:
                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_x
                mov     pDX,eax
                        
                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                        
                ; eval destination start addresses                
                mov     esi,pDY
                mov     cl,shift_high_y
                shl     esi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     esi,eax
                add     esi,msxvram

                ; load the filling byte
                mov     al,byte ptr [offset vdpregs+44]
                mov     edx,pDX
                
                READ_PIXEL 

                and     byte ptr [offset vdpstatus+2],NBIT_0
                mov     byte ptr [offset vdpstatus+7],al

                popad
                ret

; --------------------------------------------------------------------
; logical operations used in write_pixel

write_pixel_timp:
                or      al,al
                jz      _ret
                and     ah,[edi]
                or      ah,al
                mov     [edi],ah
                ret

write_pixel_imp:
                and     ah,[edi]
                or      ah,al
                mov     [edi],ah
                ret

write_pixel_and:
                or      al,ah
                and     [edi],al
                ret

write_pixel_or:
                or      [edi],al
                ret

write_pixel_xor:
                xor     [edi],al
                ret

write_pixel_not:
                xor     ah,255
                xor     al,ah
                xor     ah,255
                and     ah,[edi]
                or      ah,al
                mov     [edi],ah
                ret

write_pixel_tand:
                or      al,al
                jz      _ret 
                or      al,ah
                and     [edi],al
                ret

write_pixel_tor:
                or      al,al
                jz      _ret 
                or      [edi],al
                ret

write_pixel_txor:
                or      al,al
                jz      _ret 
                xor     [edi],al
                ret

write_pixel_tnot:
                or      al,al
                jz      _ret 
                xor     ah,255
                xor     al,ah
                xor     ah,255
                and     ah,[edi]
                or      ah,al
                mov     [edi],ah
                ret

; vdp_command_LMMM ---------------------------------------------------

vdp_command_LMMM:
                pushad

                ; load SX
                movzx   eax,word ptr [offset vdpregs+32]
                and     eax,and_x
                mov     pSX,eax

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_x
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_x
                mov     pNX,eax

                CHECK_HORIZONTAL_SIZE

                CHECK_HORIZONTAL pDX,pNX
                CHECK_HORIZONTAL pSX,pNX

                ; load SY
                movzx   eax,word ptr [offset vdpregs+34]
                and     eax,and_y
                mov     pSY,eax
                
                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax

                CHECK_VERTICAL pDY,pNY
                CHECK_VERTICAL pSY,pNY

                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_LMMM_exit

                ; eval source start addresses                
                mov     esi,pSY
                mov     cl,shift_high_y
                shl     esi,cl
                mov     eax,pSX
                mov     cl,shift_low_x
                shr     eax,cl
                add     esi,eax
                add     esi,msxvram

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                LOAD_Y_INCREMENT

                mov     inc_y,ebp

                ; adjust the pixel counters
                mov     eax,pSX
                mov     ebp,pDX

                ; begin the transfer
                mov     ebx,pNY
vdp_command_LMMM_outer:

                mov     ecx,pNX
                push    esi edi
vdp_command_LMMM_inner:

                push    eax
                mov     edx,eax
                READ_PIXEL 
                mov     edx,ebp
                WRITE_PIXEL
                pop     eax

                PERFORM_X_INCREMENT edi,ebp
                PERFORM_X_INCREMENT esi,eax

                dec     ecx
                jnz     vdp_command_LMMM_inner

                pop     edi esi

                mov     eax,pSX
                mov     ebp,pDX
                add     esi,inc_y 
                add     edi,inc_y 

                dec     ebx
                jnz     vdp_command_LMMM_outer

                cmp     vdptiming,1
                jne     vdp_command_LMMM_exit

                mov     command_in_use,1
                mov     eax,pNX
                mov     ecx,pNY
                mul     ecx
                mov     ecx,22
                mul     ecx
                add     eax,masterclocklow
                mov     saveclocklow,eax
                mov     eax,masterclockhigh
                adc     eax,0
                mov     saveclockhigh,eax

vdp_command_LMMM_exit:
                popad
                ret

; vdp_command_SEARCH -------------------------------------------------

vdp_command_SEARCH:
                test    byte ptr [offset vdpregs+45],100b
                jnz     _ret

                pushad

                ; load SX
                movzx   eax,word ptr [offset vdpregs+32]
                and     eax,and_x
                mov     pSX,eax

                ; load SY
                movzx   eax,word ptr [offset vdpregs+34]
                and     eax,and_y
                mov     pSY,eax
                
                ; eval source start addresses                
                mov     esi,pSY
                mov     cl,shift_high_y
                shl     esi,cl
                mov     eax,pSX
                mov     cl,shift_low_x
                shr     eax,cl
                add     esi,eax
                add     esi,msxvram

                ; adjust the pixel counters
                mov     edx,pSX
                mov     ah,byte ptr [offset vdpregs+44]
                and     ah,pixel_mask

                mov     ecx,max_x
                sub     ecx,pSX
vdp_command_SEARCH_inner:

                push    edx
                READ_PIXEL 
                pop     edx
                cmp     al,ah
                je      vdp_command_SEARCH_found

                PERFORM_X_INCREMENT esi,edx

                dec     ecx
                jnz     vdp_command_SEARCH_inner

                and     byte ptr [offset vdpstatus+2],NBIT_0
                or      byte ptr [offset vdpstatus+2],BIT_4
                or      edx,0FE00h
                mov     word ptr [offset vdpstatus+8],dx

                popad
                ret

vdp_command_SEARCH_found:
                and     byte ptr [offset vdpstatus+2],NBIT_4 AND NBIT_0

                popad
                ret

; vdp_command_LMMV ---------------------------------------------------

vdp_command_LMMV:
                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_x
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_x
                mov     pNX,eax

                ; check NX consistency
                CHECK_HORIZONTAL_SIZE

                ; check DX consistency
                CHECK_HORIZONTAL pDX,pNX

                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                ; check DY consistency
                CHECK_VERTICAL pDY,pNY

                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_LMMV_exit

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the pixel counters
                mov     al,byte ptr [offset vdpregs+44]
                mov     ebp,pDX
                
                ; begin the transfer
                mov     ebx,pNY
vdp_command_LMMV_outer:

                mov     ecx,pNX
                push    esi edi
vdp_command_LMMV_inner:

                push    eax
                mov     edx,ebp
                WRITE_PIXEL 
                pop     eax

                PERFORM_X_INCREMENT edi,ebp
                
                dec     ecx
                jnz     vdp_command_LMMV_inner

                pop     edi esi

                LOAD_Y_INCREMENT
                add     esi,ebp
                add     edi,ebp
                mov     ebp,pDX

                dec     ebx
                jnz     vdp_command_LMMV_outer

vdp_command_LMMV_exit:
                popad
                ret

; vdp_command_LMMC ---------------------------------------------------

vdp_command_LMMC:
                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_x
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_x
                mov     pNX,eax

                ; check NX consistency
                CHECK_HORIZONTAL_SIZE

                ; check DX consistency
                CHECK_HORIZONTAL pDX,pNX         

                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                ; check DY consistency
                CHECK_VERTICAL pDY,pNY

                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_LMMC_exit

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                LOAD_Y_INCREMENT
                mov     save_YINC,ebp

                ; adjust the pixel counters
                mov     al,byte ptr [offset vdpregs+44]
                mov     ebp,pDX

                ; prepare the transfer
                mov     save_POS,edi
                mov     save_START,edi

                mov     eax,pNY
                mov     save_NY,eax

                mov     ecx,pNX
                mov     save_XSIZE,ecx
                mov     save_NX,ecx

                mov     eax,pDX
                mov     save_XOFFSET,eax
                mov     store_XOFFSET,eax

                or      byte ptr [offset vdpstatus+2],081h

                mov     callback_44,offset callback_LMMC
                call    dword ptr [offset callback_44]

vdp_command_LMMC_exit:
                popad
                ret

callback_LMMC:
                mov     al,byte ptr [offset vdpregs+44]
                push    edi edx
                mov     edi,save_POS
                mov     edx,save_XOFFSET
                WRITE_PIXEL
                mov     edx,save_XOFFSET
                PERFORM_X_INCREMENT edi,edx
                mov     save_XOFFSET,edx
                mov     save_POS,edi
                pop     edx edi

                mov     eax,0

                dec     save_NX
                jnz     _ret

                mov     ecx,save_START
                add     ecx,save_YINC
                mov     save_START,ecx
                mov     save_POS,ecx

                mov     ecx,save_XSIZE
                mov     save_NX,ecx

                mov     ecx,store_XOFFSET
                mov     save_XOFFSET,ecx

                dec     save_NY
                jnz     _ret

                mov     callback_44,offset _ret
                and     byte ptr [offset vdpstatus+2],07Eh
                
                ret

; vdp_command_LMCM ---------------------------------------------------

vdp_command_LMCM:
                ; only DIX=0 and DIY=0 are supported by now
                test    byte ptr [offset vdpregs+45],1100b
                jnz     _ret

                pushad

                ; load DX
                movzx   eax,word ptr [offset vdpregs+32] ;;;
                and     eax,and_x
                mov     pDX,eax
                        
                ; load NX
                movzx   eax,word ptr [offset vdpregs+40] 
                and     eax,and_x
                mov     pNX,eax

                ; check NX consistency
                cmp     pNX,0
                jne     LMCM_NX_consistent

                mov     pDX,0
                mov     pSY,0
                mov     eax,max_x
                mov     pNX,eax

LMCM_NX_consistent:

                ; check DX consistency
                mov     eax,pDX
                add     eax,pNX                        
                cmp     eax,max_x
                jbe     LMCM_DX_consistent

                mov     eax,max_x
                sub     eax,pDX
                mov     pNX,eax

LMCM_DX_consistent:

                ; load DY
                movzx   eax,word ptr [offset vdpregs+34] ;;;
                and     eax,and_y
                mov     pDY,eax
                
                ; load NY
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_y
                mov     pNY,eax
                
                ; check DY consistency
                mov     eax,pDY
                add     eax,pNY                        
                cmp     eax,max_y
                jbe     LMCM_DY_consistent

                mov     eax,max_y
                sub     eax,pDY
                mov     pNY,eax

LMCM_DY_consistent:

                ; check NY consistency
                cmp     pNY,0
                je      vdp_command_LMCM_exit

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; adjust the pixel counters
                mov     al,byte ptr [offset vdpregs+44]
                mov     ebp,pDX

                ; prepare the transfer
                mov     save_POS,edi
                mov     save_START,edi

                mov     eax,pNY
                mov     save_NY,eax

                mov     ecx,pNX
                mov     save_XSIZE,ecx
                mov     save_NX,ecx

                mov     eax,pDX
                mov     save_XOFFSET,eax
                mov     store_XOFFSET,eax

                or      byte ptr [offset vdpstatus+2],081h

                mov     callback_07,offset callback_LMCM

vdp_command_LMCM_exit:
                popad
                ret

callback_LMCM:
                push    edi edx
                mov     esi,save_POS
                mov     edx,save_XOFFSET
                READ_PIXEL
                mov     byte ptr [offset vdpregs+44],al
                mov     byte ptr [offset vdpstatus+7],al
                mov     edx,save_XOFFSET
                inc     edx
                mov     save_XOFFSET,edx
                test    edx,shift_mask
                jnz     callback_LMCM_edx
                inc     esi
                mov     save_POS,esi
callback_LMCM_edx:
                pop     edx edi

                mov     eax,0

                dec     save_NX
                jnz     _ret

                mov     ecx,save_START
                add     ecx,size_hx
                mov     save_START,ecx
                mov     save_POS,ecx

                mov     ecx,save_XSIZE
                mov     save_NX,ecx

                mov     ecx,store_XOFFSET
                mov     save_XOFFSET,ecx

                dec     save_NY
                jnz     _ret

                mov     callback_07,offset _ret
                and     byte ptr [offset vdpstatus+2],07Eh
                
                ret

; vdp_command_LINE ---------------------------------------------------

vdp_command_LINE:
                pushad

                ; load MIN
                movzx   eax,word ptr [offset vdpregs+42]
                and     eax,and_x
                mov     pMIN,eax
                
                ; load DX
                movzx   eax,word ptr [offset vdpregs+36]
                and     eax,and_x
                mov     pDX,eax
                        
                ; load DY
                movzx   eax,word ptr [offset vdpregs+38]
                and     eax,and_y
                mov     pDY,eax
                
                ; load MAX
                movzx   eax,word ptr [offset vdpregs+40]
                and     eax,and_x
                mov     pMAX,eax

                ; select major axis 
                test    byte ptr [offset vdpregs+45],BIT_0
                jnz     vdp_command_vLINE
                
vdp_command_hLINE:
                ; check MAX consistency
                cmp     pMAX,0
                je      vdp_command_LINE_exit

                ; bugfix
                inc     pMAX
                inc     pMIN

                CHECK_HORIZONTAL pDX,pMAX

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; check MIN/MAX consistency
                mov     eax,pMAX
                cmp     eax,pMIN
                jb      vdp_command_LINE_exit

                ; evaluate the DDA factor
                mov     eax,pMIN
                shl     eax,16
                ;add     eax,8000h   ; 0.5 in fixed point
                mov     edx,0
                mov     ebx,pMAX
                div     ebx
                mov     ebx,eax
                mov     esi,0
                mov     eax,0

                ; adjust the pixel counters
                mov     al,byte ptr [offset vdpregs+44]
                mov     ebp,pDX

vdp_command_hLINE_start:      

                mov     ecx,pMAX
vdp_command_hLINE_inner:

                push    eax
                mov     edx,ebp
                WRITE_PIXEL
                pop     eax

                PERFORM_X_INCREMENT edi,ebp

vdp_command_hLINE_next:
                add     esi,ebx
                test    esi,0FFFF0000h
                jz      vdp_command_hLINE_continue
                and     esi,0FFFFh
                
                ;add     edi,size_hx
                test    byte ptr [offset vdpregs+45],1000b
                jnz     vdp_command_hLINE_up
                
                add     edi,size_hx
                jmp     vdp_command_hLINE_continue

vdp_command_hLINE_up:
                sub     edi,size_hx

vdp_command_hLINE_continue:
                dec     ecx
                jnz     vdp_command_hLINE_inner

vdp_command_LINE_exit:
                popad
                ret

vdp_command_vLINE:
                ; check MAX consistency
                cmp     pMAX,0
                je      vdp_command_LINE_exit

                ; bugfix
                inc     pMAX
                inc     pMIN

                ; check pDY consistency
                CHECK_VERTICAL pDY,pMAX

                ; eval destination start addresses                
                mov     edi,pDY
                mov     cl,shift_high_y
                shl     edi,cl
                mov     eax,pDX
                mov     cl,shift_low_x
                shr     eax,cl
                add     edi,eax
                add     edi,msxvram

                ; check MIN/MAX consistency
                mov     eax,pMAX
                cmp     eax,pMIN
                jb      vdp_command_LINE_exit
                
                ; evaluate the DDA factor
                mov     eax,pMIN
                shl     eax,16
                ;add     eax,8000h   ; 0.5 in fixed point
                mov     edx,0
                mov     ebx,pMAX
                div     ebx
                mov     ebx,eax
                mov     esi,0
                mov     eax,0

                ; adjust the pixel counters
                mov     al,byte ptr [offset vdpregs+44]
                mov     ebp,pDX

                mov     ecx,pMAX
vdp_command_vLINE_inner:

                push    eax
                mov     edx,ebp
                WRITE_PIXEL 
                pop     eax

                test    byte ptr [offset vdpregs+45],1000b
                jnz     vdp_command_vLINE_up
                
                add     edi,size_hx
                jmp     vdp_command_vLINE_next

vdp_command_vLINE_up:
                sub     edi,size_hx

vdp_command_vLINE_next:

                add     esi,ebx
                test    esi,0FFFF0000h
                jz      vdp_command_vLINE_continue
                and     esi,0FFFFh
                
                PERFORM_X_INCREMENT edi,ebp


vdp_command_vLINE_continue:

                dec     ecx
                jnz     vdp_command_vLINE_inner

                jmp     vdp_command_LINE_exit

; render_msx2 --------------------------------------------------------
; render the MSX screen, based on VDP registers and VRAM
; MSX2 VERSION

render_msx2:
                test    byte ptr [offset vdpregs+1],BIT_6
                jz      render_msx2_clear

                ; check if the GUI is enabled
                cmp     cpupaused,1
                je      render_draw

                ; GUI is not enabled: update the border color
                call    set_border_color

render_draw:
                call    set_correct_palette

                mov     bl,actualscreen

                cmp     bl,0
                je      render_screen0

                ;push    ebx
                ;call    prepare_ocultation
                ;pop     ebx

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

                cmp     bl,8
                je      render_screen8

                ret

render_msx2_clear:
                cmp     text_columns,80
                je      render_msx2_clear_512

                cmp     videomode,7
                je      render_msx2_clear_256

                cmp     actualscreen,6
                je      render_msx2_clear_512

                cmp     actualscreen,7
                je      render_msx2_clear_512

render_msx2_clear_256:
                pushad

                call    set_adjust

                mov     edi,adjustbuffer
                mov     esi,first_line
                shl     esi,8
                add     edi,esi

                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx
                shl     ecx,8-2

                mov     eax,10101010h
                cmp     actualscreen,8
                jne     render_msx2_clear_256_non8
                mov     eax,0
render_msx2_clear_256_non8:

                rep     stosd

                popad
                ret

render_msx2_clear_512:
                pushad

                call    set_adjust

                mov     edi,adjustbuffer
                mov     esi,first_line
                shl     esi,9
                add     edi,esi

                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx
                shl     ecx,9-2

                mov     eax,10101010h

                rep     stosd

                popad
                ret

; load_border_color --------------------------------------------------
; load the border color in al based on the current screen

load_border_color:
                cmp     actualscreen,8
                je      load_border_color_scr8

                mov     al,byte ptr [offset vdpregs+7]
                and     al,0Fh
                or      al,10h
                ret

load_border_color_scr8:
                mov     al,byte ptr [offset vdpregs+7]
                ret

; set_adjust ---------------------------------------------------------
; perform the correction on blitbuffer 
; in order to apply the set adjust

set_adjust:
                cmp     videomode,7
                je      set_adjust_256
                cmp     text_columns,80
                je      set_adjust_512
                cmp     actualscreen,6
                je      set_adjust_512
                cmp     actualscreen,7
                je      set_adjust_512

set_adjust_256:                
                movzx   ecx,byte ptr [offset vdpregs+18]
                mov     edx,[offset set_adjust_table_256+ecx*8]
                add     edx,[offset set_adjust_table_256+ecx*8+4]
                mov     eax,blitbuffer
                sub     eax,edx
                mov     adjustbuffer,eax
                ret

set_adjust_512:
                movzx   ecx,byte ptr [offset vdpregs+18]
                mov     edx,[offset set_adjust_table_512+ecx*8]
                add     edx,[offset set_adjust_table_512+ecx*8+4]
                mov     eax,blitbuffer
                sub     eax,edx
                mov     adjustbuffer,eax
                ret

set_adjust_exit:
                pushad  

                call    check_scroll_mask

                ; check if we are in 192 lines mode
                test    byte ptr [offset vdpregs+9],BIT_7
                jnz     set_adjust_exit_start

                cmp     last_line,192
                jb      set_adjust_exit_start

                cmp     videomode,7
                je      set_adjust_192_256
                cmp     text_columns,80
                je      set_adjust_192_512
                cmp     actualscreen,6
                je      set_adjust_192_512
                cmp     actualscreen,7
                je      set_adjust_192_512

set_adjust_192_256:
                mov     edi,adjustbuffer
                add     edi,192*256
                call    load_border_color
                mov     ah,al
                mov     bx,ax
                shl     eax,16
                mov     ax,bx
                mov     ecx,(212-192)*256/4
                rep     stosd
                jmp     set_adjust_exit_start

set_adjust_192_512:
                mov     edi,adjustbuffer
                add     edi,192*512
                call    load_border_color
                mov     ah,al
                mov     bx,ax
                shl     eax,16
                mov     ax,bx
                mov     ecx,(212-192)*512/4
                rep     stosd

set_adjust_exit_start:
                mov     eax,first_line
                cmp     eax,last_line
                ja      set_adjust_exit_ret

                cmp     videomode,7
                je      set_adjust_exit_256
                cmp     text_columns,80
                je      set_adjust_exit_512
                cmp     actualscreen,6
                je      set_adjust_exit_512
                cmp     actualscreen,7
                je      set_adjust_exit_512

set_adjust_exit_256:
                movzx   ecx,byte ptr [offset vdpregs+18]
                mov     edx,[offset set_adjust_table_256+ecx*8]
                mov     edi,blitbuffer
                sub     edi,edx
                mov     eax,first_line
                shl     eax,7
                lea     edi,[edi+eax*2]

                mov     ebp,last_line
                sub     ebp,first_line
                inc     ebp

                mov     al,byte ptr [offset vdpregs+7]
                and     al,0Fh
                or      al,10h

                mov     ecx,dword ptr [offset set_adjust_table_256+ecx*8+4]
                cmp     ecx,0
                je      set_adjust_exit_ret
                jl      set_adjust_exit_256_negative

                add     edi,256
                sub     edi,ecx

                jmp     set_adjust_exit_256_loop
                
set_adjust_exit_256_negative:
                neg     ecx

set_adjust_exit_256_loop:
                push    ecx edi
                rep     stosb
                pop     edi ecx
                add     edi,256

                dec     ebp
                jnz     set_adjust_exit_256_loop

set_adjust_exit_ret:
                popad
                ret

set_adjust_exit_512:
                movzx   ecx,byte ptr [offset vdpregs+18]
                mov     edx,[offset set_adjust_table_512+ecx*8]
                mov     edi,blitbuffer
                sub     edi,edx
                mov     eax,first_line
                shl     eax,7
                lea     edi,[edi+eax*2]

                mov     ebp,last_line
                sub     ebp,first_line
                inc     ebp

                mov     al,byte ptr [offset vdpregs+7]
                and     al,0Fh
                or      al,10h

                mov     ecx,dword ptr [offset set_adjust_table_512+ecx*8+4]
                cmp     ecx,0
                je      set_adjust_exit_ret
                jl      set_adjust_exit_512_negative

                add     edi,512
                sub     edi,ecx

                jmp     set_adjust_exit_512_loop
                
set_adjust_exit_512_negative:
                mov     ecx,0
                sub     ecx,dword ptr [offset set_adjust_table_256+ecx*8+4]

set_adjust_exit_512_loop:
                push    ecx edi
                rep     stosb
                pop     edi ecx
                add     edi,512

                dec     ebp
                jnz     set_adjust_exit_512_loop
                popad
                ret

; check_scroll_mask --------------------------------------------------
; check if the scroll mask is enabled

check_scroll_mask:
                cmp     msxmodel,2
                jb      _ret

                test    byte ptr [offset vdpregs+25],BIT_1
                jz      _ret

                mov     eax,first_line
                cmp     eax,last_line
                ja      _ret

                cmp     videomode,7
                je      check_scroll_mask_256
                cmp     text_columns,80
                je      check_scroll_mask_512
                cmp     actualscreen,6
                je      check_scroll_mask_512
                cmp     actualscreen,7
                je      check_scroll_mask_512

check_scroll_mask_256:
                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx
                mov     edi,first_line
                shl     edi,8
                add     edi,adjustbuffer
                call    load_border_color
                mov     ah,al
                mov     bx,ax
                shl     eax,16
                mov     ax,bx
check_scroll_mask_256_loop:
                mov     [edi],eax
                mov     [edi+4],eax
                add     edi,256
                dec     ecx
                jnz     check_scroll_mask_256_loop
                ret

check_scroll_mask_512:
                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx
                mov     edi,first_line
                shl     edi,9
                add     edi,adjustbuffer
                call    load_border_color
                mov     ah,al
                mov     bx,ax
                shl     eax,16
                mov     ax,bx
check_scroll_mask_512_loop:
                mov     [edi],eax
                mov     [edi+4],eax
                mov     [edi+8],eax
                mov     [edi+8+4],eax
                add     edi,512
                dec     ecx
                jnz     check_scroll_mask_512_loop
                ret


; render_screen0_msx2 ------------------------------------------------
; render a screen 0 page
; MSX2 version

render_screen0_msx2:                
                call    set_adjust

                cmp     text_columns,40
                je      render_screen0_msx2_40

                mov     esi,msxvram                
                add     esi,nametable
                
                mov     ebx,msxvram
                add     ebx,patterntable
                
                mov     edi,adjustbuffer
                add     edi,16

                mov     ecx,0
                mov     edx,0
                
                mov     ebp,24
                ; draw a screen

render06_80:
                push    ebp
                mov     ebp,80
                ; draw a line

render05_80:
                ; draw two chars

                mov     cl,[esi]
                mov     dl,[ebx+ecx*8]
                
                irp     i,<0,1,2,3,4,5,6,7>
                
                mov     eax,[offset screen0_table1_msx2+edx*8]
                mov     [edi+i*512],eax
                mov     eax,[offset screen0_table1_msx2+edx*8+4]
                mov     dl,[ebx+ecx*8+i+1]
                mov     [edi+4+i*512],eax

                endm

                mov     cl,[esi+1]
                mov     dl,[ebx+ecx*8]
                
                irp     i,<0,1,2,3,4,5,6,7>
                
                mov     eax,[offset screen0_table2_msx2+edx*8]
                mov     [edi+6+i*512],ax
                mov     eax,[offset screen0_table2_msx2+edx*8+4]
                mov     dl,[ebx+ecx*8+i+1]
                mov     [edi+8+i*512],eax

                endm

                add     esi,2
                add     edi,12
                sub     ebp,2
                jnz     render05_80

                pop     ebp
                add     edi,512*7+32
                dec     ebp
                jnz     render06_80

                mov     spriteenable,0

                ret

render_screen0_msx2_40:                
                mov     esi,msxvram                
                add     esi,nametable
                
                mov     ebx,msxvram
                add     ebx,patterntable
                
                mov     edi,adjustbuffer
                add     edi,16

                mov     ecx,0
                mov     edx,0
                
                mov     ebp,24
                ; draw a screen

render06_40:
                push    ebp
                mov     ebp,40
                ; draw a line

render05_40:
                ; draw two chars

                mov     cl,[esi]
                mov     dl,[ebx+ecx*8]
                
                irp     i,<0,1,2,3,4,5,6,7>
                
                mov     eax,[offset screen0_table1_msx2+edx*8]
                mov     [edi+i*256],eax
                mov     eax,[offset screen0_table1_msx2+edx*8+4]
                mov     dl,[ebx+ecx*8+i+1]
                mov     [edi+4+i*256],eax

                endm

                mov     cl,[esi+1]
                mov     dl,[ebx+ecx*8]
                
                irp     i,<0,1,2,3,4,5,6,7>
                
                mov     eax,[offset screen0_table2_msx2+edx*8]
                mov     [edi+6+i*256],ax
                mov     eax,[offset screen0_table2_msx2+edx*8+4]
                mov     dl,[ebx+ecx*8+i+1]
                mov     [edi+8+i*256],eax

                endm

                add     esi,2
                add     edi,12
                sub     ebp,2
                jnz     render05_40

                pop     ebp
                add     edi,256*7+16
                dec     ebp
                jnz     render06_40

                mov     spriteenable,0

                ret

; render_screen1_msx2 ------------------------------------------------
; render the SCREEN 1
; MSX2 version

render_screen1_msx2:                
                call    set_adjust

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
                mov     edi,adjustbuffer

                ; mask the temporary registers
                xor     edx,edx
                xor     eax,eax

                ; for each line
                mov     ebp,24
render10:       push    ebp

                ; for each char
                mov     ebp,32
render11:       push    ebp

                PIPE1   MSX2_RENDER

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

; render_screen2_msx2 ------------------------------------------------
; render the SCREEN 2
; MSX2 version

render_screen2_msx2:
                cmp     msxmodel,1
                ja      render_screen2_msx2p

                call    set_adjust

                mov     edi,adjustbuffer
                mov     eax,first_line
                shl     eax,7
                lea     edi,[edi+eax*2]

                mov     esi,first_line
                movzx   eax,byte ptr [offset vdpregs+23]
                add     esi,eax
                and     esi,0FFh

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
                pop     ebp esi ecx

                ; adjust scroll wraparound
                inc     esi
                and     esi,0FFh

                dec     ecx
                jnz     render_screen2_outer

                mov     spriteenable,1

                ret

; render_screen3_msx2 ------------------------------------------------
; render the SCREEN 3
; MSX2 version

render_screen3_msx2:                
                call    set_adjust

                mov     edi,adjustbuffer

                mov     ecx,nametable
                add     ecx,msxvram

                mov     esi,patterntable
                add     esi,msxvram

                mov     eax,0
                mov     edx,0

                mov     ebp,6
render_screen3_outerloop_msx2:
                push    ebp

                irp     i,<0,1,2,3,4,5,6,7>
                local   render_screen3_innerloop

                mov     ebx,0
render_screen3_innerloop:
                
                mov     al,[ecx]
                
                mov     dl,[esi+eax*8+i]
                mov     ebp,[offset foregroundcolor+edx*4]
                or      ebp,10101010h
                irp     j,<0,1,2,3>
                mov     [edi+j*256],ebp
                endm
                
                mov     ebp,[offset backgroundcolor+edx*4]
                or      ebp,10101010h
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
                jnz     render_screen3_outerloop_msx2

                mov     spriteenable,1
                ret

; render_screen4 -----------------------------------------------------
; render a screen 4 page

render_screen4:
                call    render_screen2_msx2
                mov     spriteenable,2
                ret

; render_screen5 -----------------------------------------------------
; render the SCREEN 5

render_screen5:
                cmp     msxmodel,1
                ja      render_screen5_msx2p

                call    set_adjust

                cmp     enginetype,0
                jne     render_screen5_mmx

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

                mov     ebp,msxvram
                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx

render_screen5_outer:
                push    ecx
                mov     edx,32

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

; render_screen5_mmx -------------------------------------------------
; render the SCREEN 5 using MMX

render_screen5_mmx:
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

                mov     ebp,msxvram
                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx

                ; movq    mm4,mem0F
                movq
                db      00100101b
                dd      offset all0F

                ; movq    mm5,mem10
                movq
                db      00101101b
                dd      offset all10

render_screen5_mmx_outer:
                push    ecx
                mov     edx,16

render_screen5_mmx_inner:
                ; movq    mm0,[esi+ebp]
                movq
                db      00000100b 
                db      02Eh

                ; movq     mm1,mm0
                movq
                db      11001000b

                ; pand    mm0,mm4
                pand
                db      11000100b

                ; psrlq    mm1,4
                psrlq   
                db      11010001b
                db      4
                
                ; por      mm0,mm5
                por
                db      11000101b

                ; pand    mm1,mm4
                pand
                db      11001100b

                ; movq    mm2,mm0
                movq
                db      11010000b
                
                ; por      mm1,mm5
                por
                db      11001101b

                ; movq     mm3,mm1
                movq
                db      11011001b
                
                add     esi,8

                ; punpckhbw mm1,mm0
                punpckhbw
                db      11001000b

                add     edi,16
                
                ; punpcklbw mm3,mm2
                punpcklbw
                db      11011010b

                ; movq_st [edi-8],mm1
                movq_st
                db      10001111b
                dd      -8

                dec     edx

                ; movq_st [edi-16],mm3
                movq_st
                db      10011111b
                dd      -16

                jnz     render_screen5_mmx_inner

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen5_mmx_outer

                mov     spriteenable,2

                ret

; render_screen6 -----------------------------------------------------
; render the SCREEN 6

render_screen6:
                cmp     msxmodel,1
                ja      render_screen6_msx2p

                call    set_adjust

                cmp     videomode,7
                je      render_screen6_sizedown

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
                
                mov     ebp,msxvram
                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx
                mov     eax,0

render_screen6_outer:
                push    ecx
                mov     edx,128/4

render_screen6_inner:
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
                jnz     render_screen6_inner

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

                mov     ebp,msxvram
                mov     ecx,last_line
                sub     ecx,first_line
                inc     ecx


render_screen6_outer_sizedown:
                push    ecx
                mov     edx,32

render_screen6_inner_sizedown:
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
                jnz     render_screen6_inner_sizedown

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF8000h
                and     esi,000007FFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen6_outer_sizedown

                mov     spriteenable,0

                ret

; render_screen7 -----------------------------------------------------
; render the SCREEN 7

render_screen7:
                call    set_adjust

                cmp     videomode,7
                je      render_screen7_sizedown
                
                cmp     enginetype,0
                jne     render_screen7_mmx

                mov     edi,adjustbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,8
                add     esi,eax
                mov     ebp,msxvram
                mov     ecx,212

render_screen7_outer:
                push    ecx
                mov     edx,64 

render_screen7_inner:
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
                jnz     render_screen7_inner

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF0000h
                and     esi,00000FFFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen7_outer

                mov     spriteenable,0

                ret

; render_screen7_mmx -------------------------------------------------
; render the SCREEN 7 using MMX

render_screen7_mmx:
                mov     edi,adjustbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,8
                add     esi,eax
                mov     ebp,msxvram
                mov     ecx,212

                ; movq    mm4,mem0F
                movq
                db      00100101b
                dd      offset all0F

                ; movq    mm5,mem10
                movq
                db      00101101b
                dd      offset all10

render_screen7_mmx_outer:
                push    ecx
                mov     edx,32 ;16

render_screen7_mmx_inner:
                ; movq    mm0,[esi+ebp]
                movq
                db      00000100b 
                db      02Eh

                ; movq     mm1,mm0
                movq
                db      11001000b

                ; pand    mm0,mm4
                pand
                db      11000100b

                ; psrlq    mm1,4
                psrlq   
                db      11010001b
                db      4
                
                ; por      mm0,mm5
                por
                db      11000101b

                ; pand    mm1,mm4
                pand
                db      11001100b

                ; movq    mm2,mm0
                movq
                db      11010000b
                
                ; por      mm1,mm5
                por
                db      11001101b

                ; movq     mm3,mm1
                movq
                db      11011001b
                
                add     esi,8

                ; punpckhbw mm1,mm0
                punpckhbw
                db      11001000b

                add     edi,16
                
                ; punpcklbw mm3,mm2
                punpcklbw
                db      11011010b

                ; movq_st [edi-8],mm1
                movq_st
                db      10001111b
                dd      -8

                dec     edx

                ; movq_st [edi-16],mm3
                movq_st
                db      10011111b
                dd      -16

                jnz     render_screen7_mmx_inner

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF0000h
                and     esi,00000FFFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen7_mmx_outer

                mov     spriteenable,0

                ret

; render_screen7_sizedown --------------------------------------------
; render the SCREEN 7 in "-res 7"

render_screen7_sizedown:
                cmp     enginetype,0
                jne     render_screen7_sizedown_mmx

                mov     edi,adjustbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,8
                add     esi,eax
                mov     ebp,msxvram
                mov     ecx,212

render_screen7_outer_sizedown:
                push    ecx
                mov     edx,64 

render_screen7_inner_sizedown:
                mov     eax,dword ptr [esi+ebp]
                and     eax,0F0F0F0Fh
                or      eax,10101010h
                add     esi,4
                mov     dword ptr [edi],eax
                add     edi,4
                dec     edx
                jnz     render_screen7_inner_sizedown

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF0000h
                and     esi,00000FFFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen7_outer_sizedown

                mov     spriteenable,2

                ret

; render_screen7_sizedown_mmx ----------------------------------------
; render the SCREEN 7 in "-res 7" using MMX

render_screen7_sizedown_mmx:
                mov     edi,adjustbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,8
                add     esi,eax
                mov     ebp,msxvram
                mov     ecx,212
                
                ; movq    mm4,mem0F
                movq
                db      00100101b
                dd      offset all0F

                ; movq    mm5,mem10
                movq
                db      00101101b
                dd      offset all10


render_screen7_outer_sizedown_mmx:
                push    ecx
                mov     edx,64/2

render_screen7_inner_sizedown_mmx:
                ;mov     eax,dword ptr [esi+ebp]
                ;and     eax,0F0F0F0Fh
                ;or      eax,10101010h
                ;add     esi,4
                ;mov     dword ptr [edi],eax
                ;add     edi,4
                
                ; movq    mm0,[esi+ebp]
                movq
                db      00000100b 
                db      02Eh

                add     esi,8
                
                ; pand    MM0,MM4
                pand    
                db      11000100b

                add     edi,8

                ; por     MM0,MM5
                por
                db      11000101b

                dec     edx

                ; movq_st [edi-8],mm0
                movq_st
                db      10000111b
                dd      -8

                jnz     render_screen7_inner_sizedown_mmx

                pop     ecx

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF0000h
                and     esi,00000FFFFh
                or      esi,edx

                dec     ecx
                jnz     render_screen7_outer_sizedown_mmx

                mov     spriteenable,2

                ret

; render_screen8 -----------------------------------------------------
; render the SCREEN 8

render_screen8:
                call    set_adjust

                mov     edi,adjustbuffer
                mov     esi,nametable
                movzx   eax,byte ptr [offset vdpregs+23]
                shl     eax,8
                add     esi,eax
                mov     ebp,msxvram
                mov     ebx,212

render_screen8_outer:
                mov     ecx,64

render_screen8_inner:
                mov     eax,dword ptr [esi+ebp]
                add     esi,4
                mov     dword ptr [edi],eax
                add     edi,4
                dec     ecx
                jnz     render_screen8_inner

                ; adjust scroll wraparound
                dec     esi
                mov     edx,esi
                inc     esi
                and     edx,0FFFF0000h
                and     esi,00000FFFFh
                or      esi,edx
       
                dec     ebx
                jnz     render_screen8_outer

                mov     spriteenable,2

                ret

; sprite_render_msx2 -------------------------------------------------
; draw the sprites directly on the blit buffer
; MSX2 version - sprites mode 2

align 4

sprite_render_msx2:
                mov     sprite_color_mask,10101010h

                ; check for screen 8
                cmp     actualscreen,8
                jne     sprite_render_msx2_start
                
                mov     sprite_color_mask,0

sprite_render_msx2_start:

                ; check for screen enabled
                test    byte ptr [offset vdpregs+1],BIT_6
                jz      _ret

                ; check for sprites enabled
                test    byte ptr [offset vdpregs+8],BIT_1
                jnz     _ret

                mov     esi,msxvram
                add     esi,sprattrtable

                ; find last sprite
                mov     ebp,32
sprite_render_find_loop_msx2:
                mov     ah,[esi]
                cmp     ah,0D8h
                je      sprite_render_found_msx2

                add     esi,4
                dec     ebp
                jnz     sprite_render_find_loop_msx2
sprite_render_found_msx2:
                sub     esi,4
                mov     eax,32
                sub     eax,ebp
                mov     ebp,eax
                jz      _ret

                mov     save_ebp,ebp
                mov     save_esi,esi

                ; at this point
                ; esi = pointer to last sprite's attribute table
                ; ebp = number of sprites

sprite_render_outer_msx2:
                push    ebp

                ; draw sprite image in false sprite buffer
                call    draw_sprite_image_msx2

                ; eval sprite coordinates
                call    eval_sprite_coords_msx2

                ;mov     ebx,eax
                mov     edi,eax
                movzx   eax,byte ptr [offset vdpregs+23]
                sub     edi,eax
                jns     sprite_positive
                add     edi,256
sprite_positive:
                jns     sprite_positive_2
                add     edi,256
sprite_positive_2:
                ;cmp     edi,212-16
                ;jg      sprite_render_next_msx2
                mov     ebx,edi ;;;
                sal     edi,8
                add     edi,ecx
                mov     ebp,edi
                add     edi,adjustbuffer
                add     ebp,redbuffer

                ; check for unusual size
                cmp     edx,16
                jne     sprite_render_next_msx2
                
                ; check for crop
                cmp     ecx,0
                jl      sprite_render_next_msx2
                cmp     ecx,256-16
                jge     sprite_render_next_msx2
                
                ; draw the sprite in adjustbuffer
                
                mov     ecx,offset falsesprite
                push    esi
                sub     esi,msxvram
                sub     esi,sprattrtable
                shr     esi,2
                xchg    eax,esi
                mov     edx,0

sprite_render_line_msx2:
                test    byte ptr [offset vdpregs+8],BIT_5
                jnz     sprite_render_line_msx2_go

                test    byte ptr [offset falsemask+edx],0Fh
                jz      sprite_render_next_line_msx2

sprite_render_line_msx2_go:
                mov     eax,0
                test    byte ptr [offset falsemask+edx],BIT_6
                jz      sprite_render_line_msx2_normal
                mov     eax,0FFFFFFFFh

sprite_render_line_msx2_normal:
                ;cmp     al,byte ptr [offset spritemask+esi]
                ;ja      sprite_render_next_line_msx2
                cmp     ebx,first_line
                jl      sprite_render_next_line_msx2
                cmp     ebx,last_line
                jg      sprite_render_next_line_msx2

                push    esi edx ebx
                irp     i,<0,4,8,12>
                mov     esi,[ebp+i]
                mov     edx,[ecx+i]
                mov     ebx,[edi+i]
                or      esi,edx
                xor     edx,0FFFFFFFFh
                and     ebx,esi
                or      ebx,[ecx+32+i]
                and     edx,eax
                or      ebx,sprite_color_mask
                mov     [edi+i],ebx
                mov     [ebp+i],edx
                endm
                pop     ebx edx esi

sprite_render_next_line_msx2:
                inc     esi
                inc     edx
                inc     ebx
                add     ecx,64
                add     edi,256
                add     ebp,256
                cmp     edx,16
                jne     sprite_render_line_msx2

                pop     esi

sprite_render_next_msx2:
                pop     ebp
                sub     esi,4
                dec     ebp   
                jnz     sprite_render_outer_msx2

                ; now we must clear the redbuffer
                
                mov     ebp,save_ebp
                mov     esi,save_esi


                ; at this point
                ; esi = pointer to last sprite's attribute table
                ; ebp = number of sprites

sprite_render_outer_clear:
                push    ebp

                ; eval sprite coordinates
                call    eval_sprite_coords_msx2

                mov     edi,eax
                movzx   eax,byte ptr [offset vdpregs+23]
                sub     edi,eax
                jns     sprite_positive_clear
                add     edi,256
sprite_positive_clear:
                jns     sprite_positive_2_clear
                add     edi,256
sprite_positive_2_clear:
                cmp     edi,212-16
                jg      sprite_render_next_clear
                sal     edi,8
                add     edi,ecx
                mov     ebp,edi
                add     edi,adjustbuffer
                add     ebp,redbuffer

                ; check for crop
                cmp     ecx,0
                jl      sprite_render_next_clear
                cmp     ecx,256-16
                jge     sprite_render_next_clear
                
                ; draw the sprite in adjustbuffer
                
                push    esi
                sub     esi,msxvram
                sub     esi,sprattrtable
                shr     esi,2
                xchg    eax,esi
                mov     edx,0

sprite_render_line_clear:
                test    byte ptr [offset vdpregs+8],BIT_5
                jnz     sprite_render_line_clear_go

                test    byte ptr [offset falsemask+edx],0Fh
                jz      sprite_render_next_line_clear

sprite_render_line_clear_go:
                ;mov     ah,0
                mov     eax,0
                test    byte ptr [offset falsemask+edx],BIT_6
                jz      sprite_render_line_clear_normal
                ;mov     ah,0FFh
                mov     eax,0FFFFFFFFh

sprite_render_line_clear_normal:
                ;cmp     al,byte ptr [offset spritemask+esi]
                ;ja      sprite_render_next_line_msx2

                irp     i,<0,4,8,12>
                mov     dword ptr [ebp+i],0
                endm

sprite_render_next_line_clear:
                inc     esi
                inc     edx
                add     ecx,64
                add     edi,256
                add     ebp,256
                cmp     edx,16
                jne     sprite_render_line_clear

                pop     esi

sprite_render_next_clear:
                pop     ebp
                sub     esi,4
                dec     ebp   
                jnz     sprite_render_outer_clear


                ret

; draw_sprite_image_msx2 ---------------------------------------------
; draw a sprite image in the false buffer
; MSX2 version
; enter: esi = start of sprite attribute in vram
; exit: false sprite buffer filled with sprite image
;       edx = number of lines/rows of sprite

draw_sprite_image_msx2:
                test    byte ptr [offset vdpregs+1],BIT_1
                jz      draw_sprite_image_8_msx2 

draw_sprite_image_16_msx2:       
                test    byte ptr [offset vdpregs+1],BIT_0
                jnz     _ret
                
                ; only 16x16N is supported
                
                ; eval address of sprite image
                movzx   eax,byte ptr [esi+2]
                and     eax,11111100b
                mov     ecx,msxvram
                add     ecx,sprpatttable
                lea     ecx,[ecx+eax*8]

                mov     edx,0
                mov     edi,offset falsesprite
                mov     ebx,0

                cmp     actualscreen,8
                je      draw_sprite_image_16N_loop_msx2_scr8

draw_sprite_image_16N_loop_msx2:                     
                push    esi

                mov     eax,esi
                sub     eax,sprattrtable
                sub     eax,msxvram
                shr     eax,2
                shl     eax,4
                add     eax,sprattrtable
                add     eax,msxvram
                sub     eax,512
                mov     al,[eax+edx]

                mov     byte ptr [offset falsemask+edx],al
                and     eax,0Fh
                mov     eax,[offset backgroundcolor+eax*4]
                
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

                pop     esi
                
                add     edi,64
                inc     ecx
                inc     edx
                cmp     edx,16
                jne     draw_sprite_image_16N_loop_msx2

                mov     edx,16
                ret

draw_sprite_image_8_msx2:
                test    byte ptr [offset vdpregs+1],BIT_0
                jnz     _ret
                
                ; only 8x8N is supported
                
                ; clear buffers to fool brmsx into thinking
                ; that a 8x8 sprite is a 16x16 sprite
                ; this is slow but it will be fixed in the next version :)
                mov     edi,offset falsesprite
                mov     ecx,16*16*2/4
                mov     eax,0
                rep     stosd

                mov     edi,offset falsemask
                mov     ecx,32/4
                mov     eax,0
                rep     stosd

                ; eval address of sprite image
                movzx   eax,byte ptr [esi+2]
                mov     ecx,msxvram
                add     ecx,sprpatttable
                lea     ecx,[ecx+eax*8]

                mov     edx,0
                mov     edi,offset falsesprite
                mov     ebx,0

                cmp     actualscreen,8
                je      draw_sprite_image_8N_loop_msx2_scr8

draw_sprite_image_8N_loop_msx2:                     
                push    esi

                mov     eax,esi
                sub     eax,sprattrtable
                sub     eax,msxvram
                shr     eax,2
                shl     eax,4
                add     eax,sprattrtable
                add     eax,msxvram
                sub     eax,512
                mov     al,[eax+edx]

                mov     byte ptr [offset falsemask+edx],al
                and     eax,0Fh
                mov     eax,[offset backgroundcolor+eax*4]
                
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
                
                ; fill the other 8 pixels with nothing
                mov     eax,0FFFFFFFFh
                mov     [edi+8],eax
                mov     [edi+8+4],eax
                
                pop     esi
                
                add     edi,64
                inc     ecx
                inc     edx
                cmp     edx,8
                jne     draw_sprite_image_8N_loop_msx2

                mov     edx,16
                ret

draw_sprite_image_16N_loop_msx2_scr8:
                push    esi

                mov     eax,esi
                sub     eax,sprattrtable
                sub     eax,msxvram
                shr     eax,2
                shl     eax,4
                add     eax,sprattrtable
                add     eax,msxvram
                sub     eax,512
                mov     al,[eax+edx]

                mov     byte ptr [offset falsemask+edx],al
                and     eax,0Fh
                mov     eax,dword ptr [offset screen8_sprite_color+eax*4]
                ;mov     eax,[offset backgroundcolor+eax*4]
                
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

                pop     esi
                
                add     edi,64
                inc     ecx
                inc     edx
                cmp     edx,16
                jne     draw_sprite_image_16N_loop_msx2_scr8

                mov     edx,16
                ret

draw_sprite_image_8N_loop_msx2_scr8:                     
                push    esi

                mov     eax,esi
                sub     eax,sprattrtable
                sub     eax,msxvram
                shr     eax,2
                shl     eax,4
                add     eax,sprattrtable
                add     eax,msxvram
                sub     eax,512
                mov     al,[eax+edx]

                mov     byte ptr [offset falsemask+edx],al
                and     eax,0Fh
                mov     eax,dword ptr [offset screen8_sprite_color+eax*4]
                ;mov     eax,[offset backgroundcolor+eax*4]
                
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
                
                ; fill the other 8 pixels with nothing
                mov     eax,0FFFFFFFFh
                mov     [edi+8],eax
                mov     [edi+8+4],eax
                
                pop     esi
                
                add     edi,64
                inc     ecx
                inc     edx
                cmp     edx,8
                jne     draw_sprite_image_8N_loop_msx2_scr8

                mov     edx,16
                ret


; eval_sprite_coords_msx2 --------------------------------------------
; evaluate sprite coordinates
; MSX2 version
; enter: esi = start of sprite attribute in vram
; exit: eax = offset y ; ecx = offset x (both are signed numbers)

eval_sprite_coords_msx2:
                movzx   eax,byte ptr [esi]        ; y coordinate
                cmp     eax,0D8h                  ; 0BEh ; 0F0h ??
                jbe     eval_sprite_coords1_msx2
                movsx   eax,al

eval_sprite_coords1_msx2:
                inc     eax
                
                xor     ecx,ecx
                mov     cl,[esi+1]      ; x coordinate

                ret

vram_interlace:
                cmp     actualscreen,6
                ja      _ret

                pushad

                mov     edi,msxvram
                mov     esi,msxvram_swap
                mov     ecx,65536

vram_interlace_loop:
                mov     al,[edi]
                mov     [esi],al
                mov     al,[edi+65536]
                mov     [esi+1],al
                inc     edi
                add     esi,2
                dec     ecx
                jnz     vram_interlace_loop

                mov     eax,msxvram
                mov     ebx,msxvram_swap
                mov     msxvram,ebx
                mov     msxvram_swap,eax

                popad
                ret

vram_deinterlace:
                cmp     actualscreen,7
                jb      _ret

                pushad

                mov     edi,msxvram
                mov     esi,msxvram_swap
                mov     ecx,65536

vram_deinterlace_loop:
                mov     al,[edi]
                mov     [esi],al
                mov     al,[edi+1]
                mov     [esi+65536],al
                add     edi,2
                inc     esi
                dec     ecx
                jnz     vram_deinterlace_loop

                mov     eax,msxvram
                mov     ebx,msxvram_swap
                mov     msxvram,ebx
                mov     msxvram_swap,eax

                popad
                ret

code32          ends
                end
