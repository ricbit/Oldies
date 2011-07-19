; --------------------------------------------------------------------
; Parrot video engine
; Copyright (C) 1999 by Ricardo Bittencourt                            
; -------------------------------------------------------------------- 

all40           dq      04040404040404040h
all3DEF         dq      03DEF3DEF3DEF3DEFh
all0000         dq      00000000000000000h
all0001         dq      00001000100010001h
all0002         dq      00002000200020002h
allFFFE         dq      0FFFEFFFEFFFEFFFEh
allFFFC         dq      0FFFCFFFCFFFCFFFCh
all0006         dq      00006000600060006h


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

; blit_linear_512_15_branch ------------------------------------------
; 512x384x15 main core selector

blit_linear_512_15_branch:
                cmp     enginetype,2
                je      blit_linear_512_15_mmx

                ;BLIT_LINEAR ENGINE_DOS,RES_512_15
                call    nonlinear_filter
                mov     esi,bluebuffer
                BLIT_LINEAR_512_15 ENGINE_DOS

blit_linear_512_15_mmx:

                ;BLIT_LINEAR ENGINE_MMX,RES_512_15
                call    nonlinear_filter
                mov     esi,bluebuffer
                BLIT_LINEAR_512_15 ENGINE_MMX

blit_linear_512_inter_branch:
                cmp     enginetype,2
                je      blit_linear_512_inter_mmx

                ;BLIT_LINEAR ENGINE_DOS,RES_512_15
                mov     esi,redbuffer
                BLIT_LINEAR_512_15 ENGINE_DOS

blit_linear_512_inter_mmx:

                ;BLIT_LINEAR ENGINE_MMX,RES_512_15
                mov     esi,redbuffer
                BLIT_LINEAR_512_15 ENGINE_MMX

code32          ends
                end



