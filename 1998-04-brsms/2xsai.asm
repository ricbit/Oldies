.386p
Code32 segment para public use32
assume cs:Code32, ds:Code32

; This file was automatically generated using att2intl
; Please see documentation, assuming there is any, if
; att2intl does something wrong
; Greg Velichansky
; (Hmaon / Xylem)
; With support from Cam Horn / Xylem

; I MAKE NO WARRANTIES OF ANY KIND REGARDING THIS PRODUCT
; IN FACT I CAN GUARANTEE THAT IN SOME CASES IT WILL *NOT*
; WORK CORRECTLY!


 ; .file "2xsai.cc"
gcc2_compiled_: ; basic label
___gnu_compiled_cplusplus: ; basic label
 ; .text

align 4
public __2xSaIBitmap__FPUiPUs
__2xSaIBitmap__FPUiPUs: ; basic label
sub 	esp,	60
push 	ebp
push 	edi
push 	esi
push 	ebx
mov 	DWORD PTR [72+esp],	256

align 4
L24: ; basic label
cmp 	DWORD PTR [72+esp],	0
je 	L25
mov 	edi,	DWORD PTR [84+esp]
movzx 	ebp,	WORD PTR [-514+edi]
movzx 	edi,	WORD PTR [-512+edi]
mov 	DWORD PTR [64+esp],	edi
mov 	edi,	DWORD PTR [84+esp]
movzx 	edi,	WORD PTR [-510+edi]
mov 	DWORD PTR [60+esp],	edi
mov 	edi,	DWORD PTR [84+esp]
movzx 	edi,	WORD PTR [-508+edi]
mov 	DWORD PTR [48+esp],	edi
mov 	edi,	DWORD PTR [84+esp]
movzx 	edi,	WORD PTR [-2+edi]
mov 	DWORD PTR [56+esp],	edi
mov 	edi,	DWORD PTR [84+esp]
movzx 	ebx,	WORD PTR [edi]
movzx 	esi,	WORD PTR [2+edi]
movzx 	edi,	WORD PTR [4+edi]
mov 	DWORD PTR [44+esp],	edi
mov 	edi,	DWORD PTR [84+esp]
movzx 	edi,	WORD PTR [510+edi]
mov 	DWORD PTR [52+esp],	edi
mov 	edi,	DWORD PTR [84+esp]
movzx 	edi,	WORD PTR [512+edi]
mov 	DWORD PTR [16+esp],	edi
mov 	edi,	DWORD PTR [84+esp]
movzx 	edi,	WORD PTR [514+edi]
mov 	DWORD PTR [68+esp],	edi
mov 	edi,	DWORD PTR [84+esp]
movzx 	edi,	WORD PTR [516+edi]
mov 	DWORD PTR [40+esp],	edi
mov 	edi,	DWORD PTR [84+esp]
movzx 	edi,	WORD PTR [1022+edi]
mov 	DWORD PTR [36+esp],	edi
mov 	edi,	DWORD PTR [84+esp]
movzx 	edi,	WORD PTR [1024+edi]
mov 	DWORD PTR [32+esp],	edi
mov 	edi,	DWORD PTR [84+esp]
movzx 	edi,	WORD PTR [1026+edi]
mov 	DWORD PTR [28+esp],	edi
cmp 	DWORD PTR [68+esp],	ebx
jne 	L28
cmp 	DWORD PTR [16+esp],	esi
je 	L126
cmp 	DWORD PTR [64+esp],	ebx
jne 	L31
cmp 	DWORD PTR [40+esp],	esi
je 	L34
L31: ; basic label
cmp 	DWORD PTR [16+esp],	ebx
jne 	L29
cmp 	DWORD PTR [60+esp],	ebx
jne 	L29
cmp 	DWORD PTR [64+esp],	esi
je 	L29
cmp 	DWORD PTR [48+esp],	esi
je 	L34
L29: ; basic label
cmp 	ebx,	esi
je 	L34
mov 	eax,	ebx
and 	eax,	2078178270
shr 	eax,	1
mov 	edx,	esi
and 	edx,	2078178270
shr 	edx,	1
add 	eax,	edx
mov 	edx,	ebx
and 	edx,	esi
and 	edx,	69272609
add 	eax,	edx
mov 	DWORD PTR [24+esp],	eax
jmp 	L32

align 4
L34: ; basic label
mov 	DWORD PTR [24+esp],	ebx
L32: ; basic label
cmp 	DWORD PTR [56+esp],	ebx
jne 	L38
mov 	edi,	DWORD PTR [28+esp]
cmp 	DWORD PTR [16+esp],	edi
je 	L41
L38: ; basic label
cmp 	ebx,	esi
jne 	L36
cmp 	DWORD PTR [52+esp],	ebx
jne 	L36
mov 	edi,	DWORD PTR [16+esp]
cmp 	DWORD PTR [56+esp],	edi
je 	L36
mov 	edi,	DWORD PTR [36+esp]
cmp 	DWORD PTR [16+esp],	edi
je 	L41
L36: ; basic label
cmp 	DWORD PTR [16+esp],	ebx
je 	L41
mov 	eax,	ebx
and 	eax,	2078178270
shr 	eax,	1
mov 	edx,	DWORD PTR [16+esp]
and 	edx,	2078178270
shr 	edx,	1
add 	eax,	edx
mov 	edx,	DWORD PTR [16+esp]
and 	edx,	ebx
and 	edx,	69272609
add 	eax,	edx
mov 	DWORD PTR [20+esp],	eax
jmp 	L129

align 4
L41: ; basic label
mov 	DWORD PTR [20+esp],	ebx
jmp 	L129

align 4
L28: ; basic label
cmp 	DWORD PTR [16+esp],	esi
jne 	L60
L126: ; basic label
cmp 	DWORD PTR [68+esp],	ebx
je 	L127
cmp 	DWORD PTR [60+esp],	esi
jne 	L47
cmp 	DWORD PTR [52+esp],	ebx
je 	L46
L47: ; basic label
cmp 	DWORD PTR [64+esp],	esi
jne 	L45
cmp 	DWORD PTR [68+esp],	esi
jne 	L45
cmp 	DWORD PTR [60+esp],	ebx
je 	L45
cmp 	ebx,	ebp
jne 	L45
L46: ; basic label
mov 	DWORD PTR [24+esp],	esi
jmp 	L48

align 4
L45: ; basic label
cmp 	ebx,	esi
je 	L50
mov 	eax,	ebx
and 	eax,	2078178270
shr 	eax,	1
mov 	edx,	esi
and 	edx,	2078178270
shr 	edx,	1
add 	eax,	edx
mov 	edx,	ebx
and 	edx,	esi
and 	edx,	69272609
add 	eax,	edx
mov 	DWORD PTR [24+esp],	eax
jmp 	L48

align 4
L50: ; basic label
mov 	DWORD PTR [24+esp],	ebx
L48: ; basic label
mov 	edi,	DWORD PTR [52+esp]
cmp 	DWORD PTR [16+esp],	edi
jne 	L54
cmp 	DWORD PTR [60+esp],	ebx
je 	L53
L54: ; basic label
mov 	edi,	DWORD PTR [56+esp]
cmp 	DWORD PTR [16+esp],	edi
jne 	L52
mov 	edi,	DWORD PTR [68+esp]
cmp 	DWORD PTR [16+esp],	edi
jne 	L52
cmp 	DWORD PTR [52+esp],	ebx
je 	L52
cmp 	ebx,	ebp
jne 	L52
L53: ; basic label
mov 	edi,	DWORD PTR [16+esp]
mov 	DWORD PTR [20+esp],	edi
jmp 	L130

align 4
L52: ; basic label
cmp 	DWORD PTR [16+esp],	ebx
je 	L57
mov 	eax,	ebx
and 	eax,	2078178270
shr 	eax,	1
mov 	edx,	DWORD PTR [16+esp]
and 	edx,	2078178270
shr 	edx,	1
add 	eax,	edx
mov 	edx,	DWORD PTR [16+esp]
and 	edx,	ebx
and 	edx,	69272609
add 	eax,	edx
mov 	DWORD PTR [20+esp],	eax
jmp 	L130

align 4
L57: ; basic label
mov 	DWORD PTR [20+esp],	ebx
jmp 	L130

align 4
L127: ; basic label
cmp 	DWORD PTR [16+esp],	esi
jne 	L60
cmp 	DWORD PTR [16+esp],	ebx
jne 	L61
mov 	DWORD PTR [24+esp],	ebx
mov 	DWORD PTR [20+esp],	ebx
mov 	ecx,	DWORD PTR [20+esp]
jmp 	L43

align 4
L61: ; basic label
xor 	ebp,	ebp
mov 	eax,	ebx
and 	eax,	2078178270
shr 	eax,	1
mov 	edx,	DWORD PTR [16+esp]
and 	edx,	2078178270
shr 	edx,	1
add 	eax,	edx
mov 	edx,	DWORD PTR [16+esp]
and 	edx,	ebx
and 	edx,	69272609
add 	eax,	edx
mov 	DWORD PTR [20+esp],	eax
mov 	DWORD PTR [24+esp],	eax
xor 	eax,	eax
xor 	ecx,	ecx
xor 	edx,	edx
cmp 	DWORD PTR [56+esp],	ebx
jne 	L70
mov 	eax,	1
jmp 	L71

align 4
L70: ; basic label
cmp 	DWORD PTR [56+esp],	esi
jne 	L71
mov 	ecx,	1
L71: ; basic label
cmp 	DWORD PTR [64+esp],	ebx
jne 	L73
inc 	eax
jmp 	L74

align 4
L73: ; basic label
cmp 	DWORD PTR [64+esp],	esi
jne 	L74
inc 	ecx
L74: ; basic label
cmp 	eax,	1
jg 	L76
inc 	edx
L76: ; basic label
cmp 	ecx,	1
jg 	L77
dec 	edx
L77: ; basic label
add 	ebp,	edx
xor 	eax,	eax
xor 	ecx,	ecx
xor 	edx,	edx
cmp 	DWORD PTR [44+esp],	esi
jne 	L79
mov 	eax,	1
jmp 	L80

align 4
L79: ; basic label
cmp 	DWORD PTR [44+esp],	ebx
jne 	L80
mov 	ecx,	1
L80: ; basic label
cmp 	DWORD PTR [60+esp],	esi
jne 	L82
inc 	eax
jmp 	L83

align 4
L82: ; basic label
cmp 	DWORD PTR [60+esp],	ebx
jne 	L83
inc 	ecx
L83: ; basic label
cmp 	eax,	1
jg 	L85
dec 	edx
L85: ; basic label
cmp 	ecx,	1
jg 	L86
inc 	edx
L86: ; basic label
add 	ebp,	edx
xor 	eax,	eax
xor 	ecx,	ecx
xor 	edx,	edx
cmp 	DWORD PTR [52+esp],	esi
jne 	L88
mov 	eax,	1
jmp 	L89

align 4
L88: ; basic label
cmp 	DWORD PTR [52+esp],	ebx
jne 	L89
mov 	ecx,	1
L89: ; basic label
cmp 	DWORD PTR [32+esp],	esi
jne 	L91
inc 	eax
jmp 	L92

align 4
L91: ; basic label
cmp 	DWORD PTR [32+esp],	ebx
jne 	L92
inc 	ecx
L92: ; basic label
cmp 	eax,	1
jg 	L94
dec 	edx
L94: ; basic label
cmp 	ecx,	1
jg 	L95
inc 	edx
L95: ; basic label
add 	ebp,	edx
xor 	eax,	eax
xor 	ecx,	ecx
xor 	edx,	edx
cmp 	DWORD PTR [40+esp],	ebx
jne 	L97
mov 	eax,	1
jmp 	L98

align 4
L97: ; basic label
cmp 	DWORD PTR [40+esp],	esi
jne 	L98
mov 	ecx,	1
L98: ; basic label
cmp 	DWORD PTR [28+esp],	ebx
jne 	L100
inc 	eax
jmp 	L101

align 4
L100: ; basic label
cmp 	DWORD PTR [28+esp],	esi
jne 	L101
inc 	ecx
L101: ; basic label
cmp 	eax,	1
jg 	L103
inc 	edx
L103: ; basic label
cmp 	ecx,	1
jg 	L104
dec 	edx
L104: ; basic label
add 	ebp,	edx
test 	ebp,	ebp
jle 	L105
L129: ; basic label
mov 	ecx,	ebx
jmp 	L43

align 4
L105: ; basic label
test 	ebp,	ebp
jge 	L107
L130: ; basic label
mov 	ecx,	esi
jmp 	L43

align 4
L107: ; basic label
mov 	ecx,	ebx
and 	ecx,	1939633052
shr 	ecx,	2
mov 	eax,	esi
and 	eax,	1939633052
shr 	eax,	2
add 	ecx,	eax
mov 	eax,	DWORD PTR [16+esp]
and 	eax,	1939633052
shr 	eax,	2
add 	ecx,	eax
mov 	eax,	DWORD PTR [68+esp]
and 	eax,	1939633052
shr 	eax,	2
add 	ecx,	eax
mov 	edx,	ebx
and 	edx,	207817827
mov 	eax,	esi
and 	eax,	207817827
add 	edx,	eax
mov 	eax,	DWORD PTR [16+esp]
and 	eax,	207817827
add 	edx,	eax
mov 	eax,	DWORD PTR [68+esp]
and 	eax,	207817827
add 	eax,	edx
shr 	eax,	2
and 	eax,	207817827
add 	ecx,	eax
jmp 	L43

align 4
L60: ; basic label
mov 	ecx,	ebx
and 	ecx,	1939633052
shr 	ecx,	2
mov 	eax,	esi
and 	eax,	1939633052
shr 	eax,	2
add 	ecx,	eax
mov 	eax,	DWORD PTR [16+esp]
and 	eax,	1939633052
shr 	eax,	2
add 	ecx,	eax
mov 	eax,	DWORD PTR [68+esp]
and 	eax,	1939633052
shr 	eax,	2
add 	ecx,	eax
mov 	edx,	ebx
and 	edx,	207817827
mov 	eax,	esi
and 	eax,	207817827
add 	edx,	eax
mov 	eax,	DWORD PTR [16+esp]
and 	eax,	207817827
add 	edx,	eax
mov 	eax,	DWORD PTR [68+esp]
and 	eax,	207817827
add 	eax,	edx
shr 	eax,	2
and 	eax,	207817827
add 	ecx,	eax
cmp 	DWORD PTR [16+esp],	ebx
jne 	L112
cmp 	DWORD PTR [60+esp],	ebx
jne 	L112
cmp 	DWORD PTR [64+esp],	esi
je 	L128
cmp 	DWORD PTR [48+esp],	esi
je 	L117
L112: ; basic label
cmp 	DWORD PTR [64+esp],	esi
jne 	L114
L128: ; basic label
cmp 	DWORD PTR [68+esp],	esi
jne 	L114
cmp 	DWORD PTR [60+esp],	ebx
je 	L114
cmp 	ebx,	ebp
jne 	L114
mov 	edi,	DWORD PTR [68+esp]
mov 	DWORD PTR [24+esp],	edi
jmp 	L113

align 4
L114: ; basic label
cmp 	ebx,	esi
je 	L117
mov 	eax,	ebx
and 	eax,	2078178270
shr 	eax,	1
mov 	edx,	esi
and 	edx,	2078178270
shr 	edx,	1
add 	eax,	edx
mov 	edx,	ebx
and 	edx,	esi
and 	edx,	69272609
add 	eax,	edx
mov 	DWORD PTR [24+esp],	eax
jmp 	L113

align 4
L117: ; basic label
mov 	DWORD PTR [24+esp],	ebx
L113: ; basic label
cmp 	ebx,	esi
jne 	L119
cmp 	DWORD PTR [52+esp],	ebx
jne 	L119
mov 	edi,	DWORD PTR [16+esp]
cmp 	DWORD PTR [56+esp],	edi
je 	L119
mov 	edi,	DWORD PTR [36+esp]
cmp 	DWORD PTR [16+esp],	edi
je 	L124
L119: ; basic label
mov 	edi,	DWORD PTR [56+esp]
cmp 	DWORD PTR [16+esp],	edi
jne 	L121
mov 	edi,	DWORD PTR [68+esp]
cmp 	DWORD PTR [16+esp],	edi
jne 	L121
cmp 	DWORD PTR [52+esp],	ebx
je 	L121
cmp 	ebx,	ebp
jne 	L121
mov 	edi,	DWORD PTR [16+esp]
mov 	DWORD PTR [20+esp],	edi
jmp 	L43

align 4
L121: ; basic label
cmp 	DWORD PTR [16+esp],	ebx
je 	L124
mov 	eax,	ebx
and 	eax,	2078178270
shr 	eax,	1
mov 	edx,	DWORD PTR [16+esp]
and 	edx,	2078178270
shr 	edx,	1
add 	eax,	edx
mov 	edx,	DWORD PTR [16+esp]
and 	edx,	ebx
and 	edx,	69272609
add 	eax,	edx
mov 	DWORD PTR [20+esp],	eax
jmp 	L43

align 4
L124: ; basic label
mov 	DWORD PTR [20+esp],	ebx
L43: ; basic label
mov 	eax,	DWORD PTR [24+esp]
sal 	eax,	16
or 	ebx,	eax
mov 	edi,	DWORD PTR [80+esp]
mov 	DWORD PTR [edi],	ebx
mov 	eax,	ecx
sal 	eax,	16
or 	eax,	DWORD PTR [20+esp]
mov 	DWORD PTR [1024+edi],	eax
add 	DWORD PTR [84+esp],	2
add 	edi,	4
mov 	DWORD PTR [80+esp],	edi
dec 	DWORD PTR [72+esp]
jmp 	L24

align 4
L25: ; basic label
pop 	ebx
pop 	esi
pop 	edi
pop 	ebp
add 	esp,	60
ret
 
Code32 ends
end
