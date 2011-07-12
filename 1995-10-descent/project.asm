        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc
include globals.inc
include pdosstr.inc

public SetViewer,ProjectVertex,ProjectWall,ProjectAllWalls

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

R               vector <>
K               vector <>

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; CODE
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
;-----------------------------------------------------------------------------
;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ

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
        add     eax,4000h
        and     eax,0FFFFh
        mov     edi,[edx+eax*4]
        mov     eax,theta
        mov     ebx,[edx+eax*4]
        add     eax,4000h
        and     eax,0FFFFh
        mov     esi,[edx+eax*4]

; to = (cos phi*cos theta,sin phi,cos phi*sin theta)
        mov     eax,edi
        imul    esi
        shrd    eax,edx,16
        mov     obs.to.dirx,eax

        mov     obs.to.diry,ecx

        mov     eax,edi
        imul    ebx
        shrd    eax,edx,16
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

; vd = 200 * up
        imul    eax,obs.up.dirx,200     
        mov     obs.vd.dirx,eax
        imul    eax,obs.up.diry,200     
        mov     obs.vd.diry,eax
        imul    eax,obs.up.dirz,200     
        mov     obs.vd.dirz,eax

; ud =  320 * to ^ up
        mov     eax,obs.to.diry
        imul    obs.up.dirz
        shrd    eax,edx,16
        mov     ebx,eax
        mov     eax,obs.to.dirz
        imul    obs.up.diry
        shrd    eax,edx,16
        sub     ebx,eax
        imul    ebx,dword ptr 320
        mov     obs.ud.dirx,ebx

        mov     eax,obs.to.dirz
        imul    obs.up.dirx
        shrd    eax,edx,16
        mov     ebx,eax
        mov     eax,obs.to.dirx
        imul    obs.up.dirz
        shrd    eax,edx,16
        sub     ebx,eax
        imul    ebx,dword ptr 320
        mov     obs.ud.diry,ebx

        mov     eax,obs.to.dirx
        imul    obs.up.diry
        shrd    eax,edx,16
        mov     ebx,eax
        mov     eax,obs.to.diry    
        imul    obs.up.dirx
        shrd    eax,edx,16
        sub     ebx,eax
        imul    ebx,dword ptr 320
        mov     obs.ud.dirz,ebx

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

; Set frame flag on vertex
        mov     eax,actualframe
        mov     [esi].frame,eax

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

; ebx = <R,To>
;       mov     eax,R.dirz
        imul    obs.to.dirz
        shrd    eax,edx,16
        mov     ebx,eax

        mov     eax,R.diry
        imul    obs.to.diry
        shrd    eax,edx,16
        add     ebx,eax

        mov     eax,R.dirx
        imul    obs.to.dirx
        shrd    eax,edx,16
        add     ebx,eax

; if (ebx<0) then Vertex is behind the observer
        cmp     ebx,epsilon
        jg      ProjectVertex0

; Set t=-1 to indicate failure
        mov     [esi].t,-1
        pop     edx ebx eax
        ret

ProjectVertex0:
; Vertex.t = 1/<R,To>
        mov     edx,1
        mov     eax,0
        idiv    ebx
        mov     [esi].t,eax
        mov     ebx,eax

; K = R*t - To
        mov     eax,R.dirx
        imul    ebx
        shrd    eax,edx,16
        sub     eax,obs.to.dirx
        mov     K.dirx,eax

        mov     eax,R.diry
        imul    ebx
        shrd    eax,edx,16
        sub     eax,obs.to.diry
        mov     K.diry,eax

        mov     eax,R.dirz
        imul    ebx
        shrd    eax,edx,16
        sub     eax,obs.to.dirz
        mov     K.dirz,eax

; Vertex.p.x = <K,Ud>+160*65536+32768 (centralize on screen and round)
;       mov     eax,K.dirz
        imul    obs.ud.dirz
        shrd    eax,edx,16
        mov     ebx,eax

        mov     eax,K.diry
        imul    obs.ud.diry
        shrd    eax,edx,16
        add     ebx,eax

        mov     eax,K.dirx
        imul    obs.ud.dirx
        shrd    eax,edx,16
        add     ebx,eax

        add     ebx,160*65536+32768
        shr     ebx,16
        mov     [esi].p.x,ebx

; Vertex.p.y = 100*65536-32768-<K,Vd>
        mov     ebx,100*65536-32768        

        mov     eax,K.dirx
        imul    obs.vd.dirx
        shrd    eax,edx,16
        sub     ebx,eax

        mov     eax,K.diry
        imul    obs.vd.diry
        shrd    eax,edx,16
        sub     ebx,eax

        mov     eax,K.dirz
        imul    obs.vd.dirz
        shrd    eax,edx,16
        sub     ebx,eax

        shr     ebx,16
        mov     [esi].p.y,ebx

        pop     edx ebx eax
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Project a wall on the projection plane
; In: 
;   obs, EDX -> pointer to wall
; Out: 
;   wall (v1,v2,v3,v4)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

ProjectWall:
        push    esi eax
        mov     esi,[edx].v1
        mov     eax,actualframe
        cmp     [esi].frame,eax
        je      ProjectWall0
        call    ProjectVertex
ProjectWall0:
        mov     esi,[edx].v2
        cmp     [esi].frame,eax
        je      ProjectWall1
        call    ProjectVertex
ProjectWall1:
        mov     esi,[edx].v3
        cmp     [esi].frame,eax
        je      ProjectWall2
        call    ProjectVertex
ProjectWall2:
        mov     esi,[edx].v4
        cmp     [esi].frame,eax
        je      ProjectWall3
        call    ProjectVertex
ProjectWall3:
        pop     eax esi
        ret

;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°
; Project all walls on the projection plane
; In: 
;   obs, EDX -> pointer to wall
; Out: 
;   wall (v1,v2,v3,v4)
;°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°

ProjectAllWalls:
        push    edx ecx
        mov     edx,wallroot
        mov     ecx,wallmax

; For each wall project it on the video buffer
ProjectAllWalls0:
        call    ProjectWall
        add     edx,wallsize
        loop    ProjectAllWalls0
        pop     ecx edx
        ret

;ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
code32  ends
        end

