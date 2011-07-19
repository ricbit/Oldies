; -------------------------------------------------------------------- 

FETCH1          macro   opcode

                mov     al,0

                endm

; -------------------------------------------------------------------- 

FETCH1S         macro   opcode

                mov     ecx,0

                endm

; -------------------------------------------------------------------- 

FETCHW1         macro   opcode

                mov     eax,0

                endm

; -------------------------------------------------------------------- 

READMEM         macro   

                mov     esi,offset readmem
                call    esi

                endm

; -------------------------------------------------------------------- 

READMEMW        macro   

                mov     esi,offset readmemw
                call    esi

                endm

; -------------------------------------------------------------------- 

WRITEMEM        macro   
                
                mov     esi,offset writemem
                call    esi

                endm

; -------------------------------------------------------------------- 

WRITEMEMW       macro   
                
                mov     esi,offset writememw
                call    esi

                endm
