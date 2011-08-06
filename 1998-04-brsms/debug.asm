; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: DEBUG.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include io.inc
include z80.inc
include vdp.inc
include pentium.inc
include saveload.inc
include blit.inc
include bit.inc
include compiler.inc
include serial.inc
include psg.inc
include mouse.inc
include joystick.inc
include drive.inc
include z80core.inc

include debugsrc.inc
include debug2sr.inc
include helpsrc.inc
include srsrc.inc
include clsrc.inc

extrn msxrom: near
extrn msxram: dword
extrn pentiumfound: dword
extrn isize: dword
extrn setup_profile: near
extrn end_profile: near
extrn dirtycode: dword
extrn compbuffer: dword
extrn msxvram: dword

public debug
public printmsgd
public writemessage

public change_sound
public changebargraph

public quitnow
public vesa2found

public startdebugger

; DATA ---------------------------------------------------------------

align 4

temp_screen     db      3840 dup (0)
message         db      80*2 dup (0)
messagepointer  dd      0
memdump         dd      0
tabspace        db      ' $'
tabindicator    db      '>$'
flags           db      '00000000$'
msgpentiumonly  db      'This option requires a Pentium$'
msgparcodeinserted  db      'PAR code inserted$'
msgparcodecleared   db      'All PAR codes cleared$'
res320          db      '320x200$'
res256          db      '400x300$'
res512          db      '512x384$'
res192          db      '512x384$'
modenormal      db      'NORMAL$'
modefast        db      'FAST  $'
modeturbo       db      'TURBO $'
stateon         db      'ON $'
stateoff        db      'OFF$'
intdi           db      'DI$'
intei           db      'EI$'
imagedynamic    db      ' OFF   $'
imagestatic     db      ' ON    $'
sprite8x8       db      '8x8 $'
sprite8x16      db      '8x16$'
com1            db      '1$'
com2            db      '2$'
com3            db      '3$'
com4            db      '4$'
joyn            db      '-$'
joya            db      'A$'
joyb            db      'B$'
imode0          db      'IM0$'
imode1          db      'IM1$'
imode2          db      'IM2$'
sessionsingle   db      'SINGLE$'
sessionserver   db      'SERVER$'
sessionclient   db      'CLIENT$'

align 4

quitnow         dd      0
vesa2found      dd      0
debugtype       dd      1
startdebugger   dd      0
firstone        dd      0
nextbp          dd      0
parnumber       dd      0

; COORD --------------------------------------------------------------
; convert coordinates from ASCII.EXE system to 
; the dh,dl format used by printmsgd

COORD           macro   x,y

                mov     dx,(y-1)*256+(x-1)

                endm

; clear_text ---------------------------------------------------------
; clear the text screen

clear_text:
                push    eax edi ecx
                mov     eax,07200720h
                mov     edi,offset message
                mov     ecx,80*2/4
                rep     stosd
                mov     eax,offset message
                mov     messagepointer,eax
                pop     ecx edi eax
                jmp     printmessage

; printmessage -------------------------------------------------------
; print the message in bottom line of screen

printmessage:
                push    eax esi edi ecx es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset message
                mov     edi,0b8000h+80*24*2
                mov     ecx,80*2/4
                rep     movsd
                pop     es ecx edi esi eax
                ret

; writemessage -------------------------------------------------------
; write a dos string in the message space

writemessage:
                mov     edx,messagepointer
                mov     bl,[eax]
                cmp     bl,'$'
                je      _ret
                mov     [edx],bl
                add     messagepointer,2
                inc     eax
                jmp     writemessage

; write8 -------------------------------------------------------------
; write a 8-byte hex number in the message field

write8:
                push    eax
                shr     eax,16
                call    convhex4
                mov     eax,offset tmphex4
                call    writemessage
                pop     eax
                call    convhex4
                mov     eax,offset tmphex4
                call    writemessage
                ret

; printmsgd ----------------------------------------------------------
; print a message in dos format, 
; drawing directly in the temp buffer
; enter: dh=row, dl=column
;        eax= offset of message

printmsgd:
                push    eax edi edx
                movzx   edi,dh
                lea     edi,[edi+edi*4]
                shl     edi,5
                and     edx,0FFh
                lea     edi,[edi+edx*2]
                add     edi,offset temp_screen
printmsgd1:
                mov     dl,[eax]
                cmp     dl,'$'
                je      printmsgd2
                mov     [edi],dl
                add     edi,2
                inc     eax
                jmp     printmsgd1
printmsgd2:
                pop     edx edi eax
                ret

; --------------------------------------------------------------------
                
emulate_client:                
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset client_screen
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es
                call    turnon_kb_irq
                call    UART_init
                call    UART_send_idstring

emulate_client_loop:
                ;call    UART_receive_idstring

                mov     al,smsjoya
                and     al,111111b

                call    UART_send

                mov     al,smsjoyb
                test    al,BIT_4
                jnz     emulate_client_loop

                mov     smsjoyb,0FFh

                call    turnoff_kb_irq
                jmp     debug_loop

; --------------------------------------------------------------------

changemode:
                inc     emulatemode
                cmp     emulatemode,3
                jne     _ret
                mov     emulatemode,0
                ret

; --------------------------------------------------------------------

changevideomode:
                xor     videomode,2
                cmp     videomode,2
                je      changevideomode_vesa2
                cmp     videomode,4
                jne     _ret
                mov     videomode,0
                ret
changevideomode_vesa2:
                cmp     vesa2found,0
                jne     _ret
                mov     videomode,0
                ret

; --------------------------------------------------------------------

change_sound:
                mov     eax,sounddetected
                xor     soundenabled,eax
                ret

; --------------------------------------------------------------------

change_scc:
                xor     sccenabled,1
                ret

; --------------------------------------------------------------------

change_joystick:
                add     joyenable,1
                cmp     joyenable,3
                jne     _ret
                mov     joyenable,0
                ret

; --------------------------------------------------------------------

changebargraph:
                ;mov     eax,pentiumfound
                xor     bargraphmode,1 ;eax
                ret

; --------------------------------------------------------------------

change_vsync:
                xor     vsyncflag,1
                ret

; --------------------------------------------------------------------

changesession:
                inc     sessionmode
                cmp     sessionmode,3
                jne     _ret
                mov     sessionmode,0
                ret

; --------------------------------------------------------------------

checkpentium:
                cmp     pentiumfound,1
                je      checkpentium1
                mov     eax,offset msgpentiumonly
                call    writemessage
                stc
                ret
checkpentium1:
                or      eax,eax
                ret

; render_debug -------------------------------------------------------
; render a debug screen

render_debug:

                cmp     debugtype,2
                je      render_debug2

                ; copy the template to temp buffer
                
                mov     esi,offset debug_screen
                mov     edi,offset temp_screen
                mov     ecx,3840/4
                rep     movsd

                call    status_bar

; --------------------------------------------------------------------

                ; print the contents of Z80 registers

                mov     eax,regeaf
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,2
                call    printmsgd

                mov     eax,regebc
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,3
                call    printmsgd

                mov     eax,regede
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,4
                call    printmsgd

                mov     eax,regehl
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,5
                call    printmsgd

                mov     eax,regeix
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,6
                call    printmsgd

                mov     eax,regeiy
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,7
                call    printmsgd

                mov     eax,regepc
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,8
                call    printmsgd

                mov     eax,regesp
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,9
                call    printmsgd

                mov     eax,regeafl
                call    convhex4
                mov     eax,offset tmphex4
                COORD   59,2
                call    printmsgd

                mov     eax,regebcl
                call    convhex4
                mov     eax,offset tmphex4
                COORD   59,3
                call    printmsgd

                mov     eax,regedel
                call    convhex4
                mov     eax,offset tmphex4
                COORD   59,4
                call    printmsgd

                mov     eax,regehll
                call    convhex4
                mov     eax,offset tmphex4
                COORD   59,5
                call    printmsgd

; --------------------------------------------------------------------
                
                ; dump the msx memory

                irp     i,<0,1,2,3>
                mov     eax,memdump
                add     eax,i*8

                ; print the address
                push    eax                
                call    convhex4
                COORD   4,16+i
                mov     eax,offset tmphex4
                call    printmsgd
                pop     eax

                ; print the contents in hex format
                xor     ecx,ecx
                COORD   9,16+i
print_dump1&i:
                push    eax
                lea     edi,[eax+ecx]
                and     edi,0FFFFh
                call    fetch
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                pop     eax
                add     edx,3
                inc     ecx
                cmp     ecx,8
                jnz     print_dump1&i
                
                ; print the contents in ascii format
                xor     ecx,ecx
                COORD   33,16+i
print_dump2&i:
                push    eax
                lea     edi,[eax+ecx]
                and     edi,0FFFFh
                call    fetch
                cmp     al,32
                jb      print_dump3&i
                cmp     al,128
                jae     print_dump3&i
                mov     tabspace,al
                push    edx
                mov     eax,offset tabspace
                call    printmsgd
                pop     edx
print_dump3&i:
                pop     eax
                inc     ecx                
                inc     edx
                cmp     ecx,8
                jnz     print_dump2&i

                endm

; --------------------------------------------------------------------
                
                ; print the contents of VDP registers

                mov     ecx,0
                mov     esi,offset vdpregs
                COORD   71,2
print_vdp1:
                mov     al,[esi]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                inc     esi
                inc     ecx
                cmp     ecx,16
                jnz     print_vdp1

; --------------------------------------------------------------------
                
                ; print the contents of BG palette registers

                mov     ecx,0
                mov     esi,offset smspalette
                COORD   74,2
print_pal1:
                mov     al,[esi]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                inc     esi
                inc     ecx
                cmp     ecx,16
                jnz     print_pal1

; --------------------------------------------------------------------
                                               
                ; print the contents of SP palette registers

                mov     ecx,0
                mov     esi,offset smspalette+16
                COORD   77,2
print_pal2:
                mov     al,[esi]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                inc     esi
                inc     ecx
                cmp     ecx,16
                jnz     print_pal2

; --------------------------------------------------------------------
                
                ; print the contents of sound freq registers

                mov     ecx,0
                mov     esi,offset psgreg
                COORD   57,13
print_psg1:
                mov     ax,[esi]
                call    convhex4
                mov     eax,offset tmphex4
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                add     esi,2
                inc     ecx
                cmp     ecx,4
                jnz     print_psg1

; --------------------------------------------------------------------
                
                ; print the contents of sound volume registers

                mov     ecx,0
                mov     esi,offset psgreg+8
                COORD   62,13
print_psg2:
                mov     al,[esi]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                inc     esi
                inc     ecx
                cmp     ecx,4
                jnz     print_psg2

; --------------------------------------------------------------------
                
                ; print the contents of mapper registers

                mov     ecx,0
                mov     esi,offset mapperblock
                COORD   50,13
print_mapper:
                mov     eax,[esi]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                add     esi,4
                inc     ecx
                cmp     ecx,3
                jnz     print_mapper

; --------------------------------------------------------------------
                
                ; print contents of Z80 register "I"

                mov     al,regi
                call    convhex4
                COORD   48,10
                mov     eax,offset tmphex2
                call    printmsgd

; --------------------------------------------------------------------
                
                ; print contents of iff1 flag: DI or EI

                cmp     iff1,0
                je      print_iff1
                mov     eax,offset intei
                jmp     print_iff0
print_iff1:
                mov     eax,offset intdi
print_iff0:
                COORD   51,10
                call    printmsgd

; --------------------------------------------------------------------
                
                ; print interrupt mode

                cmp     imtype,2
                je      print_im2
                cmp     imtype,0
                je      print_im0
                mov     eax,offset imode1
                jmp     print_im_print
print_im0:
                mov     eax,offset imode0
                jmp     print_im_print
print_im2:
                mov     eax,offset imode2
print_im_print:
                COORD   55,10
                call    printmsgd

; --------------------------------------------------------------------
                
                ; disassemble the program

                mov     ecx,0
                mov     edi,regepc
                mov     firstone,1
print_dis0:
                xor     eax,eax
                COORD   23,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                push    edi
                call    print
                pop     edi
                
                ; print the address
                COORD   4,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                mov     eax,edi
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd

                ; print the pc indicator
                cmp     edi,regepc
                jne     print_dis2
                COORD   8,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                mov     eax,offset tabindicator
                call    printmsgd

print_dis2:
                ; print the opcode
                COORD   10,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                push    ecx
                mov     ecx,isize
print_dis1:
                call    fetch                                
                call    convhex4
                mov     eax,offset tmphex2
                call    printmsgd
                add     edx,3
                inc     edi
                and     edi,0FFFFh
                dec     ecx
                jnz     print_dis1
                pop     ecx

                cmp     firstone,1
                jne     print_dis_skip
                mov     firstone,0
                mov     ebp,isize
                add     ebp,regepc
                and     ebp,0FFFFh
                mov     nextbp,ebp
print_dis_skip:

                inc     ecx
                cmp     ecx,11
                jne     print_dis0

; --------------------------------------------------------------------
                
                ; print the Z80 flags

                mov     ecx,8
                mov     eax,offset flags+7
                mov     ebx,regeaf
print_flags0:
                xor     edx,edx
                shr     ebx,1
                adc     dl,'0'
                mov     [eax],dl
                dec     eax
                dec     ecx
                jnz     print_flags0
                COORD   55,8
                mov     eax,offset flags
                call    printmsgd
                
; --------------------------------------------------------------------
                
                ; print the Z80 register "R"

                mov     eax,rcounter
                and     eax,07Fh
                or      al,rmask
                call    convhex4
                mov     eax,offset tmphex2
                COORD   61,10
                call    printmsgd
                
; --------------------------------------------------------------------
                
                ; print the current line
                
                mov     eax,currentline
                call    convhex4
                mov     eax,offset tmphex4
                COORD   60,19
                call    printmsgd

                mov     eax,linesleft
                call    convhex4
                mov     eax,offset tmphex4
                COORD   60,18
                call    printmsgd

                movzx   eax,vdpstatus
                ;mov     eax,mousex
                call    convhex4
                mov     eax,offset tmphex2
                COORD   77,19
                call    printmsgd

; --------------------------------------------------------------------
                
                ; blit the temp buffer to screen 
                
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset temp_screen
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es

                ret

; --------------------------------------------------------------------
                
render_debug2:
                ; second debug screen
                ; copy the template to temp buffer
                
                mov     esi,offset debug2_screen
                mov     edi,offset temp_screen
                mov     ecx,3840/4
                rep     movsd

                call    status_bar

; --------------------------------------------------------------------
                
                ; print the vertical interrupt on/off

                test    byte ptr [offset vdpregs+1],BIT_5
                jnz     print_virq1
                mov     eax,offset stateoff
                jmp     print_virq0
print_virq1:
                mov     eax,offset stateon
print_virq0:
                COORD   28,3
                call    printmsgd

; --------------------------------------------------------------------
                
                ; print the horizontal interrupt on/off

                test    byte ptr [offset vdpregs+0],BIT_4
                jnz     print_hirq1
                mov     eax,offset stateoff
                jmp     print_hirq0
print_hirq1:
                mov     eax,offset stateon
print_hirq0:
                COORD   28,4
                call    printmsgd

; --------------------------------------------------------------------
                
                ; print the sprite size

                test    byte ptr [offset vdpregs+1],BIT_1
                jnz     print_sprsize1
                mov     eax,offset sprite8x8
                jmp     print_sprsize0
print_sprsize1:
                mov     eax,offset sprite8x16
print_sprsize0:
                COORD   17,6
                call    printmsgd

; --------------------------------------------------------------------
                
                ; print the sprite zoom

                test    byte ptr [offset vdpregs+1],BIT_0
                jnz     print_sprzoom1
                mov     eax,offset stateoff
                jmp     print_sprzoom0
print_sprzoom1:
                mov     eax,offset stateon
print_sprzoom0:
                COORD   17,7
                call    printmsgd

; --------------------------------------------------------------------
                
                ; print the screen enable flag

                test    byte ptr [offset vdpregs+1],BIT_6
                jnz     print_screnable1
                mov     eax,offset stateoff
                jmp     print_screnable0
print_screnable1:
                mov     eax,offset stateon
print_screnable0:
                COORD   20,9
                call    printmsgd
                                          
; --------------------------------------------------------------------
                
                ; print the screen stretch flag

                test    byte ptr [offset vdpregs+0],BIT_1
                jnz     print_scrstretch1
                mov     eax,offset stateoff
                jmp     print_scrstretch0
print_scrstretch1:
                mov     eax,offset stateon
print_scrstretch0:
                COORD   20,10
                call    printmsgd
                                                        
; --------------------------------------------------------------------
                
                ; print the screen stretch by 4 flag

                test    byte ptr [offset vdpregs+1],BIT_4 
                jnz     print_scrstretch14
                mov     eax,offset stateoff
                jmp     print_scrstretch04
print_scrstretch14:
                mov     eax,offset stateon
print_scrstretch04:
                COORD   20,11
                call    printmsgd
                                                        
; --------------------------------------------------------------------
                
                ; print the screen stretch by 6 flag

                test    byte ptr [offset vdpregs+1],BIT_3
                jnz     print_scrstretch16
                mov     eax,offset stateoff
                jmp     print_scrstretch06
print_scrstretch16:
                mov     eax,offset stateon
print_scrstretch06:
                COORD   20,12
                call    printmsgd
                                                        
; --------------------------------------------------------------------
                
                ; print the undocumented mode

                test    byte ptr [offset vdpregs+0],BIT_2
                jnz     print_undoc1
                mov     eax,offset stateon
                jmp     print_undoc0
print_undoc1:
                mov     eax,offset stateoff
print_undoc0:
                COORD   23,14
                call    printmsgd
                                                        
; --------------------------------------------------------------------
                
                ; print the fm mode

                cmp     fmtouched,1
                jne     print_fm1
                mov     eax,offset stateon
                jmp     print_fm0
print_fm1:
                mov     eax,offset stateoff
print_fm0:
                COORD   14,13
                call    printmsgd
                                                        
; --------------------------------------------------------------------
                
                ; print the contents of VDP registers

                mov     ecx,0
                mov     esi,offset vdpregs
                COORD   71,2
print_vdp2:
                mov     al,[esi]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                inc     esi
                inc     ecx
                cmp     ecx,16
                jnz     print_vdp2

; --------------------------------------------------------------------
                
                ; print the contents of BG palette registers

                mov     ecx,0
                mov     esi,offset smspalette
                COORD   74,2
print_pal2b:
                mov     al,[esi]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                inc     esi
                inc     ecx
                cmp     ecx,16
                jnz     print_pal2b

; --------------------------------------------------------------------
                                               
                ; print the contents of SP palette registers

                mov     ecx,0
                mov     esi,offset smspalette+16
                COORD   77,2
print_pal2c:
                mov     al,[esi]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                inc     esi
                inc     ecx
                cmp     ecx,16
                jnz     print_pal2c

; --------------------------------------------------------------------
                
                ; dump the vram memory

                irp     i,<0,1,2,3>
                mov     eax,memdump
                add     eax,i*8
                and     eax,03FFFh

                ; print the address
                push    eax                
                call    convhex4
                COORD   4,16+i
                mov     eax,offset tmphex4
                call    printmsgd
                pop     eax

                ; print the contents in hex format
                xor     ecx,ecx
                COORD   9,16+i
vprint_dump1&i:
                push    eax
                lea     edi,[eax+ecx]
                and     edi,03FFFh
                ;call    fetch
                mov     eax,msxvram
                mov     al,[edi+eax]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                pop     eax
                add     edx,3
                inc     ecx
                cmp     ecx,8
                jnz     vprint_dump1&i
                
                ; print the contents in ascii format
                xor     ecx,ecx
                COORD   33,16+i
vprint_dump2&i:
                push    eax
                lea     edi,[eax+ecx]
                and     edi,03FFFh
                ;call    fetch
                mov     eax,msxvram
                mov     al,[edi+eax]
                cmp     al,32
                jb      vprint_dump3&i
                cmp     al,128
                jae     vprint_dump3&i
                mov     tabspace,al
                push    edx
                mov     eax,offset tabspace
                call    printmsgd
                pop     edx
vprint_dump3&i:
                pop     eax
                inc     ecx                
                inc     edx
                cmp     ecx,8
                jnz     vprint_dump2&i

                endm

; --------------------------------------------------------------------
                
                ; print VDP address

                movzx   eax,vdpaddress
                and     eax,03FFFh
                call    convhex4
                mov     eax,offset tmphex4
                COORD   75,19
                call    printmsgd
                
; --------------------------------------------------------------------
                
                ; blit the temp buffer to screen 
                
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset temp_screen
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es

                ret

; --------------------------------------------------------------------
                
status_bar:

                ; print the resolution
                
                cmp     videomode,1
                jae     print_res1
                mov     eax,offset res320
                jmp     print_res0
print_res1:
                cmp     videomode,2
                jae     print_res2
                mov     eax,offset res256
                jmp     print_res0
print_res2:
                cmp     videomode,6
                jae     print_res3
                mov     eax,offset res512
                jmp     print_res0
print_res3:
                mov     eax,offset res192
print_res0:
                COORD   15,21
                call    printmsgd
                
; --------------------------------------------------------------------

                ; print the emulation mode

                cmp     emulatemode,0
                jne     print_mode1
                mov     eax,offset modenormal
                jmp     print_mode0
print_mode1:
                cmp     emulatemode,1
                jne     print_mode2
                mov     eax,offset modefast
                jmp     print_mode0
print_mode2:
                mov     eax,offset modeturbo
print_mode0:
                COORD   73,21
                call    printmsgd

; --------------------------------------------------------------------

                ; print the vsync mode

                cmp     vsyncflag,0
                jne     print_vsync1
                mov     eax,offset stateoff
                jmp     print_vsync_done
print_vsync1:
                mov     eax,offset stateon
print_vsync_done:
                COORD   30,22
                call    printmsgd

; --------------------------------------------------------------------

                ; print the sound mode

                cmp     soundenabled,0
                jne     print_sound1
                mov     eax,offset stateoff
                jmp     print_sound_done
print_sound1:
                mov     eax,offset stateon
print_sound_done:
                COORD   18,22
                call    printmsgd

; --------------------------------------------------------------------

                ; print the bar graph status

                cmp     bargraphmode,1
                je      print_bar1
                mov     eax,offset stateoff
                jmp     print_bar0
print_bar1:
                mov     eax,offset stateon
print_bar0:
                COORD   57,21
                call    printmsgd

; --------------------------------------------------------------------

                ; print the COM port being used

                COORD   57,22
                cmp     comport,1
                jne     print_com2
                mov     eax,offset com1
                call    printmsgd
                jmp     print_com_exit
print_com2:
                cmp     comport,2
                jne     print_com3
                mov     eax,offset com2
                call    printmsgd
                jmp     print_com_exit
print_com3:
                cmp     comport,3
                jne     print_com4
                mov     eax,offset com3
                call    printmsgd
                jmp     print_com_exit
print_com4:
                mov     eax,offset com4
                call    printmsgd
print_com_exit:

; --------------------------------------------------------------------

                ; print the session mode

                COORD   44,22
                cmp     sessionmode,0
                jne     print_session1
                mov     eax,offset sessionsingle
                call    printmsgd
                jmp     print_session_exit
print_session1:
                cmp     sessionmode,1
                jne     print_session2
                mov     eax,offset sessionserver
                call    printmsgd
                jmp     print_session_exit
print_session2:
                mov     eax,offset sessionclient
                call    printmsgd
print_session_exit:

; --------------------------------------------------------------------

                ; print the joystick mode

                COORD   8,22
                cmp     joyenable,0
                jne     joystick_mode1
                mov     eax,offset joyn
                call    printmsgd
                jmp     joystick_mode_exit
joystick_mode1:
                cmp     joyenable,1
                jne     joystick_mode2
                mov     eax,offset joya
                call    printmsgd
                jmp     joystick_mode_exit
joystick_mode2:
                mov     eax,offset joyb
                call    printmsgd
joystick_mode_exit:

; --------------------------------------------------------------------

                ; print the frame skipping factor

                mov     eax,framerate
                call    convhex4
                mov     eax,offset tmphex4
                COORD   40,21
                call    printmsgd

; --------------------------------------------------------------------

                ; print the image type

                cmp     imagetype,0
                jne     print_image0
                mov     eax,offset imagedynamic
                jmp     print_image1
print_image0:
                mov     eax,offset imagestatic
print_image1:
                COORD   72,22
                call    printmsgd

; --------------------------------------------------------------------

                ; print the SCC status

                cmp     sccenabled,0
                jne     print_scc0
                mov     eax,offset imagedynamic
                jmp     print_scc1
print_scc0:
                mov     eax,offset imagestatic
print_scc1:
                COORD   72,23
                call    printmsgd

                ret

; init_compiler ------------------------------------------------------
; initialize the luts for the compile pipeline

;init_compiler:
;                mov     ecx,131072 ; 64kb*8 /4
;                mov     eax,0
;                mov     edi,dirtycode
;                rep     stosd
;                mov     ecx,262144 ;1048576/4
;                mov     eax,0C3C3C3C3h
;                mov     edi,compbuffer
;                rep     stosd
;                mov     ebx,compbuffer
;                mov     nextopcode,ebx
;                ret

; --------------------------------------------------------------------

debug:          
                ;call    init_compiler
                call    set_com_baseaddr
                call    clear_text
                cmp     startdebugger,1
                je      debug_loop
                jmp     command_s
debug_loop:                
                call    reset_autoframe
                cmp     quitnow,1
                je      _ret
                call    render_debug
                call    printmessage
                COORD   12,23
                call    set_cursor_position
                call    getchar
                or      al,al
                je      command_extended
                call    clear_text
                call    toupper
                call    printasc
                call    crlf
                cmp     al,'D'
                je      command_d      
                cmp     al,'C'
                je      command_c
                cmp     al,'0'
                je      command_0
                cmp     al,'M'
                je      command_m
                ;cmp     al,'X'
                ;je      command_x
                cmp     al,'S'
                je      command_s
                cmp     al,'B'
                je      command_b
                cmp     al,'P'
                je      command_p
                cmp     al,'Y'
                je      command_y
                cmp     al,'F'
                je      command_f
                cmp     al,'?'
                je      command_find
                cmp     al,'H'
                je      command_h
                cmp     al,'J'
                je      command_j
                cmp     al,'K'
                je      command_k
                cmp     al,'R'
                je      command_r
                ;cmp     al,'A'
                ;je      command_a
                ;cmp     al,'I'
                ;je      command_i
                ;cmp     al,'L'
                ;je      command_l
                cmp     al,'G'
                je      command_g
                cmp     al,'T'
                je      command_t
                cmp     al,'1'
                je      command_1
                cmp     al,'2'
                je      command_2
                cmp     al,'V'
                je      command_v
                cmp     al,'E'
                je      command_e
                ;cmp     al,'Z'
                ;je      command_z
                cmp     al,'N'
                je      command_n
                ;cmp     al,'E'
                ;je      command_e
                cmp     al,'Q'
                je      command_exit
                cmp     al,27
                je      command_exit
                jmp     debug_loop

command_extended:
                call    crlf
                cmp     ah,59 ;F1
                je      command_help
                cmp     ah,65 ;F7
                je      command_t
                cmp     ah,66 ;F8
                je      command_stepover
                cmp     ah,73 ;page up
                je      command_pgup
                cmp     ah,81 ;page down
                je      command_pgdown
                jmp     debug_loop

command_pgup:
                cmp     debugtype,1
                jne     command_pgup_2
                sub     memdump,32
                and     memdump,0FFFFh
                jmp     debug_loop
command_pgup_2:
                sub     memdump,16*8
                and     memdump,0FFFFh
                jmp     debug_loop

command_find:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                mov     edx,eax
command_find_next:
                mov     ecx,memdump
                call    readmemw
                cmp     ax,dx
                je      debug_loop
                inc     memdump
                cmp     memdump,0FFFFh
                je      debug_loop
                jmp     command_find_next

command_pgdown:
                cmp     debugtype,1
                jne     command_pgdown_2
                add     memdump,32
                and     memdump,0FFFFh
                jmp     debug_loop
command_pgdown_2:
                add     memdump,16*8
                and     memdump,0FFFFh
                jmp     debug_loop

command_n:
                call    changesession
                jmp     debug_loop

command_d:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0FFFFh
                mov     memdump,eax
                jmp     debug_loop

command_y:              
                call    change_vsync
                jmp     debug_loop

command_z:
                call    UART_init
                call    UART_send_idstring
                jmp     debug_loop

command_r:
                call    save_histogram
                jmp     debug_loop

command_x:
                call    change_scc
                jmp     debug_loop

command_help:
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset help_screen
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es
                call    getchar
                jmp     debug_loop

command_g:
                call    checkpentium
                jc      debug_loop
                call    changebargraph
                jmp     debug_loop

command_f:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0ffffh
                mov     framerate,eax
                mov     on_off,eax
                call    crlf
                jmp     debug_loop

command_j:
                call    change_joystick
                jmp     debug_loop

command_v:      call    changevideomode
                jmp     debug_loop

command_i:
                xor     imagetype,1
                jmp     debug_loop

command_a:
                call    save_state
                jmp     debug_loop

command_l:
                call    load_state
                jmp     debug_loop

command_m:      
                call    changemode
                jmp     debug_loop

command_b:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0ffffh
                mov     breakpoint,eax
                call    crlf
                call    force_dirty
                call    setgraphmode
                call    turnon_irq
                call    turnon_kb_irq
                call    sound_on
                call    emulate_break
                call    sound_off
                call    speaker_shutup
                call    turnoff_kb_irq
                call    turnoff_irq
                call    settextmode
                call    crlf
                jmp     debug_loop

command_stepover:
                mov     eax,nextbp
                mov     breakpoint,eax
                call    crlf
                call    force_dirty
                call    setgraphmode
                call    turnon_irq
                call    turnon_kb_irq
                call    sound_on
                call    emulate_break
                call    sound_off
                call    speaker_shutup
                call    turnoff_kb_irq
                call    turnoff_irq
                call    settextmode
                call    crlf
                jmp     debug_loop

command_p:
                ;call    change_sound
                cmp     parnumber,4
                je      debug_loop

                mov     dword ptr [offset memlock+6*4],2
                mov     dword ptr [offset memlock+7*4],2
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0FFFFh
                push    eax
                call    gethex4
                and     eax,0FFFFh
                pop     edx
                shl     edx,8
                mov     ebx,eax
                shr     ebx,8
                and     ebx,0FFh
                or      edx,ebx
                and     edx,0FFFFh
                mov     ecx,parnumber
                inc     parnumber
                lea     ebp,[offset par1+ecx*4]
                mov     dword ptr [ebp],edx
                mov     ecx,msxram
                and     edx,01FFFh
                mov     byte ptr [ecx+edx],al
                mov     eax,offset msgparcodeinserted
                call    writemessage
                jmp     debug_loop

command_e:
                mov     dword ptr [offset par1+0*4],0
                mov     dword ptr [offset par1+1*4],0
                mov     dword ptr [offset par1+2*4],0
                mov     dword ptr [offset par1+3*4],0
                mov     parnumber,0
                mov     eax,offset msgparcodecleared
                call    writemessage
                jmp     debug_loop

command_h:
                call    force_dirty
                call    setgraphmode
                call    clear
                call    turnon_kb_irq
                call    turnon_irq
                call    sound_on
                call    emulate_histogr
                call    sound_off
                call    speaker_shutup
                call    turnoff_irq
                call    turnoff_kb_irq
                call    settextmode
                jmp     debug_loop

command_0:
                call    setgraphmode
                call    clear
                call    render
                call    sprite_render
                call    blit
                call    getchar
                call    settextmode
                jmp     debug_loop

command_s:      
                cmp     sessionmode,2
                je      emulate_client
                cmp     sessionmode,1
                jne     command_s_go
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,offset server_screen
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es
                call    UART_init
                call    UART_receive_idstring
command_s_go:
                call    force_dirty
                call    setgraphmode
                call    clear
                call    turnon_kb_irq
                call    turnon_irq
                call    sound_on
                call    emulate
                call    sound_off
                call    speaker_shutup
                call    turnoff_irq
                call    turnoff_kb_irq
                call    settextmode
                jmp     debug_loop

command_c:      
                call    calibrate_joystick
                mov     joyenable,1
                jmp     debug_loop

command_k:
                inc     comport
                cmp     comport,5
                jne     command_k_print
                mov     comport,1
command_k_print:
                call    set_com_baseaddr
                jmp     debug_loop

command_1:
                mov     debugtype,1
                jmp     debug_loop

command_2:
                mov     debugtype,2
                jmp     debug_loop

command_t:
                mov     edi,regepc
                mov     edx,regeaf
                mov     eax,0
                call    trace
                jmp     debug_loop

command_exit:
                ret

code32          ends
                end



