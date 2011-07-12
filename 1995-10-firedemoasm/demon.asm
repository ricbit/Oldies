        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc
include kb32.inc
include argc32.inc
include pdosstr.inc
include strltu.rt
include strhtn.rt

public  _main

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

include random5.inc
include rand320.inc

align 4
VGAbuffer       dd      ?
LastLine        dd      ?
pont320         dd      ?
pont5           dd      ?
vid             dd      ?
ticks           dd      0
frames          dd      0
endflag         dd      0
grades          dd      270
endx            dd      320
rendx           dd      ?
numbuf          db      32 dup (0)
msg1            db      'Frames per second: ',0

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Puts the display in mode 13h - 320x200/256
; In:
;   None
; Out:
;   None
; Destroys:
;   AL    
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

InitGraph:
        mov     v86r_ax,0013h
        mov     al,10h
        int     30h
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Puts the display in mode 3h - Text 80 columns/multicolor
; In:
;   None
; Out:
;   None
; Destroys:
;   AL    
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

CloseGraph:
        mov     v86r_ax,0003h
        mov     al,10h
        int     30h
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Set a palette color
; In:
;   al - palette number
;   bl  - red
;   bh  - green
;   ah  - blue
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

SetRGB:
        push    eax
        mov     dx,03C8h
        out     dx,al
        inc     dx
        mov     al,bl
        out     dx,al
        mov     al,bh
        out     dx,al
        mov     al,ah
        out     dx,al
        pop     eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Time handler (ticks every 1/100 sec)
; In:
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

TimeHandler:
        pushad
        push    ds
        mov     ax,ss
        mov     ds,ax
        inc     ticks
        mov     al,20h
        out     20h,al
        pop     ds
        popad
        iretd


;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
setendflag:
        mov     endflag,1
        jmp     next

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
_main:
        xor     al,al                       
        mov     edx,offset numbuf
        call    _cchekstr
        jc      init0

        call    _strltu                    
        call    _strhtn                    

        mov     grades,eax

init0:
        mov     al,1
        mov     edx,offset numbuf
        call    _cchekstr
        jc      init1

        call    _strltu                    
        call    _strhtn                    

        mov     endx,eax

init1:

; Initialize
        @rlp    eax,0A0000h
        mov     VGAbuffer,eax
        mov     eax,64000
        call    _getmem
        mov     vid,eax
        call    _init_kb
        call    InitGraph

; Sets the palette

        mov     cl,0
        mov     ch,63
pal0:
        mov     al,cl
        mov     bl,cl
        mov     bh,0
        mov     ah,0
        call    SetRGB
        add     al,64
        mov     bl,63
        mov     bh,cl
        mov     ah,0
        call    SetRGB
        add     al,64
        mov     bl,ch
        mov     bh,ch
        mov     ah,cl
        call    SetRGB
        add     al,64
        mov     bl,cl
        mov     bh,cl
        mov     ah,63
        call    SetRGB
        dec     ch
        inc     cl
        cmp     cl,64
        jne     pal0

; Turns on the time handler
        mov     bl,20h
        mov     eax,offset TimeHandler
        call    _setvect
        mov     al,34h
        out     43h,al
        mov     al,155
        out     40h,al
        mov     al,46
        out     40h,al

; Fire effect!!!!

        mov     esi,vid
        add     esi,198*320
        mov     LastLine,esi
        mov     pont320,0
        mov     pont5,0
        mov     edi,vid
        mov     ecx,64000/4
        mov     eax,0
        cld
        rep     stosd
        mov     edi,VGAbuffer
        mov     ecx,64000/4
        mov     eax,0
        rep     stosd

fire:
        mov     edi,LastLine
        mov     ecx,2*320/4
        mov     eax,0
        cld
        rep     stosd     
        
        mov     ecx,grades
        mov     esi,offset random320
        mov     ebx,pont320
        mov     edx,LastLine
fire1:
        mov     eax,edx
        add     eax,[esi+ebx*4]
        mov     byte ptr [eax],255
        inc     ebx
        and     ebx,8191
        loop    fire1
        mov     pont320,ebx

        mov     esi,offset random5
        mov     edi,pont5
        mov     edx,vid
        add     edx,198*320
        mov     ecx,0
        mov     ebx,0
loopao:        
        mov     ebp,edx ;
        inc     ebp ;
        mov     rendx,edx
        mov     eax,endx
        add     rendx,eax
align 4
loopinho:
        mov     eax,ebp ;
        add     eax,[esi+edi*4]
        mov     bl,byte ptr [eax-1]
        xor     ecx,ecx
        mov     cl,byte ptr [eax+1]
        inc     edi
        add     ebx,ecx
        mov     cl,byte ptr [eax+320]
        and     edi,8191
        add     ebx,ecx
        mov     cl,byte ptr [eax-320]
        add     ebx,ecx
        mov     cl,byte ptr [eax]
        shl     ecx,2
        add     ebx,ecx
        shr     ebx,3
        mov     byte ptr [ebp-320],bl

        inc     ebp
        cmp     ebp,rendx
        jne     loopinho

        sub     edx,320
        cmp     edx,vid
        jge     loopao

        mov     pont5,edi
        cmp     endflag,0
        je      vrt
        sub     grades,8

; Wait for vertical retrace
vrt:
        mov     dx,03DAh
vrt0:
        in      al,dx
        test    al,8
        jz      vrt0
        
        mov     esi,vid
        mov     edi,VGAbuffer
        mov     ecx,(64000-640-320)/4
        cld
        rep     movsd
        inc     frames
        @kbhit
        jc      setendflag

next:
        cmp     grades,0
        jg      fire      

        call    CloseGraph
        call    _reset_kb        
        mov     al,34h
        out     43h,al
        mov     al,0
        out     40h,al
        mov     al,0
        out     40h,al
        mov     edx,offset msg1
        call    _putdosstr
        mov     eax,frames
        imul    eax,100
        mov     edx,0
        idiv    ticks
        call    _putdecimal
        @NewLine
        
        db      0fh,031h
        mov     ebx,eax

        mov     ecx,100
loopc:  

        mov     edx,1
        mov     ecx,ecx
        dec     ecx        
        jnz     loopc

        db      0fh,031h
        sub     eax,ebx
        call    _putdecimal                
        @NewLine
        
        jmp     _exit

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; In:
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; In:
; Out:
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

code32  ends
        end

