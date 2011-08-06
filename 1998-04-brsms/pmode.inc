extrn   v86r_eax:dword, v86r_ebx:dword, v86r_ecx:dword, v86r_edx:dword
extrn   v86r_esi:dword, v86r_edi:dword, v86r_ebp:dword
extrn   v86r_ah:byte, v86r_al:byte, v86r_bh:byte, v86r_bl:byte
extrn   v86r_ch:byte, v86r_cl:byte, v86r_dh:byte, v86r_dl:byte
extrn   v86r_ax:word, v86r_bx:word, v86r_cx:word, v86r_dx:word
extrn   v86r_si:word, v86r_di:word, v86r_bp:word
extrn   v86r_ds:word, v86r_es:word, v86r_fs:word, v86r_gs:word
extrn   v86r_flags:word
extrn   _selcode:word, _seldata:word, _selzero:word, _lomembase:dword
extrn   _lomemtop:dword, _himembase:dword, _himemtop:dword, _pspa:dword
extrn   _code16a:dword, _code32a:dword, _getirqvect:dword, _setirqvect:dword
extrn   _sysbyte0:byte, _setselector:dword, _exitcode:byte

extrn   _getmem:near, _getlomem:near, _gethimem:near, _lomemsize:near
extrn   _himemsize:near, _ret:near, _exit:near, _getirqmask:near
extrn   _setirqmask:near, _rmpmirqset:near, _rmpmirqfree:near
extrn   _getselector:near, _freeselector:near

; Convert physical pointer to realative pointer
@rlp    macro reg, ptr
	mov &reg,&ptr
	sub &reg,_code32a
endm

; Convert realative pointer to physical pointer
@php    macro reg, ptr
	mov &reg,&ptr
	add &reg,_code32a
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

; Get interrupt flag status
@gif    macro
	mov ax,902h
	int 31h
endm

; Get interrupt flag status and clear
@gifc   macro
	mov ax,900h
	int 31h
endm

; Get interrupt flag status and set
@gifs   macro
	mov ax,901h
	int 31h
endm

; Get interrupt flag status and set to AL (0=clear, 1=set)
@gifal  macro
	mov ah,9
	int 31h
endm

