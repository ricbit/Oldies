        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc
include file32.inc
include pdosstr.inc
include kb32.inc
include globals.inc
include graph.inc

public InitAll

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

msg1            db      'Low memory free: ',0h
msg2            db      'Press any key to start',0h
msg3            db      'Passei por aqui',0Dh,0Ah,0h
msg4            db      'Texture ',0h
msg5            db      ' loaded',0Dh,0Ah,0h
msg6            db      'High memory free: ',0h
msg7            db      'Number of vertex: ',0h
msg8            db      'Number of walls: ',0h
msg9            db      'Vertex ',0h
msg10           db      'Wall ',0h
msg11           db      'Sin table loaded',0Dh,0Ah,0h
welcome         db      'Loading RB Descent...',0Dh,0Ah,0h
errmsg1         db      'Error in file: ',0h
errmsg2         db      'Not enough memory',0h
texname         db      'ice.shp',0h
scenename       db      'scene.dat',0h
sintablename    db      'sintable.dat',0h  
filebuffer      dd      ?
handle          dw      ?

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;-----------------------------------------------------------------------------
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

PPA:
        push    edx eax
        mov     edx,offset msg3
        call    _putdosstr
        call    _getch
        pop     eax edx
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Initialize the file buffers
; In: 
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

InitFileBuffers:
        push    eax
        mov     eax,4000h
        call    _getlomem
        jc      NotEnoughMemory
        mov     filebuffer,eax
        pop     eax
        ret
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
NotEnoughMemory:
        mov     edx,offset errmsg2
        call    _putdosstr
        jmp     _exit

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Initialize the video buffer
; In: 
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

InitVideoBuffer:
        push    eax
        mov     eax,64000
        call    _getmem
        jc      NotEnoughMemory
        mov     videobuffer,eax
        pop     eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Loads a texture from disk
; In: 
;   EDX -> ASCIIZ with name of texture    
; Out:
;   EAX -> pointer to texture
; Destroys:
;   ECX,EDI,ESI
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

LoadTexture:
        
; Open the file
        push    edx
        call    _openfile
        jc      ErrorOpeningFile
        
; Read to buffer
        mov     edx,filebuffer
        mov     ecx,10000
        call    _readfile
        
; Allocate the memory for texture
        mov     eax,10000
        call    _getmem
        jc      NotEnoughMemory
        
; Copy from buffer to memory
        cld
        mov     edi,eax
        mov     ecx,10000/4
        mov     esi,filebuffer
        rep     movsd
        
; Print a message
        mov     edx,offset msg4
        call    _putdosstr
        pop     edx
        call    _putdosstr
        mov     edx,offset msg5
        call    _putdosstr

; Close the file
        call    _closefile
        ret
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
ErrorOpeningFile:
        push    edx
        mov     edx,offset errmsg1
        call    _putdosstr
        pop     edx
        call    _putdosstr
        jmp     _exit


;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Print status of memory
; In: 
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

Chkmem:
        mov     edx,offset msg1
        call    _putdosstr
        call    _lomemsize
        call    _putdecimal
        mov     edx,offset newline
        call    _putdosstr
        mov     edx,offset msg6
        call    _putdosstr
        call    _himemsize
        call    _putdecimal
        @NewLine
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Load the scene description from disk
; In: 
;   EDX -> ASCIIZ with file name
; Out:
;   wallroot,vertexroot,vertexmax,wallmax
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

LoadScene:
; Open the file        
        call    _openfile
        jc      ErrorOpeningFile
        mov     ax,v86r_bx
        mov     handle,ax

; Load the number of vertex from disk
        mov     edx,filebuffer
        mov     ecx,4
        call    _readfile
        mov     eax,[edx]
        mov     vertexmax,eax

; Print the number of vertex
        mov     edx,offset msg7
        call    _putdosstr        
        call    _putdecimal
        @NewLine
        
; Allocate memory to vertex
        mov     ecx,eax
        imul    eax,dword ptr vertexsize
        call    _getmem
        jc      NotEnoughMemory
        mov     vertexroot,eax

; Load the vertex from disk     
        push    ecx
        mov     edx,filebuffer
        imul    ecx,dword ptr 12
        mov     si,handle
        mov     v86r_bx,si
        call    _readfile
        pop     ecx

; Move vertex from buffer
        mov     esi,filebuffer
        mov     edi,vertexroot
        cld
LoadScene0:
        push    ecx
        mov     ecx,12
        rep     movsb
        add     edi,vertexsize-12
        pop     ecx
        loop    LoadScene0

; Load the number of walls from disk
        mov     edx,filebuffer
        mov     ecx,4
        mov     si,handle
        mov     v86r_bx,si
        call    _readfile
        mov     eax,[edx]
        mov     wallmax,eax

; Print the number of walls
        mov     edx,offset msg8
        call    _putdosstr
        call    _putdecimal
        @NewLine

; Allocate memory to walls
        mov     ecx,eax
        imul    eax,dword ptr wallsize
        call    _getmem
        jc      NotEnoughMemory
        mov     wallroot,eax

; Load the walls from disk
        mov     edx,filebuffer
        push    ecx
        imul    ecx,16
        mov     si,handle
        mov     v86r_bx,si
        call    _readfile
        pop     ecx

; Move the walls from buffer
        imul    ecx,4
        mov     esi,filebuffer
        mov     edx,0
        mov     edi,wallroot
LoadScene1:
        mov     eax,[esi+edx*4]
        imul    eax,28
        add     eax,vertexroot
        mov     [edi],eax
        add     edi,4
        inc     edx
        loop    LoadScene1

        mov     si,handle
        mov     v86r_bx,si
        call    _closefile
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Print scene description
; In: 
;   wallroot,wallmax,vertexroot,vertexmax
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

PrintScene:
; Print all the vertex        
        mov     ecx,vertexmax
        mov     esi,vertexroot
        mov     eax,0
PrintScene0:
        mov     edx,offset msg9
        call    _putdosstr
        call    _putdecimal
        @NewLine
        call    PrintVertex
        add     esi,vertexsize
        inc     eax
        loop    PrintScene0

; Print all the walls
        mov     ecx,wallmax
        mov     edi,wallroot
        mov     eax,0
        mov     edx,offset msg10
PrintScene1:
        call    _putdosstr
        call    _putdecimal
        @NewLine
        inc     eax
        mov     esi,[edi].v1
        call    PrintVertex
        mov     esi,[edi].v2
        call    PrintVertex
        mov     esi,[edi].v3
        call    PrintVertex
        mov     esi,[edi].v4
        call    PrintVertex
        add     edi,wallsize
        loop    PrintScene1
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
PrintVertex:
        push    eax
        mov     eax,[esi].v.dirx
        call    _putdecimal
        @WhiteSpace
        mov     eax,[esi].v.diry
        call    _putdecimal
        @WhiteSpace
        mov     eax,[esi].v.dirz
        call    _putdecimal
        @NewLine
        pop     eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Load the sin table from disk
; In: 
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

LoadSinTable:
; Open the file
        mov     edx,offset sintablename
        call    _openfile
        jc      ErrorOpeningFile

; Allocate memory for the table
        mov     eax,65536*4
        call    _getmem
        jc      NotEnoughMemory
        mov     sintable,eax

; Read the table from disk, in blocks of 4000h bytes
        mov     ecx,16
        mov     edi,eax
        mov     esi,filebuffer
        mov     edx,esi
LoadSinTable0:
        push    ecx
        mov     ecx,4000h
        call    _readfile
        cld
        rep     movsb
        pop     ecx
        mov     esi,edx
        loop    LoadSinTable0
        call    _closefile
        mov     edx,offset msg11
        call    _putdosstr
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Initialize all 
; In: 
;   None
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

InitAll:
        mov     edx,offset welcome
        call    _putdosstr
        
; Check memory
        call    Chkmem

; Init the keyboard
        call    _init_kb

; Init the temporary buffer for file loading        
        call    InitFileBuffers

; Init the video buffer
        call    InitVideoBuffer

; Load the texture        
        mov     edx,offset texname
        call    LoadTexture
        mov     texture,eax
        
; Load the precalculated sin table
        call    LoadSinTable

; Initialize the global pointers        
        @rlp    eax,0A0000h
        mov     VGAbuffer,eax

; Load the scene description
        mov     edx,offset scenename
        call    LoadScene

; Print scene description
        call    PrintScene

; Check memory again
        call    Chkmem

; Wait for user        
        mov     edx,offset msg2
        call    _putdosstr
        call    _getch

; Init the graphics mode
        call    InitGraph
        call    InitPalette

        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
code32  ends
        end

