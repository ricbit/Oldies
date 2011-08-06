; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80CORE.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include bit.inc
include io.inc
include vdp.inc
include psg.inc
include blit.inc
include fetch.inc
include pmode.inc
include saveload.inc
include mouse.inc
include vesa.inc

extrn iset: dword
extrn start_counter: near
extrn end_counter: near
extrn gamegear: dword
extrn sg1000: dword
extrn noise_table: byte
extrn blitbuffer: dword
extrn msxvram: dword
extrn redbuffer: dword
extrn coleco: dword
extrn msxram: dword
extrn codetable: dword

public emulate
public emulate_break
public emulate_histogr   
public emulate_fakeirq
public fetch_me
public compile_me
public lightgun_mask

; DATA ---------------------------------------------------------------

noise_counter   dd      0
noise_counter2  dd      0

lightgun_mask   db      0

; emulate ------------------------------------------------------------

BREAK           EQU     0
NOBREAK         EQU     1
TRAP            EQU     2
HISTOGRAM       EQU     3

NORMAL          EQU     0
FAST            EQU     1       
TURBO           EQU     2       

CONSOLE_SMS     EQU     0
CONSOLE_GG      EQU     1
CONSOLE_SG1000  EQU     2
CONSOLE_COLECO  EQU     3

EMULATE_GENERAL macro   brtype,console
                local   emulate_loop
                local   emulate_interrupt
                local   emulate_exit
                local   emulate_virq
                local   emulate_nmi
                local   emulate_hirq
                local   emulate_continue
                local   emulate_classic
                local   emulate_check_virq
                local   emulate_virq_continue
                local   emulate_endframe
                local   emulate_periodic_sms

                xor     eax,eax
                xor     ecx,ecx
                mov     error,eax
                mov     exit_now,eax
                mov     interrupt,eax
                mov     firstscreen,1
                movzx   edi,regpc
                movzx   edx,regaf

emulate_loop:

                ;and     edi,0ffffh
                
                if      brtype EQ BREAK
                cmp     edi,breakpoint
                je      emulate_exit
                endif

                ;if      console NE CONSOLE_COLECO
                
                FETCHMACRO 0

                if      brtype EQ HISTOGRAM
                inc     dword ptr [offset histogr+eax*4]
                endif

                inc     rcounter
                call    [offset iset + eax*4]

                ;else
                ;mov     esi,edi
                ;mov     ebx,edi
                ;shr     esi,13 
                ;and     ebx,01fffh                      
                ;mov     ecx,codetable
                ;inc     rcounter
                ;mov     esi,[offset mem+esi*4] 
                ;call    dword ptr [ecx+edi*4]
                ;endif
                
                cmp     ebp,0
                jg      emulate_loop

                add     ebp,TOTALCLOCKS
                add     soundclocks,TOTALCLOCKS
                
                if      console EQ CONSOLE_SMS
                
                cmp     nmi,1
                je      emulate_nmi

                endif
                
                cmp     linebyline,1
                jne     emulate_classic

                call    refresh_line_engine

emulate_classic:
                mov     ebx,currentline
                mov     al,byte ptr [offset vdpregs+8]
                mov     byte ptr [offset xscrollbuf+ebx],al
                
                inc     ebx                
                mov     currentline,ebx

                cmp     ebx,100
                jne     emulate_check_virq
                
                test    byte ptr [offset vdpregs+1],BIT_6
                setnz   al
                mov     display_enabled,eax

emulate_check_virq:

                if      console EQ CONSOLE_GG

                cmp     ebx,168
                jne     emulate_endframe
                
                call    periodic_tasks
                jmp     emulate_continue
emulate_endframe:
                endif

                cmp     ebx,194 ;193
                je      emulate_virq
                
                cmp     ebx,280
                jb      emulate_continue

                mov     currentline,0
                movzx   ecx,byte ptr [offset vdpregs+10]
                inc     ecx
                mov     linesleft,ecx

                jmp     emulate_loop

emulate_continue:
                dec     linesleft
                jz      emulate_hirq
                
                jmp     emulate_loop

emulate_nmi:
                mov     iff1,0
                mov     nmi,0
                call    emulIM
                mov     edi,066h
                jmp     emulate_loop

; end of screen - must perform all the other periodic tasks                

emulate_virq:
                cmp     gamegear,1
                je      emulate_periodic_sms

                call    periodic_tasks
emulate_periodic_sms:                

                cmp     exit_now,1
                je      emulate_exit

; Vertical interrupt is processed here      

                or      vdpstatus,BIT_7

                and     vdpstatus,NBIT_5
                mov     al,collision_found
                or      vdpstatus,al
                mov     collision_found,0

                test    byte ptr [offset vdpregs+1],BIT_5
                jz      emulate_continue 

                if      console NE CONSOLE_COLECO

                mov     iline,1
                cmp     iff1,1
                jne     emulate_continue 

                call    remove_halted_condition                
                
                mov     iff1,0
                mov     iff2,0
                inc     rcounter
                call    z80_interrupt

                jmp     emulate_loop

                else

                call    remove_halted_condition
                jmp     emulate_nmi

                endif

emulate_hirq:
                if      (console EQ CONSOLE_GG) OR (console EQ CONSOLE_SMS)
                
                movzx   ecx,byte ptr [offset vdpregs+10]
                inc     ecx
                mov     linesleft,ecx

                cmp     currentline,194 ;193
                jae     emulate_loop

                or      vdpstatus,BIT_6

                test    byte ptr [offset vdpregs+0],BIT_4
                jz      emulate_loop

                mov     iline,1
                cmp     iff1,1
                jne     emulate_loop

                call    remove_halted_condition                

                mov     iff1,0
                mov     iff2,0
                inc     rcounter
                call    z80_interrupt

                endif

                jmp     emulate_loop

emulate_exit:
                mov     regpc,di
                mov     regaf,dx
                ret

                endm

; remove_halted_condition --------------------------------------------
; resume emulation after a HALT opcode

remove_halted_condition:
                cmp     halted,1
                jne     _ret

                mov     halted,0
                inc     edi
                ret

; fetch_me -----------------------------------------------------------

fetch_me:
                FETCHMACRO 0
                jmp     [offset iset + eax*4]

; compile_me ---------------------------------------------------------

compile_me:
                FETCHMACRO 0
                mov     eax,dword ptr [offset iset + eax*4]
                mov     ecx,codetable
                mov     dword ptr [ecx+edi*4],eax
                mov     ecx,eax
                mov     eax,0
                jmp     ecx

; periodic_tasks -----------------------------------------------------
; perform all periodic tasks, like video updating
; and joystick sampling

periodic_tasks:
                mov     eax,offset z80counter
                call    end_counter
                mov     eax,dword ptr [offset z80counter]
                mov     z80rate,eax
                mov     eax,0

                mov     soundclocks,0

                call    compose_sound
                call    z80paused
                call    process_frame
                call    checkpsg
                call    check_joystick
                call    check_client
                call    log_interrupt
                call    check_mouse
                call    check_turned_off

                call    synch_emulation

                mov     eax,offset z80counter
                call    start_counter
                mov     eax,0

                ret

check_mouse:
                cmp     mouse_enabled,1
                je      check_mouse_pad

                cmp     lightgun,1
                jne     _ret
                
                pushad
                call    read_mouse
                mov     eax,mouseleft
                shl     eax,4
                and     eax,BIT_4
                xor     al,lightgun_mask
                mov     smsjoya,11101111b
                or      smsjoya,al
                popad
                ret

check_mouse_pad:
                pushad
                call    read_mouse
                
                mov     eax,mouseleft
                shl     eax,4
                and     eax,BIT_4
                xor     eax,BIT_4
                and     smsjoya,NBIT_4
                or      smsjoya,al
                
                mov     eax,mousex
                cmp     eax,256
                ja      check_mouse_pad_exit_15

                shr     al,4
                mov     bl,smsjoya
                and     bl,0F0h
                or      bl,al
                mov     smsjoya,bl
                popad
                ret

check_mouse_pad_exit_0:
                mov     al,smsjoya
                and     al,0F0h
                mov     smsjoya,al
                popad
                ret

check_mouse_pad_exit_15:
                mov     al,smsjoya
                and     al,0F0h
                or      al,0Fh
                mov     smsjoya,al
                popad
                ret

; --------------------------------------------------------------------

check_turned_off:
                cmp     turnedoff,1
                jne     _ret

                pushad

                mov     byte ptr [offset vdpregs+7],0
                call    set_border_color
                call    erase_border

                call    sound_off
                call    sound_on

check_turned_off_outer:
                call    draw_noise_screen
                call    convert_to_direct
                call    wait_vsync
                call    wait_next_vsync
                call    wait_next_vsync
                call    blit
                call    compose_purenoise
                
                cmp     turnedoff,1
                je      check_turned_off_outer

                mov     ecx,256*28*8/4
                mov     eax,0
                mov     edi,blitbuffer
                rep     stosd

                mov     ecx,16384/4
                mov     eax,0
                mov     edi,msxvram
                rep     stosd

                mov     ecx,512/4
                mov     eax,01010101h
                mov     edi,offset dirtypattern
                rep     stosd

                mov     firstscreen,1

                call    reset_autoframe
                call    really_clear
                call    force_dirty
                call    dirty_all_sprites
                call    update_tilecache
                call    blit

                mov     edi,msxram
                mov     ecx,32768/4
                mov     eax,0
                rep     stosd

                call    sound_off
                call    sound_on

                popad
                
                mov     edi,0
                mov     iff1,0
                mov     iff2,0

                ret

erase_border:
                cmp     noborder,1
                je      _ret

                cmp     videomode,0
                jne     _ret

                mov     edi,0A0000h
                sub     edi,_code32a
                mov     ecx,320*200/4
                mov     eax,0
                rep     stosd

                ret

convert_to_direct:
                cmp     videomode,4
                je      convert_to_direct_start

                cmp     videomode,8
                je      convert_to_direct_start

                cmp     videomode,6
                jne     _ret

convert_to_direct_start:
                mov     edi,redbuffer
                mov     ecx,256*192
                mov     esi,blitbuffer

convert_to_direct_loop:
                mov     al,[esi]
                or      al,al
                jz      convert_to_direct_zero
                mov     word ptr [edi],07FFFh
                jmp     convert_to_direct_next

convert_to_direct_zero:
                mov     word ptr [edi],0

convert_to_direct_next:
                inc     esi
                add     edi,2
                dec     ecx
                jnz     convert_to_direct_loop

                ret

; really_clear -------------------------------------------------------
; clear the screen to black, without any intermediate buffer

really_clear:
                cmp     videomode,0
                je      really_clear_0

                cmp     videomode,1
                je      really_clear_1

                cmp     videomode,2
                je      really_clear_2

                cmp     videomode,4
                je      really_clear_4

                cmp     videomode,6
                je      really_clear_4

                cmp     videomode,8
                je      really_clear_4

                ret

really_clear_0:
                mov     eax,0
                mov     ecx,320*200/4
                mov     edi,0A0000h
                sub     edi,_code32a
                rep     stosd
                ret

really_clear_1:
                mov     ebp,2
                jmp     really_clear_svga

really_clear_2:
                mov     ebp,3
                jmp     really_clear_svga

really_clear_4:
                mov     ebp,6
                jmp     really_clear_svga

really_clear_svga:
                mov     eax,0
really_clear_svga_loop:
                call    set_vesa_bank
                push    eax
                mov     eax,0
                mov     edi,0A0000h
                sub     edi,_code32a
                mov     ecx,65536/4
                rep     stosd
                pop     eax
                inc     eax
                dec     ebp
                jnz     really_clear_svga_loop
                ret

; emulate_fakeirq ----------------------------------------------------
; called from inside the EI handler
; if there's any interrupt pending

emulate_fakeirq:
                test    vdpstatus,BIT_7
                jz      emulate_fakeirq_horizontal

                test    byte ptr [offset vdpregs+1],BIT_5
                jz      emulate_fakeirq_horizontal

                jmp     emulate_fakeirq_go

emulate_fakeirq_horizontal:                
                test    vdpstatus,BIT_6
                jz      _ret 

                test    byte ptr [offset vdpregs+0],BIT_4
                jz      _ret 

emulate_fakeirq_go:
                call    remove_halted_condition                

                mov     iff1,0
                mov     iff2,0
                inc     rcounter
                call    z80_interrupt
                ret     

; EMULATE ------------------------------------------------------------
; call the z80 engine based on current console type

EMULATE         macro brtype
                local   emulate_gg
                local   emulate_sg1000
                local   emulate_coleco

                cmp     gamegear,1
                je      emulate_gg

                cmp     coleco,1
                je      emulate_coleco

                cmp     sg1000,1
                je      emulate_sg1000

                EMULATE_GENERAL brtype,CONSOLE_SMS

emulate_gg:
                EMULATE_GENERAL brtype,CONSOLE_GG

emulate_sg1000:
                EMULATE_GENERAL brtype,CONSOLE_SG1000

emulate_coleco:
                EMULATE_GENERAL brtype,CONSOLE_COLECO

                endm
                                                     
; emulate ------------------------------------------------------------
; starts emulation, stop with any error

emulate:        
                EMULATE NOBREAK

; emulate_break ------------------------------------------------------
; starts emulation with breakpoint, stop with any error

emulate_break:        
                EMULATE BREAK

; emulate_histogr ----------------------------------------------------
; starts emulation with histogram evaluation, stop with any error

emulate_histogr:        
                EMULATE HISTOGRAM

; --------------------------------------------------------------------

; draw_noise_screen --------------------------------------------------
; draw noise on the blitbuffer
; enter: ebx = a random seed

draw_noise_screen:
                mov     edi,blitbuffer
                mov     ecx,256*28*8
                mov     ebx,0

                mov     edx,noise_counter
                mov     ebp,noise_counter2
                
draw_noise_screen_loop:
                mov     al,byte ptr [offset noise_table+edx]
                xor     al,byte ptr [offset noise_table+ebp]
                inc     edx
                inc     ebp
                and     al,15
                mov     [ebx+edi],al
                and     edx,16383
                cmp     ebp,16383
                sbb     esi,esi
                and     ebp,esi
                inc     ebx
                dec     ecx
                jnz     draw_noise_screen_loop

                mov     eax,01010101h
                mov     ecx,32*28/4
                mov     edi,offset dirtyname
                rep     stosd
                
                mov     noise_counter,edx
                mov     noise_counter2,ebp

                ret


code32          ends
                end


