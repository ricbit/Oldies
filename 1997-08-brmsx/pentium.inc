rdtsc           macro
                db 0fh,031h
                endm

cpuid           macro
                db 0fh,0a2h
                endm

rdmsr           macro
                db 0fh,032h
                endm

wrmsr           macro
                db 0fh,030h
                endm

emms            macro
                db 0fh,077h
                endm

movq            macro
                db 0fh,06fh
                endm

movd            macro
                db 0fh,06eh
                endm

movq_st         macro
                db 0fh,07fh
                endm

pand            macro
                db 0fh,0dbh
                endm

pandn           macro
                db 0fh,0dfh
                endm

por             macro
                db 0fh,0ebh     
                endm

paddd           macro
                db 0fh,0feh
                endm

pcmpgtd         macro
                db 0fh,066h
                endm

psubd           macro
                db 0fh,0fah
                endm

pxor            macro
                db 0fh,0efh
                endm

pcmpgtb         macro
                db 0fh,064h
                endm

pcmpeqb         macro
                db 0fh,074h
                endm

punpckhbw       macro
                db 0fh,068h
                endm

punpcklbw       macro
                db 0fh,060h
                endm

punpckhwd       macro
                db 0fh,069h
                endm

punpcklwd       macro
                db 0fh,061h
                endm

paddw           macro
                db      0fh,0fdh
                endm

psrlq           macro
                db      0fh,073h
                endm

psllq           macro
                db      0fh,073h
                endm

pcmpeqw         macro
                db      0fh,075h
                endm

packuswb        macro
                db      0Fh,067h
                endm
