; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: SYMDEB.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include io.inc
include pmode.inc
include print.inc
include debug.inc

extrn symbolic_debugger: dword
extrn prn_name: byte
extrn transf_buffer: dword
extrn printmsgp: near
extrn printhex2p: near
extrn printhex4p: near
extrn printnulp: near

public install_symdeb
public _printop322
public _printop321
public _printop312
public _printop412
public _printop422
public _printop2jr
public search_label
public enable_symbolic
public printleftd

; DATA ---------------------------------------------------------------

enable_symbolic dd      0
prn_size        dd      0
prn_image       dd      0
total_labels    dd      0
addr_table      dd      0
label_table     dd      0

leftbuffer      db      64 dup (32)

; --------------------------------------------------------------------

install_symdeb:
                cmp     symbolic_debugger,1
                jne     _ret

                ; create the address table
                mov     eax,1024*2
                call    _getmem
                jc      _ret
                mov     addr_table,eax

                ; create the label table
                mov     eax,1024*32
                call    _getmem
                jc      _ret
                mov     label_table,eax

                ; clear the label table
                mov     edi,eax
                mov     ecx,1024*32/4
                mov     eax,0
                rep     stosd

                ; read symbolic information from file
                mov     edx,offset prn_name
                call    open_file
                jc      _ret

                ; check file size
                call    read_size_file
                add     eax,16383
                and     eax,0FFFFC000h
                mov     prn_size,eax

                call    _getmem
                jc      _ret
                mov     prn_image,eax

                ; read the file from disk
                mov     ebx,prn_size
                shr     ebx,14
                mov     edi,prn_image
load_prn_image_loop:
                mov     ecx,16384
                mov     edx,transf_buffer
                push    ebx
                call    read_file
                pop     ebx
                mov     esi,transf_buffer
                mov     ecx,16384/4 
                rep     movsd
                dec     ebx
                jnz     load_prn_image_loop

                call    close_file

; --------------------------------------------------------------------

                ; search for the string "Symbols:"
                mov     ecx,prn_size
                mov     edi,prn_image

search_prn_loop:
                mov     al,'S' 
                repnz   scasb

                cmp     ecx,0
                je      _ret

                cmp     dword ptr [edi-1],'bmyS' 
                jne     search_prn_loop

                cmp     dword ptr [edi+3],':slo' 
                jne     search_prn_loop
                                          
; --------------------------------------------------------------------

                ; the string was found, now decode the labels
                mov     eax,edi
                sub     eax,prn_image
                add     edi,7
                mov     edx,addr_table
                mov     esi,label_table
                mov     ebp,esi

decode_labels_outer:
                inc     edi
                mov     al,[edi]

                cmp     al,0Ch
                je      decode_labels_escape
                
                cmp     al,'N'
                jne     decode_labels_digit

                cmp     dword ptr [edi],'F oN'
                je      _ret

decode_labels_digit:                
                call    isdigit
                cmp     al,16
                jz      decode_labels_outer

                movzx   ebx,al

                rept    3

                shl     ebx,4
                inc     edi
                mov     al,[edi]
                call    isdigit
                or      bl,al

                endm
                
                mov     word ptr [edx],bx
                add     edx,2
                add     edi,2
                inc     total_labels
                mov     ebp,esi
                add     esi,32

retrieve_name_loop:
                mov     al,[edi]
                cmp     al,020h
                je      decode_labels_outer
                cmp     al,09h
                je      retrieve_name_escape

                mov     byte ptr [ebp],al
                inc     ebp

retrieve_name_escape:
                inc     edi

                jmp     retrieve_name_loop

decode_labels_escape:
                inc     edi
                mov     al,[edi]
                cmp     al,0Dh
                je      decode_labels_outer
                jmp     decode_labels_escape

; --------------------------------------------------------------------

isdigit:
                cmp     al,'0'
                jb      isdigit_exit

                cmp     al,'9'
                ja      isdigit_alpha

                sub     al,'0'
                ret

isdigit_alpha:
                cmp     al,'A'
                jb      isdigit_exit

                cmp     al,'F'
                ja      isdigit_exit

                sub     al,'A'-10
                ret

isdigit_exit:
                mov     al,16
                ret

; --------------------------------------------------------------------

test_implementation:
                mov     ecx,total_labels
                mov     edi,addr_table
                mov     esi,label_table

test_implementation_loop:
                movzx   eax,word ptr [edi]
                add     edi,2
                pushad
                call    printdecimal
                popad

                mov     al,32
                call    printasc

                mov     eax,esi
                add     esi,32
                call    printnul

                call    crlf

                dec     ecx
                jnz     test_implementation_loop
                                
                ret

; --------------------------------------------------------------------
; search_label - search a label in the addr_table
; enter eax=address
; exit  eax=pointer to the label (null terminated)

search_label:
                push    ecx edi

                mov     edi,addr_table
                mov     ecx,total_labels

                ; check if there is any symbol on the table
                cmp     ecx,1
                jc      search_label_ret

                inc     ecx
                repnz   scasw
                
                cmp     ecx,1
                jc      search_label_ret

                sub     edi,addr_table
                shl     edi,4
                mov     eax,label_table
                add     eax,edi
                sub     eax,32

                pop     edi ecx
                or      eax,eax
                ret

search_label_ret:
                pop     edi ecx
                ret

; --------------------------------------------------------------------

_printop322:                
                call    printmsgp
                inc     edi
                call    fetchw
                
                cmp     enable_symbolic,0
                je      _printop322_nolabel
                call    search_label
                jc      _printop322_nolabel

                call    printnulp
                ret

_printop322_nolabel:
                call    printhex4p
                ret

; --------------------------------------------------------------------

_printop321:                
                call    printmsgp
                add     edi,2
                call    fetch
                call    printhex2p
                ret

; --------------------------------------------------------------------

_printop312:                
                call    printmsgp
                inc     edi
                call    fetchw

                cmp     enable_symbolic,0
                je      _printop312_nolabel
                call    search_label
                jc      _printop312_nolabel

                call    printnulp
                ret

_printop312_nolabel:
                call    printhex4p
                ret

; --------------------------------------------------------------------

_printop412:                
                call    printmsgp
                add     edi,2
                call    fetchw
                
                cmp     enable_symbolic,0
                je      _printop412_nolabel
                call    search_label
                jc      _printop412_nolabel

                call    printnulp
                ret

_printop412_nolabel:
                call    printhex4p
                ret

; --------------------------------------------------------------------

_printop422:
                call    printmsgp
                add     edi,2
                call    fetchw
                
                cmp     enable_symbolic,0
                je      _printop422_nolabel
                call    search_label
                jc      _printop422_nolabel

                call    printnulp
                ret

_printop422_nolabel:
                call    printhex4p
                ret
                
; --------------------------------------------------------------------

_printop2jr:                
                call    printmsgp
                inc     edi
                call    fetch
                movsx   eax,al
                lea     eax,[eax+edi+1]
                and     eax,0FFFFh
                
                cmp     enable_symbolic,0
                je      _printop2jr_nolabel
                call    search_label
                jc      _printop2jr_nolabel

                call    printnulp
                ret

_printop2jr_nolabel:
                call    printhex4p
                ret

; --------------------------------------------------------------------
; printleftd - print a null terminated string with left justifying
; enter eax=string, shouldn't modify any register

printleftd:
                push    esi ecx edi

                mov     esi,eax
                mov     edi,offset leftbuffer+24
                mov     ecx,32/4
                rep     movsd

                mov     ecx,0
                mov     edi,offset leftbuffer+24

printleftd_loop:
                mov     al,[edi]
                inc     ecx
                inc     edi
                or      al,al
                jnz     printleftd_loop

                mov     byte ptr [edi-1],':'
                mov     byte ptr [edi],0

                lea     eax,[offset leftbuffer+ecx]
                call    printnuld

                pop     edi ecx esi
                ret

; --------------------------------------------------------------------

code32          ends
                end


