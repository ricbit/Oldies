        .386p 
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc
include globals.inc

public InitGraph,CloseGraph,TestTexture,InitPalette,ClearBuffer
public Line,x1,x2,y1,y2,color,ClearScreen,PLine,ClearPolygon,FlushPolygon
public FlushBuffer

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

x1              dd      ?
y1              dd      ?
x2              dd      ?
y2              dd      ?
color           db      ?

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;-----------------------------------------------------------------------------
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

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
; Tests a texture
; In:
;   EDX -> pointer to texture
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

TestTexture:
        mov     ebx,100
        mov     edi,VGAbuffer
        mov     esi,edx
TestTexture0:
        mov     ecx,100/4
        rep     movsd
        add     edi,320-100
        dec     ebx
        jnz     TestTexture0
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Inits the palette
; In:
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

InitPalette:
        mov     ecx,64
        mov     dx,03C8h
        mov     al,0
        out     dx,al
        inc     dx
InitPalette0:
        out     dx,al
        out     dx,al
        out     dx,al
        inc     al
        loop    InitPalette0
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Draws a Line using Bresenham to the video buffer
; In:
;   x1,y1,x2,y2,color
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

Line:
        pushad        

; Finds the initial position on frame buffer
        mov     edi,y1
        lea     edi,[edi*4+edi]
        shl     edi,6
        add     edi,x1
        add     edi,videobuffer
        
        mov     bl,color
        
        mov     edx,x2
        sub     edx,x1
        js      LineDxl

LineDxg:
        mov     esi,y2
        sub     esi,y1
        js      LineDxgDyl

LineDxgDyg:
        cmp     edx,esi
        jl      LineDxgDygAy

LineDxgDygAx:
        add     esi,esi
        mov     eax,esi
        sub     eax,edx
        mov     ecx,edx
        add     edx,edx
        inc     ecx
Line0:
        mov     [edi],bl
        dec     ecx
        jz      LineExit
        cmp     eax,0
        jl      Line0h
        add     edi,320
        sub     eax,edx
Line0h:
        inc     edi
        add     eax,esi
        jmp     Line0

LineDxgDygAy:
        add     edx,edx
        mov     eax,edx
        sub     eax,esi
        mov     ecx,esi
        add     esi,esi
        inc     ecx
Line1:
        mov     [edi],bl
        dec     ecx
        jz      LineExit
        cmp     eax,0
        jl      Line1h
        inc     edi
        sub     eax,esi
Line1h:
        add     edi,320
        add     eax,edx
        jmp     Line1

LineDxgDyl:
        neg     esi
        cmp     edx,esi
        jl      LineDxgDylAy

LineDxgDylAx:
        add     esi,esi
        mov     eax,esi
        sub     eax,edx
        mov     ecx,edx
        add     edx,edx
        inc     ecx
Line2:
        mov     [edi],bl
        dec     ecx
        jz      LineExit
        cmp     eax,0
        jl      Line2h
        sub     edi,320
        sub     eax,edx
Line2h:
        inc     edi
        add     eax,esi
        jmp     Line2

LineDxgDylAy:
        add     edx,edx
        mov     eax,edx
        sub     eax,esi
        mov     ecx,esi
        add     esi,esi
        inc     ecx
Line3:
        mov     [edi],bl
        dec     ecx
        jz      LineExit
        cmp     eax,0
        jl      Line3h
        inc     edi
        sub     eax,esi
Line3h:
        sub     edi,320
        add     eax,edx
        jmp     Line3

LineDxl:
        neg     edx
        mov     esi,y2
        sub     esi,y1
        js      LineDxlDyl

LineDxlDyg:
        cmp     edx,esi
        jl      LineDxlDygAy

LineDxlDygAx:
        add     esi,esi
        mov     eax,esi
        sub     eax,edx
        mov     ecx,edx
        add     edx,edx
        inc     ecx
Line4:
        mov     [edi],bl
        dec     ecx
        jz      LineExit
        cmp     eax,0
        jl      Line4h
        add     edi,320
        sub     eax,edx
Line4h:
        dec     edi
        add     eax,esi
        jmp     Line4

LineDxlDygAy:
        add     edx,edx
        mov     eax,edx
        sub     eax,esi
        mov     ecx,esi
        add     esi,esi
        inc     ecx
Line5:
        mov     [edi],bl
        dec     ecx
        jz      LineExit
        cmp     eax,0
        jl      Line5h
        dec     edi
        sub     eax,esi
Line5h:
        add     edi,320
        add     eax,edx
        jmp     Line5

LineDxlDyl:
        neg     esi
        cmp     edx,esi
        jl      LineDxlDylAy

LineDxlDylAx:
        add     esi,esi
        mov     eax,esi
        sub     eax,edx
        mov     ecx,edx
        add     edx,edx
        inc     ecx
Line6:
        mov     [edi],bl
        dec     ecx
        jz      LineExit
        cmp     eax,0
        jl      Line6h
        sub     edi,320
        sub     eax,edx
Line6h:
        dec     edi
        add     eax,esi
        jmp     Line6

LineDxlDylAy:
        add     edx,edx
        mov     eax,edx
        sub     eax,esi
        mov     ecx,esi
        add     esi,esi
        inc     ecx
Line7:
        mov     [edi],bl
        dec     ecx
        jz      LineExit
        cmp     eax,0
        jl      Line7h
        dec     edi       
        sub     eax,esi
Line7h:
        sub     edi,320
        add     eax,edx
        jmp     Line7

LineExit:
        popad    
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Clear the screen 
; In:
;   color
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

ClearScreen:
        push    edi ecx eax
        movzx   eax,byte ptr color
        imul    eax,dword ptr 01010101h
        mov     edi,VGAbuffer
        mov     ecx,64000/4
        cld
        rep     stosd
        pop     eax ecx edi
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Clear the polygon buffer
; In:
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

ClearPolygon:
        push    ebx edi ecx eax
        mov     edi,offset polygon
        mov     ecx,200
        mov     eax,-1
        mov     ebx,320

; Clear the buffer, making max=-1 and min=320
ClearPolygon0:
        mov     [edi].min,ebx
        mov     [edi].max,eax
        add     edi,8
        loop    ClearPolygon0

; Sets miny=200 and maxy=0
        mov     miny,200
        mov     maxy,0
        pop     eax ecx edi ebx
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Insert a point on the polygon buffer
; In:
;   EDI -> x, EBX -> y, EBP -> polygon
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

@InsertPoint macro number

;; Verifies if y<0 or y>200
        cmp     ebx,0
        jl      @InsertPointExit&number
        cmp     ebx,200
        jge     @InsertPointExit&number

;; Verifies if y<miny or y>maxy
        cmp     ebx,miny
        jge     @InsertPoint1&number
        mov     miny,ebx
@InsertPoint1&number:
        cmp     ebx,maxy
        jl      @InsertPoint2&number
        mov     maxy,ebx

@InsertPoint2&number:
;; Atualizes the polygon buffer
        cmp     edi,[ebp+ebx*8].min
        jge     @InsertPoint0&number
        mov     [ebp+ebx*8].min,edi
@InsertPoint0&number:
        cmp     edi,[ebp+ebx*8].max
        jl      @InsertPointExit&number
        mov     [ebp+ebx*8].max,edi

@InsertPointExit&number:

endm

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Precompute a Line rasterization using Bresenham
; In:
;   x1,y1,x2,y2,color
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

PLine:
        pushad        

        mov     ebp,offset polygon
        mov     edx,x2
        sub     edx,x1
        js      PLineDxl

PLineDxg:
        mov     esi,y2
        sub     esi,y1
        js      PLineDxgDyl

PLineDxgDyg:
        cmp     edx,esi
        jl      PLineDxgDygAy

PLineDxgDygAx:
        add     esi,esi
        mov     eax,esi
        sub     eax,edx
        mov     ecx,edx
        add     edx,edx
        inc     ecx
        mov     edi,x1
        mov     ebx,y1
PLine0:
        @InsertPoint 0
        dec     ecx
        jz      PLineExit
        cmp     eax,0
        jl      PLine0h
        inc     ebx
        sub     eax,edx
PLine0h:
        inc     edi
        add     eax,esi
        jmp     PLine0

PLineDxgDygAy:
        add     edx,edx
        mov     eax,edx
        sub     eax,esi
        mov     ecx,esi
        add     esi,esi
        inc     ecx
        mov     edi,x1
        mov     ebx,y1
PLine1:
        @InsertPoint 1
        dec     ecx
        jz      PLineExit
        cmp     eax,0
        jl      PLine1h
        inc     edi
        sub     eax,esi
PLine1h:
        inc     ebx
        add     eax,edx
        jmp     PLine1

PLineDxgDyl:
        neg     esi
        cmp     edx,esi
        jl      PLineDxgDylAy

PLineDxgDylAx:
        add     esi,esi
        mov     eax,esi
        sub     eax,edx
        mov     ecx,edx
        add     edx,edx
        inc     ecx
        mov     edi,x1
        mov     ebx,y1
PLine2:
        @InsertPoint 2
        dec     ecx
        jz      PLineExit
        cmp     eax,0
        jl      PLine2h
        dec     ebx
        sub     eax,edx
PLine2h:
        inc     edi
        add     eax,esi
        jmp     PLine2

PLineDxgDylAy:
        add     edx,edx
        mov     eax,edx
        sub     eax,esi
        mov     ecx,esi
        add     esi,esi
        inc     ecx
        mov     edi,x1
        mov     ebx,y1
PLine3:
        @InsertPoint 3
        dec     ecx
        jz      PLineExit
        cmp     eax,0
        jl      PLine3h
        inc     edi
        sub     eax,esi
PLine3h:
        dec     ebx
        add     eax,edx
        jmp     PLine3

PLineDxl:
        neg     edx
        mov     esi,y2
        sub     esi,y1
        js      PLineDxlDyl

PLineDxlDyg:
        cmp     edx,esi
        jl      PLineDxlDygAy

PLineDxlDygAx:
        add     esi,esi
        mov     eax,esi
        sub     eax,edx
        mov     ecx,edx
        add     edx,edx
        inc     ecx
        mov     edi,x1
        mov     ebx,y1
PLine4:
        @InsertPoint 4
        dec     ecx
        jz      PLineExit
        cmp     eax,0
        jl      PLine4h
        inc     ebx
        sub     eax,edx
PLine4h:
        dec     edi
        add     eax,esi
        jmp     PLine4

PLineDxlDygAy:
        add     edx,edx
        mov     eax,edx
        sub     eax,esi
        mov     ecx,esi
        add     esi,esi
        inc     ecx
        mov     edi,x1
        mov     ebx,y1
PLine5:
        @InsertPoint 5
        dec     ecx
        jz      PLineExit
        cmp     eax,0
        jl      PLine5h
        dec     edi
        sub     eax,esi
PLine5h:
        inc     ebx
        add     eax,edx
        jmp     PLine5

PLineDxlDyl:
        neg     esi
        cmp     edx,esi
        jl      PLineDxlDylAy

PLineDxlDylAx:
        add     esi,esi
        mov     eax,esi
        sub     eax,edx
        mov     ecx,edx
        add     edx,edx
        inc     ecx
        mov     edi,x1
        mov     ebx,y1
PLine6:
        @InsertPoint 6
        dec     ecx
        jz      PLineExit
        cmp     eax,0
        jl      PLine6h
        dec     ebx
        sub     eax,edx
PLine6h:
        dec     edi
        add     eax,esi
        jmp     PLine6

PLineDxlDylAy:
        add     edx,edx
        mov     eax,edx
        sub     eax,esi
        mov     ecx,esi
        add     esi,esi
        inc     ecx
        mov     edi,x1
        mov     ebx,y1
PLine7:
        @InsertPoint 7
        dec     ecx
        jz      PLineExit
        cmp     eax,0
        jl      PLine7h
        dec     edi       
        sub     eax,esi
PLine7h:
        dec     ebx
        add     eax,edx
        jmp     PLine7

PLineExit:
        popad    
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Flush a polygon to buffer
; In:
;   miny,maxy,polygon
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

FlushPolygon:
        pushad
        mov     edx,miny
        cmp     edx,200
        jge     FlushPolygonExit
        mov     ebp,offset polygon
        cld
        mov     al,63

FlushPolygon0:
        mov     ebx,[ebp+edx*8].min
        cmp     ebx,0
        jge     FlushPolygon1
        mov     ebx,0
FlushPolygon1:
        mov     esi,[ebp+edx*8].max
        cmp     esi,320
        jl      FlushPolygon2
        mov     esi,320
FlushPolygon2:
        mov     edi,edx
        lea     edi,[edi*4+edi]
        shl     edi,6
        add     edi,ebx
        add     edi,videobuffer
        mov     ecx,esi
        sub     ecx,ebx
        jz      FlushPolygon3
        rep     stosb
FlushPolygon3:
        inc     edx
        cmp     edx,maxy
        jne     FlushPolygon0

FlushPolygonExit:
        popad
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Clear the video buffer
; In:
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

ClearBuffer:
        push    eax ecx edi
        mov     eax,0
        mov     ecx,64000/4
        mov     edi,videobuffer
        cld
        rep     stosd
        pop     edi ecx eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Flush the video buffer to screen
; In:
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

FlushBuffer:
        push    edi esi ecx eax
        mov     edi,VGAbuffer
        mov     esi,videobuffer
        mov     ecx,64000/4
        cld

; Wait for vertical retrace
        mov     dx,03DAh
FlushBuffer0:
        in      al,dx
        test    al,8
        jz      FlushBuffer0

; Flush entire buffer
        rep     movsd
        pop     eax ecx esi edi
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
code32  ends
        end


