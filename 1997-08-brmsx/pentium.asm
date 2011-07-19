; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: PENTIUM.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include pentium.inc
include pmode.inc

public pentiumfound
public mmxfound

public detect_cpu
public start_counter
public end_counter
public setup_profile
public end_profile

; DATA ---------------------------------------------------------------

align 4

pentiumfound    dd      0
mmxfound        dd      0
counter12       db      8 dup (0)
counter13       db      8 dup (0)

; CODE ---------------------------------------------------------------

; detect_cpu ---------------------------------------------------------
; this function detect the cpuid instruction
; and then use it to determine the processor type
; return eax=0 if cpuid is not found
; else return 3=386, 4=486, 5=pentium, 6=ppro

detect_cpu:
                pushfd
                pop     eax
                mov     ebx,eax
                xor     eax,200000h
                push    eax
                popfd
                pushfd
                pop     eax
                xor     eax,ebx
                jz      _ret
                xor     eax,eax
                inc     eax
                cpuid
                and     eax,0F00h
                shr     eax,8
                cmp     eax,5
                jb      _ret
                mov     pentiumfound,1
                test    edx,(1 SHL 23)
                jz      _ret
                mov     mmxfound,1
                ret

; start_counter ------------------------------------------------------
; this function starts a counter using the tsc
; enter eax=counter

start_counter:
                cmp     pentiumfound,1
                jne     _ret
                push    esi edx
                mov     esi,eax
                rdtsc
                mov     [esi],eax
                mov     [esi+4],edx
                pop     edx esi
                ret

; end_counter --------------------------------------------------------
; this function ends a counter using the tsc
; enter eax=counter

end_counter:
                cmp     pentiumfound,1
                jne     _ret
                push    esi edx
                mov     esi,eax
                rdtsc
                sub     eax,[esi]
                sbb     edx,[esi+4]
                mov     [esi],eax
                mov     [esi+4],edx
                pop     edx esi
                ret

; setup_profile ------------------------------------------------------
; this function setup the pentium msr to read two profile registers

setup_profile:
                cmp     pentiumfound,1
                jne     _ret
                xor     edx,edx
                ;                     msr 13          msr 12
                ;                     ------          ------
                mov     eax,00000000110101100000000011010111b
                mov     ecx,011h
                wrmsr
                mov     ecx,012h
                rdmsr
                mov     dword ptr [offset counter12],eax
                mov     dword ptr [offset counter12+4],edx
                mov     ecx,013h
                rdmsr
                mov     dword ptr [offset counter13],eax
                mov     dword ptr [offset counter13+4],edx
                ret

; end_profile --------------------------------------------------------
; this function ends the profiling
; return eax=counter for msr 12 and edx=counter for msr 13

end_profile:
                cmp     pentiumfound,1
                jne     _ret
                
                mov     ecx,012h
                rdmsr
                sub     eax,dword ptr [offset counter12]
                sbb     edx,dword ptr [offset counter12+4]
                mov     dword ptr [offset counter12],eax

                mov     ecx,013h
                rdmsr
                sub     eax,dword ptr [offset counter13]
                sbb     edx,dword ptr [offset counter13+4]
                mov     dword ptr [offset counter13],eax

                mov     eax,dword ptr [offset counter12]
                mov     edx,dword ptr [offset counter13]

                ret


code32          ends
                end

