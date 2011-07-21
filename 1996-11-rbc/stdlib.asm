; Standard library for RBCC

_hello:
        push    bp
        push    ds
        mov     ax,seg HELLO
        mov     ds,ax
        mov     dx,offset HELLO
        mov     ah,9
        int     21h
        pop     ds
        pop     bp
        ret

_putchar:
        push    bp
        mov     bp,sp
        mov     dl,[bp+4]
        mov     ah,2
        int     21h
        pop     bp
        ret

_getchar:
        push    bp
        mov     ah,0
        int     16h
        mov     ah,0
        pop     bp
        ret

HELLO:  db "Hello, World!",13,10,"$"

