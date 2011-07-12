        .386p
        jumps
code32  segment para public use32
        assume cs:code32, ds:code32, ss:code32

include start32.inc

public texture,VGAbuffer,obs,actualframe,vertexroot,wallroot
public vertexmax,wallmax,phi,theta,sintable,videobuffer,polygon
public miny,maxy

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; TYPES
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

vector struc
        
        dirx    dd 0     
        diry    dd 0
        dirz    dd 0

vector ends

pixel struc

        x       dd 0
        y       dd 0

pixel ends

observer struc

        from    vector <0,0,0>
        to      vector <0,0,10000h>
        up      vector <0,10000h,0>
        ud      vector <>
        vd      vector <>

observer ends      

vertex struc

        v       vector <>
        p       pixel <>
        t       dd ?
        frame   dd 0

vertex ends

wall struc  

        v1      dd ?
        v2      dd ?
        v3      dd ?
        v4      dd ?

wall ends

minmax struc

        min     dd ?
        max     dd ?

minmax ends

;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
; DATA
;±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±

align 4
texture         dd      ?
VGAbuffer       dd      ?
obs             observer <>
actualframe     dd      1
vertexroot      dd      ?
wallroot        dd      ?   
vertexmax       dd      ?
wallmax         dd      ?    
phi             dd      0
theta           dd      4000h
sintable        dd      ?
videobuffer     dd      ?
polygon         minmax  200 dup (?)
miny            dd      ?
maxy            dd      ?

code32  ends
        end

