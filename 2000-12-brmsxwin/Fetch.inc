
; --------------------------------------------------------------------

FETCH1          macro   opcode

                push    ecx
                mov     ecx,edi
                inc     ecx
                call    readmem
                pop     ecx

                endm

; --------------------------------------------------------------------

FETCH1SX        macro   opcode

                push    ecx
                call    fetch1
                movsx   ebx,al
                pop     ecx
                endm

; --------------------------------------------------------------------

FETCHW1         macro   opcode

                call    fetchw1


                endm

