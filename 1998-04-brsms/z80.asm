; --------------------------------------------------------------------
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: Z80.ASM                                                      
; -------------------------------------------------------------------- 
        
        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

extrn msxrom: near
extrn msxvram: dword
extrn cart1: dword
extrn pset: near
extrn isetCBxx: near
extrn isetDDxx: near
extrn isetEDxx: near
extrn isetFDxx: near
extrn emulEDFF: near
extrn start_counter: near
extrn end_counter: near
extrn iset: dword
extrn emulCB: near
extrn emulDD: near
extrn emulED: near
extrn emulFD: near
extrn emulFF: near
extrn emulXX: near
extrn soundbuffer: dword
extrn timebuffer: dword
extrn sccram: dword
extrn msxram: dword
extrn blitbuffer: dword
extrn gamegear: dword
extrn cart_sram: dword
extrn sc3000: dword

include io.inc
include vdp.inc
include psg.inc
include debug.inc
include serial.inc
include bit.inc
include blit.inc
include opcode.inc
include z80supp.inc
include pmode.inc
include gui.inc
include fetch.inc
include flags.inc
include z80sing.inc
include mouse.inc
include joystick.inc
include drive.inc
include saveload.inc
include vdp_sg.inc

public checkpsg
public compose_sound
public check_joystick
public check_client
public set_vdp_interrupt
public synch_emulation
public z80paused
public z80_interrupt
public process_frame
public set_keyboard_leds
public emulIM
public currentline
public lookahead
public outemul01_gg
public inemul01_gg
public fmtouched
public outemul7F_log
public outemul7F
public video_vsync
public memlock
public statusmask
public pad_enabled
public inemulE0_coleco
public outemulC0_coleco
public outemul80_coleco

public fetch
public fetch1
public fetchw
public fetchw1
public readmem
public readmemw
public writemem
public writememw
public trace
public print
public outemulXX
public inemulXX
public outportxx
public inportxx
public histogr
public error
public imtype
public iline
public clocksleft
public psgpos
public psgclocks
public psgclear
public sccdetected
public sccenabled
public newleds
public smsjoya
public smsjoyb
public rommask
public smspalette
public mapperblock
public country
public iff2
public fakeirq
public cpu_frames

public outemul99
public outemul98
public outemulDE
public inemulDE
public inemul99
public inemul98

public vdpcond
public vdppalcond
public vdppaladdr
public vdpaddress
public linesleft

public opsubreg
public opsbcreg
public opadcreg
public opaddreg
public opcpreg

public breakpoint
public iff1
public interrupt
public vdpstatus
public rcounter
public rmask
public regi
public emulatemode
public megarommode
public psgreg
public prim_slotreg
public z80rate
public z80counter
public reset_flag
public sccregs
public inemul00_gg
public inemul05_gg
public outemulBE_gg
public vdptemp
public halted
public fastforward

public slot0
public slot1
public slot2
public slot3
public mem
public turnedoff

public regaf
public regbc
public reghl
public regde
public regsp
public regpc
public regix
public regiy
public rega
public regf
public regb
public regc
public regd
public rege
public regh
public regl
public regsph
public regspl
public regixh
public regixl
public regiyh
public regiyl
public regeaf
public regebc
public regede
public regehl
public regeafl
public regebcl
public regedel
public regehll
public regesp
public regeix
public regeiy
public regepc
public vdpregs
public vsyncflag
public reset_cpu
public nmi
public nmisave
public soundclocks
public has_sram
public truevsync
public raster_scroll
public mouse_enabled

public BIT0_table
public BIT1_table
public BIT2_table
public BIT3_table
public BIT4_table
public BIT5_table
public BIT6_table
public BIT7_table
public LOGICAL_table
public ARITP_table
public ARITN_table
public OVERFLOW_table
public NEG_table
public INTERRUPT_table
public PVS53_table
public PVN53_table
public INC_table
public DEC_table
public CP_table
public CPL_table
public DAA_table
public DAA_select_table
public LDI_table
public frametime
public collision_found
public padstatus
public par1
public autoframe

; DATA ---------------------------------------------------------------

align 4

include outport.inc
include inport.inc

include bit0.inc
include bit1.inc
include bit2.inc
include bit3.inc
include bit4.inc
include bit5.inc
include bit6.inc
include bit7.inc
include overflow.inc
include logical.inc
include aritp.inc
include aritn.inc
include pvs53.inc
include pvn53.inc
include neg.inc
include daa.inc
include daas.inc
include inc.inc
include dec.inc
include int.inc
include cp.inc
include cpl.inc
include ldi.inc

align 4

mem:
mem00           dd      ?
mem20           dd      ?
mem40           dd      ?
mem60           dd      ?
mem80           dd      ?
memA0           dd      ?
memC0           dd      ?
memE0           dd      ?

memlock:               
memlock00       dd      1
memlock20       dd      1
memlock40       dd      1
memlock60       dd      1
memlock80       dd      1
memlockA0       dd      1
memlockC0       dd      2
memlockE0       dd      2

slot:           
slot0:
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
slot1:
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
slot2:
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
slot3:
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1
                dd      ?
                dd      1

mapperblock:
                dd      0
                dd      0
                dd      0

; Z80 registers
align 4

breakpoint      dd      0
iff1            dd      0
iff2            dd      0
interrupt       dd      0
nmi             dd      0
nmisave         dd      0
error           dd      0
rcounter        dd      0        
clockcounter    dd      0
emulatemode     dd      0
megarommode     dd      0
z80counter      db      8 dup (0)
z80rate         dd      0
reset_flag      dd      0
imtype          dd      1
iline           dd      0
fakeirq         dd      0
clocksleft      dd      TOTALCLOCKS
linesleft       dd      255
halted          dd      0
fastforward     dd      0
currentline     dd      0
soundclocks     dd      0
rommask         dd      0
sramstate       dd      0
has_sram        dd      0
truevsync       dd      0
raster_scroll   dd      0
frametime       dd      0
cpu_frames      dd      0
collision_found db      0
rmask           db      0
regi            db      0
turnedoff       db      0
autoframe       db      1

; PAR codes
par1            dd      0
par2            dd      0
par3            dd      0
par4            dd      0

; VDP registers
align 4

vdpcond         dd      0
vdppalcond      dd      0
vdppaladdr      dd      0
vdpaddress      dw      0
                dw      0
vdpregs         db      16 dup (0)
vsyncflag       dd      0
vdptemp         db      0
vdpstatus       db      0
smspalette      db      64 dup (0)
lookahead       db      0
statusmask      db      03Fh

; PSG registers
align 4

psgcond         dd      0
psgclocks       dd      0
psgpos          dd      0
psgclear        dd      1
psgselect       db      0
psgreg          db      16 dup (0h)
psgjoya         db      00111111b
psgjoyb         db      00111111b
psgtemp         db      0

; SCC registers

sccregs         db      16 dup (0)
sccactive       dd      0
sccdetected     dd      0
sccenabled      dd      0

; FM registers
align 4

fmtouched       dd      0
fmregister      db      0
fmdetect        db      0
           
; SMS joystick

smsjoya         db      0ffh
smsjoyb         db      0ffh
ggbutton        db      080h
smsdummy        db      6+8 dup (0ffh)
country         db      0
serial_data_gg  db      0
padstatus       db      8
pad_enabled     db      0
smslastjoy      db      0ffh
mouse_enabled   db      0
colecomode      db      080h

; PPI registers
align 4

prim_slotreg    db      0
keyboard_line   db      0
keyboard_select db      0
newleds         db      0
oldleds         db      7

align 4

histogr         dd      256 dup (0)

align 4

regaf           dw      00h
                dw      00h
regbc           dw      00h
                dw      00h
regde           dw      00h
                dw      00h
reghl           dw      00h
                dw      00h
regix           dw      00h
                dw      00h
regiy           dw      00h
                dw      00h
regpc           dw      00h
                dw      00h
regsp           dw      0D000h
                dw      00h
regafl          dw      00h
                dw      00h
regbcl          dw      00h
                dw      00h
regdel          dw      00h
                dw      00h
reghll          dw      00h
                dw      00h

rega            equ     byte ptr [offset regaf+1]
regf            equ     byte ptr [offset regaf+0]
regb            equ     byte ptr [offset regbc+1]
regc            equ     byte ptr [offset regbc+0]
regd            equ     byte ptr [offset regde+1]
rege            equ     byte ptr [offset regde+0]
regh            equ     byte ptr [offset reghl+1]
regl            equ     byte ptr [offset reghl+0]
regixh          equ     byte ptr [offset regix+1]
regixl          equ     byte ptr [offset regix+0]
regiyh          equ     byte ptr [offset regiy+1]
regiyl          equ     byte ptr [offset regiy+0]
regsph          equ     byte ptr [offset regsp+1]
regspl          equ     byte ptr [offset regsp+0]

regeaf          equ     dword ptr [offset regaf]
regebc          equ     dword ptr [offset regbc]
regede          equ     dword ptr [offset regde]
regehl          equ     dword ptr [offset reghl]
regeix          equ     dword ptr [offset regix]
regeiy          equ     dword ptr [offset regiy]
regepc          equ     dword ptr [offset regpc]
regesp          equ     dword ptr [offset regsp]
regeafl         equ     dword ptr [offset regafl]
regebcl         equ     dword ptr [offset regbcl]
regedel         equ     dword ptr [offset regdel]
regehll         equ     dword ptr [offset reghll]

vdpaddressh     equ     byte ptr [offset vdpaddress+1]
vdpaddressl     equ     byte ptr [offset vdpaddress+0]
vdpaddresse     equ     dword ptr [offset vdpaddress]

SYSTEM_SMS      EQU     0
SYSTEM_GG       EQU     1

; fetch --------------------------------------------------------------
; fetch a byte from Z80 memory
; in, edi: address
; out, al: byte
; affect: esi,ebx

fetch:          
                FETCHMACRO 0
                ret

; fetch1 -------------------------------------------------------------
; fetch the next byte from Z80 memory
; in, edi: (address-1)
; out, al: byte
; affect: esi,ebx

fetch1:
                FETCHMACRO 1
                ret

; fetchw -------------------------------------------------------------
; fetch a word from Z80 memory
; in, edi: address
; out, ax: word
; affect: esi,ebx

fetchw:
                FETCHWMACRO     0

; fetchw1 ------------------------------------------------------------
; fetch the next word from Z80 memory
; in, edi: (address-1)
; out, ax: word
; affect: esi,ebx

fetchw1:
                FETCHWMACRO     1

; readmem ------------------------------------------------------------
; read a byte from Z80 memory
; in, ecx: address
; out, al: byte
; affect: esi,ebx

readmem:        mov     esi,ecx                         ; clock 1 U
                mov     ebx,ecx                         ; clock 1 V
                shr     esi,13                          ; clock 2 U
                and     ebx,01fffh                      ; clock 2 V
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     al,byte ptr [esi+ebx]           ; clock 6 U [AGI]
                ret

; readmemw -----------------------------------------------------------
; read a word from Z80 memory
; in, ecx: address
; out, ax: word
; affect: esi,ebx

readmemw:        
                mov     ebx,ecx                         ; clock 1 U
                mov     esi,ecx                         ; clock 1 V
                and     ebx,01FFFh                      ; clock 2
                cmp     ebx,01FFFh                      ; clock 3 U
                je      readmemw_slow                   ; clock 3 V
                shr     esi,13                          ; clock 4
                mov     esi,[offset mem+esi*4]          ; clock 6 [AGI]
                mov     ax,word ptr [esi+ebx]           ; clock 8 [AGI]
                ret

readmemw_slow:
                inc     ecx
                call    readmem
                dec     ecx
                mov     ah,al
                call    readmem
                ret

; writemem -----------------------------------------------------------
; write a byte to Z80 memory
; in, ecx: address
; in, al: byte
; affect: esi,ebx

writemem:       mov     esi,ecx                         ; clock 1 U
                shr     esi,13                          ; clock 2 U
                ; lock
                mov     ebx,[offset memlock+esi*4]

                cmp     ebx,0
                je      writemem_go

                cmp     ebx,3
                je      writemem_coleco

                cmp     ebx,1
                je      _ret
                
                cmp     ebx,2
                je      writemem_par

writemem_go:                
                mov     ebx,ecx
                and     ebx,01fffh                      ; clock 2 V
                
                cmp     ecx,0fffch
                jae     writemem_register
writemem_ram:                
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     byte ptr [esi+ebx],al           ; clock 6 U [AGI]
                ret

writemem_coleco:
                mov     ebx,ecx
                and     ebx,03ffh              
                
                mov     esi,[offset mem+esi*4] 
                irp     i,<0,1,2,3,4,5,6,7>
                mov     byte ptr [esi+ebx+0400h*i],al           
                endm
                ret

writemem_par:
                cmp     ecx,par1
                je      _ret
                cmp     ecx,par2
                je      _ret
                cmp     ecx,par3
                je      _ret
                cmp     ecx,par4
                je      _ret
                
                mov     ebx,ecx
                and     ebx,01fffh                      ; clock 2 V
                
                cmp     ecx,0fffch
                jae     writemem_register
                
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     byte ptr [esi+ebx],al           ; clock 6 U [AGI]
                ret



writemem_register:
                cmp     sc3000,1
                je      writemem_ram

                cmp     ecx,0FFFCh
                je      writemem_select

                cmp     ecx,0FFFFh
                je      writemem_sram

writemem_mapper: 
                and     eax,rommask
                
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     byte ptr [esi+ebx],al           ; clock 6 U [AGI]
                
                sub     ebx,01ffdh
                mov     dword ptr [offset mapperblock+ebx*4],eax
                shl     eax,14
                add     eax,cart1
                mov     dword ptr [offset mem+ebx*8],eax
                add     eax,2000h
                mov     dword ptr [offset mem+ebx*8+4],eax
                xor     eax,eax
                ret

writemem_select:
                test    al,BIT_3
                jz      writemem_select_rom

                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     byte ptr [esi+ebx],al           ; clock 6 U [AGI]
                
                and     eax,100b
                shl     eax,12
                add     eax,cart_sram
                mov     dword ptr [offset mem+4*4],eax
                add     eax,2000h
                mov     dword ptr [offset mem+5*4],eax
                mov     dword ptr [offset memlock+4*4],0
                mov     dword ptr [offset memlock+5*4],0
                mov     sramstate,1
                mov     has_sram,1
                mov     eax,0
                ret

writemem_select_rom:
                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     byte ptr [esi+ebx],al           ; clock 6 U [AGI]
                
                mov     eax,dword ptr [offset mapperblock+2*4]
                shl     eax,14
                add     eax,cart1
                mov     dword ptr [offset mem+4*4],eax
                add     eax,2000h
                mov     dword ptr [offset mem+5*4],eax
                mov     dword ptr [offset memlock+4*4],1
                mov     dword ptr [offset memlock+5*4],1
                mov     sramstate,0
                mov     eax,0
                ret


writemem_sram:
                cmp     sramstate,0
                je      writemem_mapper

                mov     esi,[offset mem+esi*4]          ; clock 4 U [AGI]
                mov     byte ptr [esi+ebx],al           ; clock 6 U [AGI]
                
                and     eax,rommask
                mov     dword ptr [offset mapperblock+2*4],eax
                mov     eax,0
                ret

; writememw ----------------------------------------------------------
; write a word to Z80 memory
; in, ecx: address
; in, ax: word
; affect: esi,ebx

writememw:      
writememw_slow:
                push    eax
                mov     ah,0
                call    writemem
                pop     eax
                shr     eax,8
                inc     ecx
                call    writemem
                dec     ecx
                ret

; trace --------------------------------------------------------------
; executes only the next instruction
; in: edi = regpc , eax = 0

trace:
                call    fetch
                inc     rcounter
                call    [offset iset + eax*4]
                mov     regpc,di
                mov     regaf,dx
                ret

; set_vdp_interrupt --------------------------------------------------

set_vdp_interrupt:
                or      vdpstatus,10000000b
                ret

; compose_sound ------------------------------------------------------

compose_sound:
                mov     eax,offset psgcounter
                call    start_counter
                call    compose_soundstream
                mov     eax,offset psgcounter
                call    end_counter
                mov     eax,dword ptr [offset psgcounter]
                mov     psgrate,eax
                ret
                
; synch_emulation ----------------------------------------------------

synch_emulation:
                cmp     fastforward,1
                je      _ret
                
                cmp     truevsync,1
                je      _ret

                cmp     autoframe,1
                je      synch_emulation_autoframe

                cmp     interrupt,1
                jne     synch_emulation
                mov     interrupt,0
                ret

synch_emulation_autoframe:
                push    eax
synch_emulation_autoframe_loop:
                mov     eax,cpu_frames
                cmp     eax,time_base
                jae     synch_emulation_autoframe_loop

                pop     eax
                ret

; checkpsg -----------------------------------------------------------

checkpsg:
                cmp     psgclear,1
                je      checkpsg_clear
                add     psgclocks,59602 ;55440 ;TOTALCLOCKS
                ret

checkpsg_clear:
                mov     psgclocks,0
                mov     psgclear,0
                ret

; process_frame ------------------------------------------------------
; process a frame and blit the result

process_frame:
                cmp     autoframe,1
                jne     process_frame_normal

                inc     cpu_frames
                mov     eax,cpu_frames
                cmp     eax,time_base
                jb      _ret

                cmp     fastforward,1
                jne     process_frame_start

                cmp     interrupt,1
                jne     _ret
                jmp     process_frame_start

process_frame_normal:                
                cmp     fastforward,0
                je      process_frame_go

                cmp     interrupt,1
                jne     _ret

process_frame_go:
                dec     on_off
                jnz     _ret

process_frame_start:
                pushad

                mov     eax,framerate
                mov     on_off,eax

                inc     frames_drawed

                call    pre_dirty

                call    video_processing

                mov     eax,offset blitcounter
                call    start_counter
                call    blit
                call    dirty_bargraph
                mov     eax,offset blitcounter
                call    end_counter
                mov     eax,dword ptr [offset blitcounter]
                mov     blitrate,eax

                popad

                ret

; video_vsync --------------------------------------------------------
                
video_vsync:
                cmp     fastforward,0
                jne     process_frame_vsyncskip

                cmp     truevsync,1
                je      process_frame_vsync

                cmp     vsyncflag,1
                jne     process_frame_vsyncskip

process_frame_vsync:
                call    wait_vsync

process_frame_vsyncskip:
                ret

; video_processing ---------------------------------------------------
; perform all video processing including render, sprite and gui

video_processing:
                mov     eax,offset rendercounter
                call    start_counter
                call    render
                call    init_skip_buffer
                mov     eax,offset rendercounter
                call    end_counter
                mov     eax,dword ptr [offset rendercounter]
                mov     renderrate,eax

                mov     eax,offset spritecounter
                call    start_counter
                call    sprite_render
                mov     eax,offset spritecounter
                call    end_counter
                mov     eax,dword ptr [offset spritecounter]
                mov     spriterate,eax

                mov     eax,offset guicounter
                call    start_counter
                call    draw_gui
                mov     eax,offset guicounter
                call    end_counter
                mov     eax,dword ptr [offset guicounter]
                mov     guirate,eax

                ret

; z80_interrupt ------------------------------------------------------
; perform a Z80 interrupt
; this is sensitive to IM 1 and IM 2 differences

z80_interrupt:
                cmp     imtype,2
                je      z80_interrupt_im2

                ; IM 0 and IM 1
                call    emulIM
                mov     edi,038h
                ret

z80_interrupt_im2:
                ; IM 2
                call    emulIM
                mov     ch,regi
                mov     cl,0FFh
                call    readmemw
                mov     edi,eax
                mov     eax,0
                ret

PUSHREGW        IM,edi,0

; pre_dirty ----------------------------------------------------------
; this routine pre-dirty some parts of screen
; used for transparency effects, like in PSG GRAPH routine

pre_dirty:
                ret

; check_mouse --------------------------------------------------------
; if the mouse button is pressed, then start the GUI 
; and pause emulation

check_mouse:
                pushad
                call    read_mouse
                cmp     mouseleft,1
                jne     check_mouse_end

                mov     cpupaused,1

check_mouse_end:
                popad
                ret

; check_client -------------------------------------------------------
; if the emulator is in a SERVER session
; then this function call the client to get 
; joystick information

check_client:
                cmp     sessionmode,1
                jne     _ret

                pushad
                call    UART_send_idstring
                call    UART_receive
                and     smsjoya,00111111b
                mov     bl,al
                shl     bl,6
                or      smsjoya,bl
                and     smsjoyb,11110000b
                mov     bl,al
                shr     bl,2
                and     bl,1111b
                or      smsjoyb,bl
                popad
                ret

; set_keyboard_leds --------------------------------------------------
; set the keyboard leds

set_keyboard_leds:
                push    eax
                mov     al,newleds
                cmp     al,oldleds
                je      set_keyboard_leds_exit
                pushad
                mov     bl,newleds
                mov     oldleds,bl
                call    setkb
                popad
                pop     eax
                ret

set_keyboard_leds_exit:
                pop     eax
                ret

; check_joystick -----------------------------------------------------
; check the joystick status

check_joystick:
                cmp     joyenable,0
                je      _ret

                ;push    eax
                pushad
                call    read_joystick
                cmp     joyenable,2
                je      check_joystick_b

                and     smsjoya,11000000b
                and     al,00111111b
                or      smsjoya,al
                jmp     check_joystick_exit
check_joystick_b:
                mov     bl,al
                shl     bl,6
                and     smsjoya,00111111b
                or      smsjoya,bl
                shr     al,2
                and     al,1111b
                and     smsjoyb,11110000b
                or      smsjoyb,al

check_joystick_exit:
                ;pop     eax
                popad
                ret

; z80paused ----------------------------------------------------------
; pauses the Z80 and starts the gui
; must preserve ebp,eax,edx,edi,esp
; also check for random events like the save game

z80paused:
                cmp     savenow,1
                je      event_savestate

                cmp     loadnow,1
                je      event_loadstate

                cmp     savesnap,1
                je      event_savesnap

                cmp     cpupaused,1
                jne     _ret
                
                push    ebp eax edx edi

                mov     reset_flag,0
                mov     regeaf,edx
                mov     regepc,edi

                call    sound_off
                call    start_gui
                call    sound_on

                pop     edi edx eax ebp

                cmp     reset_flag,1
                jne     _ret

                mov     edx,regeaf
                mov     edi,regepc
                mov     reset_flag,0

                ret

event_savestate:
                mov     savenow,0
                pushad
                call    save_state
                popad
                ret

event_loadstate:
                mov     loadnow,0
                pushad
                call    load_state
                call    refresh_all_screen
                popad
                ;mov     edi,regepc
                ;mov     edx,regeaf
                ;mov     ebp,clocksleft
                ret

event_savesnap:
                mov     savesnap,0
                pushad
                call    sound_off
                call    save_snapshot_pcx
                call    sound_on
                popad
                ret

; reset_cpu ----------------------------------------------------------
; reset the MSX

reset_cpu:
                ; put the pc at address 0
                mov     regepc,0

                ; enable all ROM
                mov     bl,0

                ; disable interrupts
                mov     iff1,0

                ; clear vram
                mov     edi,msxvram
                mov     ecx,16384/4
                mov     eax,0
                rep     stosd

                ; clear psg registers
                mov     edi,offset psgreg
                mov     ecx,16/4
                mov     eax,0
                rep     stosd

                ; clear scc memory
                mov     edi,sccram
                mov     ecx,8192/4
                mov     eax,0
                rep     stosd

                ; clear scc registers
                mov     edi,offset sccregs
                mov     ecx,16/4
                mov     eax,0
                rep     stosd

                ; if a megarom is loaded, then init it
                cmp     dword ptr [offset slot1+16+4],2
                jne     reset_cpu_nomegarom

reset_cpu_nomegarom:

                ; inform to main routine that MSX is reseted
                mov     reset_flag,1
                ret

; refresh_all_screen -------------------------------------------------
; set all the dirty tables to force redraw of every internal buffer

refresh_all_screen:
                mov     edi,offset dirtyname
                mov     ecx,32*28/4
                mov     eax,01010101h
                rep     stosd
                
                mov     edi,offset dirtypattern
                mov     ecx,512/4
                rep     stosd

                mov     edi,offset dirty_palette
                mov     ecx,32/4
                rep     stosd

                mov     firstscreen,1
                mov     raster_scroll,1
                mov     border_updated,1
                mov     update_attr,1

                mov     ecx,32
                mov     esi,offset smspalette
                mov     edi,offset dynamic_palette
refresh_all_screen_loop:
                mov     al,[esi]
                or      al,080h
                irp     i,<0,020h,040h,060h,080h,0A0h,0C0h,0E0h>
                mov     [edi+i],al
                endm
                dec     ecx
                jnz     refresh_all_screen_loop

                ret

; print --------------------------------------------------------------
; prints only the next instruction
; in: edi = regpc , eax = 0

print:
                call    fetch
                call    [offset pset + eax*4]
                ret

; sound_buffer -------------------------------------------------------
; add a sound event to the sound buffer
; enter al=register, bl=value
; destroy ecx,ebx,esi
                
sound_buffer:
                movzx   ecx,al                
                add     ecx,offset psgreg
                mov     [ecx],bl

                mov     ecx,psgpos
                cmp     ecx,32768
                jae     _ret

                mov     esi,soundbuffer
                mov     [esi+ecx*2],al
                mov     [esi+ecx*2+1],bl

                mov     esi,timebuffer
                mov     ebx,TOTALCLOCKS
                sub     ebx,ebp
                add     ebx,psgclocks
                add     ebx,soundclocks
                mov     [esi+ecx*4],ebx

                inc     psgpos

                ret

; --------------------------------------------------------------------

; byte to be outputed must be in bl register

outemulXX:      ret

; --------------------------------------------------------------------
; port 01 - Serial communications data register

outemul01_gg:
                mov     serial_data_gg,bl
                ret

; --------------------------------------------------------------------
; port 3F - nationalization

outemul3F:
                mov     cl,bl
                and     cl,0Fh
                cmp     cl,5
                jne     outemul3F_clear
                and     smsjoyb,00111111b
                xor     bl,country
                mov     cl,bl
                and     cl,80h
                or      smsjoyb,cl
                mov     cl,bl
                and     cl,20h
                add     cl,cl
                or      smsjoyb,cl
                ret

outemul3F_clear:
                or      smsjoyb,11000000b
                ret

; --------------------------------------------------------------------
; port 7F - PSG with logging

outemul7F_log:
               ; call    log_psg_sample
                
                ; fall through

; --------------------------------------------------------------------
; port 7F - PSG

outemul7F:
                cmp     psgcond,1
                je      outemul7F_write
                mov     psgtemp,bl
                cmp     bl,080h
                jb      _ret
                test    bl,00010000b
                jz      outemul7F_setcond
                shr     bl,5
                and     bl,3
                add     bl,8
                mov     al,bl
                mov     bl,psgtemp
                and     bl,0Fh
                xor     bl,0Fh
                call    sound_buffer
                ret

outemul7F_setcond:
                mov     cl,bl
                and     cl,0F0h
                cmp     cl,0E0h
                je      outemul7F_setnoise
                mov     psgcond,1
                ret

outemul7F_setnoise:
                mov     al,6
                and     bl,7
                call    sound_buffer
                ret

outemul7F_write:
                mov     psgcond,0
                mov     al,psgtemp
                cmp     al,11100000b
                jae     _ret
                and     eax,0Fh
                and     ebx,03Fh
                shl     ebx,4
                or      ebx,eax
                push    ebx
                mov     al,psgtemp
                shr     al,5
                and     al,3
                shl     al,1
                call    sound_buffer
                pop     ebx
                mov     al,psgtemp
                shr     al,5
                and     al,3
                shl     al,1
                inc     al
                mov     bl,bh
                call    sound_buffer
                ret

; --------------------------------------------------------------------

outemul98:      
                mov     vdpcond,0
                mov     esi,msxvram
                mov     eax,vdpaddresse
                mov     ecx,eax
                inc     eax
                and     eax,03FFFh
                mov     vdpaddresse,eax
                xor     eax,eax
                cmp     imagetype,0
                je      outemul98_ret
                
                mov     eax,ecx
                shr     eax,6
                and     eax,0FFh
                mov     al,[offset vrammapping+eax]
                jmp     [offset screenselect+eax*4]
                
outemul98_ret:
                mov     [ecx+esi],bl
                ret

; --------------------------------------------------------------------

outemul99:      cmp     vdpcond,0
                jne     outemul99a
                mov     vdpcond,1
                mov     vdptemp,bl
                ret

outemul99a:     mov     vdpcond,0
                test    bl,10000000b
                jnz     outemul99b
                cmp     bl,01000000b
                jb      outemul99_read
                and     bl,00111111b
                mov     vdpaddressh,bl
                mov     bl,vdptemp
                mov     vdpaddressl,bl
                ret
outemul99_read:
                and     bl,00111111b
                mov     vdpaddressh,bl
                mov     bl,vdptemp
                mov     vdpaddressl,bl
                mov     ecx,vdpaddresse
                mov     esi,msxvram
                mov     bl,[esi+ecx]
                mov     lookahead,bl
                inc     ecx
                and     ecx,03FFFh
                mov     vdpaddresse,ecx
                ret

outemul99b:     and     ebx,00000111b
                mov     al,vdptemp
                mov     cl,byte ptr [offset vdpregs+ebx]
                cmp     cl,al
                je      _ret
                mov     byte ptr [offset vdpregs+ebx],al
                cmp     bl,7
                je      set_border_color
outemul99_update:
                mov     firstscreen,1
                jmp     eval_base_address

; --------------------------------------------------------------------
; port BE - VDP data port

VDP_DATA_PORT   macro   system
                local   outemulBE_palette
                local   outemulBE_sprite
                local   outemulBE_ret
                local   outemulBE_fast
                local   outemulBE_direct

                cmp     vdppalcond,1
                je      outemulBE_palette

                mov     eax,vdpaddresse
                mov     esi,eax
                add     eax,msxvram
                mov     ecx,esi
                shr     esi,5
                ;
                mov     lookahead,bl
                ;
                cmp     [eax],bl
                je      outemulBE_fast
                mov     [eax],bl
                inc     vdpaddress
                mov     byte ptr [offset dirtypattern+esi],1
                mov     vram_touched,1
                and     vdpaddress,03FFFh
                mov     esi,ecx
                sub     ecx,nametable
                jc      outemulBE_sprite
                cmp     ecx,32*28*2
                jae     outemulBE_sprite
                shr     ecx,1
                mov     byte ptr [offset dirtyname+ecx],1
outemulBE_sprite:
                sub     esi,sprattrtable
                jc      outemulBE_ret
                cmp     esi,100h
                jae     outemulBE_ret
                call    dirty_sprite
outemulBE_ret:
                mov     eax,0
                ret

outemulBE_fast:
                inc     vdpaddress
                mov     eax,0
                and     vdpaddress,03FFFh
                ret

outemulBE_palette:
                mov     eax,vdppaladdr
                inc     vdppaladdr

                if      system EQ SYSTEM_SMS
                and     vdppaladdr,01Fh
                else
                and     vdppaladdr,03Fh
                endif

                cmp     bl,byte ptr [offset smspalette+eax]
                je      _ret
                mov     [offset smspalette+eax],bl

                if      system EQ SYSTEM_GG
                shr     eax,1
                endif

                mov     byte ptr [offset dirty_palette+eax],1
                
                cmp     direct_color,1
                je      outemulBE_direct
                
                cmp     palette_raster,1
                jne     _ret
                
                or      bl,080h
                irp     i,<0,020h,040h,060h,080h,0A0h,0C0h,0E0h>
                mov     byte ptr [offset dynamic_palette+i+eax],bl
                endm

                ret

outemulBE_direct:
                if      system EQ SYSTEM_SMS
                
                push    edx
                mov     esi,0
                mov     ecx,ebx

                ; SMS color is 00BBGGRR

                ; R
                and     ebx,3
                mov     edx,ebx
                shl     edx,2
                or      ebx,edx
                shl     ebx,1+10
                or      esi,ebx

                ; G
                mov     ebx,ecx
                and     ebx,1100b
                mov     edx,ebx
                shr     edx,2
                or      ebx,edx
                shl     ebx,1+5
                or      esi,ebx

                ; B
                and     ecx,110000b
                mov     ebx,ecx
                shr     ebx,2
                or      ecx,ebx
                shr     ecx,1
                or      esi,ecx


                pop     edx
                mov     word ptr [offset direct_palette+eax*2],si

                else
                
                push    edx
                mov     esi,0
                movzx   ebx,word ptr [offset smspalette+eax*2]
                mov     ecx,ebx

                ; GG color is BBB0GGG0RRR0

                ; R
                and     ebx,1110b
                shl     ebx,1+10
                mov     edx,ebx
                shr     edx,3
                or      ebx,edx
                and     ebx,111110000000000b
                or      esi,ebx

                ; G
                mov     ebx,ecx
                and     ebx,11100000b
                shl     ebx,2
                mov     edx,ebx
                shr     edx,3
                or      ebx,edx
                and     ebx,1111100000b
                or      esi,ebx

                ; B
                and     ecx,111000000000b
                shr     ecx,7
                mov     edx,ecx
                shr     edx,3
                or      ecx,edx
                or      esi,ecx


                pop     edx
                mov     word ptr [offset direct_palette+eax*2],si

                
                endif
                ret

                endm

outemulBE:
                VDP_DATA_PORT SYSTEM_SMS

outemulBE_gg:
                VDP_DATA_PORT SYSTEM_GG

; --------------------------------------------------------------------
; port BF - VDP command port

outemulBF:
                cmp     vdpcond,1
                je      outemulBF_write

                mov     vdpcond,1
                mov     vdptemp,bl

                ret

outemulBF_write:
                mov     vdpcond,0
                mov     cl,bl
                
                and     cl,0F0h
                cmp     cl,080h
                jb      outemulBF_address

                cmp     cl,0C0h
                jae     outemulBF_palette

                cmp     cl,080h
                jne     outemulBF_address

outemulBF_register:
                and     ebx,0Fh
                mov     al,vdptemp
                mov     cl,[offset vdpregs+ebx]
                mov     [offset vdpregs+ebx],al
                cmp     ebx,1
                je      outemulBF_checkirq
                cmp     ebx,2
                je      outemulBF_nametable
                cmp     ebx,5
                je      outemulBF_sprattrtable
                cmp     ebx,7
                je      outemulBF_border
                cmp     ebx,8
                je      outemulBF_Xscroll
                cmp     ebx,9
                je      outemulBF_Yscroll
                ret

outemulBF_nametable:
                and     eax,14
                shl     eax,10
                mov     nametable,eax
                mov     eax,0
                ret

outemulBF_sprattrtable:
                and     eax,07Eh 
                shl     eax,7
                mov     sprattrtable,eax
                mov     eax,0
                mov     update_attr,1
                ret

outemulBF_Yscroll:
                cmp     al,cl
                je      _ret
                jmp     dirty_all_sprites

outemulBF_border:
                mov     border_updated,1
                ret

outemulBF_Xscroll:
                cmp     al,cl
                je      _ret
                cmp     currentline,193
                jae     dirty_all_sprites
                mov     raster_scroll,1
                jmp     dirty_all_sprites

outemulBF_checkirq:
                test    cl,BIT_5
                jnz     _ret
                test    al,BIT_5
                jz      _ret
                and     vdpstatus,NBIT_7
                ret

outemulBF_palette:
                mov     vdppalcond,1
                movzx   eax,vdptemp
                mov     vdppaladdr,eax

                cmp     gamegear,1
                je      outemulBF_palette_gg

                and     vdppaladdr,01Fh
                ret

outemulBF_palette_gg:
                and     vdppaladdr,03Fh
                ret

outemulBF_address:
                mov     ah,bl
                mov     al,vdptemp
                cmp     ax,03FFFh
                jbe     outemulBF_address_read
                and     ax,03FFFh
                mov     vdpaddress,ax
                mov     vdppalcond,0
                mov     eax,0
                ret

outemulBF_address_read:
                and     eax,03FFFh
                mov     esi,eax
                add     esi,msxvram
                mov     cl,[esi]
                mov     lookahead,cl
                inc     eax
                and     eax,03FFFh
                mov     vdpaddress,ax
                mov     vdppalcond,0
                mov     eax,0
                ret

; --------------------------------------------------------------------
; port F0 - FM register

outemulF0:
                mov     fmregister,bl
                mov     fmtouched,1
                ret

; --------------------------------------------------------------------
; port F1 - FM data

outemulF1:
                push    ebx
                mov     bl,fmregister
                call    log_psg_sample
                pop     ebx
                call    log_psg_sample
                ret
;
; --------------------------------------------------------------------
; port 7F - PSG with logging
;
;outemul7F_log:
                ;call    log_psg_sample
                
                ; fall through

; --------------------------------------------------------------------
; port DE - SC3000 keyboard

outemulDE:
                mov     keyboard_select,bl
                ret

; --------------------------------------------------------------------
; port 80 - Coleco joystick mode 1

outemul80_coleco:
                mov     colecomode,080h
                ret

; --------------------------------------------------------------------
; port C0 - Coleco joystick mode 2

outemulC0_coleco:
                mov     colecomode,0C0h
                ret

; --------------------------------------------------------------------

; byte to be inputed returns in bl register

inemulXX:       
                mov     bl,0FFh
                ret

; --------------------------------------------------------------------
; port 00 - START button / nationalization

inemul00_gg:
                mov     bl,ggbutton
                mov     al,country
                and     al,BIT_6
                xor     al,BIT_6
                or      bl,al
                ret

; --------------------------------------------------------------------
; port 01 - Serial communications data register

inemul01_gg:
                mov     bl,serial_data_gg
                ret

; --------------------------------------------------------------------
; port 05 - Serial communications status register

inemul05_gg:
                mov     bl,0
                ret

; --------------------------------------------------------------------
; port F2 - FM auto-detect

inemulF2:
                mov     bl,fmdetect
                ret

outemulF2:
                mov     fmdetect,bl
                ret

; --------------------------------------------------------------------
; port 7E - Current scanline

inemul7E:
                mov     ebx,currentline
                ;;;
                dec     ebx
                ;;;
                cmp     ebx,256
                jb      _ret
                mov     ebx,255
                ret

; --------------------------------------------------------------------

inemul98:       mov     ecx,msxvram
                mov     esi,vdpaddresse
                mov     bl,lookahead
                mov     bh,[ecx+esi]
                inc     esi
                and     esi,03FFFh
                mov     vdpaddresse,esi
                mov     lookahead,bh
                mov     vdpcond,0
                ret

; --------------------------------------------------------------------

inemul99:       mov     bl,vdpstatus
                and     vdpstatus,00111111b
                mov     vdpcond,0
                mov     iline,0
                ret

; --------------------------------------------------------------------
; port BE - VDP Data port

inemulBE:
                cmp     vdppalcond,1                
                je      inemulBE_palette

                mov     bl,lookahead
                mov     ecx,vdpaddresse
                mov     esi,msxvram
                mov     bh,[ecx+esi]
                inc     ecx
                and     ecx,03FFFh
                mov     vdpaddresse,ecx
                mov     lookahead,bh
                ret

inemulBE_palette:
                cmp     gamegear,1                
                je      inemulBE_palette_gg

                mov     eax,vdppaladdr
                inc     vdppaladdr
                and     vdppaladdr,01Fh
                mov     bl,byte ptr [offset smspalette+eax]
                ret

inemulBE_palette_gg:
                mov     eax,vdppaladdr
                inc     vdppaladdr
                and     vdppaladdr,03Fh
                mov     bl,byte ptr [offset smspalette+eax]
                ret

; --------------------------------------------------------------------
; port BF - VDP Status register

inemulBF:
                mov     bl,vdpstatus
                mov     cl,statusmask
                and     vdpstatus,cl
                mov     iline,0
                mov     vdpcond,0
                ret

; --------------------------------------------------------------------
; port DC - Joystick #1

inemulC0:
inemulDC:
                cmp     sc3000,1
                je      inemulDC_sc3000

                cmp     pad_enabled,1
                je      inemulDC_paddle

                cmp     lightgun,1
                je      inemulDC_lightgun
                
                mov     bl,smsjoya
                ret

inemulDC_lightgun:
                mov     bl,smsjoya
                or      bl,11101111b
                ret

inemulDC_paddle:
                cmp     mouse_enabled,1
                je      inemulDC_paddle_mouse

                cmp     joyenable,1
                jne     inemulDC_paddle_keyboard

                mov     bl,smsjoya
                and     bl,0F0h
                or      bl,padstatus
                ret

inemulDC_paddle_keyboard:
                mov     bl,smsjoya
                xor     bl,smslastjoy
                and     bl,smslastjoy
                mov     al,padstatus

                test    bl,BIT_2 ; left
                jz      inemulDC_paddle_keyboard_right
                cmp     al,0
                je      inemulDC_paddle_keyboard_right
                sub     al,2

inemulDC_paddle_keyboard_right:
                test    bl,BIT_3 ; right
                jz      inemulDC_paddle_keyboard_up
                cmp     al,14
                je      inemulDC_paddle_keyboard_up
                add     al,2

inemulDC_paddle_keyboard_up:
                test    bl,BIT_0 ; up
                jz      inemulDC_paddle_keyboard_down
                mov     al,8

inemulDC_paddle_keyboard_down:
                test    bl,BIT_1 ; down
                jz      inemulDC_paddle_keyboard_exit
                mov     al,8

inemulDC_paddle_keyboard_exit:

                mov     padstatus,al
                mov     bl,smsjoya
                and     bl,0F0h
                or      bl,padstatus

                mov     bh,smsjoya
                mov     smslastjoy,bh
                ret

inemulDC_paddle_mouse:
                mov     bl,smsjoya
                ret

inemulDC_sc3000:
                movzx   ebx,keyboard_select
                and     ebx,07h
                mov     bl,[offset smsjoya+ebx]
                ret

; --------------------------------------------------------------------
; port DD - Joystick #2

inemulC1:
inemulDD:
                cmp     sc3000,1
                je      inemulDD_sc3000

                cmp     lightgun,1
                jne     inemulDD_doit

                cmp     currentline,192
                jae     inemulDD_doit
                
                mov     ebx,mousey
                cmp     currentline,ebx
                jb      inemulDD_doit
                
                xor     smsjoyb,BIT_6
                
inemulDD_doit:                
                mov     bl,smsjoyb
                ret

inemulDD_sc3000:
                movzx   ebx,keyboard_select
                and     ebx,07h
                mov     bl,[offset smsjoya+ebx+8]
                or      bl,0F0h
                ret

; --------------------------------------------------------------------
; port E0 - Coleco joystick 1

inemulE0_coleco:
                cmp     colecomode,080h
                je      inemulE0_coleco_keypad
                
                mov     cl,smsjoya

                ; up
                mov     bl,cl
                and     bl,1
                or      bl,10110000b

                ; down
                mov     ch,cl
                and     ch,BIT_1
                shl     ch,1
                or      bl,ch

                ; left
                mov     ch,cl
                and     ch,BIT_2
                shl     ch,1
                or      bl,ch

                ; right
                mov     ch,cl
                and     ch,BIT_3
                shr     ch,2
                or      bl,ch

                ; left button
                mov     ch,cl
                and     ch,BIT_4
                shl     ch,2
                or      bl,ch

                ret

inemulE0_coleco_keypad:
                mov     bl,smsjoya
                and     bl,BIT_5
                shl     bl,1
                or      bl,10111111b


COLECOKEY       macro   pos,off,value
                local   colecokey_exit

                test    byte ptr [offset smsjoya+pos],off
                jnz     colecokey_exit
                and     bl,0F0h
                or      bl,value
                ret

colecokey_exit:
                endm

                COLECOKEY       2,BIT_0,1010b ;0
                COLECOKEY       2,BIT_1,1101b ;1
                COLECOKEY       2,BIT_2,0111b ;2
                COLECOKEY       2,BIT_3,1100b ;3
                COLECOKEY       2,BIT_4,0010b ;4
                COLECOKEY       2,BIT_5,0011b ;5
                COLECOKEY       2,BIT_6,1110b ;6
                COLECOKEY       2,BIT_7,0101b ;7
                COLECOKEY       3,BIT_0,0001b ;8
                COLECOKEY       3,BIT_1,1011b ;9
                COLECOKEY       3,BIT_2,1001b ;*
                COLECOKEY       3,BIT_3,0110b ;#

                ret

; --------------------------------------------------------------------
; port DE - SC3000 keyboard

inemulDE:
                mov     bl,keyboard_select
                ret

; --------------------------------------------------------------------
; port 7F - lightgun

inemul7F:
                cmp     lightgun,1
                je      inemul7F_lightgun
                mov     bl,0FFh
                ret

inemul7F_lightgun:
                mov     ebx,mousex
                shr     ebx,1
                add     ebx,20
                and     ebx,127
                ret

; --------------------------------------------------------------------

code32          ends
                end



