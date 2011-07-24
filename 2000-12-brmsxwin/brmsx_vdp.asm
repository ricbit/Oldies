	.686p
	ifdef ??version
	if    ??version GT 500H
	.mmx
	endif
	endif
	model flat
	ifndef	??version
	?debug	macro
	endm
	endif
	?debug	S "C:\progs\brmsxwin\brmsx_vdp.cpp"
	?debug	T "C:\progs\brmsxwin\brmsx_vdp.cpp"
_TEXT	segment dword public use32 'CODE'
_TEXT	ends
_DATA	segment dword public use32 'DATA'
_DATA	ends
_BSS	segment dword public use32 'BSS'
_BSS	ends
$$BSYMS	segment byte public use32 'DEBSYM'
$$BSYMS	ends
$$BTYPES	segment byte public use32 'DEBTYP'
$$BTYPES	ends
$$BNAMES	segment byte public use32 'DEBNAM'
$$BNAMES	ends
$$BROWSE	segment byte public use32 'DEBSYM'
$$BROWSE	ends
$$BROWFILE	segment byte public use32 'DEBSYM'
$$BROWFILE	ends
DGROUP	group	_BSS,_DATA
_BSS	segment dword public use32 'BSS'
_Value	label	byte
	db	1	dup(?)
	align	4
_vdptemp	label	dword
	db	4	dup(?)
_BSS	ends
_DATA	segment dword public use32 'DATA'
	align	4
_vdpaddr	label	dword
	dd	0
	align	4
_vdpcond	label	dword
	dd	0
_DATA	ends
_BSS	segment dword public use32 'BSS'
_vdpreg	label	byte
	db	8	dup(?)
_BSS	ends
_DATA	segment dword public use32 'DATA'
_keymatrix	label	byte
	db	255
	db	255
	db	255
	db	255
	db	255
	db	255
	db	255
	db	255
	db	255
	db	255
	db	255
	db	255
	db	255
	db	255
	db	255
	db	255
_DATA	ends
_BSS	segment dword public use32 'BSS'
_keyline	label	byte
	db	1	dup(?)
_vdpstatus	label	byte
	db	1	dup(?)
_BSS	ends
_TEXT	segment dword public use32 'CODE'
_outemul98	segment virtual
	align	2
@_outemul98	proc	near
?live16385@0:
	?debug L 12
	push      ebp
	mov       ebp,esp
	push      ebx
	?debug L 13
@1:
 	pushad	
	?debug L 14
 	mov	 _Value,bl
	?debug L 15
	mov       eax,dword ptr [_vram]
	mov       edx,dword ptr [_vdpaddr]
	mov       cl,byte ptr [_Value]
	mov       byte ptr [eax+edx],cl
	?debug L 16
	mov       eax,dword ptr [_vdpaddr]
	inc       eax
	and       eax,16383
	mov       dword ptr [_vdpaddr],eax
	?debug L 17
 	popad	
	?debug L 18
@2:
	pop       ebx
	pop       ebp
	ret 
	?debug L 0
@_outemul98	endp
_outemul98	ends
_TEXT	ends
$$BSYMS	segment byte public use32 'DEBSYM'
	db	2
	db	0
	db	0
	db	0
	dw	56
	dw	517
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dd	?patch1
	dd	?patch2
	dd	?patch3
	df	@_outemul98
	dw	0
	dw	4096
	dw	0
	dw	1
	dw	0
	dw	0
	dw	0
	db	9
	db	111
	db	117
	db	116
	db	101
	db	109
	db	117
	db	108
	db	57
	db	56
?patch1	equ	@2-@_outemul98+3
?patch2	equ	0
?patch3	equ	@2-@_outemul98
	dw	2
	dw	6
	dw	8
	dw	531
	dw	1
	dw	65532
	dw	65535
$$BSYMS	ends
_TEXT	segment dword public use32 'CODE'
_outemul99	segment virtual
	align	2
@_outemul99	proc	near
?live16386@0:
	?debug L 20
	push      ebp
	mov       ebp,esp
	push      ebx
	?debug L 21
@3:
 	pushad	
	?debug L 22
 	mov	 _Value,bl
	?debug L 23
	cmp       dword ptr [_vdpcond],0
	je        short @5
	?debug L 24
@4:
	mov       al,byte ptr [_Value]
	test      al,-128
	je        short @6
	?debug L 25
?live16386@80: ; EAX = @temp0
	xor       edx,edx
	mov       dl,al
	and       edx,7
	mov       cl,byte ptr [_vdptemp]
	mov       byte ptr [edx+_vdpreg],cl
	?debug L 26
?live16386@96: ; 
	jmp       short @7
	?debug L 27
?live16386@112: ; EAX = @temp0
@6:
	and       eax,255
	and       eax,63
	shl       eax,8
	or        eax,dword ptr [_vdptemp]
	mov       dword ptr [_vdpaddr],eax
	?debug L 29
?live16386@128: ; 
@7:
	xor       edx,edx
	mov       dword ptr [_vdpcond],edx
	?debug L 30
	jmp       short @8
	?debug L 31
@5:
	xor       ecx,ecx
	mov       cl,byte ptr [_Value]
	mov       dword ptr [_vdptemp],ecx
	?debug L 32
	mov       dword ptr [_vdpcond],1
	?debug L 34
@8:
 	popad	
	?debug L 35
@9:
	pop       ebx
	pop       ebp
	ret 
	?debug L 0
@_outemul99	endp
_outemul99	ends
_TEXT	ends
$$BSYMS	segment byte public use32 'DEBSYM'
	dw	56
	dw	517
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dd	?patch4
	dd	?patch5
	dd	?patch6
	df	@_outemul99
	dw	0
	dw	4098
	dw	0
	dw	2
	dw	0
	dw	0
	dw	0
	db	9
	db	111
	db	117
	db	116
	db	101
	db	109
	db	117
	db	108
	db	57
	db	57
?patch4	equ	@9-@_outemul99+3
?patch5	equ	0
?patch6	equ	@9-@_outemul99
	dw	2
	dw	6
	dw	8
	dw	531
	dw	1
	dw	65532
	dw	65535
$$BSYMS	ends
_TEXT	segment dword public use32 'CODE'
_outemulAA	segment virtual
	align	2
@_outemulAA	proc	near
?live16387@0:
	?debug L 37
	push      ebp
	mov       ebp,esp
	push      ebx
	?debug L 38
@10:
 	pushad	
	?debug L 39
 	mov	 _Value,bl
	?debug L 40
	mov       al,byte ptr [_Value]
	and       al,15
	mov       byte ptr [_keyline],al
	?debug L 41
 	popad	
	?debug L 42
@11:
	pop       ebx
	pop       ebp
	ret 
	?debug L 0
@_outemulAA	endp
_outemulAA	ends
_TEXT	ends
$$BSYMS	segment byte public use32 'DEBSYM'
	dw	56
	dw	517
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dd	?patch7
	dd	?patch8
	dd	?patch9
	df	@_outemulAA
	dw	0
	dw	4100
	dw	0
	dw	3
	dw	0
	dw	0
	dw	0
	db	9
	db	111
	db	117
	db	116
	db	101
	db	109
	db	117
	db	108
	db	65
	db	65
?patch7	equ	@11-@_outemulAA+3
?patch8	equ	0
?patch9	equ	@11-@_outemulAA
	dw	2
	dw	6
	dw	8
	dw	531
	dw	1
	dw	65532
	dw	65535
$$BSYMS	ends
_TEXT	segment dword public use32 'CODE'
_inemul98_C	segment virtual
	align	2
@_inemul98_C	proc	near
?live16388@0:
	?debug L 44
	push      ebp
	mov       ebp,esp
	?debug L 45
@12:
 	pushad	
	?debug L 46
	mov       eax,dword ptr [_vram]
	mov       edx,dword ptr [_vdpaddr]
	mov       cl,byte ptr [eax+edx]
	mov       byte ptr [_Value],cl
	?debug L 47
	mov       eax,dword ptr [_vdpaddr]
	inc       eax
	and       eax,16383
	mov       dword ptr [_vdpaddr],eax
	?debug L 48
 	popad	
	?debug L 49
@13:
	pop       ebp
	ret 
	?debug L 0
@_inemul98_C	endp
_inemul98_C	ends
_TEXT	ends
$$BSYMS	segment byte public use32 'DEBSYM'
	dw	57
	dw	517
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dd	?patch10
	dd	?patch11
	dd	?patch12
	df	@_inemul98_C
	dw	0
	dw	4102
	dw	0
	dw	4
	dw	0
	dw	0
	dw	0
	db	10
	db	105
	db	110
	db	101
	db	109
	db	117
	db	108
	db	57
	db	56
	db	95
	db	67
?patch10	equ	@13-@_inemul98_C+2
?patch11	equ	0
?patch12	equ	@13-@_inemul98_C
	dw	2
	dw	6
$$BSYMS	ends
_TEXT	segment dword public use32 'CODE'
_inemul99_C	segment virtual
	align	2
@_inemul99_C	proc	near
?live16389@0:
	?debug L 51
	push      ebp
	mov       ebp,esp
	?debug L 52
@14:
 	pushad	
	?debug L 53
	mov       al,byte ptr [_vdpstatus]
	mov       byte ptr [_Value],al
	?debug L 54
	and       byte ptr [_vdpstatus],127
	?debug L 55
 	popad	
	?debug L 56
@15:
	pop       ebp
	ret 
	?debug L 0
@_inemul99_C	endp
_inemul99_C	ends
_TEXT	ends
$$BSYMS	segment byte public use32 'DEBSYM'
	dw	57
	dw	517
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dd	?patch13
	dd	?patch14
	dd	?patch15
	df	@_inemul99_C
	dw	0
	dw	4104
	dw	0
	dw	5
	dw	0
	dw	0
	dw	0
	db	10
	db	105
	db	110
	db	101
	db	109
	db	117
	db	108
	db	57
	db	57
	db	95
	db	67
?patch13	equ	@15-@_inemul99_C+2
?patch14	equ	0
?patch15	equ	@15-@_inemul99_C
	dw	2
	dw	6
$$BSYMS	ends
_TEXT	segment dword public use32 'CODE'
_inemulA9_C	segment virtual
	align	2
@_inemulA9_C	proc	near
?live16390@0:
	?debug L 58
	push      ebp
	mov       ebp,esp
	?debug L 59
@16:
 	pushad	
	?debug L 60
	xor       eax,eax
	mov       al,byte ptr [_keyline]
	mov       dl,byte ptr [eax+_keymatrix]
	mov       byte ptr [_Value],dl
	?debug L 61
 	popad	
	?debug L 62
@17:
	pop       ebp
	ret 
	?debug L 0
@_inemulA9_C	endp
_inemulA9_C	ends
_TEXT	ends
$$BSYMS	segment byte public use32 'DEBSYM'
	dw	57
	dw	517
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dw	0
	dd	?patch16
	dd	?patch17
	dd	?patch18
	df	@_inemulA9_C
	dw	0
	dw	4106
	dw	0
	dw	6
	dw	0
	dw	0
	dw	0
	db	10
	db	105
	db	110
	db	101
	db	109
	db	117
	db	108
	db	65
	db	57
	db	95
	db	67
?patch16	equ	@17-@_inemulA9_C+2
?patch17	equ	0
?patch18	equ	@17-@_inemulA9_C
	dw	2
	dw	6
$$BSYMS	ends
_DATA	segment dword public use32 'DATA'
	public	 _inemul98
_inemul98:
	call	 @_inemul98_C
	mov	 bl,_Value
	ret	
	public	 _inemul99
_inemul99:
	call	 @_inemul99_C
	mov	 bl,_Value
	ret	
	public	 _inemulA9
_inemulA9:
	call	 @_inemulA9_C
	mov	 bl,_Value
	ret	
_DATA	ends
_TEXT	segment dword public use32 'CODE'
_TEXT	ends
	public	_Value
	public	_vdptemp
	public	_vdpaddr
	public	_vdpcond
	public	_vdpreg
	public	_keymatrix
	public	_keyline
	public	_vdpstatus
	extrn	_vram:dword
$$BSYMS	segment byte public use32 'DEBSYM'
	dw	22
	dw	514
	df	_Value
	dw	0
	dw	32
	dw	0
	dw	7
	dw	0
	dw	0
	dw	0
	dw	22
	dw	514
	df	_vdptemp
	dw	0
	dw	116
	dw	0
	dw	8
	dw	0
	dw	0
	dw	0
	dw	22
	dw	514
	df	_vdpaddr
	dw	0
	dw	116
	dw	0
	dw	9
	dw	0
	dw	0
	dw	0
	dw	22
	dw	514
	df	_vdpcond
	dw	0
	dw	116
	dw	0
	dw	10
	dw	0
	dw	0
	dw	0
	dw	22
	dw	514
	df	_vdpreg
	dw	0
	dw	4108
	dw	0
	dw	11
	dw	0
	dw	0
	dw	0
	dw	22
	dw	514
	df	_keymatrix
	dw	0
	dw	4109
	dw	0
	dw	12
	dw	0
	dw	0
	dw	0
	dw	22
	dw	514
	df	_keyline
	dw	0
	dw	32
	dw	0
	dw	13
	dw	0
	dw	0
	dw	0
	dw	22
	dw	514
	df	_vdpstatus
	dw	0
	dw	32
	dw	0
	dw	14
	dw	0
	dw	0
	dw	0
	dw	?patch19
	dw	1
	db	2
	db	1
	db	8
	db	24
	db	6
	db	66
	db	67
	db	52
	db	46
	db	48
	db	48
?patch19	equ	13
$$BSYMS	ends
$$BTYPES	segment byte public use32 'DEBTYP'
	db        2,0,0,0,14,0,8,0,3,0,0,0,0,0,0,0
	db        1,16,0,0,4,0,1,2,0,0,14,0,8,0,3,0
	db        0,0,0,0,0,0,3,16,0,0,4,0,1,2,0,0
	db        14,0,8,0,3,0,0,0,0,0,0,0,5,16,0,0
	db        4,0,1,2,0,0,14,0,8,0,3,0,0,0,0,0
	db        0,0,7,16,0,0,4,0,1,2,0,0,14,0,8,0
	db        3,0,0,0,0,0,0,0,9,16,0,0,4,0,1,2
	db        0,0,14,0,8,0,3,0,0,0,0,0,0,0,11,16
	db        0,0,4,0,1,2,0,0,18,0,3,0,32,0,0,0
	db        17,0,0,0,0,0,0,0,8,0,8,0,18,0,3,0
	db        32,0,0,0,17,0,0,0,0,0,0,0,16,0,16,0
$$BTYPES	ends
$$BNAMES	segment byte public use32 'DEBNAM'
	db	9,'outemul98'
	db	9,'outemul99'
	db	9,'outemulAA'
	db	10,'inemul98_C'
	db	10,'inemul99_C'
	db	10,'inemulA9_C'
	db	5,'Value'
	db	7,'vdptemp'
	db	7,'vdpaddr'
	db	7,'vdpcond'
	db	6,'vdpreg'
	db	9,'keymatrix'
	db	7,'keyline'
	db	9,'vdpstatus'
$$BNAMES	ends
	?debug	D "C:\progs\brmsxwin\brmsx_vdp.cpp" 11562 33291
	end
