; print opcodes  routines ---------------------------------------------
; first number is size of instruction
; second number is number of strings
; third number is size of argument

PRINTOP100      macro number,desc

prin&number:    
                db      1
msg&number:     db      desc

                endm

PRINTOP200      macro number,desc

prin&number:    
                db      2
msg&number:     db      desc

                endm

PRINTOP211      macro   number,desc        

prin&number:    
                db      3
msg&number:     db      desc

                endm
                                  
PRINTOP2JR      macro   number,desc        

prin&number:    
                db      4
                xor     eax,eax
                inc     eax
                inc     eax
                mov     isize,eax
                mov     eax,offset msg&number
                jmp     _printop2jr
msg&number:     db      desc

                endm
                                  
PRINTOP221      macro   number,desc1,desc2

prin&number:    
                db      5
msg&number&a:   db      desc1
msg&number&b:   db      desc2

                endm

PRINTOP312      macro number,desc

prin&number:    
                db      6
                mov     isize,3
                mov     eax,offset msg&number
                jmp    _printop312
msg&number:     db      desc

                endm

PRINTOP322      macro number,desc1,desc2

prin&number:    
                db      7
                mov     isize,3
                mov     eax,offset msg&number&a
                call    _printop322
                mov     eax,offset msg&number&b
                jmp     printmsgp
msg&number&a:   db      desc1
msg&number&b:   db      desc2

                endm

PRINTOP321      macro number,desc1,desc2

prin&number:    
                db      8
msg&number&a:   db      desc1
msg&number&b:   db      desc2

                endm

PRINTOP422      macro number,desc1,desc2

prin&number:    
                db      9
                mov     isize,4
                mov     eax,offset msg&number&a
                call    _printop422
                mov     eax,offset msg&number&b
                jmp     printmsgp
msg&number&a:   db      desc1
msg&number&b:   db      desc2

                endm

PRINTOP421      macro number,desc1,desc2

prin&number:    
                db      10
                mov     isize,4
                mov     eax,offset msg&number&a
                call    printmsgp
                add     edi,2
                call    fetch
                call    printhex2p
                mov     eax,offset msg&number&b
                call    printmsgp
                inc     edi
                call    fetch
                jmp     printhex2p
msg&number&a:   db      desc1
msg&number&b:   db      desc2

                endm

PRINTOP42X      macro number,desc1,desc2

prin&number:    
                db      11
msg&number&a:   db      desc1
msg&number&b:   db      desc2

                endm

PRINTOP412      macro number,desc

prin&number:    
                db      12
                mov     isize,4
                mov     eax,offset msg&number
                jmp     _printop412
msg&number:     db      desc

                endm

