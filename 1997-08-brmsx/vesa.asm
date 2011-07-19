; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: VESA.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include pmode.inc
include io.inc
include bit.inc

extrn vesaheader: dword
extrn vesamodeinfo: dword

public init_vesa
public search_vesa_mode
public search_vesa_mode_400
public search_vesa_mode_512_15
public search_vesa_mode_640
public set_vesa_mode
public vesalinearbuffer
public set_vesa_bank

; DATA ---------------------------------------------------------------

align 4

vesalinearbuffer        dd      0
vesamodenumber512       dd      0
vesamodenumber400       dd      0
vesamodenumber512_15    dd      0
vesamodenumber640       dd      0
vesaselector            dw      0

; --------------------------------------------------------------------

; init_vesa ----------------------------------------------------------
; looks for VESA driver and return NC if found

init_vesa:
                ; init the header with VESA2 identifier
                mov     ebx,'2EBV'
                mov     eax,vesaheader
                mov     [eax],ebx

                ; convert vesaheader to real mode pointer
                add     eax,_code32a
                mov     ebx,eax
                shr     ebx,4
                mov     v86r_es,bx
                and     eax,15
                mov     v86r_di,ax

                ; call int 10h
                mov     v86r_ax,04F00h
                mov     al,10h
                int     33h

                cmp     v86r_al,04Fh
                jne     error_no_vesa

                mov     eax,vesaheader
                cmp     [eax],'ASEV'
                jne     error_no_vesa

                or      eax,eax                

                ret

error_no_vesa:
                stc
                ret

; search_vesa_mode ---------------------------------------------------
; looks for mode 512x384x8 linear

search_vesa_mode:
                ; evaluate linear address of mode list
                mov     eax,vesaheader
                movzx   ebx,word ptr [eax+14]
                movzx   ecx,word ptr [eax+16]
                shl     ecx,4
                add     ecx,ebx
                sub     ecx,_code32a

search_vesa_mode_loop:
                movzx   eax,word ptr [ecx]
                cmp     eax,0FFFFh
                je      search_vesa_mode_ret
                
                ; set the mode number
                mov     v86r_cx,ax

                ; convert vesamodeinfo to real mode pointer
                mov     eax,vesamodeinfo
                add     eax,_code32a
                mov     ebx,eax
                shr     ebx,4
                mov     v86r_es,bx
                and     eax,15
                mov     v86r_di,ax

                ; call VESA driver
                mov     v86r_ax,04F01h
                mov     al,10h
                int     33h

                mov     eax,vesamodeinfo

                ; test for color mode
                test    word ptr [eax],BIT_3
                jz      search_vesa_mode_next
                
                ; test for graphics mode
                test    word ptr [eax],BIT_4
                jz      search_vesa_mode_next
                
                ; test for linear frame buffer
                ;test    word ptr [eax],BIT_7
                ;jz      search_vesa_mode_next

                ; X resolution of 512
                movzx   ebx,word ptr [eax+18]
                cmp     ebx,512
                jne     search_vesa_mode_next

                ; Y resolution of 384
                movzx   ebx,word ptr [eax+20]
                cmp     ebx,384
                jne     search_vesa_mode_next

                ; number of planes: 1
                movzx   ebx,byte ptr [eax+24]
                cmp     ebx,1
                jne     search_vesa_mode_next

                ; bits per pixel: 8
                movzx   ebx,byte ptr [eax+25]
                cmp     ebx,8
                jne     search_vesa_mode_next

                ; memory model: packed
                movzx   ebx,byte ptr [eax+27]
                cmp     ebx,4
                jne     search_vesa_mode_next

                ; found!!
                ;mov     ebx,dword ptr [eax+40]
                ;sub     ebx,_code32a
                ;mov     vesalinearbuffer,ebx

                movzx   ebx,word ptr [ecx]
                mov     vesamodenumber512,ebx
               
                or      eax,eax
                ret
                
search_vesa_mode_next:
                add     ecx,2
                jmp     search_vesa_mode_loop

search_vesa_mode_ret:
                stc
                ret

; search_vesa_mode_640------------------------------------------------
; looks for mode 640x480x8 linear

search_vesa_mode_640:
                ; evaluate linear address of mode list
                mov     eax,vesaheader
                movzx   ebx,word ptr [eax+14]
                movzx   ecx,word ptr [eax+16]
                shl     ecx,4
                add     ecx,ebx
                sub     ecx,_code32a

search_vesa_mode_loop_640:
                movzx   eax,word ptr [ecx]
                cmp     eax,0FFFFh
                je      search_vesa_mode_ret_640
                
                ; set the mode number
                mov     v86r_cx,ax

                ; convert vesamodeinfo to real mode pointer
                mov     eax,vesamodeinfo
                add     eax,_code32a
                mov     ebx,eax
                shr     ebx,4
                mov     v86r_es,bx
                and     eax,15
                mov     v86r_di,ax

                ; call VESA driver
                mov     v86r_ax,04F01h
                mov     al,10h
                int     33h

                mov     eax,vesamodeinfo

                ; test for color mode
                test    word ptr [eax],BIT_3
                jz      search_vesa_mode_next_640
                
                ; test for graphics mode
                test    word ptr [eax],BIT_4
                jz      search_vesa_mode_next_640
                
                ; test for linear frame buffer
                ;test    word ptr [eax],BIT_7
                ;jz      search_vesa_mode_next_640

                ; X resolution of 640
                movzx   ebx,word ptr [eax+18]
                cmp     ebx,640
                jne     search_vesa_mode_next_640

                ; Y resolution of 480
                movzx   ebx,word ptr [eax+20]
                cmp     ebx,480
                jne     search_vesa_mode_next_640

                ; number of planes: 1
                movzx   ebx,byte ptr [eax+24]
                cmp     ebx,1
                jne     search_vesa_mode_next_640

                ; bits per pixel: 8
                movzx   ebx,byte ptr [eax+25]
                cmp     ebx,8
                jne     search_vesa_mode_next_640

                ; memory model: packed
                movzx   ebx,byte ptr [eax+27]
                cmp     ebx,4
                jne     search_vesa_mode_next_640

                ; found!!
                ;mov     ebx,dword ptr [eax+40]
                ;sub     ebx,_code32a
                ;mov     vesalinearbuffer,ebx

                movzx   ebx,word ptr [ecx]
                mov     vesamodenumber640,ebx
               
                or      eax,eax
                ret
                
search_vesa_mode_next_640:
                add     ecx,2
                jmp     search_vesa_mode_loop_640

search_vesa_mode_ret_640:
                stc
                ret

; search_vesa_mode_400 -----------------------------------------------
; looks for mode 400x300x8 linear

search_vesa_mode_400:
                ; evaluate linear address of mode list
                mov     eax,vesaheader
                movzx   ebx,word ptr [eax+14]
                movzx   ecx,word ptr [eax+16]
                shl     ecx,4
                add     ecx,ebx
                sub     ecx,_code32a

search_vesa_mode_loop_400:
                movzx   eax,word ptr [ecx]
                cmp     eax,0FFFFh
                je      search_vesa_mode_ret_400
                
                ; set the mode number
                mov     v86r_cx,ax

                ; convert vesamodeinfo to real mode pointer
                mov     eax,vesamodeinfo
                add     eax,_code32a
                mov     ebx,eax
                shr     ebx,4
                mov     v86r_es,bx
                and     eax,15
                mov     v86r_di,ax

                ; call VESA driver
                mov     v86r_ax,04F01h
                mov     al,10h
                int     33h

                mov     eax,vesamodeinfo

                ; test for color mode
                test    word ptr [eax],BIT_3
                jz      search_vesa_mode_next_400
                
                ; test for graphics mode
                test    word ptr [eax],BIT_4
                jz      search_vesa_mode_next_400
                
                ; test for linear frame buffer
                ;test    word ptr [eax],BIT_7
                ;jz      search_vesa_mode_next_400

                ; X resolution of 400
                movzx   ebx,word ptr [eax+18]
                cmp     ebx,400
                jne     search_vesa_mode_next_400

                ; Y resolution of 300
                movzx   ebx,word ptr [eax+20]
                cmp     ebx,300
                jne     search_vesa_mode_next_400

                ; number of planes: 1
                movzx   ebx,byte ptr [eax+24]
                cmp     ebx,1
                jne     search_vesa_mode_next_400

                ; bits per pixel: 8
                movzx   ebx,byte ptr [eax+25]
                cmp     ebx,8
                jne     search_vesa_mode_next_400

                ; memory model: packed
                movzx   ebx,byte ptr [eax+27]
                cmp     ebx,4
                jne     search_vesa_mode_next_400

                ; found!!
                mov     ebx,dword ptr [eax+40]
                mov     vesalinearbuffer,ebx

                movzx   ebx,word ptr [ecx]
                mov     vesamodenumber400,ebx
               
                or      eax,eax
                ret
                
search_vesa_mode_next_400:
                add     ecx,2
                jmp     search_vesa_mode_loop_400

search_vesa_mode_ret_400:
                stc
                ret

; search_vesa_mode ---------------------------------------------------
; looks for mode 512x384x15 linear

search_vesa_mode_512_15:
                ; evaluate linear address of mode list
                mov     eax,vesaheader
                movzx   ebx,word ptr [eax+14]
                movzx   ecx,word ptr [eax+16]
                shl     ecx,4
                add     ecx,ebx
                sub     ecx,_code32a

search_vesa_mode_loop_512_15:
                movzx   eax,word ptr [ecx]
                cmp     eax,0FFFFh
                je      search_vesa_mode_ret_512_15
                
                ; set the mode number
                mov     v86r_cx,ax

                ; convert vesamodeinfo to real mode pointer
                mov     eax,vesamodeinfo
                add     eax,_code32a
                mov     ebx,eax
                shr     ebx,4
                mov     v86r_es,bx
                and     eax,15
                mov     v86r_di,ax

                ; call VESA driver
                mov     v86r_ax,04F01h
                mov     al,10h
                int     33h

                mov     eax,vesamodeinfo

                ; test for color mode
                test    word ptr [eax],BIT_3
                jz      search_vesa_mode_next_512_15
                
                ; test for graphics mode
                test    word ptr [eax],BIT_4
                jz      search_vesa_mode_next_512_15
                
                ; test for linear frame buffer
                ;test    word ptr [eax],BIT_7
                ;jz      search_vesa_mode_next_512_15

                ; X resolution of 512
                movzx   ebx,word ptr [eax+18]
                cmp     ebx,512
                jne     search_vesa_mode_next_512_15

                ; Y resolution of 384
                movzx   ebx,word ptr [eax+20]
                cmp     ebx,384
                jne     search_vesa_mode_next_512_15

                ; number of planes: 1
                movzx   ebx,byte ptr [eax+24]
                cmp     ebx,1
                jne     search_vesa_mode_next_512_15

                ; bits per pixel: 15
                movzx   ebx,byte ptr [eax+25]
                cmp     ebx,15
                jne     search_vesa_mode_next_512_15

                ; memory model: direct color
                movzx   ebx,byte ptr [eax+27]
                cmp     ebx,6
                jne     search_vesa_mode_next_512_15

                ; found!!
                ;mov     ebx,dword ptr [eax+40]
                ;sub     ebx,_code32a
                ;mov     vesalinearbuffer,ebx

                movzx   ebx,word ptr [ecx]
                mov     vesamodenumber512_15,ebx
               
                or      eax,eax
                ret
                
search_vesa_mode_next_512_15:
                add     ecx,2
                jmp     search_vesa_mode_loop_512_15

search_vesa_mode_ret_512_15:
                stc
                ret

; set_vesa_mode ------------------------------------------------------
; set the chosen vesa mode
; enter eax=512 or 400

set_vesa_mode:
                cmp     videomode,1
                je      set_vesa_mode_400

                cmp     videomode,4
                je      set_vesa_mode_512_15

                cmp     videomode,6
                je      set_vesa_mode_512_15

                cmp     videomode,11
                je      set_vesa_mode_640

                cmp     videomode,12
                je      set_vesa_mode_512_15

                mov     ebx,vesamodenumber512
                jmp     set_vesa_mode_now

set_vesa_mode_400:
                mov     ebx,vesamodenumber400
                jmp     set_vesa_mode_now

set_vesa_mode_640:
                mov     ebx,vesamodenumber640
                jmp     set_vesa_mode_now

set_vesa_mode_512_15:
                mov     ebx,vesamodenumber512_15

set_vesa_mode_now:
                ; set the mode
                mov     v86r_ax,04F02h
                ;;
                ;mov     ebx,vesamodenumber
                ;or      ebx,(1 SHL 14)
                ;;
                mov     v86r_bx,bx
                mov     al,10h
                int     33h

                ; clear the buffer with "1s"
                irp     i,<0,1,2,3,4>

                mov     eax,i
                call    set_vesa_bank
                mov     eax,0
                mov     edi,0a0000h
                sub     edi,_code32a
                mov     ecx,65536/4
                rep     stosd
                endm


                ; set larger area

                ;mov     v86r_ax,4F06h
                ;mov     v86r_bx,0
                ;mov     v86r_cx,1024
                ;
                ;mov     al,10h
                ;int     33h
                
                ret

; set_vesa_bank ------------------------------------------------------
; set the vesa bank register
; enter eax=bank number

set_vesa_bank:
                push    eax
                mov     v86r_ax,04F05h
                mov     v86r_bx,0
                mov     v86r_dx,ax
                mov     al,10h
                int     33h
                pop     eax
                ret

code32          ends
                end




;; VESA HEADER

VbeSignature    db      'VESA' ; VBE Signature
VbeVersion      dw      0200h   ; VBE Version
OemStringPtr    dd      ?       ; Pointer to OEM String
Capabilities    db      4 dup (?)       ; Capabilities of graphics controller
VideoModePtr    dd      ?       ; Pointer to VideoModeList
TotalMemory     dw      ?       ; Number of 64kb memory blocks
; Added for VBE 2.0
OemSoftwareRev  dw      ?       ; VBE implementation Software revision
OemVendorNamePtr        dd      ?       ; Pointer to Vendor Name String
OemProductNamePtr       dd      ?       ; Pointer to Product Name String
OemProductRevPtr        dd      ?       ; Pointer to Product Revision String
Reserved        db      222 dup (?); Reserved for VBE implementation scratch
;   area
OemData db      256 dup (?); Data Area for OEM Strings
