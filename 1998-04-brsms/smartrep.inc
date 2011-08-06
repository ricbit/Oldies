; SMART_REP ----------------------------------------------------------

SMART_REP       macro
                local   skip1,skip2

                shr     ecx,1
                jnc     skip1
                movsb
skip1:
                shr     ecx,1
                jnc     skip2
                movsw
skip2:
                rep     movsd

                endm

