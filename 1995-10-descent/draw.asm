        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc
include kb32.inc
include globals.inc
include graph.inc

public WireFrame,Flat,DrawAllWalls

;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
; DATA
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�

;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�
; CODE
;北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北�

;哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪哪�
;-----------------------------------------------------------------------------
;屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯�

;鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍�
; Draw a wireframe version of a projected wall on screen
; In:
;   EDX -> pointer to wall
; Out:
;   None
;鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍�

WireFrame:
        push    esi eax

; Draws a line from v1 to v2        
        mov     color,63
        mov     esi,[edx].v1
        mov     eax,[esi].p.x
        mov     x1,eax
        mov     eax,[esi].p.y
        mov     y1,eax
        mov     esi,[edx].v2
        mov     eax,[esi].p.x
        mov     x2,eax
        mov     eax,[esi].p.y
        mov     y2,eax
        call    Line

; Draws a line from v2 to v3
        mov     esi,[edx].v3
        mov     eax,[esi].p.x
        mov     x1,eax
        mov     eax,[esi].p.y
        mov     y1,eax
        call    Line

; Draws a line from v3 to v4
        mov     esi,[edx].v4
        mov     eax,[esi].p.x
        mov     x2,eax
        mov     eax,[esi].p.y
        mov     y2,eax
        call    Line

; Draws a line from v4 to v1
        mov     esi,[edx].v1
        mov     eax,[esi].p.x
        mov     x1,eax
        mov     eax,[esi].p.y
        mov     y1,eax
        call    Line

        pop     eax esi
        ret

;鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍�
; Draw a flat version of a projected wall on screen
; In:
;   EDX -> pointer to wall
; Out:
;   None
;鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍�

Flat:
        push    esi eax

; Clear the polygon buffer
        call    ClearPolygon

; Draws a line from v1 to v2        
        mov     color,63
        mov     esi,[edx].v1
        mov     eax,[esi].p.x
        mov     x1,eax
        mov     eax,[esi].p.y
        mov     y1,eax
        mov     esi,[edx].v2
        mov     eax,[esi].p.x
        mov     x2,eax
        mov     eax,[esi].p.y
        mov     y2,eax
        call    PLine

; Draws a line from v2 to v3
        mov     esi,[edx].v3
        mov     eax,[esi].p.x
        mov     x1,eax
        mov     eax,[esi].p.y
        mov     y1,eax
        call    PLine

; Draws a line from v3 to v4
        mov     esi,[edx].v4
        mov     eax,[esi].p.x
        mov     x2,eax
        mov     eax,[esi].p.y
        mov     y2,eax
        call    PLine

; Draws a line from v4 to v1
        mov     esi,[edx].v1
        mov     eax,[esi].p.x
        mov     x1,eax
        mov     eax,[esi].p.y
        mov     y1,eax
        call    PLine

; Flush polygon buffer
        call    FlushPolygon

        pop     eax esi
        ret

;鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍�
; Draw a flat version of a projected wall on screen
; In:
;   None
; Out:
;   None
;鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍鞍�

DrawAllWalls:
        push    ecx edx
        mov     edx,wallroot
        mov     ecx,wallmax

DrawAllWalls0:
        call    Flat
        add     edx,wallsize
        loop    DrawAllWalls0
        pop     edx ecx
        ret

;屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯屯�
code32  ends
        end

