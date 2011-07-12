        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc
include kb32.inc
include sintable.inc
include divtable.inc
include texture.inc
include indxbyte.rt

public  _main

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

epsilon         equ     80000

vector  struc

        dirx    dd      0
        diry    dd      0
        dirz    dd      0

vector  ends

pixel   struc

        x       dd      0
        y       dd      0

pixel   ends

observ  struc

        from    vector  <>
        to      vector  <>
        up      vector  <>
        ud      vector  <>
        vd      vector  <>

observ  ends

vertex  struc

        v       vector  <>
        p       pixel   <>
        i       dd      0
        t       dd      0

vertex  ends

interp  struc

        x       dd      ?
        xp      dd      ?
        yp      dd      ?

interp  ends

interpsize      equ     12

; globals
phi             dd      ?
theta           dd      ?
resx            dd      200
resy            dd      200
halfx           dd      ?
halfy           dd      ?
VGAbuffer       dd      ?
obs             observ  <>
vbtable         dd      200 dup (?)
keytable        db 5,14,25,26,23,24
functable       dd esckey,upkey,downkey,leftkey,rightkey

v1              vertex  <>
v2              vertex  <>
v3              vertex  <>
v4              vertex  <>
v5              vertex  <>
v6              vertex  <>
v7              vertex  <>
v8              vertex  <>

;locals

;ProjectVertex 
R               vector  <>
V               vector  <>

;Line
x1              dd      0
y1              dd      0
x2              dd      0
y2              dd      0
color           db      0

;QuadDraw and TriDraw
videobuffer     dd      0
vert1           dd      ?
vert2           dd      ?
vert3           dd      ?
vert4           dd      ?
vl              dd      ?
vm              dd      ?
vmr             dd      ?
vml             dd      ?
vg              dd      ?
method          dd      ?
Xstep           dd      ?
Istep           dd      ?
Istart          dd      ?
fakevertex      vertex  <>
Evect           vector  <>
Mvect           vector  <>
Ltable          interp  200 dup (?)
Rtable          interp  200 dup (?)

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
; Clear the screen
; In:
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

ClearGraph:
        mov     ecx,64000/4
        mov     edi,VGAbuffer
        mov     eax,0
        rep     stosd
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
; Draws a Line using Bresenham to the video buffer
; In:
;   x1,y1,x2,y2,color - coordinates in fixed point
; Out:
;   None
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

LineFE:
        shr     x1,16
        shr     y1,16
        shr     x2,16
        shr     y2,16
        jmp     Line

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Adjust the observer vectors
; In:
;   phi,theta
; Out:
;   obs
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

SetViewer:
        ; sets ebx=-cos theta ebp=-sin theta
        ;      esi=cos phi   edi=sin phi
        mov     ebx,theta
        mov     ebp,ebx
        mov     ebx,[offset costable+ebx*4]
        neg     ebx
        mov     ebp,[offset sintable+ebp*4]
        neg     ebp

        mov     esi,phi
        mov     edi,esi
        mov     esi,[offset costable+esi*4]
        mov     edi,[offset sintable+edi*4]

        ; sets up=(-cos theta.cos phi,-sin theta.cos phi, sin phi)
        mov     eax,ebx
        imul    esi
        shrd    eax,edx,16
        mov     obs.up.dirx,eax

        mov     eax,ebp
        imul    esi
        shrd    eax,edx,16
        mov     obs.up.diry,eax

        mov     obs.up.dirz,edi

        ;sets to=(-cos theta.sin phi,-sin theta.sin phi,-cos phi)
        mov     eax,ebx
        imul    edi
        shrd    eax,edx,16
        mov     obs.to.dirx,eax

        mov     eax,ebp
        imul    edi
        shrd    eax,edx,16
        mov     obs.to.diry,eax

        neg     esi
        mov     obs.to.dirz,esi

        ;sets from=(32,32,32)-256*to
        mov     eax,32*65536
        mov     ebx,obs.to.dirx
        sal     ebx,8
        sub     eax,ebx
        mov     obs.from.dirx,eax
        
        mov     eax,32*65536
        mov     ebx,obs.to.diry
        sal     ebx,8
        sub     eax,ebx
        mov     obs.from.diry,eax
        
        mov     eax,32*65536
        mov     ebx,obs.to.dirz
        sal     ebx,8
        sub     eax,ebx
        mov     obs.from.dirz,eax
        
        ;sets vd=resy*up
        mov     eax,obs.up.dirx
        imul    resy
        mov     obs.vd.dirx,eax

        mov     eax,obs.up.diry
        imul    resy
        mov     obs.vd.diry,eax

        mov     eax,obs.up.dirz
        imul    resy
        mov     obs.vd.dirz,eax

        ;sets ud=resx*(to^up)
        mov     eax,obs.to.diry
        imul    obs.up.dirz
        shrd    eax,edx,16
        mov     ebx,eax
        mov     eax,obs.to.dirz
        imul    obs.up.diry
        shrd    eax,edx,16
        sub     ebx,eax
        imul    ebx,resx
        mov     obs.ud.dirx,ebx

        mov     eax,obs.to.dirz
        imul    obs.up.dirx
        shrd    eax,edx,16
        mov     ebx,eax
        mov     eax,obs.to.dirx
        imul    obs.up.dirz
        shrd    eax,edx,16
        sub     ebx,eax
        imul    ebx,resx
        mov     obs.ud.diry,ebx

        mov     eax,obs.to.dirx
        imul    obs.up.diry
        shrd    eax,edx,16
        mov     ebx,eax
        mov     eax,obs.to.diry
        imul    obs.up.dirx
        shrd    eax,edx,16
        sub     ebx,eax
        imul    ebx,resx
        mov     obs.ud.dirz,ebx

        mov     eax,resx
        inc     eax
        shl     eax,15
        mov     halfx,eax

        mov     eax,resy
        dec     eax
        shl     eax,15
        mov     halfy,eax
        
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Project a vertex
; In:
;   edi - offset of vertex
; Out:
;   projected vertex (fixed coordinates)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

ProjectVertex:

        ; R=(Vertex-From)
        mov     eax,[edi].v.dirx
        sub     eax,obs.from.dirx
        mov     R.dirx,eax

        mov     eax,[edi].v.diry
        sub     eax,obs.from.diry
        mov     R.diry,eax

        mov     eax,[edi].v.dirz
        sub     eax,obs.from.dirz
        mov     R.dirz,eax

        ; t=<To,B>
        mov     eax,obs.to.dirx
        imul    R.dirx
        shrd    eax,edx,16
        mov     ebx,eax

        mov     eax,obs.to.diry
        imul    R.diry
        shrd    eax,edx,16
        add     ebx,eax

        mov     eax,obs.to.dirz
        imul    R.dirz
        shrd    eax,edx,16
        add     ebx,eax

        ; compare with epsilon
        cmp     ebx,epsilon
        jg      ProjectVertex0

        mov     [edi].t,-1
        ret

ProjectVertex0:
        ; t=1/<To,R>
        mov     edx,1
        mov     eax,0
        idiv    ebx
        mov     [edi].t,eax
        mov     ecx,eax

        ; V=t.R-To
        mov     eax,R.dirx
        imul    ecx
        shrd    eax,edx,16
        sub     eax,obs.to.dirx
        mov     V.dirx,eax

        mov     eax,R.diry
        imul    ecx
        shrd    eax,edx,16
        sub     eax,obs.to.diry
        mov     V.diry,eax

        mov     eax,R.dirz
        imul    ecx
        shrd    eax,edx,16
        sub     eax,obs.to.dirz
        mov     V.dirz,eax

        ; p.x=<V,Ud>+halfx
        mov     eax,V.dirx
        imul    obs.ud.dirx
        shrd    eax,edx,16
        mov     ebx,eax

        mov     eax,V.diry
        imul    obs.ud.diry
        shrd    eax,edx,16
        add     ebx,eax

        mov     eax,V.dirz
        imul    obs.ud.dirz
        shrd    eax,edx,16
        add     ebx,eax

        add     ebx,halfx
        mov     [edi].p.x,ebx

        ;p.y=halfy-<V,Vd>
        mov     ebx,halfy

        mov     eax,V.dirx
        imul    obs.vd.dirx
        shrd    eax,edx,16
        sub     ebx,eax

        mov     eax,V.diry
        imul    obs.vd.diry
        shrd    eax,edx,16
        sub     ebx,eax

        mov     eax,V.dirz
        imul    obs.vd.dirz
        shrd    eax,edx,16
        sub     ebx,eax

        mov     [edi].p.y,ebx

        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Show a vertex on screen
; In:
;   edi - offset of vertex
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

BlitVertex:
        mov     eax,[edi].p.y
        lea     eax,[eax+eax*4]
        shl     eax,6
        add     eax,[edi].p.x
        add     eax,VGAbuffer
        mov     byte ptr [eax],15
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Draw a quadrilateral on videobuffer
; In:
;   videobuffer,vert1..vert4 - clockwise or anticlockwise
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

QuadDraw:
        mov     eax,vert1
        mov     ebx,vert2
        mov     ecx,vert3
        mov     edx,vert4
        mov     esi,[eax].p.y
        cmp     esi,[ebx].p.y
        jg      QuadDraw2
        cmp     esi,[ecx].p.y
        jg      QuadDraw2
        cmp     esi,[edx].p.y
        jg      QuadDraw2
        cmp     esi,[edx].p.y
        je      QuadDrawAD
        cmp     esi,[ebx].p.y
        je      QuadDrawAB
        mov     vl,eax
        mov     vg,ecx
        mov     edi,[eax].p.x
        cmp     edi,[ebx].p.x
        jl      QuadDraw1l
        je      QuadDraw1e

QuadDraw1g:
        mov     vmr,edx
        mov     vml,ebx
        jmp     QuadDrawRaster

QuadDraw1l:
        mov     vmr,ebx
        mov     vml,edx
        jmp     QuadDrawRaster

QuadDraw1e:
        cmp     edi,[edx].p.x
        jl      QuadDraw1g
        jmp     QuadDraw1l

QuadDrawAB:
        mov     edi,[eax].p.x
        cmp     edi,[ebx].p.x
        jl      QuadDrawABL

QuadDrawABG:
        mov     vl,eax
        mov     vmr,edx
        mov     vml,ebx
        mov     vg,ecx
        jmp     QuadDrawRaster

QuadDrawABL:
        mov     vl,eax
        mov     vmr,ebx
        mov     vml,edx     
        mov     vg,ecx
        jmp     QuadDrawRaster

QuadDrawAD:
        mov     edi,[eax].p.x
        cmp     edi,[edx].p.x
        jl      QuadDrawADL

QuadDrawADG:    
        mov     vl,eax
        mov     vml,edx
        mov     vmr,ebx
        mov     vg,ecx
        jmp     QuadDrawRaster

QuadDrawADL:
        mov     vl,eax
        mov     vmr,edx
        mov     vml,ebx
        mov     vg,ecx
        jmp     QuadDrawRaster

QuadDraw2:
        mov     esi,[ebx].p.y
        cmp     esi,[ecx].p.y
        jg      QuadDraw3
        cmp     esi,[edx].p.y
        jg      QuadDraw3
        cmp     esi,[eax].p.y
        je      QuadDrawBA
        cmp     esi,[ecx].p.y
        je      QuadDrawBC
        mov     vl,ebx
        mov     vg,edx
        mov     edi,[ebx].p.x
        cmp     edi,[ecx].p.x
        jl      QuadDraw2l
        je      QuadDraw2e

QuadDraw2g:
        mov     vmr,eax
        mov     vml,ecx
        jmp     QuadDrawRaster

QuadDraw2l:
        mov     vmr,ecx
        mov     vml,eax
        jmp     QuadDrawRaster

QuadDraw2e:
        cmp     edi,[eax].p.x
        jl      QuadDraw2g
        jmp     QuadDraw2l

QuadDrawBA:
        mov     edi,[ebx].p.x
        cmp     edi,[eax].p.x
        jl      QuadDrawBAL

QuadDrawBAG:
        mov     vl,ebx
        mov     vml,eax
        mov     vmr,ecx
        mov     vg,edx
        jmp     QuadDrawRaster

QuadDrawBAL:
        mov     vl,ebx
        mov     vmr,eax
        mov     vml,ecx
        mov     vg,edx
        jmp     QuadDrawRaster

QuadDrawBC:
        mov     edi,[ebx].p.x
        cmp     edi,[ecx].p.x
        jl      QuadDrawBCL

QuadDrawBCG:
        mov     vl,ebx
        mov     vml,ecx
        mov     vmr,eax
        mov     vg,edx
        jmp     QuadDrawRaster

QuadDrawBCL:
        mov     vl,ebx
        mov     vmr,ecx
        mov     vml,eax
        mov     vg,edx
        jmp     QuadDrawRaster

QuadDraw3:
        mov     esi,[ecx].p.y
        cmp     esi,[edx].p.y
        jg      QuadDraw4
        cmp     esi,[ebx].p.y
        je      QuadDrawCB
        cmp     esi,[edx].p.y
        je      QuadDrawCD
        mov     vl,ecx
        mov     vg,eax
        mov     edi,[ecx].p.x
        cmp     edi,[edx].p.x
        jl      QuadDraw3l
        je      QuadDraw3e

QuadDraw3g:
        mov     vmr,ebx
        mov     vml,edx
        jmp     QuadDrawRaster

QuadDraw3l:
        mov     vmr,edx
        mov     vml,ebx
        jmp     QuadDrawRaster

QuadDraw3e:
        cmp     edi,[ebx].p.x
        jl      QuadDraw3g
        jmp     QuadDraw3l

QuadDrawCB:
        mov     edi,[ecx].p.x
        cmp     edi,[ecx].p.x
        jl      QuadDrawCBL

QuadDrawCBG:
        mov     vl,ecx
        mov     vml,ebx
        mov     vmr,edx
        mov     vg,eax
        jmp     QuadDrawRaster

QuadDrawCBL:
        mov     vl,ecx
        mov     vmr,ebx
        mov     vml,edx
        mov     vg,eax
        jmp     QuadDrawRaster

QuadDrawCD:
        mov     edi,[ecx].p.x
        cmp     edi,[edx].p.x
        jl      QuadDrawCDL

QuadDrawCDG:
        mov     vl,ecx
        mov     vml,edx
        mov     vmr,ebx
        mov     vg,eax
        jmp     QuadDrawRaster

QuadDrawCDL:
        mov     vl,ecx
        mov     vmr,edx
        mov     vml,ebx
        mov     vg,eax
        jmp     QuadDrawRaster

QuadDraw4:
        mov     esi,[edx].p.y
        cmp     esi,[ecx].p.y
        je      QuadDrawDC
        cmp     esi,[eax].p.y
        je      QuadDrawDA
        mov     vl,edx
        mov     vg,ebx
        mov     edi,[edx].p.x
        cmp     edi,[eax].p.x
        jl      QuadDraw4l
        je      QuadDraw4e

QuadDraw4g:
        mov     vmr,ecx
        mov     vml,eax
        jmp     QuadDrawRaster

QuadDraw4l:
        mov     vmr,eax
        mov     vml,ecx
        jmp     QuadDrawRaster

QuadDraw4e:
        cmp     edi,[ecx].p.x
        jl      QuadDraw4g
        jmp     QuadDraw4l

QuadDrawDA:
        mov     edi,[edx].p.x
        cmp     edi,[eax].p.x
        jl      QuadDrawDAL

QuadDrawDAG:
        mov     vl,edx
        mov     vml,eax
        mov     vmr,ecx
        mov     vg,ebx
        jmp     QuadDrawRaster

QuadDrawDAL:
        mov     vl,edx
        mov     vmr,eax
        mov     vml,ecx
        mov     vg,ebx
        jmp     QuadDrawRaster

QuadDrawDC:
        mov     edi,[edx].p.x
        cmp     edi,[ecx].p.x
        jl      QuadDrawDCL

QuadDrawDCG:
        mov     vl,edx
        mov     vml,ecx
        mov     vmr,eax
        mov     vg,ebx
        jmp     QuadDrawRaster

QuadDrawDCL:
        mov     vl,edx
        mov     vml,ecx
        mov     vmr,eax
        mov     vg,ebx
        jmp     QuadDrawRaster

QuadDrawRaster:
        mov     eax,vl
        mov     ebx,vml
        mov     ecx,vg
        mov     edx,vmr
        
        mov     x1,0
        mov     x2,319
        mov     esi,[eax].p.y
        mov     y1,esi
        mov     y2,esi
        mov     color,1
        call    Line

        mov     esi,[ecx].p.y
        mov     y1,esi
        mov     y2,esi
        mov     color,2
        call    Line

        mov     y1,0
        mov     y2,199
        mov     edi,[ebx].p.x
        mov     x1,edi
        mov     x2,edi
        mov     color,3
        call    Line

        mov     edi,[edx].p.x
        mov     x1,edi
        mov     x2,edi
        mov     color,4
        call    Line

        ret;;

QuadDrawRastervlvml:
        ; draw from vl to vml
        mov     esi,vl
        mov     edi,vml
        mov     ebp,[esi].p.y
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Ltable+ebp*4] ;interpsize
        mov     ecx,[edi].p.y
        sub     ecx,[esi].p.y
        jz      QuadDrawRastervmlvg
        mov     eax,[offset divtable+ecx*4]
        mov     ebx,[edi].p.x
        sub     ebx,[esi].p.x
        imul    ebx
        mov     edx,[esi].p.x
        shl     edx,16
QuadDrawRastervlvmlL:
        mov     [ebp].x,edx
        add     edx,eax
        add     ebp,interpsize
        loop    QuadDrawRastervlvmlL

        ; draw from vml to vg
QuadDrawRastervmlvg:
        mov     esi,vml
        mov     edi,vg
        mov     ebp,[esi].p.y
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Ltable+ebp*4] ;interpsize
        mov     ecx,[edi].p.y
        sub     ecx,[esi].p.y
        jz      QuadDrawRastervlvmr
        mov     eax,[offset divtable+ecx*4]
        mov     ebx,[edi].p.x
        sub     ebx,[esi].p.x
        imul    ebx
        mov     edx,[esi].p.x
        shl     edx,16
QuadDrawRastervmlvgL:
        mov     [ebp].x,edx
        add     edx,eax
        add     ebp,interpsize
        loop    QuadDrawRastervmlvgL

        ; draw from vl to vmr
QuadDrawRastervlvmr:
        mov     esi,vl
        mov     edi,vmr
        mov     ebp,[esi].p.y
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Rtable+ebp*4] ;interpsize
        mov     ecx,[edi].p.y
        sub     ecx,[esi].p.y
        jz      QuadDrawRastervmrvg
        mov     eax,[offset divtable+ecx*4]
        mov     ebx,[edi].p.x
        sub     ebx,[esi].p.x
        imul    ebx
        mov     edx,[esi].p.x
        shl     edx,16
QuadDrawRastervlvmrL:
        mov     [ebp].x,edx
        add     edx,eax
        add     ebp,interpsize
        loop    QuadDrawRastervlvmrL

        ; draw from vmr to vg
QuadDrawRastervmrvg:
        mov     esi,vmr
        mov     edi,vg
        mov     ebp,[esi].p.y
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Rtable+ebp*4] ;interpsize
        mov     ecx,[edi].p.y
        sub     ecx,[esi].p.y
        jz      QuadDrawFlush
        mov     eax,[offset divtable+ecx*4]
        mov     ebx,[edi].p.x
        sub     ebx,[esi].p.x
        imul    ebx
        mov     edx,[esi].p.x
        shl     edx,16
QuadDrawRastervmrvgL:
        mov     [ebp].x,edx
        add     edx,eax
        add     ebp,interpsize
        loop    QuadDrawRastervmrvgL

QuadDrawFlush:
        mov     esi,vl
        mov     edi,vg
        mov     edx,[edi].p.y
        sub     edx,[esi].p.y
        jz      _ret
        mov     ebp,[esi].p.y
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Ltable+ebp*4] ;interpsize
        mov     ebx,[esi].p.y
QuadDrawFlushloop:
        movzx   eax,word ptr [ebp+2]
        movzx   ecx,word ptr [ebp+2+offset Rtable-offset Ltable]
        sub     ecx,eax
        cmp     ecx,2
        jb      QuadDrawFlush0
        mov     edi,[offset vbtable+ebx*4]
        add     edi,eax
        mov     al,15
        rep     stosb
QuadDrawFlush0:
        add     ebp,interpsize
        inc     ebx
        dec     edx
        jnz     QuadDrawFlushloop

        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Draw a triangle to video buffer
; In:
;   vert1,vert2,vert2
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

DebugLines:
        pushad
        mov     x1,0
        mov     x2,199
        mov     y1,0
        mov     y2,0
        mov     eax,esi
        mov     color,al
        call    Line
        mov     y1,1
        mov     y2,2
        mov     eax,edi
        mov     color,al
        call    Line
        popad   
        ret

TriDraw:
        mov     eax,vert1
        mov     ebx,vert2
        mov     ecx,vert3
        mov     esi,[eax].p.y
        cmp     esi,[ebx].p.y
        jg      TriDrawB
        cmp     esi,[ecx].p.y
        jg      TriDrawB
        mov     esi,[ebx].p.y
        cmp     esi,[ecx].p.y
        jl      TriDrawAC

TriDrawAB:
        mov     vl,eax
        mov     vg,ebx
        mov     vm,ecx
        mov     esi,1
        mov     edi,2
        call    DebugLines
        mov     esi,[eax].p.y
        mov     edi,[eax].p.x

        mov     edx,[ebx].p.x
        sub     edx,edi
        mov     Evect.dirx,edx

        mov     edx,[ebx].p.y
        sub     edx,esi
        mov     Evect.diry,edx

        mov     edx,[ecx].p.x
        sub     edx,edi
        mov     Mvect.dirx,edx

        mov     edx,[ecx].p.y
        sub     edx,esi
        mov     Mvect.diry,edx

        jmp     TriDrawSelectPipe

TriDrawAC:
        mov     vl,eax
        mov     vg,ecx
        mov     vm,ebx
        mov     esi,1
        mov     edi,3
        call    DebugLines
        mov     esi,[eax].p.y
        mov     edi,[eax].p.x

        mov     edx,[ecx].p.x
        sub     edx,edi
        mov     Evect.dirx,edx

        mov     edx,[ecx].p.y
        sub     edx,esi
        mov     Evect.diry,edx

        mov     edx,[ebx].p.x
        sub     edx,edi
        mov     Mvect.dirx,edx

        mov     edx,[ebx].p.y
        sub     edx,esi
        mov     Mvect.diry,edx

        jmp     TriDrawSelectPipe

TriDrawB:
        mov     esi,[ebx].p.y
        cmp     esi,[ecx].p.y
        jg      TriDrawC
        mov     esi,[eax].p.y
        cmp     esi,[ecx].p.y
        jl      TriDrawBC

TriDrawBA:
        mov     vl,ebx
        mov     vg,eax
        mov     vm,ecx
        mov     esi,2
        mov     edi,1
        call    DebugLines
        mov     esi,[ebx].p.y
        mov     edi,[ebx].p.x

        mov     edx,[eax].p.x
        sub     edx,edi
        mov     Evect.dirx,edx

        mov     edx,[eax].p.y
        sub     edx,esi
        mov     Evect.diry,edx

        mov     edx,[ecx].p.x
        sub     edx,edi
        mov     Mvect.dirx,edx

        mov     edx,[ecx].p.y
        sub     edx,esi
        mov     Mvect.diry,edx

        jmp     TriDrawSelectPipe

TriDrawBC:
        mov     vl,ebx
        mov     vg,ecx
        mov     vm,eax
        mov     esi,2
        mov     edi,3
        call    DebugLines
        mov     esi,[ebx].p.y
        mov     edi,[ebx].p.x

        mov     edx,[ecx].p.x
        sub     edx,edi
        mov     Evect.dirx,edx

        mov     edx,[ecx].p.y
        sub     edx,esi
        mov     Evect.diry,edx

        mov     edx,[eax].p.x
        sub     edx,edi
        mov     Mvect.dirx,edx

        mov     edx,[eax].p.y
        sub     edx,esi
        mov     Mvect.diry,edx

        jmp     TriDrawSelectPipe

TriDrawC:
        mov     esi,[eax].p.y
        cmp     esi,[ebx].p.y
        jl      TriDrawCB

TriDrawCA:
        mov     vl,ecx
        mov     vg,eax
        mov     vm,ebx
        mov     esi,3
        mov     edi,1
        call    DebugLines
        mov     esi,[ecx].p.y
        mov     edi,[ecx].p.x

        mov     edx,[eax].p.x
        sub     edx,edi
        mov     Evect.dirx,edx

        mov     edx,[eax].p.y
        sub     edx,esi
        mov     Evect.diry,edx

        mov     edx,[ebx].p.x
        sub     edx,edi
        mov     Mvect.dirx,edx

        mov     edx,[ebx].p.y
        sub     edx,esi
        mov     Mvect.diry,edx

        jmp     TriDrawSelectPipe

TriDrawCB:
        mov     vl,ecx
        mov     vg,ebx
        mov     vm,eax
        mov     esi,3
        mov     edi,2
        call    DebugLines
        mov     esi,[ecx].p.y
        mov     edi,[ecx].p.x

        mov     edx,[ebx].p.x
        sub     edx,edi
        mov     Evect.dirx,edx

        mov     edx,[ebx].p.y
        sub     edx,esi
        mov     Evect.diry,edx

        mov     edx,[eax].p.x
        sub     edx,edi
        mov     Mvect.dirx,edx

        mov     edx,[eax].p.y
        sub     edx,esi
        mov     Mvect.diry,edx

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TriDrawSelectPipe:
        mov     eax,Evect.dirx
        imul    Mvect.diry
        shrd    eax,edx,16
        mov     ebp,eax

        mov     eax,Evect.diry
        imul    Mvect.dirx
        shrd    eax,edx,16
        sub     ebp,eax

        js      TriDrawPipeR
        jmp     TriDrawPipeL

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TriDrawPipeR:

TriDrawPipeR1:        
        ; draw from vl to vm (R)
        mov     esi,vl
        mov     edi,vm
        mov     ebp,[esi].p.y
        shr     ebp,16
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Rtable+ebp*4] ;interpsize
        mov     ecx,[edi].p.y
        sub     ecx,[esi].p.y
        cmp     ecx,65536
        jl      TriDrawPipeR2
        shr     ecx,16
        mov     edx,[offset divtable+ecx*4]
        add     ecx,2
        mov     eax,[edi].p.x
        sub     eax,[esi].p.x
        imul    edx
        shrd    eax,edx,16
        mov     Xstep,eax
        mov     edx,[offset divtable+ecx*4]
        mov     eax,[edi].i
        sub     eax,[esi].i
        imul    edx
        shrd    eax,edx,16
        mov     edx,[esi].p.x
        mov     esi,[esi].i
        mov     edi,Xstep
        ; eax = step i esi = start i
        ; edi = step x edx = start x
TriDrawPipeR1Loop:
        mov     [ebp].x,edx
        mov     [ebp].xp,esi
        add     edx,edi
        add     esi,eax
        add     ebp,interpsize
        loop    TriDrawPipeR1Loop

TriDrawPipeR2:     
        ; draw from vm to vg (R)
        mov     esi,vm
        mov     edi,vg
        mov     ebp,[esi].p.y
        shr     ebp,16
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Rtable+ebp*4] ;interpsize
        mov     ecx,[edi].p.y
        sub     ecx,[esi].p.y
        cmp     ecx,65536
        jl      TriDrawPipeR3
        shr     ecx,16
        mov     edx,[offset divtable+ecx*4]
        add     ecx,2
        mov     eax,[edi].p.x
        sub     eax,[esi].p.x
        imul    edx
        shrd    eax,edx,16
        mov     Xstep,eax
        mov     edx,[offset divtable+ecx*4]
        mov     eax,[edi].i
        sub     eax,[esi].i
        imul    edx
        shrd    eax,edx,16
        mov     edx,[esi].p.x
        mov     esi,[esi].i
        mov     edi,Xstep
        ; eax = step i esi = start i
        ; edi = step x edx = start x
TriDrawPipeR2Loop:
        mov     [ebp].x,edx
        mov     [ebp].xp,esi
        add     edx,edi
        add     esi,eax
        add     ebp,interpsize
        loop    TriDrawPipeR2Loop

TriDrawPipeR3:    
        ; draw from vl to vg (L)
        mov     esi,vl
        mov     edi,vg
        mov     ebp,[esi].p.y
        shr     ebp,16
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Ltable+ebp*4] ;interpsize
        mov     ecx,[edi].p.y
        sub     ecx,[esi].p.y
        cmp     ecx,65536
        jl      TriDrawFlush
        shr     ecx,16
        mov     edx,[offset divtable+ecx*4]
        add     ecx,2
        mov     eax,[edi].p.x
        sub     eax,[esi].p.x
        imul    edx
        shrd    eax,edx,16
        mov     Xstep,eax
        mov     edx,[offset divtable+ecx*4]
        mov     eax,[edi].i
        sub     eax,[esi].i
        imul    edx
        shrd    eax,edx,16
        mov     edx,[esi].p.x
        mov     esi,[esi].i
        mov     edi,Xstep
        ; eax = step i esi = start i
        ; edi = step x edx = start x
TriDrawPipeR3Loop:
        mov     [ebp].x,edx
        mov     [ebp].xp,esi
        add     edx,edi
        add     esi,eax
        add     ebp,interpsize
        loop    TriDrawPipeR3Loop
        jmp     TriDrawFlush

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TriDrawPipeL:

TriDrawPipeL1:        
        ; draw from vl to vm (L)
        mov     esi,vl
        mov     edi,vm
        mov     ebp,[esi].p.y
        shr     ebp,16
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Ltable+ebp*4] ;interpsize
        mov     ecx,[edi].p.y
        sub     ecx,[esi].p.y
        cmp     ecx,65536
        jl      TriDrawPipeL2
        shr     ecx,16
        mov     edx,[offset divtable+ecx*4]
        add     ecx,2
        mov     eax,[edi].p.x
        sub     eax,[esi].p.x
        imul    edx
        shrd    eax,edx,16
        mov     Xstep,eax
        mov     edx,[offset divtable+ecx*4]
        mov     eax,[edi].i
        sub     eax,[esi].i
        imul    edx
        shrd    eax,edx,16
        mov     edx,[esi].p.x
        mov     esi,[esi].i
        mov     edi,Xstep
        ; eax = step i esi = start i
        ; edi = step x edx = start x
TriDrawPipeL1Loop:
        mov     [ebp].x,edx
        mov     [ebp].xp,esi
        add     edx,edi
        add     esi,eax
        add     ebp,interpsize
        loop    TriDrawPipeL1Loop

TriDrawPipeL2:  
        ; draw from vm to vg (L)
        mov     esi,vm
        mov     edi,vg
        mov     ebp,[esi].p.y
        shr     ebp,16
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Ltable+ebp*4] ;interpsize
        mov     ecx,[edi].p.y
        sub     ecx,[esi].p.y
        cmp     ecx,65536
        jl      TriDrawPipeL3
        shr     ecx,16
        mov     edx,[offset divtable+ecx*4]
        add     ecx,2
        mov     eax,[edi].p.x
        sub     eax,[esi].p.x
        imul    edx
        shrd    eax,edx,16
        mov     Xstep,eax
        mov     edx,[offset divtable+ecx*4]
        mov     eax,[edi].i
        sub     eax,[esi].i
        imul    edx
        shrd    eax,edx,16
        mov     edx,[esi].p.x
        mov     esi,[esi].i
        mov     edi,Xstep
        ; eax = step i esi = start i
        ; edi = step x edx = start x
TriDrawPipeL2Loop:
        mov     [ebp].x,edx
        mov     [ebp].xp,esi
        add     edx,edi
        add     esi,eax
        add     ebp,interpsize
        loop    TriDrawPipeL2Loop

TriDrawPipeL3:  
        ; draw from vl to vg (R)
        mov     esi,vl
        mov     edi,vg
        mov     ebp,[esi].p.y
        shr     ebp,16
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Rtable+ebp*4] ;interpsize
        mov     ecx,[edi].p.y
        sub     ecx,[esi].p.y
        cmp     ecx,65536
        jl      TriDrawFlush
        shr     ecx,16
        mov     edx,[offset divtable+ecx*4]
        add     ecx,2
        mov     eax,[edi].p.x
        sub     eax,[esi].p.x
        imul    edx
        shrd    eax,edx,16
        mov     Xstep,eax
        mov     edx,[offset divtable+ecx*4]
        mov     eax,[edi].i
        sub     eax,[esi].i
        imul    edx
        shrd    eax,edx,16
        mov     edx,[esi].p.x
        mov     esi,[esi].i
        mov     edi,Xstep
        ; eax = step i esi = start i
        ; edi = step x edx = start x
TriDrawPipeL3Loop:
        mov     [ebp].x,edx
        mov     [ebp].xp,esi
        add     edx,edi
        add     esi,eax
        add     ebp,interpsize
        loop    TriDrawPipeL3Loop

TriDrawFlush:
        jmp     [method]

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
FlatFlush:        
        mov     esi,vl
        mov     edi,vg
        mov     edx,[edi].p.y
        sub     edx,[esi].p.y
        cmp     edx,65536
        jl      _ret
        shr     edx,16
        mov     ebp,[esi].p.y
        shr     ebp,16
        mov     ebx,ebp
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Ltable+ebp*4] ;interpsize
        mov     al,15
FlatFlushLoop:
        movzx   esi,word ptr [ebp+2]
        movzx   ecx,word ptr [ebp+2+offset Rtable-offset Ltable]
        sub     ecx,esi
        cmp     ecx,0
        jl      FlatFlush0
        mov     edi,[offset vbtable+ebx*4]
        add     edi,esi
        rep     stosb
FlatFlush0:
        add     ebp,interpsize
        inc     ebx
        dec     edx
        jnz     FlatFlushLoop
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GouraudFlush:        
        mov     esi,vl
        mov     edi,vg
        ; interp setup
        mov     ebp,vm
        mov     ebp,[ebp].p.y
        shr     ebp,16
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Rtable+ebp*4] ; interpsize
        movzx   ebx,word ptr [ebp+2]
        movzx   ecx,word ptr [ebp+offset Ltable-offset Rtable+2]
        sub     ebx,ecx
        mov     ebx,[offset divtable+ebx*4]
        ; ebx = 1/delta x
        mov     eax,[ebp+4]
        mov     ecx,[ebp+offset Ltable-offset Rtable+4]
        sub     eax,ecx
        ; eax = delta i
        imul    ebx
        shrd    eax,edx,16
        ; eax = delta i / delta x
        mov     Istep,eax
        ; trace setup 
        mov     edx,[edi].p.y
        sub     edx,[esi].p.y
        cmp     edx,65536
        jl      _ret
        shr     edx,16
        mov     ebp,[esi].p.y
        shr     ebp,16
        mov     ebx,ebp
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Ltable+ebp*4] ;interpsize
GouraudFlushLoop:
        movzx   esi,word ptr [ebp+2]
        movzx   ecx,word ptr [ebp+2+offset Rtable-offset Ltable]
        sub     ecx,esi
        cmp     ecx,0
        jle     GouraudFlush0
        mov     edi,[offset vbtable+ebx*4]
        add     edi,esi
        mov     eax,[ebp].xp
        mov     Istart,eax
GouraudFlushInnerLoop:
        mov     eax,Istart
        shr     eax,16
        mov     byte ptr [edi],al
        mov     eax,Istep
        add     Istart,eax
        inc     edi
        loop    GouraudFlushInnerLoop
GouraudFlush0:
        add     ebp,interpsize
        inc     ebx
        dec     edx
        jnz     GouraudFlushLoop
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TextureFlush:        
        mov     esi,vl
        mov     edi,vg
        ; interp setup
        mov     ebp,vm
        mov     ebp,[ebp].p.y
        shr     ebp,16
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Rtable+ebp*4] ; interpsize
        movzx   ebx,word ptr [ebp+2]
        movzx   ecx,word ptr [ebp+offset Ltable-offset Rtable+2]
        sub     ebx,ecx
        mov     ebx,[offset divtable+ebx*4]
        ; ebx = 1/delta x
        mov     eax,[ebp+4]
        mov     ecx,[ebp+offset Ltable-offset Rtable+4]
        sub     eax,ecx
        ; eax = delta i
        cdq
        shld    edx,eax,16
        sal     eax,16
        idiv    ebx
;        imul    ebx
;        shrd    eax,edx,16
        ; eax = delta i / delta x
        mov     Istep,eax
        ; trace setup 
        mov     edx,[edi].p.y
        sub     edx,[esi].p.y
        cmp     edx,65536
        jl      _ret
        shr     edx,16
        mov     ebp,[esi].p.y
        shr     ebp,16
        mov     ebx,ebp
        lea     ebp,[ebp+ebp*2]
        lea     ebp,[offset Ltable+ebp*4] ;interpsize
TextureFlushLoop:
        movzx   esi,word ptr [ebp+2]
        movzx   ecx,word ptr [ebp+2+offset Rtable-offset Ltable]
        sub     ecx,esi
        cmp     ecx,0
        jle     TextureFlush0
        mov     edi,[offset vbtable+ebx*4]
        add     edi,esi
        mov     eax,[ebp].xp
        mov     Istart,eax
TextureFlushInnerLoop:
        mov     eax,Istart
        shr     eax,16
        lea     eax,[offset texture+eax]
        mov     al,[eax]
        mov     byte ptr [edi],al
        mov     eax,Istep
        add     Istart,eax
        inc     edi
        loop    TextureFlushInnerLoop
TextureFlush0:
        add     ebp,interpsize
        inc     ebx
        dec     edx
        jnz     TextureFlushLoop
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Shows a cube on screen
; In:
; Out:
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

showcube:
        call    ClearGraph        

        mov     edi,offset v1
        call    ProjectVertex
        mov     edi,offset v2
        call    ProjectVertex
        mov     edi,offset v3
        call    ProjectVertex
        mov     edi,offset v4
        call    ProjectVertex
        mov     edi,offset v5
        call    ProjectVertex
        mov     edi,offset v6
        call    ProjectVertex
        mov     edi,offset v7
        call    ProjectVertex
        mov     edi,offset v8
        call    ProjectVertex

        mov     color,14

        mov     eax,v1.p.x
        mov     x1,eax
        mov     eax,v1.p.y
        mov     y1,eax
        mov     eax,v2.p.x
        mov     x2,eax
        mov     eax,v2.p.y
        mov     y2,eax
;        call    LineFE
        
        mov     eax,v2.p.x
        mov     x1,eax
        mov     eax,v2.p.y
        mov     y1,eax
        mov     eax,v3.p.x
        mov     x2,eax
        mov     eax,v3.p.y
        mov     y2,eax
;        call    LineFE
        
        mov     eax,v3.p.x
        mov     x1,eax
        mov     eax,v3.p.y
        mov     y1,eax
        mov     eax,v4.p.x
        mov     x2,eax
        mov     eax,v4.p.y
        mov     y2,eax
        call    LineFE
        
        mov     eax,v4.p.x
        mov     x1,eax
        mov     eax,v4.p.y
        mov     y1,eax
        mov     eax,v1.p.x
        mov     x2,eax
        mov     eax,v1.p.y
        mov     y2,eax
        call    LineFE
        
        mov     eax,v1.p.x
        mov     x1,eax
        mov     eax,v1.p.y
        mov     y1,eax
        mov     eax,v5.p.x
        mov     x2,eax
        mov     eax,v5.p.y
        mov     y2,eax
        call    LineFE
        
        mov     eax,v2.p.x
        mov     x1,eax
        mov     eax,v2.p.y
        mov     y1,eax
        mov     eax,v6.p.x
        mov     x2,eax
        mov     eax,v6.p.y
        mov     y2,eax
        call    LineFE
        
        mov     eax,v3.p.x
        mov     x1,eax
        mov     eax,v3.p.y
        mov     y1,eax
        mov     eax,v7.p.x
        mov     x2,eax
        mov     eax,v7.p.y
        mov     y2,eax
        call    LineFE
        
        mov     eax,v4.p.x
        mov     x1,eax
        mov     eax,v4.p.y
        mov     y1,eax
        mov     eax,v8.p.x
        mov     x2,eax
        mov     eax,v8.p.y
        mov     y2,eax
        call    LineFE
        
        mov     eax,v5.p.x
        mov     x1,eax
        mov     eax,v5.p.y
        mov     y1,eax
        mov     eax,v6.p.x
        mov     x2,eax
        mov     eax,v6.p.y
        mov     y2,eax
        call    LineFE
        
        mov     eax,v6.p.x
        mov     x1,eax
        mov     eax,v6.p.y
        mov     y1,eax
        mov     eax,v7.p.x
        mov     x2,eax
        mov     eax,v7.p.y
        mov     y2,eax
        call    LineFE
        
        mov     eax,v7.p.x
        mov     x1,eax
        mov     eax,v7.p.y
        mov     y1,eax
        mov     eax,v8.p.x
        mov     x2,eax
        mov     eax,v8.p.y
        mov     y2,eax
        call    LineFE
        
        mov     eax,v8.p.x
        mov     x1,eax
        mov     eax,v8.p.y
        mov     y1,eax
        mov     eax,v5.p.x
        mov     x2,eax
        mov     eax,v5.p.y
        mov     y2,eax
        call    LineFE
        
        mov     eax,v3.p.x
        mov     x1,eax
        mov     eax,v3.p.y
        mov     y1,eax
        mov     eax,v1.p.x
        mov     x2,eax
        mov     eax,v1.p.y
        mov     y2,eax
;        call    LineFE
        
        mov     eax,v1.v.dirx
        mov     v1.i,eax
        mov     eax,offset v1
        mov     vert1,eax
        
        mov     eax,v2.v.dirx
        mov     v2.i,eax
        mov     eax,offset v2
        mov     vert2,eax
        
        mov     eax,v3.v.dirx
        mov     v3.i,eax
        mov     eax,offset v3
        mov     vert3,eax
        
        mov     method,offset GouraudFlush
        call    TriDraw

;        
        mov     eax,v3.v.dirx
        mov     v3.i,eax
        mov     eax,offset v3
        mov     vert1,eax
        
        mov     eax,v4.v.dirx
        mov     v4.i,eax
        mov     eax,offset v4
        mov     vert2,eax
        
        mov     eax,v1.v.dirx
        mov     v1.i,eax
        mov     eax,offset v1
        mov     vert3,eax
        
        mov     method,offset GouraudFlush
        call    TriDraw

        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
InitPalette:
        mov     ecx,64
        mov     al,0
InitPalette0:
        mov     bl,al
        mov     bh,al
        mov     ah,al
        call    SetRGB
        inc     al
        loop    InitPalette0
        ret

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;-----------------------------------------------------------------------------
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

v63     equ     63*65536

_main:
        call    _init_kb
        call    InitGraph
        @rlp    eax,0A0000h
        mov     VGAbuffer,eax
 
        call    InitPalette
        
        ; init the videobuffer table
        mov     ecx,200
        mov     eax,VGAbuffer
        mov     ebp,offset vbtable
init0:
        mov     [ebp],eax
        add     ebp,4
        add     eax,320
        loop    init0
        
        mov     v1.v.dirx,0
        mov     v1.v.diry,0
        mov     v1.v.dirz,0
        
        mov     v2.v.dirx,0
        mov     v2.v.diry,v63
        mov     v2.v.dirz,0
        
        mov     v3.v.dirx,v63
        mov     v3.v.diry,v63
        mov     v3.v.dirz,0
        
        mov     v4.v.dirx,v63
        mov     v4.v.diry,0
        mov     v4.v.dirz,0
        
        mov     v5.v.dirx,0
        mov     v5.v.diry,0
        mov     v5.v.dirz,v63
        
        mov     v6.v.dirx,0
        mov     v6.v.diry,v63
        mov     v6.v.dirz,v63
        
        mov     v7.v.dirx,v63
        mov     v7.v.diry,v63
        mov     v7.v.dirz,v63
        
        mov     v8.v.dirx,v63
        mov     v8.v.diry,0
        mov     v8.v.dirz,v63
        
        mov     phi,0
        mov     theta,0
        call    SetViewer
        call    showcube
main0:        
        call    _getch
        mov     edx,offset keytable
        call    _indexbyte
        jc      main0
        jmp     [functable+eax*4]

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
esckey:
        call    CloseGraph
        call    _reset_kb
        jmp     _exit

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
upkey:
        inc     phi
        and     phi,63
        call    SetViewer
        call    showcube
        jmp     main0

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
downkey:
        dec     phi
        and     phi,63
        call    SetViewer
        call    showcube
        jmp     main0

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
leftkey:
        dec     theta
        and     theta,63
        call    SetViewer
        call    showcube
        jmp     main0

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
rightkey:
        inc     theta
        and     theta,63
        call    SetViewer
        call    showcube
        jmp     main0

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

