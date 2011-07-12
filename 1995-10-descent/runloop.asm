        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc
include kb32.inc
include graph.inc
include project.inc
include keyboard.inc
include draw.inc
include globals.inc

public RunLoop

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

newframe        dd      1

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;-----------------------------------------------------------------------------
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Run loop
; In:
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

RunLoop:
; Configure the keyboard
        mov     _kbhand,offset KeyboardHandler

RunLoopStart:
; Check if screen needs atualization
        cmp     newframe,0
        je      RunLoop0     

; Draw a new frame
        mov     newframe,0
        inc     actualframe
        mov     color,0   
        call    ClearBuffer
        call    SetViewer
        call    ProjectAllWalls
        call    DrawAllWalls
        call    FlushBuffer

RunLoop0:      
; Check the right key
        cmp     rightkey,1
        jne     RunLoop1
        add     theta,100
        and     theta,0FFFFh
        mov     newframe,1

RunLoop1:
; Check the left key
        cmp     leftkey,1
        jne     RunLoop2
        mov     newframe,1
        sub     theta,100       
        jns     RunLoop2
        add     theta,10000h     
        and     theta,0FFFFh

RunLoop2:
; Check the up key
        cmp     upkey,1
        jne     RunLoop3
        mov     newframe,1
        add     phi,100
        and     phi,0FFFFh

RunLoop3:
; Check the down key
        cmp     downkey,1
        jne     RunLoop4
        mov     newframe,1
        sub     phi,100
        jns     RunLoop4
        add     phi,10000h
        and     phi,0FFFFh

RunLoop4:
; Check for A key
        cmp     akey,1
        jne     RunLoop5
        mov     newframe,1

; obs.from=obs.from+0.1*obs.to
        mov     ebx,0CCCh 
        mov     eax,obs.to.dirx
        imul    ebx
        shrd    eax,edx,16
        add     obs.from.dirx,eax

        mov     eax,obs.to.diry
        imul    ebx
        shrd    eax,edx,16
        add     obs.from.diry,eax

        mov     eax,obs.to.dirz
        imul    ebx
        shrd    eax,edx,16
        add     obs.from.dirz,eax

RunLoop5: 
; Check for Z key
        cmp     zkey,1
        jne     RunLoopEnd
        mov     newframe,1

; obs.from = obs.from-0.1*obs.to
        mov     ebx,0CCCh
        mov     eax,obs.to.dirx
        imul    ebx
        shrd    eax,edx,16
        sub     obs.from.dirx,eax

        mov     eax,obs.to.diry
        imul    ebx
        shrd    eax,edx,16
        sub     obs.from.diry,eax

        mov     eax,obs.to.dirz
        imul    ebx
        shrd    eax,edx,16
        sub     obs.from.dirz,eax

RunLoopEnd:
; Check the esc key        
        cmp     esckey,1
        jne     RunLoopStart

; Reset the keyboard
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
code32  ends
        end

