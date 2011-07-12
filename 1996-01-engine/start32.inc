extrn   v86r_ah:byte, v86r_al:byte, v86r_bh:byte, v86r_bl:byte
extrn   v86r_ch:byte, v86r_cl:byte, v86r_dh:byte, v86r_dl:byte
extrn   v86r_ax:word, v86r_bx:word, v86r_cx:word, v86r_dx:word
extrn   v86r_si:word, v86r_di:word, v86r_bp:word, v86r_flags:word
extrn   v86r_ds:word, v86r_es:word
extrn   _totalextmem:word, _code16a:dword, _code32a:dword, _hextbl:byte
extrn   _lomembase:dword, _lomemtop:dword, _himembase:dword, _himemtop:dword

extrn   _putdosmsg:near, _getvect:near, _setvect:near, _exit:near
extrn   _getmem:near, _getlomem:near, _gethimem:near, _lomemsize:near
extrn   _himemsize:near, _ret:near

; Move realatively adjusted pointer to reg
@rlp    macro reg, ptr
        mov &reg,&ptr
        sub &reg,_code32a
endm

; Output a byte to DX
@outb           macro   val
        mov al,&val
        out dx,al
endm

; Output a word to DX
@outw           macro   val
        mov ax,&val
        out dx,ax
endm


