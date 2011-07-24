opaddreg:
                mov     ch,dh                           ; clock 2 
                add     dh,bh                           ; clock 3 U
                mov     cl,0                            ; clock 3 V
                mov     al,dh                           ; clock 4 V
                adc     cl,cl                           ; clock 5 U
                xor     bh,dh                           ; clock 5 V
                mov     dl,[offset ARITP_table+eax]     ; clock 6 U
                xor     bh,ch                           ; clock 6 V
                or      dl,cl                           ; clock 7 U
                mov     al,cl                           ; clock 7 V
                or      al,bh                           ; clock 8 U
                and     bh,BIT_4                        ; clock 8 V
                or      dl,bh                           ; clock 9
                or      dl,[offset OVERFLOW_table+eax]  ; clock 10
                ret

opadcreg:
                shr     dl,1                            ; clock 2 U
                mov     ch,dh                           ; clock 2 V
                adc     dh,bh                           ; clock 3 U
                mov     cl,0                            ; clock 3 V
                mov     al,dh                           ; clock 4 V
                adc     cl,cl                           ; clock 5 U
                xor     bh,dh                           ; clock 5 V
                mov     dl,[offset ARITP_table+eax]     ; clock 6 U
                xor     bh,ch                           ; clock 6 V
                or      dl,cl                           ; clock 7 U
                mov     al,cl                           ; clock 7 V
                and     bh,0FEh
                or      al,bh                           ; clock 8 U
                and     bh,BIT_4                        ; clock 8 V
                or      dl,bh                           ; clock 9
                or      dl,[offset OVERFLOW_table+eax]  ; clock 10
                ret

opsubreg:
                mov     ch,dh                           ; clock 2 V
                sub     dh,bh                           ; clock 3 U
                mov     cl,0                            ; clock 3 V
                mov     al,dh                           ; clock 4 V
                adc     cl,cl                           ; clock 5 U
                xor     bh,dh                           ; clock 5 V
                mov     dl,[offset ARITN_table+eax]     ; clock 6 U
                xor     bh,ch                           ; clock 6 V
                or      dl,cl                           ; clock 7 U
                mov     al,cl                           ; clock 7 V
                or      al,bh                           ; clock 8 U
                and     bh,BIT_4                        ; clock 8 V
                or      dl,bh                           ; clock 9
                or      dl,[offset OVERFLOW_table+eax]  ; clock 10
                ret

opsbcreg:
                shr     dl,1                            ; clock 2 U
                mov     ch,dh                           ; clock 2 V
                sbb     dh,bh                           ; clock 3 U
                mov     cl,0                            ; clock 3 V
                mov     al,dh                           ; clock 4 V
                adc     cl,cl                           ; clock 5 U
                xor     bh,dh                           ; clock 5 V
                mov     dl,[offset ARITN_table+eax]     ; clock 6 U
                xor     bh,ch                           ; clock 6 V
                or      dl,cl                           ; clock 7 U
                mov     al,cl                           ; clock 7 V
                and     bh,0FEh
                or      al,bh                           ; clock 8 U
                and     bh,BIT_4                        ; clock 8 V
                or      dl,bh                           ; clock 9
                or      dl,[offset OVERFLOW_table+eax]  ; clock 10
                ret

opcpreg:
                mov     bl,dh                           ; clock 1 U
                xor     ecx,ecx                         ; clock 1 V
                sub     bl,al                           ; clock 2
                adc     cl,cl                           ; clock 3 U
                mov     dl,al                           ; clock 3 V
                and     dl,BIT_5 OR BIT_3               ; clock 4 U
                xor     al,bl                           ; clock 4 V
                or      dl,[offset CP_table+ebx]        ; clock 5 U
                xor     al,dh                           ; clock 5 V
                or      dl,cl                           ; clock 6 U
                or      cl,al                           ; clock 6 V
                and     al,BIT_4                        ; clock 7
                or      dl,al                           ; clock 8
                or      dl,[offset OVERFLOW_table+ecx]  ; clock 9
                ret

_ret:   ret
