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
        mov     esi,[ebx].p.y
        mov     edi,[ebx].p.x

        mov     edx,[eax].p.x
        sub     edx,edi
        mov     Evect.dirx,edx

        mov     edx,[eax].p.x
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

