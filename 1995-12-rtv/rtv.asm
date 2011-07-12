; RTV v1.0PC        
; by Ricardo Bittencourt
        
        .386p 
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc
include kb32.inc
include argc32.inc
include pdosstr.inc
include file32.inc
include sqrt.inc
include invtable.inc
include m320tab.inc
include indxbyte.rt

public  _main

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±


xmode           equ     0
ymode           equ     1
zmode           equ     2
tmode           equ     3
fmode           equ     4
epsilon         equ     80000
V               equ     63*65536
invsqrt3        equ     37837

vector struc

        dirx    dd      0
        diry    dd      0
        dirz    dd      0

vector ends

pixel struc

        x       dd      0
        y       dd      0

pixel ends

observer struc

        from    vector  <>
        to      vector  <>
        up      vector  <>
        ud      vector  <>
        vd      vector  <>

observer ends      

vertex struc

        v       vector  <>
        p       pixel   <>
;        norm    vector  <>
;        shade   dd      ?

vertex ends

interp struc

        xpos    dd      0
        zvect   dd      ?

interp ends

align 4
VGAbuffer       dd      ?
volume          dd      ?
slice           dd      ?
Xinc            dd      ?
Xinc64          dd      ?
Yinc            dd      ?
Zinc            dd      ?
phiXinc         dd      ?
gradvol         dd      ?
volumemax       dd      ?
Zincface        dd      ?
Zend            dd      ?
x1              dd      ?
x2              dd      ?
y1              dd      ?
y2              dd      ?
sintable        dd      ?
offvl           dd      ?
offvml          dd      ?
offvmr          dd      ?
offvg           dd      ?
startX          dd      ?
endX            dd      ?
intstartZ       dd      ?
intstepZ        dd      ?
filehandle      dw      ?
savevoxel       db      ?
color           db      ?
R               vector  <>
K               vector  <>
gradient        vector  <>
direction       vector  <>
v000            vertex  <>
v001            vertex  <>
v010            vertex  <>
v011            vertex  <>
v100            vertex  <>
v101            vertex  <>
v110            vertex  <>
v111            vertex  <>
v1              vertex  <>
v2              vertex  <>
v3              vertex  <>
v4              vertex  <>
obs             observer <>

align 4
Ltable          interp  100 dup (<>)
Rtable          interp  100 dup (<>)
mode            dd      0
segmode         dd      0
theta           dd      0100h
phi             dd      0100h
Xslice          dd      20
Yslice          dd      20
Zslice          dd      20
Tlevel          dd      40
Fstart          dd      5
keytable        db      15,'+','-',14,'x','y','z','s','t','r','f','l'
                db      25,26,23,24
functable       dd      keyplus,keyminus,mainend
                dd      setXmode,setYmode,setZmode,setsegmode,setTmode
                dd      redrawkey,setFmode,lampkey
                dd      upkey,downkey,leftkey,rightkey
msg1            db      'Not enough high memory',13,10,0
msg2            db      'Error in file',13,10,0
msg3            db      'Not enough low memory',13,10,0
msg4            db      'RTV v1.0PC - by Ricardo Bittencourt',13,10,10,0
msg5            db      'Reading volume...',13,10,0
msg6            db      'Generating gradients...',13,10,0
msg7            db      'Press any key to start...',0
msg8            db      'High memory free ',0
msg9            db      'Low memory free ',0
msg10           db      'Reading sin table...',13,10,0
file1           db      'CORN.INT',0
file2           db      'SINTABLE.DAT',0

; x = unit
; y = 64x unit
; z = 64x64x unit

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
; Put a pixel on screen
; In:
;   ESI->pixel al=color
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

PutPixel:
        push    edi
        mov     edi,[esi].p.y
        lea     edi,[edi+edi*4]
        shl     edi,6
        add     edi,[esi].p.x
        add     edi,VGAbuffer
        mov     [edi],al
        pop     edi
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
        add     edi,VGAbuffer
        
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
; Adjust observer to new position
; In: 
;   theta (plane Oxz), phi (plane Oxz with axis y)
; Out: 
;   obs (to,up,ud,vd)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

SetViewer:
        pushad

; Precalculate ebx=sin theta, ecx=sin phi, esi=cos theta, edi=cos phi
        mov     edx,sintable
        mov     eax,phi
        mov     ecx,[edx+eax*4]
        add     eax,400h
        and     eax,0FFFh
        mov     edi,[edx+eax*4]
        mov     eax,theta
        mov     ebx,[edx+eax*4]
        add     eax,400h
        and     eax,0FFFh
        mov     esi,[edx+eax*4]

; to = -(cos phi*cos theta,sin phi,cos phi*sin theta)
        mov     eax,edi
        imul    esi
        shrd    eax,edx,16
        neg     eax
        mov     obs.to.dirx,eax

        mov     obs.to.diry,ecx
        neg     obs.to.diry

        mov     eax,edi
        imul    ebx
        shrd    eax,edx,16
        neg     eax
        mov     obs.to.dirz,eax

; up = (-sin phi*cos theta, cos phi, -sin phi*sin theta)
        neg     ecx
        mov     eax,ecx
        imul    esi
        shrd    eax,edx,16
        mov     obs.up.dirx,eax

        mov     obs.up.diry,edi

        mov     eax,ecx
        imul    ebx
        shrd    eax,edx,16
        mov     obs.up.dirz,eax

; from = (32,32,32) - to
        mov     eax,32*65536
        sub     eax,obs.to.dirx
        mov     obs.from.dirx,eax

        mov     eax,32*65536
        sub     eax,obs.to.diry
        mov     obs.from.diry,eax

        mov     eax,32*65536
        sub     eax,obs.to.dirz
        mov     obs.from.dirz,eax

; vd = 80% * up
        mov     eax,obs.up.dirx
        mov     ebx,0cccch
        imul    ebx
        shrd    eax,edx,16
        mov     obs.vd.dirx,eax
        
        mov     eax,obs.up.diry
        mov     ebx,0cccch
        imul    ebx
        shrd    eax,edx,16
        mov     obs.vd.diry,eax
        
        mov     eax,obs.up.dirz
        mov     ebx,0cccch
        imul    ebx
        shrd    eax,edx,16
        mov     obs.vd.dirz,eax

; ud =  80% * to ^ up
        mov     eax,obs.to.diry
        imul    obs.up.dirz
        shrd    eax,edx,16
        mov     ebx,eax
        mov     eax,obs.to.dirz
        imul    obs.up.diry
        shrd    eax,edx,16
        sub     ebx,eax
        mov     eax,ebx
        mov     ebx,0cccch
        imul    ebx
        shrd    eax,edx,16
        mov     obs.ud.dirx,eax

        mov     eax,obs.to.dirz
        imul    obs.up.dirx
        shrd    eax,edx,16
        mov     ebx,eax
        mov     eax,obs.to.dirx
        imul    obs.up.dirz
        shrd    eax,edx,16
        sub     ebx,eax
        mov     eax,ebx
        mov     ebx,0cccch
        imul    ebx
        shrd    eax,edx,16
        mov     obs.ud.diry,eax

        mov     eax,obs.to.dirx
        imul    obs.up.diry
        shrd    eax,edx,16
        mov     ebx,eax
        mov     eax,obs.to.diry    
        imul    obs.up.dirx
        shrd    eax,edx,16
        sub     ebx,eax
        mov     eax,ebx
        mov     ebx,0cccch
        imul    ebx
        shrd    eax,edx,16
        mov     obs.ud.dirz,eax

        popad
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Project a vertex on the projection plane defined by obs
; In: 
;   obs, ESI -> pointer to vertex
; Out: 
;   vertex projected
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

ProjectVertex:
        push    eax ebx edx

; R = Vertex - From
        mov     eax,[esi].v.dirx
        sub     eax,obs.from.dirx
        mov     R.dirx,eax

        mov     eax,[esi].v.diry
        sub     eax,obs.from.diry
        mov     R.diry,eax

        mov     eax,[esi].v.dirz
        sub     eax,obs.from.dirz
        mov     R.dirz,eax

; Vertex.p.x = <R,Ud>+50*65536+32768 (centralize on screen and round)
;       mov     eax,R.dirz
        imul    obs.ud.dirz
        shrd    eax,edx,16
        mov     ebx,eax

        mov     eax,R.diry
        imul    obs.ud.diry
        shrd    eax,edx,16
        add     ebx,eax

        mov     eax,R.dirx
        imul    obs.ud.dirx
        shrd    eax,edx,16
        add     ebx,eax

        add     ebx,50*65536+32768
        shr     ebx,16
        mov     [esi].p.x,ebx
 
; Vertex.p.y = 50*65536-32768-<R,Vd>
        mov     ebx,50*65536-32768        

        mov     eax,R.dirx
        imul    obs.vd.dirx
        shrd    eax,edx,16
        sub     ebx,eax

        mov     eax,R.diry
        imul    obs.vd.diry
        shrd    eax,edx,16
        sub     ebx,eax

        mov     eax,R.dirz
        imul    obs.vd.dirz
        shrd    eax,edx,16
        sub     ebx,eax

        shr     ebx,16
        mov     [esi].p.y,ebx

        pop     edx ebx eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Extract a Z slice from the volume
; In:
;   EAX - slice number
; Out:
;   slice
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

getZslice:
        push    esi edi ecx
        mov     esi,64*64
        imul    esi,eax
        add     esi,volume
        mov     edi,slice
        mov     ecx,64*64/4
        rep     movsd
        pop     ecx edi esi
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Extract a Y slice from the volume
; In:
;   EAX - slice number
; Out:
;   slice
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

getYslice:
        push    esi edi ecx ebx
        mov     esi,eax
        shl     esi,6
        add     esi,volume
        mov     edi,slice
        mov     ebx,64
getYslice0:
        mov     ecx,64/4
        rep     movsd
        add     esi,64*64-64
        dec     ebx
        jnz     getYslice0
        pop     ebx ecx edi esi
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Extract a X slice from the volume
; In:
;   EAX - slice number
; Out:
;   slice
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

getXslice:
        push    esi edi ecx
        mov     esi,eax
        add     esi,volume
        mov     edi,slice
        mov     ecx,64*64
getXslice0:
        movsb     
        add     esi,63
        loop    getXslice0
        pop     ecx edi esi
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Put a slice on screen
; In:
;   EBX - x coordinate
;   ECX - y coordinate
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

putslice:
        push    edi esi eax ebx ecx
        cmp     segmode,1
        jne     putslice1      
        mov     ecx,64*64
        mov     eax,Tlevel
        mov     esi,slice
putslice2:
        cmp     byte ptr [esi],al
        ja      putslice3
        mov     byte ptr [esi],0
putslice3:
        inc     esi
        loop    putslice2
putslice1:      
        pop     ecx
        push    ecx
        mov     edi,ecx
        lea     edi,[edi+edi*4]
        shl     edi,6
        add     edi,ebx
        add     edi,VGAbuffer
        mov     ebx,64
        mov     esi,slice
putslice0:
        mov     ecx,64/4
        rep     movsd
        add     edi,320-64
        dec     ebx
        jnz     putslice0
        pop     ecx ebx eax esi edi
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Put a 3D volume on screen, observed by an axis
; In:
;   EBX - x coordinate
;   ECX - y coordinate
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

putvolume:
        pushad
        mov     edi,ecx
        lea     edi,[edi+edi*4]
        shl     edi,6
        add     edi,ebx
        add     edi,VGAbuffer
        mov     esi,volume
        ; edi = address of video buffer
        ; esi = address of volume
        ; ecx = logical y 
        ; ebx = logical x
        mov     eax,Yinc
        mov     ebx,Xinc
        sal     ebx,6
        sub     eax,ebx
        mov     Xinc64,eax
        mov     eax,Fstart
        imul    Zinc
        mov     Zincface,eax
        mov     eax,64
        sub     eax,Fstart
        mov     Zend,eax
        mov     edx,64
        mov     eax,Tlevel
        add     esi,Zincface
        mov     ebp,Zinc
putvolumey:
        mov     ebx,64
putvolumex:
        mov     ecx,Zend
        push    esi
putvolumez:
        cmp     byte ptr [esi],al
        jae     putvolumezend
        add     esi,ebp
        loop    putvolumez
putvolumezero:
        mov     ah,0
        jmp     putvolumedd
putvolumezend:
        sub     ecx,Zend
        neg     ecx
        shr     cl,2
        mov     ah,byte ptr [esi]
        sub     ah,cl

; shade
        mov     savevoxel,ah
        pushad
        mov     eax,esi
        sub     esi,volume
        mov     edi,gradvol
        lea     edx,[esi*4]
        add     edi,edx
        lea     esi,[esi*8]
        add     edi,esi

        mov     eax,[edi].dirx
        imul    direction.dirx
        shrd    eax,edx,16
        mov     ebx,eax

        mov     eax,[edi].diry
        imul    direction.diry
        shrd    eax,edx,16
        add     ebx,eax

        mov     eax,[edi].dirz
        imul    direction.dirz
        shrd    eax,edx,16
        add     ebx,eax

        cmp     ebx,0
        jl      putvolumepdd

        mov     eax,ebx        
        imul    ebx   
        shrd    eax,edx,16
        mov     ebx,eax

        movzx   ecx,savevoxel
        mov     eax,ebx
        imul    ecx
        sar     eax,16
        mov     savevoxel,al
        popad   
        mov     ah,savevoxel
        cmp     ah,63
        jb      putvolumedd
        mov     ah,63
        jmp     putvolumedd

putvolumepdd:
        popad
        mov     ah,0
putvolumedd:
        add     ah,64
        mov     [edi],ah
        pop     esi
        inc     edi
        add     esi,Xinc
        dec     ebx
        jnz     putvolumex
        add     edi,320-64
        add     esi,Xinc64
        dec     edx
        jnz     putvolumey
        popad
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Draw a cube on screen
; In:
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

showcube:
        pushad
        mov     edx,100
        mov     edi,VGAbuffer
        add     edi,219
        mov     eax,0
showcube0:
        mov     ecx,100/4
        rep     stosd
        add     edi,220
        dec     edx
        jnz     showcube0
        
        ; project all vertex on screen
        
        mov     esi,offset v000
        call    ProjectVertex
        add     [esi].p.x,219
        
        mov     esi,offset v001
        call    ProjectVertex
        add     [esi].p.x,219
        
        mov     esi,offset v010
        call    ProjectVertex
        add     [esi].p.x,219
        
        mov     esi,offset v011
        call    ProjectVertex
        add     [esi].p.x,219
        
        mov     esi,offset v100
        call    ProjectVertex
        add     [esi].p.x,219
        
        mov     esi,offset v101
        call    ProjectVertex
        add     [esi].p.x,219
        
        mov     esi,offset v110
        call    ProjectVertex
        add     [esi].p.x,219
        
        mov     esi,offset v111
        call    ProjectVertex
        add     [esi].p.x,219

        ; draw a single face 00-10-11-01

onefacen1:
        cmp     obs.to.dirz,0
        jle     onefacen2
        
        mov     esi,offset v000
        mov     edi,offset v1
        mov     ecx,5*4
        rep     movsb
        mov     v1.v.zvect,0

        mov     esi,offset v100
        mov     edi,offset v2
        mov     ecx,5*4
        rep     movsb
        mov     v2.v.zvect,10*65536

        mov     esi,offset v110
        mov     edi,offset v3
        mov     ecx,5*4
        rep     movsb
        mov     v3.v.zvect,63*65536

        mov     esi,offset v010
        mov     edi,offset v4
        mov     ecx,5*4
        rep     movsb
        mov     v4.v.zvect,53*65536

        call    oneface

        ; draw a single face 00-10-11-01

onefacen2:
        cmp     obs.to.dirx,0
        jle     onefacen3

        mov     esi,offset v000
        mov     edi,offset v1
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v010
        mov     edi,offset v2
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v011
        mov     edi,offset v3
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v001
        mov     edi,offset v4
        mov     ecx,5*4
        rep     movsb

        call    oneface

        ; draw a single face 00-10-11-01

onefacen3:
        cmp     obs.to.diry,0
        jge     onefacen4

        mov     esi,offset v010
        mov     edi,offset v1
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v011
        mov     edi,offset v2
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v111
        mov     edi,offset v3
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v110
        mov     edi,offset v4
        mov     ecx,5*4
        rep     movsb

        call    oneface

        ; draw a single face 00-10-11-01

onefacen4:
        cmp     obs.to.dirz,0
        jge     onefacen5

        mov     esi,offset v001
        mov     edi,offset v1
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v011
        mov     edi,offset v2
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v111
        mov     edi,offset v3
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v101
        mov     edi,offset v4
        mov     ecx,5*4
        rep     movsb

        call    oneface

        ; draw a single face 00-10-11-01

onefacen5:
        cmp     obs.to.dirx,0
        jge     onefacen6

        mov     esi,offset v110
        mov     edi,offset v1
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v111
        mov     edi,offset v2
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v101
        mov     edi,offset v3
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v100
        mov     edi,offset v4
        mov     ecx,5*4
        rep     movsb

        call    oneface

        ; draw a single face 00-10-11-01

onefacen6:
        cmp     obs.to.diry,0
        jle     onefaceexit

        mov     esi,offset v000
        mov     edi,offset v1
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v001
        mov     edi,offset v2
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v101
        mov     edi,offset v3
        mov     ecx,5*4
        rep     movsb

        mov     esi,offset v100
        mov     edi,offset v4
        mov     ecx,5*4
        rep     movsb

        call    oneface

onefaceexit:

        popad     
        ret

showcube1:
        mov     color,ah
        mov     ebx,[esi].p.x
        mov     x1,ebx
        mov     ebx,[esi].p.y
        mov     y1,ebx
        mov     ebx,[edi].p.x
        mov     x2,ebx
        mov     ebx,[edi].p.y
        mov     y2,ebx
        jmp     Line

oneface:
        mov     ebp,offset v1
        mov     eax,v1.p.y
        cmp     eax,v2.p.y
        jg      onefacetry2
        cmp     eax,v3.p.y
        jg      onefacetry2
        cmp     eax,v4.p.y
        jg      onefacetry2
        lea     ebx,[ebp]
        mov     offvl,ebx
        lea     ebx,[ebp+2*5*4]
        mov     offvg,ebx
        mov     eax,v1.p.x
        cmp     eax,v4.p.x
        jl      oneface1l
        je      oneface1e
oneface1g:
        lea     ebx,[ebp+3*5*4]
        mov     offvml,ebx
        lea     ebx,[ebp+5*4]
        mov     offvmr,ebx
        jmp     onefacedraw

oneface1e:
        cmp     eax,v2.p.x
        jl      oneface1g      
        jmp     oneface1l

oneface1l:
        lea     ebx,[ebp+3*5*4]
        mov     offvmr,ebx
        lea     ebx,[ebp+5*4]
        mov     offvml,ebx
        jmp     onefacedraw

onefacetry2:
        mov     eax,v2.p.y
        cmp     eax,v3.p.y
        jg      onefacetry3
        cmp     eax,v4.p.y
        jg      onefacetry3
        lea     ebx,[ebp+5*4]
        mov     offvl,ebx
        lea     ebx,[ebp+3*5*4]
        mov     offvg,ebx
        mov     eax,v2.p.x
        cmp     eax,v1.p.x
        jl      oneface2l
        je      oneface2e
oneface2g:
        lea     ebx,[ebp]
        mov     offvml,ebx
        lea     ebx,[ebp+2*5*4]
        mov     offvmr,ebx
        jmp     onefacedraw

oneface2e:
        cmp     eax,v3.p.x
        jl      oneface2g
        jmp     oneface2l

oneface2l:
        lea     ebx,[ebp]
        mov     offvmr,ebx
        lea     ebx,[ebp+2*5*4]
        mov     offvml,ebx
        jmp     onefacedraw

onefacetry3:
        mov     eax,v3.p.y
        cmp     eax,v4.p.y
        jg      onefacetry4
        lea     ebx,[ebp+2*5*4]
        mov     offvl,ebx
        lea     ebx,[ebp]
        mov     offvg,ebx
        mov     eax,v3.p.x
        cmp     eax,v2.p.x
        jl      oneface3l
        je      oneface3e
oneface3g:
        lea     ebx,[ebp+5*4]
        mov     offvml,ebx
        lea     ebx,[ebp+3*5*4]
        mov     offvmr,ebx
        jmp     onefacedraw

oneface3e:
        cmp     eax,v4.p.x
        jl      oneface3g
        jmp     oneface3l

oneface3l:        
        lea     ebx,[ebp+5*4]
        mov     offvmr,ebx
        lea     ebx,[ebp+3*5*4]
        mov     offvml,ebx
        jmp     onefacedraw

onefacetry4:
        lea     ebx,[ebp+3*5*4]
        mov     offvl,ebx
        lea     ebx,[ebp+5*4]
        mov     offvg,ebx
        mov     eax,v4.p.x
        cmp     eax,v3.p.x
        jl      oneface4l
        je      oneface4e
oneface4g:
        lea     ebx,[ebp+2*5*4]
        mov     offvml,ebx
        lea     ebx,[ebp]
        mov     offvmr,ebx
        jmp     onefacedraw

oneface4e:
        cmp     eax,v1.p.x
        jl      oneface4g
        jmp     oneface4l

oneface4l:        
        lea     ebx,[ebp+2*5*4]
        mov     offvmr,ebx
        lea     ebx,[ebp]
        mov     offvml,ebx

onefacedraw:

onefacedrawlml:
        mov     ebp,offset Ltable
        mov     esi,offvl
        mov     edi,offvml
        mov     eax,[esi].p.y
        ; eax = (fixed) (start y)
        lea     ebp,[ebp+eax*8]
        ; ebp = absolute address of table
        mov     ecx,[edi].p.y
        sub     ecx,eax
        jz      onefacedrawmlg
        ; ecx = delta y
        mov     ebx,[offset invtable+ecx*4]
        mov     eax,ebx
        ; ebx = (fixed) (1 / delta y)
        mov     edx,[edi].p.x
        sub     edx,[esi].p.x
        ; at this point eax=ebx
        imul    edx
        mov     phiXinc,eax
        mov     edx,[edi].v.dirz
        sub     edx,[esi].v.dirz
        mov     eax,ebx
        imul    edx
        shrd    eax,edx,16
        mov     Zinc,eax
        ; speedups
        mov     ebx,phiXinc
        mov     edx,Zinc
        mov     edi,[esi].v.dirz
        mov     eax,[esi].p.x
        sal     eax,16
onefacedrawlmlL:
        mov     [ebp].xpos,eax
        mov     [ebp].zvect,edi
        add     edi,edx
        add     eax,ebx
        add     ebp,8
        loop    onefacedrawlmlL

onefacedrawmlg:
        mov     ebp,offset Ltable
        mov     esi,offvml
        mov     edi,offvg
        mov     eax,[esi].p.y
        ; eax = (fixed) (start y)
        lea     ebp,[ebp+eax*8]
        ; ebp = absolute address of table
        mov     ecx,[edi].p.y
        sub     ecx,eax
        jz      onefacedrawlmr
        ; ecx = delta y
        mov     eax,[offset invtable+ecx*4]
        mov     ebx,eax
        ; ebx = (fixed) (1 / delta y)
        mov     edx,[edi].p.x
        sub     edx,[esi].p.x
        ; at this point eax=ebx
        imul    edx
        mov     phiXinc,eax
        mov     edx,[edi].v.dirz
        sub     edx,[esi].v.dirz
        mov     eax,ebx
        imul    edx
        shrd    eax,edx,16
        mov     Zinc,eax
        ; speedups
        mov     ebx,phiXinc
        mov     edx,Zinc
        mov     edi,[esi].v.dirz
        mov     eax,[esi].p.x
        sal     eax,16
onefacedrawmlgL:
        mov     [ebp].xpos,eax
        mov     [ebp].zvect,edi
        add     edi,edx
        add     eax,ebx
        add     ebp,8
        loop    onefacedrawmlgL

onefacedrawlmr:
        mov     ebp,offset Rtable
        mov     esi,offvl
        mov     edi,offvmr
        mov     eax,[esi].p.y
        ; eax = (fixed) (start y)
        lea     ebp,[ebp+eax*8]
        ; ebp = absolute address of table
        mov     ecx,[edi].p.y
        sub     ecx,eax
        jz      onefacedrawmrg
        ; ecx = delta y
        mov     eax,[offset invtable+ecx*4]
        mov     ebx,eax
        ; ebx = (fixed) (1 / delta y)
        mov     edx,[edi].p.x
        sub     edx,[esi].p.x
        ; at this point eax=ebx
        imul    edx
        mov     phiXinc,eax
        mov     edx,[edi].v.dirz
        sub     edx,[esi].v.dirz
        mov     eax,ebx
        imul    edx
        shrd    eax,edx,16
        mov     Zinc,eax
        ; speedups
        mov     ebx,phiXinc
        mov     edx,Zinc
        mov     edi,[esi].v.dirz
        mov     eax,[esi].p.x
        sal     eax,16
onefacedrawlmrL:
        mov     [ebp].xpos,eax
        mov     [ebp].zvect,edi
        add     edi,edx
        add     eax,ebx
        add     ebp,8
        loop    onefacedrawlmrL

onefacedrawmrg:
        mov     ebp,offset Rtable
        mov     esi,offvmr
        mov     edi,offvg
        mov     eax,[esi].p.y
        ; eax = (fixed) (start y)
        lea     ebp,[ebp+eax*8]
        ; ebp = absolute address of table
        mov     ecx,[edi].p.y
        sub     ecx,eax
        jz      onefaceflush
        ; ecx = delta y
        mov     eax,[offset invtable+ecx*4]
        mov     ebx,eax
        ; ebx = (fixed) (1 / delta y)
        mov     edx,[edi].p.x
        sub     edx,[esi].p.x
        ; at this point eax=ebx
        imul    edx
        mov     phiXinc,eax
        mov     edx,[edi].v.dirz
        sub     edx,[esi].v.dirz
        mov     eax,ebx
        imul    edx
        shrd    eax,edx,16
        mov     Zinc,eax
        ; speedups
        mov     ebx,phiXinc
        mov     edx,Zinc
        mov     edi,[esi].v.dirz
        mov     eax,[esi].p.x
        sal     eax,16
onefacedrawmrgL:
        mov     [ebp].xpos,eax
        mov     [ebp].zvect,edi
        add     edi,edx
        add     eax,ebx
        add     ebp,8
        loop    onefacedrawmrgL

onefaceflush:
        mov     edi,offvg
        mov     esi,offvl
        mov     ebp,[edi].p.y
        sub     ebp,[esi].p.y
        jz      _ret
        mov     ebx,[esi].p.y
        mov     esi,offset Ltable
        lea     esi,[esi+ebx*8]
        mov     edi,offset Rtable
        lea     edi,[edi+ebx*8]
        push    ebx ebp
        shr     ebp,1
        add     ebx,ebp
        movzx   ecx,word ptr [offset Rtable+ebx*8+2]
        movzx   eax,word ptr [offset Ltable+ebx*8+2]
        sub     ecx,eax
        mov     edx,[offset Rtable+ebx*8].zvect
        sub     edx,[offset Ltable+ebx*8].zvect
        mov     eax,[offset invtable+ecx*4]
        imul    edx
        shrd    eax,edx,16
        mov     intstepZ,eax
        pop     ebp ebx
        add     ebp,ebx
        mov     endX,ebp
        mov     ebp,intstepZ
onefaceflush0:
        movzx   ecx,word ptr [esi+offset Rtable-offset Ltable+2]
        movzx   eax,word ptr [esi+2]
        sub     ecx,eax
        jz      onefaceflush1
        mov     edx,[offset m320table+ebx*4]
        add     edx,eax
        mov     edi,[esi].zvect
        shrd    eax,edi,24
onefaceflushloop:
        add     edi,ebp
        shrd    eax,edi,24
        mov     byte ptr [edx],al
        inc     edx
        loop    onefaceflushloop
onefaceflush1:
        inc     ebx
        add     esi,8
        cmp     endX,ebx
        jne     onefaceflush0

        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Set of routines to display data on screen
; In:
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

showX:
        push    ecx ebx eax
        mov     ebx,0
        mov     ecx,0
        mov     eax,Xslice
        call    getXslice
        call    putslice
        pop     eax ebx ecx
        ret

showY:
        push    ecx ebx eax
        mov     ebx,73
        mov     ecx,0
        mov     eax,Yslice
        call    getYslice
        call    putslice
        pop     eax ebx ecx
        ret

showZ:
        push    ecx ebx eax
        mov     ebx,146
        mov     ecx,0
        mov     eax,Zslice
        call    getZslice
        call    putslice
        pop     eax ebx ecx
        ret

showbars:
        mov     ecx,64
showbarsloop:        
        mov     edi,VGAbuffer
        add     edi,70*320
        add     edi,ecx
        cmp     ecx,Xslice
        jb      showbars0      
        mov     byte ptr [edi],0
        jmp     showbars1
showbars0:
        mov     byte ptr [edi],63
showbars1:
        add     edi,73
        cmp     ecx,Yslice
        jb      showbars2
        mov     byte ptr [edi],0
        jmp     showbars3
showbars2:
        mov     byte ptr [edi],63
showbars3:
        add     edi,73
        cmp     ecx,Zslice
        jb      showbars4
        mov     byte ptr [edi],0
        jmp     showbars5
showbars4:
        mov     byte ptr [edi],63
showbars5:
        add     edi,174+21*320
        cmp     ecx,Tlevel
        jb      showbars6
        mov     byte ptr [edi],0
        jmp     showbars7
showbars6:
        mov     byte ptr [edi],63
showbars7:
        add     edi,73
        cmp     ecx,Fstart
        jb      showbars8
        mov     byte ptr [edi],0
        loop    showbarsloop
        ret
showbars8:
        mov     byte ptr [edi],63
        loop    showbarsloop
        ret

redraw:
        call    showbars
        call    showX
        call    showY
        jmp     showZ

show3Dx:
        mov     Xinc,64
        mov     Yinc,64*64
        mov     Zinc,1
        mov     ecx,100   
        mov     ebx,0
        mov     direction.dirx,65536
        neg     direction.dirx
        mov     direction.diry,0
        mov     direction.dirz,0
        call    putvolume
        ret

show3Dy:
        mov     Xinc,1
        mov     Yinc,64*64
        mov     Zinc,64
        mov     ecx,100     
        mov     ebx,73
        mov     direction.dirx,0
        mov     direction.diry,65536
        neg     direction.diry
        mov     direction.dirz,0
        call    putvolume
        ret

show3Dz:
        mov     Xinc,1
        mov     Yinc,64
        mov     Zinc,64*64
        mov     ecx,100     
        mov     ebx,146
        mov     direction.dirx,0
        mov     direction.diry,0
        mov     direction.dirz,65536
        neg     direction.dirz
        call    putvolume
        ret

redraw3D:
        call    showcube
        call    show3Dx
        call    show3Dy
        jmp     show3Dz

redrawall:
        call    redraw
        jmp     redraw3D

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

nomem:
        mov     edx,offset msg1
        call    _putdosstr
        jmp     _exit

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

fileerror:
        mov     edx,offset msg2
        call    _putdosstr
        jmp     _exit

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

nolowmem:
        mov     edx,offset msg3
        call    _putdosstr
        jmp     _exit

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

fixlowx:
        mov     ebx,esi
        jmp     gradlowx

fixlowy:
        mov     ebx,esi
        jmp     gradlowy

fixlowz:
        mov     ebx,esi
        jmp     gradlowz

fixhix:
        mov     ebx,esi
        jmp     gradhix

fixhiy:
        mov     ebx,esi
        jmp     gradhiy

fixhiz:
        mov     ebx,esi
        jmp     gradhiz

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

_main:

        call    _init_kb

        mov     edx,offset msg4
        call    _putdosstr

; Initialize
        @rlp    eax,0A0000h
        mov     VGAbuffer,eax
        cld

; Alloc memory for the volume        
        mov     eax,64*64*64
        call    _gethimem
        jc      nomem
        mov     volume,eax

; Alloc memory for the gradient volume
        mov     eax,64*64*64*12
        call    _gethimem
        jc      nomem
        mov     gradvol,eax

; Alloc memory for a slice
        mov     eax,64*64
        call    _getlomem
        jc      nolowmem
        mov     slice,eax

; Alloc memory for sin table        
        mov     eax,01000h*4
        call    _getlomem
        jc      nolowmem
        mov     sintable,eax

        mov     edx,offset msg5
        call    _putdosstr

; Open the file containing the volume
        mov     edx,offset file1
        call    _openfile
        jc      fileerror
        mov     bx,v86r_bx
        mov     filehandle,bx

        mov     ebx,64
        mov     edi,volume

; Read each slice from the disk
readfile:
        mov     esi,slice
        mov     ecx,64*64
        mov     edx,esi
        call    _readfile
        jc      fileerror
        rep     movsb
        dec     ebx
        jnz     readfile
        call    _closefile

; Read sin table from disk
        mov     edx,offset msg10
        call    _putdosstr

        mov     edx,offset file2
        call    _openfile
        jc      fileerror
        mov     bx,v86r_bx
        mov     filehandle,bx

        mov     edx,sintable
        mov     ecx,01000h*4
        call    _readfile
        call    _closefile

; Update the 320x table

        mov     edx,offset m320table
        mov     ecx,200
        mov     eax,VGAbuffer
update320:
        add     [edx],eax
        add     edx,4
        loop    update320

; Generate the gradient volume        
        mov     edx,offset msg6
        call    _putdosstr
        mov     esi,volume
        mov     edi,gradvol
        mov     ecx,64*64*64
        mov     eax,volume
        add     eax,ecx
        mov     volumemax,eax

; forward gradient
gradloop:
        mov     ebx,esi
        dec     ebx
        cmp     ebx,volume
        jb      fixlowx
gradlowx:
        movzx   eax,byte ptr [ebx]
        mov     ebx,esi
        inc     ebx
        cmp     ebx,volumemax
        ja      fixhix
gradhix:
        movzx   edx,byte ptr [ebx]
        sub     eax,edx
        sal     eax,16
        mov     [edi].dirx,eax

        mov     ebx,esi
        sub     ebx,64
        cmp     ebx,volume
        jb      fixlowy
gradlowy:
        movzx   eax,byte ptr [ebx]
        mov     ebx,esi
        add     ebx,64
        cmp     ebx,volumemax
        ja      fixhiy
gradhiy:
        movzx   edx,byte ptr [ebx]
        sub     eax,edx
        sal     eax,16
        mov     [edi].diry,eax

        mov     ebx,esi
        sub     ebx,64*64
        cmp     ebx,volume
        jb      fixlowz
gradlowz:
        movzx   eax,byte ptr [ebx]
        mov     ebx,esi
        add     ebx,64*64
        cmp     ebx,volumemax
        ja      fixhiz
gradhiz:
        movzx   edx,byte ptr [ebx]
        sub     eax,edx
        sal     eax,16
        mov     [edi].dirz,eax

; Calculate the norm
        mov     eax,[edi].dirx
        imul    [edi].dirx
        shrd    eax,edx,16
        mov     ebx,eax

        mov     eax,[edi].diry
        imul    [edi].diry
        shrd    eax,edx,16
        add     ebx,eax

        mov     eax,[edi].dirz
        imul    [edi].dirz
        shrd    eax,edx,16
        add     ebx,eax

        mov     eax,ebx
        call    isqrt
        mov     ebx,eax
        sal     ebx,8

        cmp     ebx,0
        jne     divide      
        mov     ebx,65536

; normalize the gradient
divide:
        mov     eax,[edi].dirx
        cdq
        shld    edx,eax,16
        idiv    ebx
        mov     [edi].dirx,eax

        mov     eax,[edi].diry
        cdq
        shld    edx,eax,16
        idiv    ebx
        mov     [edi].diry,eax

        mov     eax,[edi].dirz
        cdq
        shld    edx,eax,16
        idiv    ebx
        mov     [edi].dirz,eax

        add     edi,12
        inc     esi
        loop    gradloop
        
        mov     edx,offset msg8
        call    _putdosstr
        call    _himemsize
        call    _putdecimal
        @NewLine
        mov     edx,offset msg9
        call    _putdosstr
        call    _lomemsize
        call    _putdecimal
        @NewLine
        @NewLine

;        mov     eax,0
;loopinho:
;        call    _getch
;        cmp     al,32
;        je      cont
;        call    _putdecimal
;        @NewLine
;        jmp     loopinho
;cont:
        
        mov     edx,offset msg7
        call    _putdosstr
        call    _getch

        call    InitGraph

; Sets the palette
        mov     ecx,64

setpalette:
        mov     al,cl
        mov     ah,cl
        mov     bh,cl
        mov     bl,cl
        call    SetRGB
        loop    setpalette

        mov     al,64
        mov     bl,0
        mov     bh,0
        mov     ah,0
setpalette0:
        call    SetRGB
        inc     al
        add     bl,2
        cmp     bl,64
        jb      setpalette1
        mov     bl,63
setpalette1:
        inc     bh
        cmp     bh,64
        jb      setpalette0

; Prepare the vertices of sample cube
        mov     esi,offset v000
        mov     [esi].v.dirx,0
        mov     [esi].v.diry,0
        mov     [esi].v.dirz,0
        
        mov     esi,offset v001
        mov     [esi].v.dirx,0
        mov     [esi].v.diry,0
        mov     [esi].v.dirz,V
        
        mov     esi,offset v010
        mov     [esi].v.dirx,0
        mov     [esi].v.diry,V
        mov     [esi].v.dirz,0
        
        mov     esi,offset v011
        mov     [esi].v.dirx,0
        mov     [esi].v.diry,V
        mov     [esi].v.dirz,V
        
        mov     esi,offset v100
        mov     [esi].v.dirx,V
        mov     [esi].v.diry,0
        mov     [esi].v.dirz,0
        
        mov     esi,offset v101
        mov     [esi].v.dirx,V
        mov     [esi].v.diry,0
        mov     [esi].v.dirz,V
        
        mov     esi,offset v110
        mov     [esi].v.dirx,V
        mov     [esi].v.diry,V
        mov     [esi].v.dirz,0
        
        mov     esi,offset v111
        mov     [esi].v.dirx,V
        mov     [esi].v.diry,V
        mov     [esi].v.dirz,V
        
        call    SetViewer
        
        call    redrawall

mainloop:
        call    _getch
        mov     edx,offset keytable
        call    _indexbyte
        jc      mainloop
        jmp     [functable+eax*4]

mainend:
        call    CloseGraph
        call    _reset_kb
        jmp     _exit

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

keyplus:
        mov     edi,offset Xslice
        mov     esi,mode
        inc     dword ptr [edi+esi*4]
        and     dword ptr [edi+esi*4],63
        call    redraw
        jmp     mainloop

keyminus:
        mov     edi,offset Xslice
        mov     esi,mode
        dec     dword ptr [edi+esi*4]
        and     dword ptr [edi+esi*4],63
        call    redraw
        jmp     mainloop

setXmode:
        mov     mode,xmode
        jmp     mainloop

setYmode:
        mov     mode,ymode
        jmp     mainloop

setZmode:
        mov     mode,zmode
        jmp     mainloop

setsegmode:
        xor     segmode,1
        call    redraw
        jmp     mainloop

setTmode:
        mov     mode,tmode
        jmp     mainloop

redrawkey:
        call    redraw3D
        jmp     mainloop

setFmode:
        mov     mode,fmode
        jmp     mainloop

upkey:
        add     phi,64
        and     phi,0fffh
        call    SetViewer
        call    showcube
        jmp     mainloop

downkey:
        sub     phi,64
        and     phi,0fffh
        call    SetViewer
        call    showcube
        jmp     mainloop

rightkey:
        add     theta,64
        and     theta,0fffh
        call    SetViewer
        call    showcube
        jmp     mainloop

leftkey:
        sub     theta,64
        and     theta,0fffh
        call    SetViewer
        call    showcube
        jmp     mainloop

lampkey:
        mov     edx,800h
lampkey0:

        ;X
        mov     Xinc,64
        mov     Yinc,64*64
        mov     Zinc,1
        mov     ecx,100     
        mov     ebx,0
        mov     direction.diry,0
        mov     eax,sintable
        mov     esi,[eax+edx*4]
        mov     direction.dirz,esi
        lea     ebp,[400h+edx]
        and     ebp,0fffh
        mov     esi,[eax+ebp*4]
        mov     direction.dirx,esi
        call    putvolume
        
        ;Y
        mov     Xinc,1
        mov     Yinc,64*64
        mov     Zinc,64
        mov     ecx,100     
        mov     ebx,73
        mov     direction.dirx,0
        mov     eax,sintable
        mov     esi,[eax+edx*4]
        mov     direction.dirz,esi
        lea     ebp,[400h+edx]
        and     ebp,0fffh
        mov     esi,[eax+ebp*4]
        mov     direction.diry,esi
        call    putvolume
        
        ;Z
        mov     Xinc,1
        mov     Yinc,64
        mov     Zinc,64*64
        mov     ecx,100     
        mov     ebx,146
        mov     direction.dirx,0
        mov     eax,sintable
        mov     esi,[eax+edx*4]
        mov     direction.diry,esi
        lea     ebp,[400h+edx]
        and     ebp,0fffh
        mov     esi,[eax+ebp*4]
        mov     direction.dirz,esi
        call    putvolume
        
        add     edx,80h
        and     edx,0fffh
        cmp     edx,800h
        jne     lampkey0
        jmp     mainloop


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

