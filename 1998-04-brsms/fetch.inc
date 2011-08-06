TOTALCLOCKS     equ     212 ;(59659/280)

; FETCHMACRO ---------------------------------------------------------
; fetch a byte from Z80 memory (macro version)
; in, edi: address
; out, al: byte
; affect: esi,ebx

FETCHMACRO      macro   skip
                
                lea     esi,[edi+skip]                  ; clock 1 U
                lea     ebx,[edi+skip]                  ; clock 1 V
                shr     esi,13                          ; clock 2 U
                and     ebx,01fffh                      ; clock 2 V
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     al,[esi+ebx]                    ; clock 6 U [AGI]

                endm

; FETCHWMACRO --------------------------------------------------------
; fetch a word from Z80 memory (MACRO VERSION)
; in, edi: address
; out, ax: word
; affect: esi,ebx

FETCHWMACRO     macro   skip

                lea     esi,[edi+skip]                  ; clock 1 U
                lea     ebx,[edi+skip]                  ; clock 1 V
                shr     esi,13                          ; clock 2 U
                and     ebx,01fffh                      ; clock 2 V
                cmp     ebx,01fffh                      ; clock 3 U
                je      fetchw_slow_&skip               ; clock 3 V
                mov     esi,[offset mem+esi*4]          ; clock 4 U 
                mov     ax,word ptr [esi+ebx]           ; clock 6 U [AGI]
                ret
fetchw_slow_&skip:  
                FETCHMACRO skip
                mov     ah,al
                FETCHMACRO skip+1
                xchg    ah,al
                ret

                endm

; -------------------------------------------------------------------- 

FETCH1          macro   opcode
                local   emul_fetch
                local   emul_continue

                cmp     ebx,01FFFh
                jne     emul_fetch

                call    fetch1
                jmp     emul_continue

emul_fetch:
                mov     al,[esi+ebx+1]

emul_continue:
                endm

; -------------------------------------------------------------------- 

FETCHW1         macro   opcode
                local   emul_fetch
                local   emul_continue

                cmp     ebx,01FFEh
                jb      emul_fetch

                call    fetchw1
                jmp     emul_continue

emul_fetch:
                mov     ax,[esi+ebx+1]

emul_continue:
                endm
