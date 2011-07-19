; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80CORE.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include vdp.inc
include io.inc
include bit.inc
include fetch.inc
include flags.inc
include psg.inc
include pmode.inc
include v9938.inc

extrn iset:dword
extrn isetCBxx: near
extrn isetDDxx: near
extrn isetEDxx: near
extrn isetFDxx: near
extrn start_counter: near
extrn end_counter: near
extrn codetable: dword
extrn msxmodel: dword

public emulate
public emulate_break
public emulate_histogr
public emulate_compiler
public fetchcallback
public comp_position
public slot_change
public intcount
public index_mark
public emumode
public soundclocks
public first_line
public last_line
public emulate_fakeirq_msx2
public current_line
public halted
public clocks_line
public force_raster
public save_vdpregs

; DATA ---------------------------------------------------------------

dirtycode:
                db      0
                db      0
                db      0
                db      0
                db      0
                db      0
                db      0
                db      0

comp_position   dd      0
intcount        dd      0
index_mark      dd      0
current_line    dd      0
emumode         dd      0
soundclocks     dd      0
first_line      dd      0
last_line       dd      211
halted          dd      0
clocks_line     dd      212
force_raster    dd      0
already_draw    dd      0

align 4
save_vdpregs    db      64 dup (0)

; --------------------------------------------------------------------

; emulate ------------------------------------------------------------

BREAK           EQU     0
NOBREAK         EQU     1
TRAP            EQU     2
HISTOGRAM       EQU     3
COMPILER        EQU     4

NORMAL          EQU     0
FAST            EQU     1       
TURBO           EQU     2       

JUMP            macro   jump,jpoint,emtype,brtype

                jump    emtype&_&brtype&_&jpoint

                endm

EMULABEL        macro   point,emtype,brtype

                emtype&_&brtype&_&point&:

                endm

EMULATE         macro   emtype,brtype
                local   skip_sync

                xor     eax,eax
                xor     ecx,ecx
                mov     emumode,emtype
                mov     error,eax
                mov     exit_now,eax
                mov     interrupt,eax
                mov     firstscreen,1
                mov     ebp,clockcounter
                mov     clocksleft,ebp  
                movzx   edi,regpc
                movzx   edx,regaf

EMULABEL        loop,emtype,brtype

                ;and     edi,0ffffh
                
                if      brtype EQ BREAK
                cmp     edi,breakpoint
                JUMP    je,exit,emtype,brtype
                endif

                if      brtype EQ COMPILER
                mov     ecx,codetable
                inc     rcounter
                call    [ecx+edi*4]
                else                

                FETCHMACRO 0

                if      brtype EQ HISTOGRAM
                inc     dword ptr [offset histogr+eax*4]
                endif

                inc     rcounter
                call    [offset iset + eax*4]
                endif
                
                if      (emtype EQ FAST)
                  cmp   interrupt,1
                  JUMP  jne,loop,emtype,brtype
                  cmp   fakeirq,1
                  JUMP  je,fakeirq,emtype,brtype
                  JUMP  jmp,interrupt,emtype,brtype
                else
                  cmp   ebp,0
                  JUMP  jg,loop,emtype,brtype
                endif

                if      (brtype EQ TRAP)
                mov     interrupt,1
                mov     exit_now,1
                endif

                cmp     fakeirq,1
                JUMP    je,fakeirq,emtype,brtype

                mov     eax,offset z80counter
                call    end_counter
                mov     eax,dword ptr [offset z80counter]
                mov     z80rate,eax
                
                call    compose_sound
                
                xor     eax,eax
                
                if      emtype EQ NORMAL
                cmp     truevsync,1
                je      skip_sync
                call    synch_emulation
skip_sync:
                endif

EMULABEL        interrupt,emtype,brtype

                pushad
                call    check_mouse

                if      (emtype EQ TURBO)
                
                cmp     interrupt,1
                JUMP    jne,turbo_skip,emtype,brtype
                call    process_frame
EMULABEL        turbo_skip,emtype,brtype
                
                else
                call    process_frame
                endif
                
                popad
                
                ; must be called without pushads
                call    z80paused

                mov     eax,offset z80counter
                call    start_counter
                xor     eax,eax
                
                inc     intcount
                mov     index_mark,1
                
                ;;;
                add     ebp,TC
                ;;;
                call    checkpsg
                mov     interrupt,0
                or      byte ptr [offset vdpstatus+2],BIT_6                

                ; check for fast forward key
                cmp     fastforward,1
                JUMP    je,exit,emtype,brtype

                cmp     error,1
                JUMP    je,exit,emtype,brtype
                cmp     exit_now,1
                JUMP    je,exit,emtype,brtype
                
                pushad
                call    set_keyboard_leds
                call    check_joystick
                call    check_client
                popad
                
                ; irq has arrived
                mov     iline,1

                test    byte ptr [vdpregs+1],00100000b
                JUMP    jz,vdpdisabled,emtype,brtype

                ; ???
                ;test    vdpstatus,BIT_7
                ;JUMP    jnz,loop,emtype,brtype
                
                call    set_vdp_interrupt
                
                cmp     iff1,1
                JUMP    jne,loop,emtype,brtype
                
                mov     iff1,0 
                mov     fakeirq,0
                inc     rcounter
                call    z80_interrupt
                JUMP    jmp,loop,emtype,brtype

EMULABEL        fakeirq,emtype,brtype

                mov     eax,0
                mov     ebp,clocksleft
                mov     fakeirq,0

                test    byte ptr [offset vdpregs+1],BIT_5
                JUMP    jz,loop,emtype,brtype
                ;
                mov     iff1,0
                inc     rcounter
                call    z80_interrupt
                JUMP    jmp,loop,emtype,brtype

EMULABEL        vdpdisabled,emtype,brtype

                call    set_vdp_interrupt
                JUMP    jmp,loop,emtype,brtype
                
EMULABEL        exit,emtype,brtype

                mov     regpc,di
                mov     regaf,dx
                if      emtype EQ FAST
                mov     clockcounter,0
                else
                mov     clockcounter,ebp
                endif
                call    speaker_shutup
                call    reset_adlib

                ; fall through !!!

                endm

FASTF           macro   jump_point

                cmp     fastforward,1
                jne     _ret
                mov     fastforward,0
                mov     ecx,oldmode
                xchg    ecx,emulatemode
                mov     oldmode,ecx
                jmp     jump_point

                endm

; EMULATE_MSX2 -------------------------------------------------------
; z80 pipeline for msx2

EMULATE_MSX2    macro emtype,brtype
                local   emulate_loop
                local   emulate_exit
                local   emulate_nextline
                local   emulate_continue
                local   emulate_continue_2
                local   emulate_norender
                local   turbo_skip
                local   skip_truevsync

                xor     eax,eax
                xor     ecx,ecx
                mov     emumode,emtype
                mov     error,eax
                mov     exit_now,eax
                mov     interrupt,eax
                mov     firstscreen,1
                mov     ebp,clocks_line
                mov     clocksleft,ebp  
                movzx   edi,regpc
                movzx   edx,regaf

emulate_loop:
                if      brtype EQ BREAK
                cmp     edi,breakpoint
                je      emulate_exit
                endif

                ; execute one z80 opcode
                FETCHMACRO 0
                inc     rcounter
                call    [offset iset + eax*4]

                cmp     ebp,0
                jg      emulate_loop
                
                add     ebp,clocks_line
                mov     ebx,clocks_line
                add     soundclocks,ebx

                add     masterclocklow,ebx
                mov     ebx,0
                adc     masterclockhigh,ebx

                mov     ebx,trclock_line
                add     trclock,ebx

                mov     already_draw,0

                mov     ebx,current_line
                
                movzx   esi,byte ptr [offset vdpregs+23]
                movzx   ecx,byte ptr [offset vdpregs+19]
                sub     ecx,esi
                add     ecx,3
                and     ecx,0FFh
                cmp     ebx,ecx 
                jne     emulate_continue

                ;cmp     ebx,212
                ;je      emulate_continue
                
                ;or      byte ptr [offset vdpstatus+1],BIT_0

                test    byte ptr [offset vdpregs+0],BIT_4
                jz      emulate_continue

                call    render_slice

                or      byte ptr [offset vdpstatus+1],BIT_0

                mov     iline,1
                
                cmp     iff1,1
                jne     emulate_continue
                
                call    remove_halted_condition
                inc     current_line
                mov     iff1,0 
                mov     fakeirq,0
                inc     rcounter
                call    z80_interrupt

                mov     ebx,current_line
                cmp     ebx,212
                je      emulate_nextline
                jmp     emulate_loop

emulate_continue:
                cmp     force_raster,1
                jne     emulate_continue_2

                call    render_slice
                mov     force_raster,0

emulate_continue_2:
                inc     ebx
                cmp     ebx,280
                jne     emulate_nextline

                mov     ebx,0
emulate_nextline:
                mov     current_line,ebx

                cmp     ebx,212
                jne     emulate_loop

                mov     eax,offset z80counter
                call    end_counter
                mov     eax,dword ptr [offset z80counter]
                mov     z80rate,eax
                
                call    compose_sound
                
                mov     eax,0
                
                if      emtype EQ TURBO
                cmp     interrupt,1
                jne     turbo_skip
                pushad
                call    check_mouse
                cmp     first_line,211
                ja      emulate_norender
                mov     last_line,211
                call    process_frame
emulate_norender:
                popad
turbo_skip:
                mov     last_line,211
                mov     first_line,0
                else
                
                cmp     truevsync,1
                je      skip_truevsync
                call    synch_emulation
skip_truevsync:
                
                pushad
                call    check_mouse
                cmp     first_line,211
                ja      emulate_norender
                mov     last_line,211
                call    process_frame
emulate_norender:
                mov     first_line,0
                popad
                endif
                
                ; must be called without pushads
                call    z80paused

                mov     eax,offset z80counter
                call    start_counter
                xor     eax,eax
                
                inc     intcount
                mov     index_mark,1
                
                mov     soundclocks,0
                call    checkpsg
                mov     interrupt,0

                cmp     fastforward,1
                je      emulate_exit
                cmp     error,1
                je      emulate_exit
                cmp     exit_now,1
                je      emulate_exit
                
                pushad
                call    set_keyboard_leds
                call    check_joystick
                call    check_client
                popad
                
                ; irq has arrived
                or      byte ptr [offset vdpstatus+0],BIT_7

                test    byte ptr [offset vdpregs+1],BIT_5
                jz      emulate_loop

                mov     iline,1

                cmp     iff1,1
                jne     emulate_loop
                
                call    remove_halted_condition
                mov     iff1,0 
                mov     fakeirq,0
                inc     rcounter
                call    z80_interrupt
                jmp     emulate_loop

emulate_exit:
                mov     regpc,di
                mov     regaf,dx
                mov     clockcounter,ebp
                call    speaker_shutup
                call    reset_adlib

                ;ret

                ; fall through

                endm

emulate_fakeirq_msx2:
                mov     eax,0
                
                test    byte ptr [offset vdpstatus+0],BIT_7
                jnz     emulate_fakeirq_horiz

                ;test    byte ptr [offset vdpregs+1],BIT_5
                ;jz      _ret

                jmp     emulate_irq_now

emulate_fakeirq_horiz:
                test    byte ptr [offset vdpstatus+1],BIT_0
                jnz     _ret

                ;test    byte ptr [offset vdpregs+0],BIT_4
                ;jz      _ret

emulate_irq_now:
                call    remove_halted_condition
                mov     iff1,0
                inc     rcounter
                call    z80_interrupt
                
                ret

remove_halted_condition:
                cmp     halted,1
                jne     _ret

                mov     halted,0
                inc     edi
                ret

; render_slice -------------------------------------------------------

render_slice:
                cmp     already_draw,1
                je      _ret

                pushad
                cmp     ebx,211
                jae     skip_render
                mov     last_line,ebx
                push    ebx
                call    render
                call    sprite_render
                call    set_adjust_exit
                pop     ebx
                mov     first_line,ebx
                inc     first_line
skip_render:
                mov     esi,offset vdpregs
                mov     edi,offset save_vdpregs
                mov     ecx,64/4
                rep     movsd

                popad

                mov     already_draw,1

                ret

; emulate ------------------------------------------------------------
; starts emulation, stop with any error

emulate:        
                cmp     msxmodel,0
                jne     emulate_msx2
                cmp     emulatemode,NORMAL
                jne     emulate1
                EMULATE NORMAL,NOBREAK
                FASTF   emulate
emulate1:       cmp     emulatemode,FAST
                jne     emulate2
                EMULATE FAST,NOBREAK
                FASTF   emulate
emulate2:       EMULATE TURBO,NOBREAK
                FASTF   emulate

emulate_msx2:
                cmp     emulatemode,TURBO
                je      emulate_msx2_turbo
                EMULATE_MSX2 NORMAL,NOBREAK
                FASTF   emulate_msx2
emulate_msx2_turbo:
                EMULATE_MSX2 TURBO,NOBREAK
                FASTF   emulate_msx2

; emulate_break ------------------------------------------------------
; starts emulation with breakpoint, stop with any error

emulate_break:        
                cmp     msxmodel,0
                jne     emulate_break_msx2
                cmp     emulatemode,NORMAL
                jne     emulate1_break
                EMULATE NORMAL,BREAK
                FASTF   emulate_break
emulate1_break: cmp     emulatemode,FAST
                jne     emulate2_break
                EMULATE FAST,BREAK
                FASTF   emulate_break
emulate2_break: EMULATE TURBO,BREAK
                FASTF   emulate_break

emulate_break_msx2:
                cmp     emulatemode,TURBO
                je      emulate_break_msx2_turbo
                EMULATE_MSX2 NORMAL,BREAK
                FASTF   emulate_break_msx2
emulate_break_msx2_turbo:
                EMULATE_MSX2 TURBO,BREAK
                FASTF   emulate_break_msx2

; emulate_trap -------------------------------------------------------
; starts emulation with trap, stop with any error

emulate_trap:        
                cmp     emulatemode,NORMAL
                jne     emulate1_trap
                EMULATE NORMAL,TRAP
                FASTF   emulate
emulate1_trap:  cmp     emulatemode,FAST
                jne     emulate2_trap
                EMULATE FAST,TRAP
                FASTF   emulate
emulate2_trap:  EMULATE TURBO,TRAP
                FASTF   emulate

; emulate_histogr ----------------------------------------------------
; starts emulation with histogram evaluation, stop with any error

emulate_histogr:        
                cmp     emulatemode,NORMAL
                jne     emulate1_histogr
                EMULATE NORMAL,HISTOGRAM
                FASTF   emulate
emulate1_histogr:  
                cmp     emulatemode,FAST
                jne     emulate2_histogr
                EMULATE FAST,HISTOGRAM
                FASTF   emulate
emulate2_histogr:  
                EMULATE TURBO,HISTOGRAM
                FASTF   emulate

; emulate_compiler ---------------------------------------------------
; starts emulation with compiler pipeline

emulate_compiler:        
                cmp     emulatemode,NORMAL
                jne     emulate1_compiler
                EMULATE NORMAL,COMPILER
                FASTF   emulate
emulate1_compiler:  
                cmp     emulatemode,FAST
                jne     emulate2_compiler
                EMULATE FAST,COMPILER
                FASTF   emulate
emulate2_compiler:  
                EMULATE TURBO,COMPILER
                FASTF   emulate

; SLOT_MACRO ---------------------------------------------------------

SLOT_MACRO      macro   page
                local   slot_macro_next
                local   slot_macro_exit

                cmp     byte ptr [offset dirtycode+page*2],0
                je      slot_macro_next
                mov     byte ptr [offset dirtycode+page*2],0
                push    edi
                mov     edi,codetable
                add     edi,16384*4*page
                mov     eax,offset fetchcallback
                mov     ecx,8192
                rep     stosd
                pop     edi
                mov     eax,0

slot_macro_next:
                cmp     byte ptr [offset dirtycode+page*2+1],0
                je      slot_macro_exit
                mov     byte ptr [offset dirtycode+page*2+1],0
                push    edi
                mov     edi,codetable
                add     edi,16384*4*page+8192*4
                mov     eax,offset fetchcallback
                mov     ecx,8192
                rep     stosd
                pop     edi
                mov     eax,0

slot_macro_exit:
                endm

; slot_change --------------------------------------------------------
; dirty all the code previously compiled in a slot change
; enter: esi = previous slot configuration
;        prim_slotreg = actual slot configuration
; warning: called form inside emulation 
;          (must preserve edx, edi, ebp, high eax=0)

slot_change:
                movzx   ecx,prim_slotreg
                and     ecx,3
                mov     ebx,esi
                and     ebx,3
                cmp     ecx,ebx
                je      slot_change_page1

                SLOT_MACRO 0

slot_change_page1:
                movzx   ecx,prim_slotreg
                and     ecx,1100b
                mov     ebx,esi
                and     ebx,1100b
                cmp     ecx,ebx
                je      slot_change_page2

                SLOT_MACRO 1

slot_change_page2:
                movzx   ecx,prim_slotreg
                and     ecx,110000b
                mov     ebx,esi
                and     ebx,110000b
                cmp     ecx,ebx
                je      slot_change_page3

                SLOT_MACRO 2

slot_change_page3:
                movzx   ecx,prim_slotreg
                and     ecx,11000000b
                mov     ebx,esi
                and     ebx,11000000b
                cmp     ecx,ebx
                je      _ret

                SLOT_MACRO 3

                ret

; fetch_multi --------------------------------------------------------

MULTI_SIZE      EQU     offset multi_callback_end - offset multi_callback

fetch_multi     macro   iset_table

                push    edi
                mov     edi,comp_position
                mov     esi,offset multi_callback
                mov     ecx,MULTI_SIZE
                rep     movsb
                pop     edi
                call    fetch1
                mov     esi,dword ptr [offset iset_table+eax*4]
                mov     ecx,comp_position
                mov     dword ptr [ecx+1],esi
                mov     esi,ecx
                add     comp_position,MULTI_SIZE
                mov     ecx,codetable
                mov     dword ptr [ecx+edi*4],esi
                ret
                endm

; fetchcallback ------------------------------------------------------
; null callback to fetch an opcode and place it in
; the code table

fetchcallback:
                mov     ecx,edi
                shr     ecx,13
                mov     byte ptr [offset dirtycode+ecx],1

                FETCHMACRO 0
                
                cmp     eax,018h
                je      fetchcallback_18

                cmp     eax,0C3h                
                je      fetchcallback_c3

                cmp     eax,0D3h
                je      fetchcallback_d3

                cmp     eax,0DBh
                je      fetchcallback_db

                cmp     eax,0CBh
                je      fetchcallback_cb

                cmp     eax,0DDh
                je      fetchcallback_dd

                cmp     eax,0EDh
                je      fetchcallback_ed

                cmp     eax,0FDh
                je      fetchcallback_fd

                mov     ecx,codetable
                mov     esi,dword ptr [offset iset+eax*4]
                mov     dword ptr [ecx+edi*4],esi
                ret

                push    edi
                mov     edi,comp_position
                mov     esi,offset callback_simple
                mov     ecx,offset callback_simple_end-offset callback_simple
                rep     movsb
                pop     edi
                mov     esi,dword ptr [offset iset+eax*4]
                mov     ecx,comp_position
                mov     dword ptr [ecx+1],esi
                mov     esi,ecx
                add     comp_position,offset callback_simple_end-offset callback_simple
                mov     ecx,codetable
                mov     dword ptr [ecx+edi*4],esi
                mov     eax,0
                ret


fetchcallback_18:
                call    fetch1
                cmp     al,0FEh
                je      fetchcallback_18_fast
                
                push    edi
                mov     edi,comp_position
                mov     esi,offset callback_18
                mov     ecx,offset callback_18_end-offset callback_18
                rep     movsb
                pop     edi
                call    fetch1
                movsx   esi,al
                lea     esi,[esi+edi+2]
                mov     ecx,comp_position
                mov     dword ptr [ecx+1],esi
                mov     esi,ecx
                add     comp_position,offset callback_18_end-offset callback_18
                mov     ecx,codetable
                mov     dword ptr [ecx+edi*4],esi
                ret

fetchcallback_18_fast:
                push    edi
                mov     edi,comp_position
                mov     esi,offset callback_18_fast
                mov     ecx,offset callback_18_fast_end-offset callback_18_fast
                rep     movsb
                pop     edi
                mov     esi,comp_position
                add     comp_position,offset callback_18_fast_end-offset callback_18_fast
                mov     ecx,codetable
                mov     dword ptr [ecx+edi*4],esi
                ret

fetchcallback_c3:
                push    edi
                mov     edi,comp_position
                mov     esi,offset callback_c3
                mov     ecx,offset callback_c3_end-offset callback_c3
                rep     movsb
                pop     edi
                call    fetchw1
                movzx   esi,ax
                mov     ecx,comp_position
                mov     dword ptr [ecx+1],esi
                mov     esi,ecx
                add     comp_position,offset callback_c3_end-offset callback_c3
                mov     ecx,codetable
                mov     dword ptr [ecx+edi*4],esi
                mov     eax,0
                ret

fetchcallback_d3:
                push    edi
                mov     edi,comp_position
                mov     esi,offset callback_d3
                mov     ecx,offset callback_d3_end-offset callback_d3
                rep     movsb
                pop     edi
                call    fetch1
                mov     esi,[offset outportxx+eax*4]
                mov     ecx,comp_position
                mov     dword ptr [ecx+1],esi
                mov     esi,ecx
                add     comp_position,offset callback_d3_end-offset callback_d3
                mov     ecx,codetable
                mov     dword ptr [ecx+edi*4],esi
                mov     eax,0
                ret

fetchcallback_db:
                push    edi
                mov     edi,comp_position
                mov     esi,offset callback_db
                mov     ecx,offset callback_db_end-offset callback_db
                rep     movsb
                pop     edi
                call    fetch1
                mov     esi,[offset inportxx+eax*4]
                mov     ecx,comp_position
                mov     dword ptr [ecx+1],esi
                mov     esi,ecx
                add     comp_position,offset callback_db_end-offset callback_db
                mov     ecx,codetable
                mov     dword ptr [ecx+edi*4],esi
                mov     eax,0
                ret

fetchcallback_cb:
                fetch_multi     isetCBxx

fetchcallback_dd:
                fetch_multi     isetDDxx

fetchcallback_ed:
                fetch_multi     isetEDxx

fetchcallback_fd:
                fetch_multi     isetFDxx

; multi_callback -----------------------------------------------------

multi_callback:
                mov     ebx,12345678h
                inc     edi
                inc     rcounter
                jmp     ebx
multi_callback_end:

; callback_c3 --------------------------------------------------------

callback_c3:
                mov     edi,12345678h
                sub     ebp,10+1
                ret
callback_c3_end:

; callback_simple ----------------------------------------------------

callback_simple:
                mov     ebx,12345678h
                call    ebx
                mov     ecx,codetable
                jmp     dword ptr [ecx+edi*4]
callback_simple_end:
                
callback_d3:
                mov     ecx,12345678h
                add     edi,2
                mov     bl,dh
                sub     ebp,11+1
                jmp     ecx
callback_d3_end:

callback_db:
                mov     ecx,12345678h
                add     edi,2
                call    ecx
                mov     dh,bl
                sub     ebp,11+1
                ret
callback_db_end:

callback_18:
                mov     edi,12345678h
                sub     ebp,12+1
                ret
callback_18_end:

callback_18_fast:
                mov     ebp,0
                ret
callback_18_fast_end:

code32          ends
                end


