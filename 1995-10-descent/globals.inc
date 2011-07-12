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

vertexsize      equ     28
wallsize        equ     16
epsilon         equ     80000

extrn texture:dword,VGAbuffer:dword,obs:observer,actualframe:dword
extrn wallroot:dword,vertexroot:dword,wallmax:dword,vertexmax:dword  
extrn phi:dword,theta:dword,sintable:dword,videobuffer:dword
extrn polygon:minmax,miny:dword,maxy:dword
