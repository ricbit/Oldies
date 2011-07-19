; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: SERIAL.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc

public comport
public comaddr
public sessionmode

public set_com_baseaddr
public UART_init
public UART_send
public UART_receive
public UART_send_idstring
public UART_receive_idstring

; DATA ---------------------------------------------------------------
  
;UART_BAUDRATE   equ     12      ; 9600 bauds
;UART_BAUDRATE   equ     1       ; 115 kbauds
UART_BAUDRATE   equ     2       ; 55 kbauds
UART_LCRVAL     equ     01Bh


comport         dd      1
comaddr         dd      0
sessionmode     dd      0

comlut          dd      03F8h
                dd      02F8h
                dd      03E8h
                dd      02E8h

idstring        db      'BrMSX 1.74',0

; CODE ---------------------------------------------------------------

; set_com_baseaddr ---------------------------------------------------
; evaluate the correct base address for selected COM port

set_com_baseaddr:
                mov     eax,comport
                dec     eax
                mov     eax,[offset comlut+eax*4]
                mov     comaddr,eax
                ret

; UART_init ----------------------------------------------------------
; initializes the UART

UART_init:
                mov     ebx,comaddr

                lea     edx,[ebx+3]
                mov     al,080h
                out     dx,al

                lea     edx,[ebx]
                mov     al,UART_BAUDRATE
                out     dx,al

                lea     edx,[ebx+3]
                mov     al,UART_LCRVAL
                out     dx,al

                lea     edx,[ebx+4]
                mov     al,0
                out     dx,al

                ret

; UART_send ----------------------------------------------------------
; send a single char through the UART
; locks the computer until char is sent
; enter: al=char
; preserves al

UART_send:
                mov     ebx,comaddr
                lea     edx,[ebx+5]
                push    eax

UART_send_loop:                
                in      al,dx
                test    al,020h
                jz      UART_send_loop

                pop     eax
                mov     edx,ebx
                out     dx,al

                ret


; UART_receive -------------------------------------------------------
; receive a single char through the UART
; locks the computer until char is received
; exit: al=char

UART_receive:
                mov     ebx,comaddr
                lea     edx,[ebx+5]

UART_receive_loop:
                in      al,dx
                test    al,1
                jz      UART_receive_loop

                mov     edx,ebx
                in      al,dx
                ret

; UART_send_idstring -------------------------------------------------
; send a identification string

UART_send_idstring:
                mov     ecx,offset idstring

UART_send_idstring_loop:
                mov     al,[ecx]
                call    UART_send
                inc     ecx
                cmp     al,0
                jne     UART_send_idstring_loop
                ret

; UART_receive_idstring ----------------------------------------------
; receive the identification string

UART_receive_idstring:

                mov     ecx,offset idstring

UART_receive_idstring_loop:
                call    UART_receive
                cmp     al,[ecx]
                jne     UART_receive_idstring
                inc     ecx
                cmp     al,0
                jne     UART_receive_idstring_loop
                ret

code32          ends
                end

