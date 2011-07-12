@NewLine macro
        push    edx
        mov     edx,offset newline
        call    _putdosstr
        pop     edx
endm      

@WhiteSpace macro
        push    edx
        mov     edx,offset whitespace
        call    _putdosstr
        pop     edx
endm

@PrintVector macro desc
        push    eax
        mov     eax,&desc.dirx
        call    _putdecimal
        @WhiteSpace
        mov     eax,&desc.diry
        call    _putdecimal
        @WhiteSpace
        mov     eax,&desc.dirz
        call    _putdecimal
        @NewLine
        pop     eax
endm

@PrintPixel macro desc
        push    eax
        mov     eax,&desc.x
        call    _putdecimal
        @WhiteSpace
        mov     eax,&desc.y
        call    _putdecimal
        @NewLine
        pop     eax
endm

extrn _putdosstr:near,_putdecimal:near
extrn newline:dword,whitespace:dword
