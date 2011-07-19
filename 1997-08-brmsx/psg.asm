; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: PSG.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include z80.inc
include bit.inc
include gui.inc
include pmode.inc
include pentium.inc

extrn dmabuffer: dword
extrn dmatemp: dword
extrn timebuffer: dword
extrn soundbuffer: dword
extrn sccram: dword
extrn noise_uncompressed: dword

public init_sound_blaster
public sound_on
public sound_off
public compose_soundstream
public soundenabled
public sbbaseaddr
public sbirq
public sbdma
public sounddetected
public read_master_volume
public write_master_volume
public compose_speaker
public speaker_shutup
;public noise_table
public sb_flushed
public noise_counter
public init_adlib
public reset_adlib
public fm_single_register
public soundplaying
public _samplerate
public _skipfactor
public _verticalrate
public uncompress_noise
public rom9dac_enabled

; DATA ---------------------------------------------------------------

align 4

;include noise.inc
include noise2.inc
include scc.inc
include envelope.inc
include fm.inc
include fmoper.inc
include fminstr.inc

align 4

SAMPLERATE              equ     45455
_samplerate             dd      45455

VERTICALRATE            equ     60
_verticalrate           dd      60

SKIPFACTOR              equ     4
_skipfactor             dd      4

DSP_TIME_CTE            equ     (256-(1000000/SAMPLERATE))
_dsp_time_cte           dd      DSP_TIME_CTE

MSXCLOCK                equ     (2*1788055)

;CONV_FACTOR            equ     (MSXCLOCK/16/SAMPLERATE*65536)  
CONV_FACTOR             equ     322247

;SINGLEINT              equ     SAMPLERATE/VERTICALRATE
SINGLEINT               equ     757
BUFFERSIZE              equ     (SINGLEINT*SKIPFACTOR)
_buffersize             dd      0

;CLOCKSPERSAMPLE        equ     (MSXCLOCK/SAMPLERATE*256)
CLOCKSPERSAMPLE         equ     20140

;SCCFACTOR              equ     (32/32*MSXCLOCK/SAMPLERATE*65536)
SCCFACTOR               equ     5155955
_sccfactor              dd      0

;ENVELOPEFACTOR         equ     (MSXCLOCK/SAMPLERATE*65536*8)
ENVELOPEFACTOR          equ     41247642
_envelopefactor         dd      0

;FMFACTOR               equ     (256*MSXCLOCK/2^18/72/SAMPLERATE*65536*256)
FMFACTOR                equ     17903

noisestream             db      8192 dup (0) ;BUFFERSIZE dup (0)
envstream               db      8192 dup (0) ;BUFFERSIZE dup (0)
doublebuffer            db      8192 dup (0) ;BUFFERSIZE dup (0)

align 4

DSP_RESET               dd      06h
DSP_READ_DATA           dd      0Ah
DSP_WRITE_DATA          dd      0Ch
DSP_WRITE_STATUS        dd      0Ch
DSP_DATA_AVAIL          dd      0Eh

DMA_page_table          db      087h,083h,081h,082h

sounddetected           dd      0
soundenabled            dd      0

sbbaseaddr              dd      0220h
sbirq                   dd      5
sbdma                   dd      1

sb_stub_buf             db      21 dup (0)
oldsbpirqvect           dd      0
oldsbrirqvect           dd      0

irqskip                 dd      0
dmaready                dd      0
sb_flushed              dd      0
buffer_flushed          dd      0

soundplaying            dd      0

align 4

PSGcounter              db      5*4 dup (0)
PSGstate                db      5*4 dup (0)
actual_channel          dd      0
localpos                dd      0
noise_counter           dd      0
noise_counter2          dd      0
danger_flag             dd      0
envelope_enabled        dd      0
envelope_first          dd      1

SCCcounter              db      5*4 dup (0)
sccsample               dd      0
SCCpos                  db      5 dup (0)

align 4

FMcounter               db      9*4 dup (0)
fmsample                dd      0
FMpos                   db      9 dup (0)

align 4
ppiclick                db      0
ppicassete              db      0

rom9dac_value           db      0
rom9dac_enabled         db      0

psgregstack             db      16 dup (0)
PSGreg                  db      16 dup (0)

sccregstack             db      16 dup (0)
SCCregs                 db      16 dup (0)

fmregstack              db      040h dup (0)
FMreg                   db      040h dup (0)

sb_default_pic1         db      0
sb_default_pic2         db      0

noisebit                db      0
musicbit                db      0

align 4
speakerchannel          dd      0
speakerfreq             dd      0
speakersilence          dd      0
speakervolume           db      0
                        db      0
                        db      0
                        db      0

align 4

localSCCram             db      128 dup (0)
firstSCCram             db      128 dup (0)

PSG_table               dd      offset PSG_full
                        dd      offset PSG_only_noise
                        dd      offset PSG_only_music
                        dd      offset PSG_nothing
                        dd      offset PSG_full_envelope
                        dd      offset PSG_only_noise_envelope
                        dd      offset PSG_only_music_envelope
                        dd      offset PSG_nothing_envelope

; reset_dsp ----------------------------------------------------------
; reset the dsp
; return flag c if any error

reset_dsp:
                mov     edx,DSP_RESET
                mov     al,1
                out     dx,al
                call    delay10

                mov     edx,DSP_RESET
                mov     al,0
                out     dx,al
                call    delay10

                mov     edx,DSP_DATA_AVAIL
                in      al,dx
                test    al,BIT_7
                jz      reset_dsp_failed

                mov     edx,DSP_READ_DATA
                in      al,dx
                cmp     al,0AAh
                jne     reset_dsp_failed

                or      eax,eax
                ret

reset_dsp_failed:
                stc
                ret

; delay10 ------------------------------------------------------------
; make a 10 ms delay

delay10:
                mov     v86r_ah,86h
                mov     v86r_cx,0
                mov     v86r_dx,10
                mov     al,15h
                int     33h
                ret

; init_sound_blaster -------------------------------------------------
; initialise the sb variables 

init_sound_blaster:
                mov     eax,sbbaseaddr
                add     DSP_RESET,eax
                add     DSP_READ_DATA,eax
                add     DSP_WRITE_DATA,eax
                add     DSP_WRITE_STATUS,eax
                add     DSP_DATA_AVAIL,eax
                call    reset_dsp
                
                ; DSP_TIME_CTE equ (256-(1000000/SAMPLERATE))

                mov     eax,1000000
                mov     edx,0
                mov     ebx,_samplerate
                div     ebx
                mov     ebx,256
                sub     ebx,eax
                mov     _dsp_time_cte,ebx

                ; CONV_FACTOR equ (MSXCLOCK/16/SAMPLERATE*65536)  

                mov     eax,06912E000h
                mov     edx,03h
                mov     ebx,_samplerate
                div     ebx
                mov     dword ptr [offset patch__11+2],eax
                mov     dword ptr [offset patch__12+2],eax
                mov     dword ptr [offset patch__13+2],eax
                mov     dword ptr [offset patch__14+2],eax
                mov     dword ptr [offset patch__15+2],eax
                
                ; SINGLEINT equ SAMPLERATE/VERTICALRATE
                ; BUFFERSIZE equ (SINGLEINT*SKIPFACTOR)

                mov     eax,_samplerate
                mov     ebx,_skipfactor
                mul     ebx
                mov     ebx,_verticalrate
                div     ebx
                mov     _buffersize,eax
                mov     dword ptr [offset patch__21+2],eax
                mov     dword ptr [offset patch__22+2],eax
                mov     dword ptr [offset patch__23+2],eax
                mov     dword ptr [offset patch__24+2],eax
                mov     dword ptr [offset patch__25+2],eax
                mov     dword ptr [offset patch__26+2],eax
                mov     dword ptr [offset patch__27+2],eax
                mov     dword ptr [offset patch__210+2],eax
                mov     dword ptr [offset patch__211+2],eax
                mov     dword ptr [offset patch__212+2],eax
                mov     dword ptr [offset patch__213+2],eax
                mov     dword ptr [offset patch__214+2],eax
                mov     dword ptr [offset patch__215+2],eax
                mov     dword ptr [offset patch__216+2],eax
                mov     dword ptr [offset patch__217+2],eax
                mov     dword ptr [offset patch__218+2],eax
                mov     dword ptr [offset patch__219+2],eax
                mov     dword ptr [offset patch__220+2],eax
                mov     dword ptr [offset patch__221+2],eax
                mov     dword ptr [offset patch__222+2],eax
                mov     dword ptr [offset patch__223+2],eax

                ; CLOCKSPERSAMPLE equ (MSXCLOCK/SAMPLERATE*256)
                mov     eax,036912E00h
                mov     edx,0
                mov     ebx,_samplerate
                div     ebx
                mov     dword ptr [offset patch__31+2],eax
                mov     dword ptr [offset patch__32+2],eax
                mov     dword ptr [offset patch__33+2],eax
                mov     dword ptr [offset patch__34+2],eax
                mov     dword ptr [offset patch__35+2],eax
                mov     dword ptr [offset patch__36+2],eax
                mov     dword ptr [offset patch__37+2],eax
                mov     dword ptr [offset patch__38+2],eax
                mov     dword ptr [offset patch__39+2],eax
                mov     dword ptr [offset patch__310+2],eax
                mov     dword ptr [offset patch__311+2],eax
                mov     dword ptr [offset patch__312+2],eax
                mov     dword ptr [offset patch__313+2],eax
                mov     dword ptr [offset patch__314+2],eax
                mov     dword ptr [offset patch__315+2],eax
                mov     dword ptr [offset patch__316+2],eax
                mov     dword ptr [offset patch__317+2],eax
                mov     dword ptr [offset patch__318+2],eax

                ; SCCFACTOR equ (32/32*MSXCLOCK/SAMPLERATE*65536)
                mov     eax,912E0000h
                mov     edx,036h
                mov     ebx,_samplerate
                div     ebx
                mov     _sccfactor,eax

                ; ENVELOPEFACTOR equ (MSXCLOCK/SAMPLERATE*65536*8)
                mov     eax,89700000h
                mov     edx,01B4h
                mov     ebx,_samplerate
                div     ebx
                mov     _envelopefactor,eax

                ret
  
; uncompress_noise ---------------------------------------------------
; uncompress the noise and patch all references

uncompress_noise:
                mov     ecx,16384/8
                mov     esi,offset noise_table_z
                mov     edi,noise_uncompressed
uncompress_noise_loop:
                mov     bl,[esi]
                irp     i,<0,1,2,3,4,5,6,7>
                rol     bl,1
                sbb     al,al
                mov     [edi],al
                inc     edi
                endm
                inc     esi
                dec     ecx
                jnz     uncompress_noise_loop

                mov     eax,noise_uncompressed
                mov     dword ptr [offset patch__41+2],eax
                mov     dword ptr [offset patch__42+2],eax
                mov     dword ptr [offset patch__43+2],eax
                mov     dword ptr [offset patch__44+2],eax
                mov     dword ptr [offset patch__45+2],eax
                mov     dword ptr [offset patch__46+2],eax
                mov     dword ptr [offset patch__47+2],eax

                ret

; init_dma_buffer ----------------------------------------------------
; init the dma buffer
; this version uses a constant tone of about 60 Hz

init_dma_buffer:
                mov     edi,dmabuffer
                mov     ecx,_buffersize ;BUFFERSIZE
                mov     al,0
                rep     stosb

                ret

; write_dsp ----------------------------------------------------------
; write a byte in the dsp
; in: bl=byte

write_dsp:
                mov     edx,DSP_WRITE_STATUS     
                
write_dsp_loop:
                in      al,dx              
                test    al,BIT_7
                jnz     write_dsp_loop

                mov     edx,DSP_WRITE_DATA
                mov     al,bl
                out     dx,al

                ret

; play ---------------------------------------------------------------
; turn on the DSP and start DMA transfers to sound board

play:
                mov     eax,sbdma
                or      eax,BIT_2
                mov     dx,0Ah
                out     dx,al

                mov     al,0
                mov     dx,0Ch
                out     dx,al

                mov     eax,(048h or 010h)
                or      eax,sbdma
                mov     dx,0Bh
                out     dx,al

                mov     edi,dmabuffer
                add     edi,_code32a

                mov     eax,edi
                mov     edx,sbdma
                shl     edx,1
                out     dx,al

                shr     eax,8
                out     dx,al

                shr     eax,8
                mov     edx,sbdma
                movzx   edx,byte ptr [offset DMA_page_table+edx]
                out     dx,al

                mov     ebx,_buffersize
                dec     ebx

                ;mov     al,((BUFFERSIZE-1) and 0FFh)
                mov     al,bl

                mov     edx,sbdma
                shl     edx,1
                inc     edx
                out     dx,al

                ;mov     al,(((BUFFERSIZE-1) shr 8) and 0FFh)
                mov     al,bh

                out     dx,al

                mov     eax,sbdma
                mov     dx,0Ah
                out     dx,al

                mov     bl,040h
                call    write_dsp

                mov     ebx,_dsp_time_cte
                call    write_dsp

                mov     bl,048h
                call    write_dsp
                
                mov     ebx,_buffersize
                dec     ebx

                ;mov     bl,((BUFFERSIZE-1) and 0FFh)
                call    write_dsp
                
                mov     ebx,_buffersize
                dec     ebx
                mov     bl,bh
                
                ;mov     bl,(((BUFFERSIZE-1) shr 8) and 0FFh)

                call    write_dsp

                mov     bl,090h
                call    write_dsp

                ret

; my_sb_irq_handler --------------------------------------------------
; sound blaster interrupt handler

my_sb_irq_handler:
                cli
                pushad
                push    ds 
                mov     ds,cs:_seldata

                mov     sb_flushed,1
                mov     buffer_flushed,1

                mov     edi,dmabuffer
                mov     esi,offset doublebuffer ; dmatemp
                ;mov     ecx,(BUFFERSIZE+4)/4
                mov     ecx,_buffersize
                shr     ecx,2
                inc     ecx

                rep     movsd

                mov     edx,DSP_DATA_AVAIL
                in      al,dx
                
                mov     al,20h
                out     20h,al
                mov     al,20h
                out     0A0h,al

                pop     ds
                popad
                sti
                iretd

; turnon_sbirq -------------------------------------------------------
; turn on the sound blaster interrupt handler

turnon_sbirq:
                mov     ebx,sbirq
                call    _getirqvect
                mov     oldsbpirqvect,edx
                mov     edx,offset my_sb_irq_handler
                call    _setirqvect
                mov     edi,offset sb_stub_buf
                call    _rmpmirqset
                mov     oldsbrirqvect,eax

                mov     dx,021h
                in      al,dx
                mov     sb_default_pic1,al

                mov     dx,0A1h
                in      al,dx
                mov     sb_default_pic2,al

                mov     eax,1
                mov     ecx,sbirq
                shl     eax,cl
                xor     eax,0FFFFFFFFh
                and     al,sb_default_pic1
                mov     dx,021h
                out     dx,al
                and     ah,sb_default_pic2
                mov     dx,0A1h
                mov     al,ah
                out     dx,al

                ret

; turnoff_sbirq ------------------------------------------------------
; turn off the sound blaster interrupt handler

turnoff_sbirq:
                mov     ebx,sbirq
                mov     eax,oldsbrirqvect
                call    _rmpmirqfree
                mov     edx,oldsbpirqvect
                call    _setirqvect

                call    reset_dsp

                mov     al,sb_default_pic1
                mov     dx,021h
                out     dx,al

                mov     al,sb_default_pic2
                mov     dx,0A1h
                out     dx,al

                ret

; sound_on -----------------------------------------------------------
; turns on the sound system

sound_on:
                or      soundplaying,1
                
                cmp     soundenabled,0
                je      _ret
                cmp     emulatemode,1
                je      _ret

                call    init_dma_buffer

                mov     eax,SKIPFACTOR
                mov     irqskip,eax
                call    turnon_sbirq
                call    play
                cmp     fmenabled,1
                jne     _ret

                call    fm_slice

                ret

; sound_off ----------------------------------------------------------
; turns off the sound system

sound_off:
                and     soundplaying,0FFFFFFFEh
                
                cmp     speaker,1
                jne     sound_off_sb

                call    speaker_shutup
                ret

sound_off_sb:
                cmp     soundenabled,0
                je      _ret
                call    turnoff_sbirq
                ret

; read_master_volume -------------------------------------------------
; read the value of the master volume from the sb pro mixer
; output: al= value read (low nibble)

read_master_volume:
                push    edx
                mov     edx,sbbaseaddr
                add     edx,4
                
                ; read the master volume
                mov     al,22h
                out     dx,al
                inc     dx
                in      al,dx
                and     al,0Fh

                pop     edx
                ret

; write_master_volume ------------------------------------------------
; write a value to the master volume 
; input: al= value write (low nibble)

write_master_volume:
                push    edx eax
                mov     edx,sbbaseaddr
                add     edx,4
                mov     ah,al
                and     ah,0Fh

                ; write the master volume
                mov     al,22h
                out     dx,al
                inc     dx
                mov     al,ah
                shl     ah,4
                or      al,ah
                out     dx,al

                pop     eax edx
                ret

; compose_soundstream ------------------------------------------------
; compose the output sound stream
; based on PSG registers

compose_soundstream:
                
                cmp     soundenabled,0
                je      compose_soundstream_off

                cmp     turnoff_flag,1
                je      compose_purenoise

                pushad

                ;call    fm_slice                
                        
                dec     irqskip
                jnz     compose_soundstream_update_buffer

                mov     dmaready,1
                
                mov     irqskip,SKIPFACTOR

                mov     esi,timebuffer
                mov     ecx,psgpos
                mov     [esi+ecx*4],0FFFFFFFFh

                mov     localpos,0
                mov     actual_channel,3
                call    compose_noise

                mov     localpos,0
                mov     actual_channel,4
                call    compose_envelope

                mov     localpos,0
                call    compose_click

                mov     localpos,0
                call    compose_rom9dac

                mov     localpos,0
                call    compose_cassete

                mov     localpos,0
                mov     actual_channel,0
                call    compose_channel
                
                mov     localpos,0
                mov     actual_channel,1
                call    compose_channel
                
                mov     localpos,0
                mov     actual_channel,2
                call    compose_channel
                
                cmp     sccenabled,0
                je      compose_soundstream_noscc

                cmp     sccdetected,0
                je      compose_soundstream_noscc

                mov     localpos,0
                mov     actual_channel,0
                mov     esi,offset localSCCram
                call    compose_scc
                
                mov     localpos,0
                mov     actual_channel,1
                mov     esi,offset localSCCram
                add     esi,32
                call    compose_scc
                
                mov     localpos,0
                mov     actual_channel,2
                mov     esi,offset localSCCram
                add     esi,32*2
                call    compose_scc
                
                mov     localpos,0
                mov     actual_channel,3
                mov     esi,offset localSCCram
                add     esi,32*3
                call    compose_scc
                
                mov     localpos,0
                mov     actual_channel,4
                mov     esi,offset localSCCram
                add     esi,32*3
                call    compose_scc

compose_soundstream_noscc:

                cmp     fmenabled,1
                jne     compose_soundstream_nofm
                
;                irp     i,<0,1,2,3,4,5,6,7,8>
;                mov     localpos,0
;                mov     actual_channel,i
;                mov     esi,offset sine_table
;                call    compose_fm
;                endm

compose_soundstream_nofm:
                
                mov     esi,offset psgreg
                mov     edi,offset psgregstack
                mov     ecx,16/4
                rep     movsd

                mov     esi,offset sccregs
                mov     edi,offset sccregstack
                mov     ecx,16/4
                rep     movsd

                mov     esi,offset localSCCram
                mov     edi,offset firstSCCram
                mov     ecx,128/4
                rep     movsd

                mov     esi,offset fmreg
                mov     edi,offset fmregstack
                mov     ecx,040h/4
                rep     movsd

                mov     psgclear,1
                mov     psgpos,0

compose_soundstream_exit:

                popad
                ret

compose_soundstream_off:
                mov     psgpos,0
                ret

compose_soundstream_update_buffer:
                cmp     dmaready,1
                jne     compose_soundstream_exit
                cmp     buffer_flushed,1
                jne     compose_soundstream_exit

                mov     dmaready,0
                mov     buffer_flushed,0

                mov     esi,dmatemp
                mov     edi,offset doublebuffer
                mov     ecx,_buffersize ;BUFFERSIZE
                rep     movsb
                
                popad
                ret

; compose_click ------------------------------------------------------
; compose and mix the keyboard click

compose_click:

                mov     ecx,0
                mov     edi,_buffersize ; BUFFERSIZE
                mov     esi,dmatemp
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8
                mov     al,ppiclick

compose_click_loop:
                mov     [esi],al
patch__31:      add     ecx,CLOCKSPERSAMPLE
                inc     esi                
                
                cmp     ecx,ebp
                jae     compose_click_check

compose_click_nextsample:                
                dec     edi
                jnz     compose_click_loop
                ret

compose_click_check:
                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer

                mov     al,byte ptr [ebp]
                mov     dl,byte ptr [ebp+1]
                cmp     al,16
                jne     compose_channel_notclick
                mov     ppiclick,dl
compose_channel_notclick:

                inc     localpos

                mov     ebp,localpos
                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                mov     al,ppiclick
                jmp     compose_click_nextsample

; compose_rom9dac ----------------------------------------------------
; compose and mix the 8-bit DAC used in mapper #9

compose_rom9dac:
                cmp     rom9dac_enabled,1
                jne     _ret

                mov     ecx,0
                mov     edi,_buffersize ; BUFFERSIZE
                mov     esi,dmatemp
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8
                mov     al,rom9dac_value

compose_rom9dac_loop:
                add     [esi],al
patch__318:     add     ecx,CLOCKSPERSAMPLE
                inc     esi                
                
                cmp     ecx,ebp
                jae     compose_rom9dac_check

compose_rom9dac_nextsample:                
                dec     edi
                jnz     compose_rom9dac_loop
                ret

compose_rom9dac_check:
                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer

                mov     al,byte ptr [ebp]
                mov     dl,byte ptr [ebp+1]
                cmp     al,18
                jne     compose_rom9dac_notclick
                mov     rom9dac_value,dl
compose_rom9dac_notclick:

                inc     localpos

                mov     ebp,localpos
                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                mov     al,rom9dac_value
                jmp     compose_rom9dac_nextsample

; compose_cassete ----------------------------------------------------
; compose and mix the cassete output

compose_cassete:

                mov     ecx,0
                mov     edi,_buffersize ;BUFFERSIZE
                mov     esi,dmatemp
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8
                mov     al,ppicassete

compose_cassete_loop:
                add     [esi],al
                inc     esi                

patch__32:      add     ecx,CLOCKSPERSAMPLE
                cmp     ecx,ebp
                jb      compose_cassete_nextsample

                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer

                mov     al,byte ptr [ebp]
                mov     dl,byte ptr [ebp+1]
                cmp     al,17
                jne     compose_channel_notcassete
                mov     ppicassete,dl
compose_channel_notcassete:

                inc     localpos

                mov     ebp,localpos
                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                mov     al,ppicassete

compose_cassete_nextsample:
                dec     edi
                jnz     compose_cassete_loop

                ret


; compose_channel ----------------------------------------------------
; compose and mix a PSG square channel
; enter: actual_channel

compose_channel:
                
                mov     esi,offset psgregstack 
                mov     edi,offset PSGreg
                mov     ecx,16/4
                rep     movsd

                mov     edi,actual_channel
                mov     esi,dword ptr [offset PSGcounter+edi*4]
                mov     eax,dword ptr [offset PSGstate+edi*4]

                mov     ecx,0
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8

                ; make the patches
                mov     edi,dmatemp
                mov     dword ptr [offset patch1+2],edi
                mov     dword ptr [offset patch2+2],edi
                mov     dword ptr [offset patch3+2],edi
                mov     dword ptr [offset patch4+2],edi
                mov     dword ptr [offset patch5+2],edi
                mov     dword ptr [offset patch6+2],edi
                mov     dword ptr [offset patch8+2],edi
                mov     dword ptr [offset patch9+2],edi

                ; play from position 0
                mov     edi,0
                call    modify_parameters

compose_channel_long_loop:
                jmp     edx

; --------------------------------------------------------------------

PSG_full:
                cmp     ah,0
                je      PSG_really_nothing

PSG_full_loop:                
patch__11:      add     esi,CONV_FACTOR
                cmp     esi,ebx
                jle     PSG_full_mix

                sub     esi,ebx
                xor     al,0FFh

PSG_full_mix:
                mov     dl,[edi+offset noisestream]
                and     dl,ah
                and     dl,al
patch__33:      add     ecx,CLOCKSPERSAMPLE
patch2:         add     [edi+12345678h],dl

                cmp     ecx,ebp
                jae     compose_channel_check

                inc     edi
patch__21:      cmp     edi,BUFFERSIZE
                jne     PSG_full_loop

                jmp     PSG_exit

; --------------------------------------------------------------------
                
PSG_only_noise:
                cmp     ah,0
                je      PSG_really_nothing

PSG_only_noise_loop:                
                mov     dl,[edi+offset noisestream]
                and     dl,ah
patch__34:      add     ecx,CLOCKSPERSAMPLE
patch6:         add     [edi+12345678h],dl

                cmp     ecx,ebp
                jae     compose_channel_check

                inc     edi
patch__22:      cmp     edi,BUFFERSIZE
                jne     PSG_only_noise_loop

                jmp     PSG_exit

; --------------------------------------------------------------------
                
PSG_only_music:
                cmp     ah,0
                je      PSG_really_nothing

PSG_only_music_loop:                
patch__12:      add     esi,CONV_FACTOR
                cmp     esi,ebx
                jle     PSG_only_music_mix

                sub     esi,ebx
                xor     al,0FFh

PSG_only_music_mix:
                mov     dl,al
                and     dl,ah
patch__35:      add     ecx,CLOCKSPERSAMPLE
patch4:         add     [edi+12345678h],dl

                cmp     ecx,ebp
                jae     compose_channel_check

                inc     edi
patch__23:      cmp     edi,BUFFERSIZE
                jne     PSG_only_music_loop

                jmp     PSG_exit

; --------------------------------------------------------------------
                
PSG_nothing:
                cmp     ah,0
                je      PSG_really_nothing

PSG_nothing_loop:
patch3:         add     [edi+12345678h],ah
patch__36:      add     ecx,CLOCKSPERSAMPLE
                cmp     ecx,ebp
                jae     compose_channel_check
                
                inc     edi
patch__24:      cmp     edi,BUFFERSIZE
                jne     PSG_nothing_loop

                jmp     PSG_exit

; --------------------------------------------------------------------
                
PSG_really_nothing:
patch__37:      add     ecx,CLOCKSPERSAMPLE
                cmp     ecx,ebp
                jae     compose_channel_check
                
                inc     edi
patch__25:      cmp     edi,BUFFERSIZE
                jne     PSG_really_nothing

                jmp     PSG_exit

; --------------------------------------------------------------------

PSG_only_music_envelope:
                
PSG_only_music_envelope_loop:                
patch__13:      add     esi,CONV_FACTOR
                cmp     esi,ebx
                jle     PSG_only_music_envelope_mix

                sub     esi,ebx
                xor     al,0FFh

PSG_only_music_envelope_mix:
                mov     dl,al
                and     dl,[edi+offset envstream]
patch__38:      add     ecx,CLOCKSPERSAMPLE
patch8:         add     [edi+12345678h],dl

                cmp     ecx,ebp
                jae     compose_channel_check

                inc     edi
patch__26:      cmp     edi,BUFFERSIZE
                jne     PSG_only_music_envelope_loop

                jmp     PSG_exit

; --------------------------------------------------------------------
                
PSG_only_noise_envelope:

PSG_only_noise_envelope_loop:                
                mov     dl,[edi+offset noisestream]
                and     dl,[edi+offset envstream]
patch__39:      add     ecx,CLOCKSPERSAMPLE
patch9:         add     [edi+12345678h],dl

                cmp     ecx,ebp
                jae     compose_channel_check

                inc     edi
patch__27:      cmp     edi,BUFFERSIZE
                jne     PSG_only_noise_envelope_loop

                jmp     PSG_exit

; --------------------------------------------------------------------

PSG_full_envelope:

PSG_full_envelope_loop:                
patch__14:      add     esi,CONV_FACTOR
                cmp     esi,ebx
                jle     PSG_full_envelope_mix

                sub     esi,ebx
                xor     al,0FFh

PSG_full_envelope_mix:
                mov     dl,[edi+offset noisestream]
                and     dl,[edi+offset envstream]
                and     dl,al
patch__310:     add     ecx,CLOCKSPERSAMPLE
patch1:         add     [edi+12345678h],dl

                cmp     ecx,ebp
                jae     compose_channel_check

                inc     edi
patch__210:     cmp     edi,BUFFERSIZE
                jne     PSG_full_envelope_loop

                jmp     PSG_exit

; --------------------------------------------------------------------
                
PSG_nothing_envelope:

PSG_nothing_envelope_loop:
                mov     al,[edi+offset envstream]
patch5:         add     [edi+12345678h],al
patch__311:     add     ecx,CLOCKSPERSAMPLE
                cmp     ecx,ebp
                jae     compose_channel_check
                
                inc     edi
patch__211:     cmp     edi,BUFFERSIZE
                jne     PSG_nothing_envelope_loop

                jmp     PSG_exit

; --------------------------------------------------------------------
                
compose_channel_check:
                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer

                mov     dh,byte ptr [ebp+1]
                movzx   ebp,byte ptr [ebp]
                cmp     ebp,15
                ja      compose_channel_notpsg
                mov     [offset PSGreg+ebp],dh
                
compose_channel_notpsg:

                mov     ebp,localpos
                inc     ebp
                mov     localpos,ebp

                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                call    modify_parameters

                inc     edi
patch__212:     cmp     edi,BUFFERSIZE
                jne     compose_channel_long_loop

; --------------------------------------------------------------------
                
PSG_exit:
                mov     edi,actual_channel
                mov     dword ptr [offset PSGcounter+edi*4],esi
                mov     dword ptr [offset PSGstate+edi*4],eax
                
                ret

; --------------------------------------------------------------------
                
modify_parameters:
                mov     edx,actual_channel
                mov     dword ptr [offset PSGcounter+edx*4],esi
                mov     dword ptr [offset PSGstate+edx*4],eax
                
                mov     eax,actual_channel
                
                ; ebx = start_counter
                movzx   ebx,word ptr [offset PSGreg+eax*2]
                and     ebx,0FFFh 
                shl     ebx,16

                ; esi = psg_counter
                mov     esi,dword ptr [offset PSGcounter+eax*4]

                ; dl = volume
                mov     dl,byte ptr [offset PSGreg+8+eax]
                and     dl,01Fh
                mov     envelope_enabled,0
                cmp     dl,0Fh
                jbe     modify_parameters_noenvelope
                mov     envelope_enabled,1
modify_parameters_noenvelope:
                
                push    ecx

                ; noisebit
                mov     dh,byte ptr [offset PSGreg+7]
                mov     cl,al
                add     cl,3+1
                shr     dh,cl
                sbb     dh,dh
                mov     noisebit,dh

                cmp     dh,0
                jne     modify_parameters_puremusic

                cmp     byte ptr [offset PSGreg+6],4
                ja      modify_parameters_puremusic

                mov     dh,dl
                add     dh,byte ptr [offset PSGreg+6]
                sub     dh,5
                jc      modify_parameters_puremusic

                mov     dl,dh

modify_parameters_puremusic:
                mov     cl,al
                mov     dh,byte ptr [offset PSGreg+7]
                inc     cl
                shr     dh,cl
                sbb     dh,dh
                mov     musicbit,dh

                ; check for frequency equal to zero -> PCM output
                ; warning: affect only the last bit
                cmp     ebx,0
                sete    ch
                or      musicbit,ch

                ; al = psg_state
                mov     eax,dword ptr [offset PSGstate+eax*4]

                ; now ah has the volume and dl will be discarded
                mov     ah,dl

                pop     ecx

                mov     dl,01h
                and     dl,musicbit
                mov     dh,02h
                and     dh,noisebit
                or      dl,dh
                and     edx,3

                cmp     envelope_enabled,1
                jne     modify_parameters_exit

                add     edx,4
                
modify_parameters_exit:
                mov     edx,dword ptr [offset PSG_table+edx*4]
                ret

; compose_scc --------------------------------------------------------
; compose and mix a SCC channel
; enter: actual_channel

compose_scc:
                mov     sccsample,esi
                
                mov     esi,offset sccregstack 
                mov     edi,offset SCCregs
                mov     ecx,16/4
                rep     movsd

                mov     esi,offset firstSCCram
                mov     edi,offset localSCCram
                mov     ecx,128/4
                rep     movsd

                mov     edi,actual_channel
                mov     edx,dword ptr [offset SCCcounter+edi*4]

                mov     ecx,0
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8

                mov     edi,dmatemp
                mov     dword ptr [offset patchscc1+2],edi
                mov     edi,sccsample
                mov     dword ptr [offset patchscc2+2],edi
                and     eax,0FFFFh
                mov     edi,0

compose_scc_outer:

                call    modify_parameters_scc

; --------------------------------------------------------------------
                
compose_scc_loop:                
                ; warning: this loop is HEAVILY convoluted
                ; the output is one sample delayed

                add     edx,ebx 
patchscc2:      mov     al,[esi+12345678h]
                and     edx,2097151 ; this is 32*65536-1
patch__312:     add     ecx,CLOCKSPERSAMPLE
                mov     esi,edx
                mov     al,[eax+offset SCC_table]
                shr     esi,16
patchscc1:      add     [edi+12345678h],al

                cmp     ecx,ebp
                jae     compose_scc_check

                inc     edi
patch__213:     cmp     edi,BUFFERSIZE
                jne     compose_scc_loop

; --------------------------------------------------------------------
                
compose_scc_exit:

                mov     edi,actual_channel
                mov     dword ptr [offset SCCcounter+edi*4],edx
                
                ret

; --------------------------------------------------------------------

compose_scc_check:
                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer
                push    eax ecx

                movzx   eax,byte ptr [ebp]
                mov     cl,byte ptr [ebp+1]
                cmp     al,7Eh
                jb      compose_channel_notscc
                cmp     al,80h
                jb      compose_channel_waveform
                mov     [offset SCCregs+eax-080h],cl
compose_channel_notscc:

                inc     localpos

                mov     ebp,localpos
                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                pop     ecx eax

                call    modify_parameters_scc

compose_scc_nextsample:
                inc     edi
patch__214:     cmp     edi,BUFFERSIZE
                jne     compose_scc_loop

                jmp     compose_scc_exit

; --------------------------------------------------------------------
                
compose_channel_waveform:

                ; cl has the address in range 00-7F
                mov     al,byte ptr [ebp+3]
                and     ecx,0FFh
                mov     byte ptr [offset localSCCram+ecx],al
                
                add     localpos,2

                mov     ebp,localpos
                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                pop     ecx eax

                jmp     compose_scc_nextsample

; --------------------------------------------------------------------
                
modify_parameters_scc:
                
                push    edi
                mov     edi,actual_channel
                mov     dword ptr [offset SCCcounter+edi*4],edx
                pop     edi
                
                mov     eax,actual_channel
                
                ; ebx = start_counter
                movzx   edx,word ptr [offset SCCregs+eax*2]
                and     edx,0FFFh 
                cmp     ebx,edx
                je      modify_parameters_scc_samefreq
                
                mov     ebx,edx
                cmp     ebx,0
                je      modify_parameters_scc_samefreq

                mov     edx,0
                mov     eax,_sccfactor ;SCCFACTOR
                div     ebx
                mov     ebx,eax

modify_parameters_scc_samefreq:

                mov     eax,actual_channel
                
                ; edx = psg_counter
                mov     edx,dword ptr [offset SCCcounter+eax*4]

                ; cl = volume
                push    ecx
                mov     cl,byte ptr [offset SCCregs+10+eax]
                and     cl,00Fh
                
                ; adjust mixer channels
                mov     ah,cl
                mov     ecx,actual_channel
                mov     ch,byte ptr [offset SCCregs+15]
                shr     ch,cl
                test    ch,1
                jnz     modify_parameters_scc_skip1
                ;;;
                ;;;mov     ah,0
                mov     ebx,0

modify_parameters_scc_skip1:

                pop     ecx

                ret

; compose_fm ---------------------------------------------------------
; compose and mix a FM channel
; enter: actual_channel

compose_fm:
                mov     fmsample,esi
                
                mov     esi,offset fmregstack 
                mov     edi,offset FMreg
                mov     ecx,040h/4
                rep     movsd

                mov     edi,actual_channel
                mov     edx,dword ptr [offset FMcounter+edi*4]

                mov     ecx,0
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8

                mov     edi,dmatemp
                mov     dword ptr [offset patchfm1+2],edi
                mov     edi,fmsample
                mov     dword ptr [offset patchfm2+2],edi
                and     eax,0FFFFh
                mov     edi,0

compose_fm_outer:

                call    modify_parameters_fm

; --------------------------------------------------------------------
                
compose_fm_loop:                
                ; warning: this loop is HEAVILY convoluted
                ; the output is one sample delayed

                add     edx,ebx 
patchfm2:       mov     al,[esi+12345678h]
                ; there should be an "and" here but this routine is tricky
patch__313:     add     ecx,CLOCKSPERSAMPLE
                mov     esi,edx
                mov     al,[eax+offset SCC_table]
                shr     esi,16+8
patchfm1:       add     [edi+12345678h],al

                cmp     ecx,ebp
                jae     compose_fm_check

                inc     edi
patch__215:     cmp     edi,BUFFERSIZE
                jne     compose_fm_loop

; --------------------------------------------------------------------
                
compose_fm_exit:

                mov     edi,actual_channel
                mov     dword ptr [offset FMcounter+edi*4],edx
                
                ret

; --------------------------------------------------------------------

compose_fm_check:
                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer
                push    eax ecx

                movzx   eax,byte ptr [ebp]
                mov     cl,byte ptr [ebp+1]
                cmp     al,70h
                jb      compose_channel_fmregister
compose_channel_notfm:

                inc     localpos

                mov     ebp,localpos
                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                pop     ecx eax

                call    modify_parameters_fm

compose_fm_nextsample:
                inc     edi
patch__216:     cmp     edi,BUFFERSIZE
                jne     compose_fm_loop

                jmp     compose_fm_exit

; --------------------------------------------------------------------
                
compose_channel_fmregister:

                ; cl has the register in range 00-3F
                mov     al,byte ptr [ebp+3]
                and     ecx,0FFh
                mov     byte ptr [offset FMreg+ecx],al
                
                add     localpos,2

                mov     ebp,localpos
                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                pop     ecx eax

                jmp     compose_fm_nextsample

; --------------------------------------------------------------------
                
modify_parameters_fm:
                
                push    edi
                mov     edi,actual_channel
                mov     dword ptr [offset FMcounter+edi*4],edx
                pop     edi
                
                mov     eax,actual_channel

                mov     dl,byte ptr [offset FMreg+eax+10h]
                mov     dh,byte ptr [offset FMreg+eax+20h]
                and     edx,01FFh
                mov     cl,byte ptr [offset FMreg+eax+20h]
                shr     cl,1
                and     cl,7
                dec     cl
                shl     edx,cl
                mov     eax,edx
                mov     edx,0
                mov     ebx,FMFACTOR
                mul     ebx
                mov     ebx,eax

                mov     eax,actual_channel
                
                ; edx = psg_counter
                mov     edx,dword ptr [offset FMcounter+eax*4]

                ; cl = volume
                push    ecx
                mov     cl,byte ptr [offset FMreg+030h+eax]
                and     cl,0Fh
                xor     cl,0Fh
                
                ; adjust mixer channels
                mov     ch,byte ptr [offset FMreg+020h+eax]
                shr     ch,5
                sbb     ch,ch
                and     cl,ch
                mov     ah,cl

                pop     ecx

                ret


; compose_noise ------------------------------------------------------
; compose the PSG noise stream
; enter: actual_channel=3

compose_noise:
                
                mov     esi,offset psgregstack 
                mov     edi,offset PSGreg
                mov     ecx,16/4
                rep     movsd

                mov     edi,actual_channel
                mov     esi,dword ptr [offset PSGcounter+edi*4]
                mov     eax,dword ptr [offset PSGstate+edi*4]
                mov     edx,noise_counter

                mov     ecx,0
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8

                mov     edi,0
                call    modify_parameters_noise

compose_noise_long_loop:
                cmp     danger_flag,1
                je      compose_noise_danger

; --------------------------------------------------------------------
                
compose_noise_loop:
patch__15:      add     esi,CONV_FACTOR
                cmp     esi,ebx
                jle     compose_noise_mix

                mov     edx,noise_counter
patch__41:      mov     al,byte ptr [offset noise_table_z+edx]
                inc     edx
                and     edx,16383
                mov     noise_counter,edx

                cmp     edx,noise_counter2
                je      compose_noise_one

                mov     edx,noise_counter2
patch__42:      xor     al,byte ptr [offset noise_table_z+edx]
                inc     edx
                cmp     edx,16383
                jne     compose_noise_skip
                mov     edx,0
compose_noise_skip:
                mov     noise_counter2,edx

compose_noise_one:
                sub     esi,ebx

compose_noise_mix:
                mov     [edi+offset noisestream],al

patch__314:     add     ecx,CLOCKSPERSAMPLE
                cmp     ecx,ebp
                jae     compose_noise_check

                inc     edi
patch__217:     cmp     edi,BUFFERSIZE
                jne     compose_noise_loop

                jmp     noise_exit

; --------------------------------------------------------------------
                
compose_noise_danger:
                push    esi
                mov     ebx,noise_counter2

compose_noise_danger_loop:
                cmp     ebx,edx
                jne     compose_noise_danger_loop_go
                inc     edx
                and     edx,16384
compose_noise_danger_loop_go:
patch__43:      mov     al,byte ptr [offset noise_table_z+edx]
patch__44:      xor     al,byte ptr [offset noise_table_z+ebx]
                inc     edx
                inc     ebx
                mov     [edi+offset noisestream],al
                and     edx,16383
                cmp     ebx,16383
                sbb     esi,esi
                and     ebx,esi

patch__315:     add     ecx,CLOCKSPERSAMPLE
                cmp     ecx,ebp
                jae     compose_noise_check_now

                inc     edi
patch__218:     cmp     edi,BUFFERSIZE
                jne     compose_noise_danger_loop

                pop     esi
                mov     noise_counter,edx
                mov     noise_counter2,ebx
                jmp     noise_exit

compose_noise_check_now:
                pop     esi
                mov     noise_counter,edx
                mov     noise_counter2,ebx
                jmp     compose_noise_check

; --------------------------------------------------------------------
                
compose_noise_check:
                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer

                mov     ah,byte ptr [ebp+1]
                movzx   ebp,byte ptr [ebp]
                cmp     ebp,15
                ja      compose_noise_notpsg
                mov     [offset PSGreg+ebp],ah
compose_noise_notpsg:

                mov     ebp,localpos
                inc     ebp
                mov     localpos,ebp

                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                call    modify_parameters_noise

                inc     edi
patch__219:     cmp     edi,BUFFERSIZE
                jne     compose_noise_long_loop

noise_exit:
                mov     edi,actual_channel
                mov     dword ptr [offset PSGcounter+edi*4],esi
                mov     dword ptr [offset PSGstate+edi*4],eax
                
                ret

; --------------------------------------------------------------------
                
modify_parameters_noise:
                
                ; ebx = start_counter
                mov     danger_flag,1
                movzx   ebx,byte ptr [offset PSGreg+6]
                and     ebx,11111b
                cmp     ebx,3
                jb      _ret
                mov     danger_flag,0
                shl     ebx,16+1

                ret

; compose_speaker ----------------------------------------------------
; compose a simple PSG sound through the PC speaker
; the method used is temporal MUX with masking
; warning: this routine is called inside the emulation
; ie must preserve edx, edi, ebp, eax=0
                
compose_speaker:
                ; evaluate all the volumes, 
                ; taking into account the mixer

                mov     al,byte ptr [offset psgreg+7]
                xor     al,255
                ; channel 1
                shr     al,1
                sbb     ah,ah
                and     ah,byte ptr [offset psgreg+8]
                mov     byte ptr [offset speakervolume+0],ah
                ; channel 2
                shr     al,1
                sbb     ah,ah
                and     ah,byte ptr [offset psgreg+9]
                mov     byte ptr [offset speakervolume+1],ah
                ; channel 3
                shr     al,1
                sbb     ah,ah
                and     ah,byte ptr [offset psgreg+10]
                mov     byte ptr [offset speakervolume+2],ah

                ; find the volume with maximum amplitude
                mov     al,byte ptr [offset speakervolume+0]
                cmp     al,byte ptr [offset speakervolume+1]
                ja      compose_speaker_skip1
                mov     al,byte ptr [offset speakervolume+1]
compose_speaker_skip1:
                cmp     al,byte ptr [offset speakervolume+2]
                ja      compose_speaker_skip2
                mov     al,byte ptr [offset speakervolume+2]
compose_speaker_skip2:

                cmp     al,0
                je      speaker_shutup

                ; evaluate the threshold volume
                shr     al,1

                mov     esi,speakerchannel
                inc     esi
                cmp     esi,3
                jne     compose_speaker_continue
                mov     esi,0
compose_speaker_continue:
                mov     speakerchannel,esi
                cmp     byte ptr [offset speakervolume+esi],al
                jb      compose_speaker_ret

                movzx   ebx,word ptr [offset psgreg+esi*2]

                ; at this point ebx must contain the desired freq
                cmp     speakersilence,0
                je      compose_speaker_go
                cmp     ebx,speakerfreq
                je      compose_speaker_ret

compose_speaker_go:
                mov     speakersilence,1
                mov     speakerfreq,ebx
                push    edx
                mov     eax,700919
                mul     ebx
                shrd    eax,edx,16
                push    eax
                mov     edx,043h
                mov     al,0B6h
                out     dx,al
                dec     edx
                pop     eax
                out     dx,al
                mov     al,ah
                out     dx,al
                mov     edx,061h
                in      al,dx
                or      al,3
                out     dx,al
                pop     edx

compose_speaker_ret:
                mov     eax,0
                ret

; speaker_shutup -----------------------------------------------------
; shut up the speaker                

speaker_shutup:
                push    edx
                mov     edx,061h
                in      al,dx
                and     al,0FCh
                out     dx,al
                pop     edx
                mov     eax,0
                mov     speakersilence,eax
                ret

; compose_purenoise --------------------------------------------------
; compose a pure white noise
; used in the TURN OFF option of the GUI

compose_purenoise:
                mov     edx,noise_counter
                mov     ebp,noise_counter2
                mov     edi,0
                mov     ebx,offset doublebuffer ; dmatemp
                
compose_purenoise_loop:
patch__45:      mov     al,byte ptr [offset noise_table_z+edx]
patch__46:      xor     al,byte ptr [offset noise_table_z+ebp]
                inc     edx
                inc     ebp
                and     al,15
                mov     [ebx+edi],al
                and     edx,16383
                cmp     ebp,16383
                sbb     ecx,ecx
                and     ebp,ecx

                inc     edi
patch__220:     cmp     edi,BUFFERSIZE
                jne     compose_purenoise_loop

                mov     noise_counter,edx
                mov     noise_counter2,ebp
                
                ret
                
; compose_envelope ---------------------------------------------------
; compose the envelope

compose_envelope:
                mov     esi,offset psgregstack 
                mov     edi,offset PSGreg
                mov     ecx,16/4
                rep     movsd

                mov     edi,actual_channel
                mov     edx,dword ptr [offset PSGcounter+edi*4]
                mov     eax,dword ptr [offset PSGstate+edi*4]

                mov     ecx,0
                mov     ebp,timebuffer
                mov     ebp,[ebp]
                shl     ebp,8

                and     eax,0FFFFh
                mov     edi,0

compose_envelope_outer:

                call    modify_parameters_envelope

; --------------------------------------------------------------------
                
compose_envelope_outer_loop:
                cmp     envelope_first,1
                jne     compose_envelope_loop

compose_envelope_first_loop:                
                ; warning: this loop is HEAVILY convoluted
                ; the output is one sample delayed

                add     edx,ebx 
                cmp     edx,16*65536*256
                jae     compose_envelope_change
                mov     esi,edx
                shr     esi,16+8
patchenv1:      mov     al,[esi+12345678h]
patch__316:     add     ecx,CLOCKSPERSAMPLE
                mov     [edi+offset envstream],al

                cmp     ecx,ebp
                jae     compose_envelope_check

                inc     edi
patch__221:     cmp     edi,BUFFERSIZE
                jne     compose_envelope_first_loop

                jmp     compose_envelope_exit

; --------------------------------------------------------------------
                
compose_envelope_change:
                sub     edx,ebx
                sub     edx,16*65536*256
                mov     envelope_first,0

; --------------------------------------------------------------------
                
compose_envelope_loop:                
                ; warning: this loop is HEAVILY convoluted
                ; the output is one sample delayed

                add     edx,ebx 
                and     edx,536870911 ; this is 32*65536*256-1
                mov     esi,edx
                shr     esi,16+8
patchenv2:      mov     al,[esi+12345678h+16]
patch__317:     add     ecx,CLOCKSPERSAMPLE
                mov     [edi+offset envstream],al

                cmp     ecx,ebp
                jae     compose_envelope_check

                inc     edi
patch__222:     cmp     edi,BUFFERSIZE
                jne     compose_envelope_loop

; --------------------------------------------------------------------
                
compose_envelope_exit:

                mov     edi,actual_channel
                mov     dword ptr [offset PSGcounter+edi*4],edx
                mov     dword ptr [offset PSGstate+edi*4],eax
                
                ret

; --------------------------------------------------------------------

compose_envelope_check:
                mov     ebp,localpos
                add     ebp,ebp
                add     ebp,soundbuffer

                mov     dh,byte ptr [ebp+1]
                movzx   ebp,byte ptr [ebp]
                cmp     ebp,15
                ja      compose_envelope_notpsg
                mov     [offset PSGreg+ebp],dh
                cmp     ebp,13
                jne     compose_envelope_notpsg
                mov     edx,0                                
                mov     envelope_first,1

compose_envelope_notpsg:

                mov     ebp,localpos
                inc     ebp
                mov     localpos,ebp

                shl     ebp,2
                add     ebp,timebuffer
                mov     ebp,dword ptr [ebp]
                shl     ebp,8

                call    modify_parameters_envelope

                inc     edi
patch__223:     cmp     edi,BUFFERSIZE
                jne     compose_envelope_outer_loop

                jmp     compose_envelope_exit

; --------------------------------------------------------------------
                
modify_parameters_envelope:
                
                push    edi
                mov     edi,actual_channel
                mov     dword ptr [offset PSGcounter+edi*4],edx
                mov     dword ptr [offset PSGstate+edi*4],eax
                pop     edi
                
                mov     eax,actual_channel
                
                ; ebx = start_counter
                movzx   edx,word ptr [offset PSGreg+11]
                cmp     ebx,edx
                je      modify_parameters_envelope_samefreq
                
                mov     ebx,edx
                cmp     ebx,0
                je      modify_parameters_envelope_samefreq

                mov     edx,0
                mov     eax,_envelopefactor ;ENVELOPEFACTOR
                div     ebx
                mov     ebx,eax

modify_parameters_envelope_samefreq:

                mov     eax,actual_channel
                
                ; edx = psg_counter
                mov     edx,dword ptr [offset PSGcounter+eax*4]

                movzx   eax,byte ptr [offset PSGreg+13]
                and     eax,0Fh
                lea     eax,[eax+eax*2]
                shl     eax,4
                add     eax,offset envelope_table
                mov     dword ptr [offset patchenv1+2],eax
                add     eax,16
                mov     dword ptr [offset patchenv2+2],eax

                ret

; set_adlib_register -------------------------------------------------
; set an adlib register
; enter: bh = register; bl = value

set_adlib_register:
                push    edx eax

                mov     dx,0388h
                mov     al,bh
                out     dx,al

                rept    6
                in      al,dx
                endm

                inc     dx
                mov     al,bl
                out     dx,al
                dec     dx

                rept    35
                in      al,dx
                endm

                pop     eax edx
                ret

; reset_adlib --------------------------------------------------------
; reset the adlib and stop all the voices

reset_adlib:
                cmp     fmenabled,1
                jne     _ret
                
                mov     ecx,0F6h
                mov     ebx,0
reset_adlib_loop:
                call    set_adlib_register
                inc     bh
                dec     ecx
                jnz     reset_adlib_loop

                mov     edi,offset FMreg
                mov     ecx,040h / 4
                mov     eax,0
                rep     stosd

                ret

; init_adlib ---------------------------------------------------------
; init the adlib and set all instruments

init_adlib:
                call    reset_adlib

                ret

; fm_slice -----------------------------------------------------------
; process a single slice of fm emulation through the adlib

fm_slice:
                mov     ecx,040h
                mov     ebx,0

fm_slice_loop:
                mov     al,[offset fmreg+ebx]
                cmp     al,[offset FMreg+ebx]
                je      fm_slice_skip

                call    fm_single_register

fm_slice_skip:
                inc     ebx
                dec     ecx
                jnz     fm_slice_loop

                ret

; fm_single_register -------------------------------------------------
; emulate a single register of FM
; enter: al=new value ; bl = register
; must preserve esi,edi,ecx,ebx

fm_single_register:
                pushad
                and     ebx,0FFh
                and     eax,0FFh

                cmp     bl,0Eh
                jne     fm_single_register_LF

                ; 0Eh
                ; Rhythm Control

                ;mov     bl,al
                ;and     bl,3Fh
                ;mov     bh,0BDh
                ;call    set_adlib_register
                ;irp     i,<0B6h,0B7h,0B8h>
                ;mov     bh,i
                ;mov     bl,0
                ;call    set_adlib_register
                ;endm

                jmp     fm_single_register_ret

fm_single_register_LF:
                cmp     bl,010h
                jb      fm_single_register_SKOF
                cmp     bl,018h
                ja      fm_single_register_SKOF

                sub     ebx,10h
                mov     al,byte ptr [offset fmreg+ebx+10h]
                shl     al,1
                mov     bh,bl
                mov     bl,al
                add     bh,0A0h
                call    set_adlib_register

                jmp     fm_single_register_ret

fm_single_register_SKOF:
                cmp     bl,020h
                jb      fm_single_register_IV
                cmp     bl,028h
                ja      fm_single_register_IV

                ; 020h - 028h
                ; Sust/Key/Octave/Freq

                sub     ebx,20h
                mov     al,byte ptr [offset fmreg+ebx+10h]
                shl     al,1
                mov     bh,bl
                mov     bl,al
                add     bh,0A0h
                call    set_adlib_register

                mov     bl,bh
                sub     bl,0A0h
                and     ebx,0FFh
                ;sub     bl,20h
                mov     al,byte ptr [offset fmreg+ebx+10h]
                mov     ah,byte ptr [offset fmreg+ebx+20h]
                shr     eax,7
                and     eax,3
                mov     bh,byte ptr [offset fmreg+ebx+20h]
                and     bh,11110b
                shl     bh,1
                or      al,bh
                mov     bh,bl
                mov     bl,al
                add     bh,0B0h
                call    set_adlib_register

                jmp     fm_single_register_ret

fm_single_register_IV:
                cmp     bl,30h
                jb      fm_single_register_ret
                cmp     bl,038h
                ja      fm_single_register_ret

                ; 030h - 038h 
                ; Instrument/Volume

                sub     bl,30h
                call    fm_change_instrument
                and     al,0Fh
                shl     al,2
                mov     bh,byte ptr [offset fm_channel_table+ebx]
                add     bh,040h
                mov     bl,al
                call    set_adlib_register
                jmp     fm_single_register_ret

fm_single_register_ret:
                popad
                mov     al,[offset fmreg+ebx]
                mov     [offset FMreg+ebx],al
                ret

fm_change_instrument:
                push    eax
                and     al,0F0h
                mov     ah,byte ptr [offset FMreg+ebx]
                and     ah,0F0h
                xor     al,ah
                pop     eax
                jz      _ret

                pushad
                mov     edx,ebx
                mov     cl,byte ptr [offset fm_channel_table+edx]
                mov     ch,byte ptr [offset fm_channel_table+edx+1]
                mov     esi,ebx
                shl     esi,4
                add     esi,offset fm_instrument_table

                ; char 1
                mov     bh,cl
                add     bh,020h
                mov     bl,[esi]
                inc     esi
                call    set_adlib_register

                ; char 2
                mov     bh,ch
                add     bh,020h
                mov     bl,[esi]
                inc     esi
                call    set_adlib_register

                ; level 1
                mov     bh,cl
                add     bh,040h
                mov     bl,[esi]
                inc     esi
                ;call    set_adlib_register

                ; level 2
                mov     bh,ch
                add     bh,040h
                mov     bl,[esi]
                inc     esi
                call    set_adlib_register

                ; attdec 1
                mov     bh,cl
                add     bh,060h
                mov     bl,[esi]
                inc     esi
                call    set_adlib_register

                ; attdec 2
                mov     bh,ch
                add     bh,060h
                mov     bl,[esi]
                inc     esi
                call    set_adlib_register

                ; susrel 1
                mov     bh,cl
                add     bh,080h
                mov     bl,[esi]
                inc     esi
                call    set_adlib_register

                ; susrel 2
                mov     bh,ch
                add     bh,080h
                mov     bl,[esi]
                inc     esi
                call    set_adlib_register

                ; wave 1
                mov     bh,cl
                add     bh,0E0h
                mov     bl,[esi]
                inc     esi
                call    set_adlib_register

                ; wave 2
                mov     bh,ch
                add     bh,0E0h
                mov     bl,[esi]
                inc     esi
                call    set_adlib_register

                ; feedback
                mov     bh,dl
                add     bh,0C0h
                mov     bl,[esi]
                inc     esi
                call    set_adlib_register

                popad
                ret

; --------------------------------------------------------------------

code32          ends
                end

