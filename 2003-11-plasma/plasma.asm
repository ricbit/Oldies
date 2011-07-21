; -----------------------------------------------------------------------
;
;    Plasma 256
;    Copyright (C) 2003 by Eduardo Sato & Ricardo Bittencourt
;
;    Project started at 11/11/2003. Last modification was on 15/11/2002.
;    Contact the author through the addresses: 
;        
;	 iguio@bol.com.br
;
;        ricardo@700km.com.br
;        http://www.mundobizarro.tk
;
; -----------------------------------------------------------------------        
;
; Credits:
;
;       Programming
; 		Eduardo Sato		(original 512 bytes version)
;               Ricardo Bittencourt 	(optimizations)
			

; -----------------------------------------------------------------------        
		
			
VGA_PALETTE_REG_SELECT	equ	03c8h	
VGA_INPUT_STATUS	equ	03dah
VGA_VRETRACE		equ	08h

costable		equ	0200h

; -----------------------------------------------------------------------        

	org	100h
			
	; make es point to vga 	
	push	0a000h
	pop	es
			
	; change to mode 13h
	mov	al,13h
	int	10h

; -----------------------------------------------------------------------        
; generate palette ramp
			
	mov	dx, VGA_PALETTE_REG_SELECT
	xor	al, al
	out	dx, al			; start at color register 0
			
	inc	dx
	mov	bx,200h	
	mov	si,bx
pal1:
	mov	al,bl
	shl	al,2
	sbb	al,al
	or	al,bl
	
	test	bl,bl
	jns	pal2
	not	al
pal2:
	mov	[si+bx],al	
	inc	bx
	cmp	bh,dh
	jbe	pal1
	
;------------------------------------------------------------------------------
; set palette and evaluate cosines

	shr	bh,1
	fild	word [const_128+2]
	fldz
	
pal3:
	; set palette
	mov	al,[si+bx+40h]
	out	dx,al
	mov	al,[si+bx]
	out	dx,al
const_128:	
	mov	al,[si+bx+80h]
	or	al,[si+bx+0C0h]
	out	dx,al
	
	; eval cosines
	fld	st0	
	fcos
	fmul	st2
	fistp	word [bx]
	fldpi
	fdiv	st2
	faddp	st1
	inc	bx
	cmp	bh,dh
	jne	pal3

;------------------------------------------------------------------------------
; begin rendering plasma
;
; color = cos(x/2 + a) + cos(2*x + a) + cos(y/2 + a) + cos(2*y + a)
;         |--------------------------|  |--------------------------|
;                      s1                           s2

plasma:		
	xor	di, di			
			
wait_vsync:	
	mov	dx,VGA_INPUT_STATUS
	in	al,dx
	test	al,VGA_VRETRACE
	jnz	wait_vsync
wait_2:	in	al,dx
	test	al,VGA_VRETRACE
	jz	wait_2
						
	mov	cx,200
			
	mov 	bx,si
	movzx	edx,bx
p_line:	
	xor	al,al
	call	core
	mov	ah,al
			
	mov	bp,320
	pusha
	mov	cx,bp
	mov	bx,si
	mov	dx,bx
	add	bl,64
p_column:	
	mov	al,ah
	call	core
	stosb
	loop	p_column
			
	popa
	add	di,bp
	loop	p_line
			
	inc	si
	and	si, 02ffh		
			
	mov	ah,1	
	push	si
	int	16h
	pop	si
	jz	plasma
			
;------------------------------------------------------------------------------

	; change back to text mode (mode 03h) and return to DOS
	
	mov	ax,3
	int	10h
	ret

;------------------------------------------------------------------------------

core:
	add	al,[bx]
	ror 	cx,1
	rcl	cx,1
	sbb 	bl,0
					
	add	al,[edx]
	sub	dl,dh
	ret
	
;------------------------------------------------------------------------------

	END