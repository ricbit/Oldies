; print opcodes  routines ---------------------------------------------
; first number is size of instruction
; second number is number of strings
; third number is size of argument

PRINTOP100      macro number,desc

msg&number:     db      desc
prin&number:    mov     isize,1
                mov     eax,offset msg&number
                call    printmsgp
                ret

                endm

PRINTOP200      macro number,desc

msg&number:     db      desc
prin&number:    mov     isize,2
                mov     eax,offset msg&number
                call    printmsgp
                ret

                endm

PRINTOP211      macro   number,desc        

msg&number:     db      desc
prin&number:    mov     isize,2
                mov     eax,offset msg&number
                call    printmsgp
                inc     edi
                call    fetch
                call    printhex2p
                ret

                endm
                                  
PRINTOP221      macro   number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,2
                mov     eax,offset msg&number&a
                call    printmsgp
                inc     edi
                call    fetch
                call    printhex2p
                mov     eax,offset msg&number&b
                call    printmsgp
                ret

                endm

PRINTOP312      macro number,desc

msg&number:     db      desc
prin&number:    mov     isize,3
                mov     eax,offset msg&number
                call    printmsgp
                inc     edi
                call    fetchw
                call    printhex4p
                ret

                endm

PRINTOP322      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,3
                mov     eax,offset msg&number&a
                call    printmsgp
                inc     edi
                call    fetchw
                call    printhex4p
                mov     eax,offset msg&number&b
                call    printmsgp
                ret

                endm

PRINTOP321      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,3
                mov     eax,offset msg&number&a
                call    printmsgp
                add     edi,2
                call    fetch
                call    printhex2p
                mov     eax,offset msg&number&b
                call    printmsgp
                ret

                endm

PRINTOP422      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,4
                mov     eax,offset msg&number&a
                call    printmsgp
                add     edi,2
                call    fetchw
                call    printhex4p
                mov     eax,offset msg&number&b
                call    printmsgp
                ret

                endm

PRINTOP421      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,4
                mov     eax,offset msg&number&a
                call    printmsgp
                add     edi,2
                call    fetch
                call    printhex2p
                mov     eax,offset msg&number&b
                call    printmsgp
                inc     edi
                call    fetch
                call    printhex2p
                ret

                endm

PRINTOP42X      macro number,desc1,desc2

msg&number&a:   db      desc1
msg&number&b:   db      desc2
prin&number:    mov     isize,4
                mov     eax,offset msg&number&a
                call    printmsgp
                add     edi,2
                call    fetch
                call    printhex2p
                mov     eax,offset msg&number&b
                call    printmsgp
                ret

                endm

PRINTOP412      macro number,desc

msg&number:     db      desc
prin&number:    mov     isize,4
                mov     eax,offset msg&number
                call    printmsgp
                add     edi,2
                call    fetchw
                call    printhex4p
                ret

                endm

