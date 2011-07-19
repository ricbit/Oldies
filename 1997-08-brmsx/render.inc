MSX1_RENDER     EQU     0
MSX2_RENDER     EQU     1

DOS_ENGINE      EQU     0
WIN_ENGINE      EQU     1
MMX_ENGINE      EQU     2

BITMASK_YES     EQU     0
BITMASK_NO      EQU     1

; PIPE1 --------------------------------------------------------------
; this is the inner loop for render_screen1_* functions

PIPE1           macro   render_model

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

                if      render_model EQ MSX2_RENDER
                or      ebp,10101010h
                endif

                ; display the subline
                mov     [edi+i*256],ebp

                ; do it again for the next four pixels
                mov     ebp,[offset foregroundmask+edx*8+4]
                and     esi,ecx
                and     ebp,eax
                or      ebp,esi
                mov     dl,[ebx+i+1]
                
                if      render_model EQ MSX2_RENDER
                or      ebp,10101010h
                endif

                mov     [edi+4+i*256],ebp

                endm

                pop     ebx
                pop     eax
                pop     esi
                pop     ecx
                
                endm

; PIPE2_DOS ----------------------------------------------------------
; this is the inner loop for render_screen2 function

PIPE2_DOS       macro   bitmask_type,render_model
                
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

                if      render_model EQ MSX2_RENDER
                or      ebp,10101010h
                endif

                mov     cl,[eax+i]
                mov     [edi+i*256],ebp
                
                mov     ebp,[offset foregroundmask+edx*8+4]
                mov     esi,[offset backgroundmask+edx*8+4]
                
                and     ebp,[offset foregroundcolor+ecx*4]
                and     esi,[offset backgroundcolor+ecx*4]
                
                or      ebp,esi
                mov     dl,[ebx+(i+1)]
                
                if      render_model EQ MSX2_RENDER
                or      ebp,10101010h
                endif

                mov     cl,[eax+(i+1)]
                mov     [edi+4+i*256],ebp

                endm
                
                mov     eax,0
                
                endm

; PIPE2_MMX ----------------------------------------------------------
; this is the inner loop for render_screen2 function
; it uses the MMX instructions for better performance

PIPE2_MMX       macro   bitmask_type,render_model

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

                if      render_model EQ MSX2_RENDER
                ;;por   MM0,MM2
                por     
                db      11000010b
                endif
                
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
                  PIPE2_DOS BITMASK_NO,MSX1_RENDER
                else
                  PIPE2_MMX BITMASK_NO,MSX1_RENDER
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

; render_screen2 (macro version) -------------------------------------

RENDER_SCREEN2_MACRO macro videoengine,render_model,currentbuffer
                local   render_screen2_next
                local   render23
                local   render20
                local   render21
                
                if      render_model EQ MSX1_RENDER                

                cmp     everyframe,1
                je      render_screen2_next
                
                cmp     imagetype,1
                je      render_screen2_dirty

render_screen2_next:

                endif

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

                if (videoengine EQ MMX_ENGINE)
                ;;movq MM2,all10
                movq
                db      00010101b
                dd      offset all10
                endif

                ; edi = blit buffer
                mov     edi,currentbuffer

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
                  PIPE2_DOS BITMASK_YES,render_model
                else
                  PIPE2_MMX BITMASK_YES,render_model
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

