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
include serial.inc
include psg.inc
include mouse.inc
include joystick.inc
include drive.inc
include z80core.inc
include symdeb.inc

extrn msxrom: near
extrn pentiumfound: dword
extrn isize: dword
extrn setup_profile: near
extrn end_profile: near
extrn dirtycode: dword
extrn compbuffer: dword
extrn msxvram: dword
extrn sccram: dword
extrn temp_screen: dword

public debug
public printmsgd
public printnuld
public writemessage

public change_sound
public changebargraph

public quitnow
public vesa2found

public startdebugger

; DATA ---------------------------------------------------------------

debug_screen: 
include debug1.inc

debug2_screen: 
include debug2.inc

debug3_screen: 
include debug3.inc

debug4_screen: 
include debug4.inc

debug5_screen: 
include debug5.inc

debug6_screen: 
include debug6.inc

help_screen: 
include help.inc

server_screen: 
include server.inc

client_screen: 
include client.inc

align 4

message         db      80*2 dup (0)
messagepointer  dd      0
memdump         dd      0
vmemdump        dd      0
tabspace        db      ' $'
tabindicator    db      '>$'
flags           db      '00000000$'
msgpentiumonly  db      'This option requires a Pentium$'
res320          db      '320x200$'
res256          db      '256x200$'
res512          db      '512x384$'
res192          db      '256x192$'
modenormal      db      'NORMAL$'
modefast        db      'FAST  $'
modeturbo       db      'TURBO $'
stateon         db      'ON $'
stateoff        db      'OFF$'
intdi           db      'DI$'
intei           db      'EI$'
imagedynamic    db      ' OFF   $'
imagestatic     db      ' ON    $'
access_write    db      'Write$'
access_read     db      ' Read$'
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
stateyes        db      'YES$'
stateno         db      ' NO$'

fminstr         db      'Original        $'
                db      'Violin          $'
                db      'Guitar          $'
                db      'Piano           $'
                db      'Flute           $'
                db      'Clarinet        $'
                db      'Oboe            $'
                db      'Trumpet         $'
                db      'Organ           $'
                db      'Horn            $'
                db      'Synthesizer     $'
                db      'Harpsichord     $'
                db      'Vibraphone      $'
                db      'Synthesizer Bass$'
                db      'Wood Bass       $'
                db      'Eletric Guitar  $'
                db      '< DRUM MODE >   $'
                ;        12345678901234567

align 4

quitnow         dd      0
vesa2found      dd      0
debugtype       dd      1
startdebugger   dd      0
firstone        dd      0
nextbp          dd      0
disasm_address  dd      0
disasm_down     dd      0

debug_reg       dw      0

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
                add     edi,temp_screen 
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

; printnuld ----------------------------------------------------------
; print a message null terminated, 
; drawing directly in the temp buffer
; enter: dh=row, dl=column
;        eax= offset of message

printnuld:
                push    eax edi edx
                movzx   edi,dh
                lea     edi,[edi+edi*4]
                shl     edi,5
                and     edx,0FFh
                lea     edi,[edi+edx*2]
                add     edi,temp_screen 
printnuld1:
                mov     dl,[eax]
                cmp     dl,0
                je      printnuld2
                mov     [edi],dl
                add     edi,2
                inc     eax
                jmp     printnuld1
printnuld2:
                pop     edx edi eax
                ret

; printyesno ---------------------------------------------------------
; print "yes" or "no" based on contents of eax
; eax=0 "NO"
; eax=1 "YES"

printyesno:
                cmp     eax,0
                je      printyesno_no
                mov     eax,offset stateyes
                jmp     printyesno_go
printyesno_no:
                mov     eax,offset stateno
printyesno_go:
                jmp     printmsgd

; --------------------------------------------------------------------
                
emulate_client:                
                mov     esi,offset client_screen
                call    uncompress_screen
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,temp_screen
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es

                call    turnon_kb_irq
                call    UART_init
                call    UART_send_idstring

emulate_client_loop:
                ;call    UART_receive_idstring

                mov     bl,byte ptr [offset keymatrix+4]
                mov     al,0
                rcr     bl,3
                rcl     al,1
                
                mov     bl,byte ptr [offset keymatrix+8]
                rcr     bl,1
                rcl     al,1

                mov     bl,byte ptr [offset keymatrix+8]
                rcl     bl,1
                rcl     al,1
                rcl     bl,3
                rcl     al,1
                
                mov     bl,byte ptr [offset keymatrix+8]
                rcl     bl,2
                rcl     al,1
                rcl     bl,1
                rcl     al,1

                call    UART_send

                mov     al,byte ptr [offset keymatrix+7]
                test    al,BIT_2
                jnz     emulate_client_loop

                mov     byte ptr [offset keymatrix+7],0FFh

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
                add     videomode,1
                and     videomode,7
                ret

; --------------------------------------------------------------------

change_sound:
                mov     eax,sounddetected
                xor     soundenabled,eax
                xor     soundplaying,2
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
                mov     eax,pentiumfound
                xor     bargraphmode,eax
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

uncompress_screen:
                mov     edi,temp_screen 
                add     edi,3840

uncompress_loop:
                movzx   ecx,byte ptr [esi]
                test    ecx,ecx
                jz      uncompress_inter

                shl     cl,1
                jc      uncompress_multi

                inc     esi
                rep     movsb
                jmp     uncompress_loop

uncompress_multi:
                inc     esi
                mov     al,[esi]
                inc     esi
                rep     stosb
                jmp     uncompress_loop

uncompress_inter:
                mov     esi,temp_screen
                add     esi,3840
                mov     edi,temp_screen
                mov     ecx,3840/2
uncompress_inter_loop:
                mov     al,[esi]
                mov     [edi],al
                mov     al,[esi+3840/2]
                mov     [edi+1],al
                inc     esi
                add     edi,2
                dec     ecx
                jnz     uncompress_inter_loop
                ret

; render_debug -------------------------------------------------------
; render a debug screen

render_debug:

                cmp     debugtype,2
                je      render_debug2

                cmp     debugtype,3
                je      render_debug3

                cmp     debugtype,4
                je      render_debug4

                cmp     debugtype,5
                je      render_debug5

                cmp     debugtype,6
                je      render_debug6

                ; copy the template to temp buffer
                
                mov     esi,offset debug_screen
                call    uncompress_screen

                call    status_bar

                mov     enable_symbolic,0

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
                COORD   73,2
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
                
                ; print the contents of PSG registers

                mov     ecx,0
                mov     esi,offset psgreg
                COORD   77,2
print_psg1:
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
                jnz     print_psg1

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
                mov     edi,disasm_address
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
                mov     ebp,isize
                add     ebp,disasm_address
                and     ebp,0FFFFh
                mov     disasm_down,ebp
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
                
                ; print the PPI registers

                mov     al,prim_slotreg
                call    convhex4
                mov     eax,offset tmphex2
                COORD   48,13
                call    printmsgd
                
                mov     al,ppic
                call    convhex4
                mov     eax,offset tmphex2
                COORD   48,14
                call    printmsgd
                
; --------------------------------------------------------------------
                
                ; print the psg address
                COORD   77,19
                movzx   eax,psgselect
                call    convhex4
                mov     eax,offset tmphex2
                call    printmsgd

; --------------------------------------------------------------------
                
                ; print primary slot configuration

                irp     i,<0,1,2,3>
                mov     al,prim_slotreg
                shr     al,i*2
                and     al,3
                add     al,'0'
                mov     tabspace,al
                mov     eax,offset tabspace
                COORD   52,16+i
                call    printmsgd
                endm

; --------------------------------------------------------------------
                
                ; print megarom block information

                mov     ecx,0
                mov     esi,offset megablock
print_mega:
                mov     eax,[esi]
                call    convhex4
                COORD   61,12
                mov     edi,ecx
                shl     edi,8
                add     edx,edi
                mov     eax,offset tmphex2
                call    printmsgd
                add     esi,4
                inc     ecx
                cmp     ecx,8
                jne     print_mega

                
; --------------------------------------------------------------------
                
                ; blit the temp buffer to screen 
                
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,temp_screen 
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
                call    uncompress_screen


                call    status_bar

; --------------------------------------------------------------------
                
                ; dump the msx memory (large version)

                irp     i,<0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15>
                mov     eax,memdump
                add     eax,i*8

                ; print the address
                push    eax                
                call    convhex4
                COORD   4,3+i
                mov     eax,offset tmphex4
                call    printmsgd
                pop     eax

                ; print the contents in hex format
                xor     ecx,ecx
                COORD   9,3+i
print2_dump1&i:
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
                jnz     print2_dump1&i
                
                ; print the contents in ascii format
                xor     ecx,ecx
                COORD   33,3+i
print2_dump2&i:
                push    eax
                lea     edi,[eax+ecx]
                and     edi,0FFFFh
                call    fetch
                cmp     al,32
                jb      print2_dump3&i
                cmp     al,128
                jae     print2_dump3&i
                mov     tabspace,al
                push    edx
                mov     eax,offset tabspace
                call    printmsgd
                pop     edx
print2_dump3&i:
                pop     eax
                inc     ecx                
                inc     edx
                cmp     ecx,8
                jnz     print2_dump2&i

                endm

; --------------------------------------------------------------------

                ; print the SCC registers

                ; frequency registers
                irp     i,<0,1,2,3,4>

                mov     ax,word ptr [offset sccregs+i*2]
                call    convhex4
                mov     eax,offset tmphex4
                COORD   49,3+i
                call    printmsgd

                endm
                
                ; volume registers
                irp     i,<0,1,2,3,4>

                mov     al,byte ptr [offset sccregs+i+10]
                call    convhex4
                mov     eax,offset tmphex2
                COORD   49,8+i
                call    printmsgd

                endm

; --------------------------------------------------------------------

                ; print the drive registers

                irp     i,<0,1,2,3,4>

                mov     al,byte ptr [offset driveD0+i]
                call    convhex4
                mov     eax,offset tmphex2
                COORD   50,15+i
                call    printmsgd

                endm
                
; --------------------------------------------------------------------

                ; print the stack dump

                irp     i,<-6,-4,-2,0,2,4,6>
                mov     ecx,i
                COORD   62,3+i/2+3
                mov     eax,regesp                
                lea     edi,[eax+ecx]
                and     edi,0FFFFh
                call    fetchw
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd

                endm
                
; --------------------------------------------------------------------

                ; print the advanced info

                ; print the interrupt pending status
                COORD   75,13
                mov     eax,iline
                call    printyesno

                ; print the vdp waiting status
                COORD   75,14
                mov     eax,vdpcond
                call    printyesno

                ; print the vdp low byte
                COORD   76,15
                movzx   eax,vdptemp
                call    convhex4
                mov     eax,offset tmphex2
                call    printmsgd

                ; print the vdp lookahead
                COORD   76,16
                movzx   eax,vdplookahead
                call    convhex4
                mov     eax,offset tmphex2
                call    printmsgd

                ; print the number of clocks left
                COORD   74,12
                mov     eax,clockcounter
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd

                ; print the vdp address
                COORD   74,17
                movzx   eax,vdpaddress
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd

                ; print the vdp status byte
                COORD   76,19
                movzx   eax,vdpstatus
                call    convhex4
                mov     eax,offset tmphex2
                call    printmsgd

; --------------------------------------------------------------------
                
                ; print the vdp access mode

                cmp     vdpaccess,0
                je      print_access1
                mov     eax,offset access_write
                jmp     print_access0
print_access1:
                mov     eax,offset access_read
print_access0:
                COORD   73,18
                call    printmsgd

; --------------------------------------------------------------------

                ; print the VDP BASE()

                ; print the name table
                COORD   75,3
                mov     eax,nametable
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd

                ; print the pattern table
                COORD   75,4
                mov     eax,patterntable
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd

                ; print the color table
                COORD   75,5
                mov     eax,colortable
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd

                ; print the sprite attribute table
                COORD   75,6
                mov     eax,sprattrtable
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd

                ; print the sprite pattern table
                COORD   75,7
                mov     eax,sprpatttable
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd

; --------------------------------------------------------------------
                
                ; print the actual screen mode

                mov     al,actualscreen
                add     al,'0'
                mov     byte ptr [offset tabspace],al
                COORD   75,9
                mov     eax,offset tabspace
                call    printmsgd

; --------------------------------------------------------------------
                
                ; blit the temp buffer to screen 
                
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,temp_screen
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
                cmp     videomode,3
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

; --------------------------------------------------------------------
                
render_debug3:
                ; third debug screen
                ; copy the template to temp buffer
                
                mov     esi,offset debug3_screen
                call    uncompress_screen


                call    status_bar

; --------------------------------------------------------------------
                
                ; print the fm registers

                irp     i,<0,1,2,3>
                local   print_fm

                mov     ecx,0
                mov     esi,offset fmreg+10h*i
                COORD   7+8*i,3
print_fm:
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
                jnz     print_fm
                endm

; --------------------------------------------------------------------
                
                ; print the fm instruments 0-8

                mov     ecx,0
                mov     esi,offset fmreg+30h
                COORD   40,3
print_fminstr:
                mov     al,[esi]
                mov     ah,al
                shr     al,4
                and     ah,0F0h
                or      al,ah
                and     eax,0FFh
                test    byte ptr [offset fmreg+0Eh],BIT_5
                jz      print_fminstr2
                cmp     ecx,6
                jb      print_fminstr2
                mov     eax,16*17
print_fminstr2:
                add     eax,offset fminstr
                push    edx
                call    printmsgd
                pop     edx
                add     edx,100h
                inc     esi
                inc     ecx
                cmp     ecx,9
                jnz     print_fminstr

; --------------------------------------------------------------------
                
blit_screen:
                ; blit the temp buffer to screen 
                
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,temp_screen 
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es

                ret

; --------------------------------------------------------------------
                
render_debug4:
                ; fourth debug screen
                ; copy the template to temp buffer
                
                mov     esi,offset debug4_screen
                call    uncompress_screen


                call    status_bar

; --------------------------------------------------------------------
                
                ; dump the msx vram

                irp     i,<0,1,2,3>
                local   print_dump1
                local   print_dump2
                local   print_dump3

                mov     eax,vmemdump
                add     eax,i*16

                ; print the address
                push    eax                
                call    convhex4
                COORD   4,15+i
                mov     eax,offset tmphex4
                call    printmsgd
                pop     eax

                ; print the contents in hex format
                xor     ecx,ecx
                COORD   10,15+i
print_dump1:
                push    eax
                lea     edi,[eax+ecx]
                and     edi,01FFFFh  ; 03FFFh
                add     edi,msxvram
                mov     al,[edi]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                pop     eax
                add     edx,3
                inc     ecx
                cmp     ecx,16
                jnz     print_dump1
                
                ; print the contents in ascii format
                xor     ecx,ecx
                COORD   59,15+i
print_dump2:
                push    eax
                lea     edi,[eax+ecx]
                and     edi,01FFFFh ;03FFFh
                add     edi,msxvram
                mov     al,[edi]
                cmp     al,32
                jbe     print_dump3
                cmp     al,128
                jae     print_dump3
                mov     tabspace,al
                push    edx
                mov     eax,offset tabspace
                call    printmsgd
                pop     edx
print_dump3:
                pop     eax
                inc     ecx                
                inc     edx
                cmp     ecx,16
                jnz     print_dump2

                endm

; --------------------------------------------------------------------
                
                ; dump the scc waveforms

                irp     i,<0,1,2,3,4,5,6,7>
                local   print_dump1

                ; print the contents in hex format
                mov     eax,16*i
                add     eax,1800h
                add     eax,sccram
                xor     ecx,ecx
                COORD   10,3+i
print_dump1:
                push    eax
                mov     al,[eax]
                call    convhex4
                mov     eax,offset tmphex2
                push    edx
                call    printmsgd
                pop     edx
                pop     eax
                inc     eax
                add     edx,3
                inc     ecx
                cmp     ecx,16
                jnz     print_dump1
                

                endm

; --------------------------------------------------------------------

                ; print the mapper registers

                irp     i,<0,1,2,3>
                
                mov     al,byte ptr [offset mapper_banks+i]
                call    convhex4
                mov     eax,offset tmphex2
                COORD   64,3+i
                call    printmsgd
                
                endm
                
; --------------------------------------------------------------------
                
                jmp     blit_screen

; --------------------------------------------------------------------
                
render_debug5:
                ; fifth debug screen
                ; copy the template to temp buffer
                
                mov     esi,offset debug5_screen
                call    uncompress_screen


                call    status_bar

                mov     enable_symbolic,1

; --------------------------------------------------------------------
                
                ; symbolic disassemble the program

                mov     ecx,0
                mov     edi,disasm_address
                mov     firstone,1
sprint_dis0:
                ; print the address label (if any)
                mov     eax,edi
                call    search_label
                jc      sprint_dis3

                COORD   2,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                call    printleftd

sprint_dis3:
                ; print the mnemonic
                xor     eax,eax
                COORD   46,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                push    edi
                call    print
                pop     edi
                
                ; print the address
                COORD   27,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                mov     eax,edi
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsgd

                ; print the pc indicator
                cmp     edi,regepc
                jne     sprint_dis2
                COORD   31,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                mov     eax,offset tabindicator
                call    printmsgd

sprint_dis2:
                ; print the opcode
                COORD   33,3
                mov     esi,ecx
                shl     esi,8
                add     edx,esi
                push    ecx
                mov     ecx,isize
sprint_dis1:
                call    fetch                                
                call    convhex4
                mov     eax,offset tmphex2
                call    printmsgd
                add     edx,3
                inc     edi
                and     edi,0FFFFh
                dec     ecx
                jnz     sprint_dis1
                pop     ecx

                cmp     firstone,1
                jne     sprint_dis_skip
                mov     firstone,0
                mov     ebp,isize
                add     ebp,regepc
                and     ebp,0FFFFh
                mov     nextbp,ebp
                mov     ebp,isize
                add     ebp,disasm_address
                and     ebp,0FFFFh
                mov     disasm_down,ebp
sprint_dis_skip:

                inc     ecx
                cmp     ecx,11
                jne     sprint_dis0

; --------------------------------------------------------------------
                
                jmp     blit_screen

; --------------------------------------------------------------------
                
render_debug6:
                ; sixth debug screen
                ; copy the template to temp buffer
                
                mov     esi,offset debug6_screen
                call    uncompress_screen


                call    status_bar

; --------------------------------------------------------------------
                
                ; print the v9938 registers

                irp     i,<0,1,2>
                local   print_38

                mov     ecx,0
                mov     esi,offset vdpregs+10h*i
                COORD   7+8*i,3
print_38:
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
                jnz     print_38
                endm

; --------------------------------------------------------------------
                
                ; print the v9938 status registers

                mov     ecx,0
                irp     i,<0,1,2,3,4,5,6,7,8,9,10,11>
                mov     esi,offset vdpstatus+i
                COORD   30+3*i,19
                mov     al,[esi]
                call    convhex4
                mov     eax,offset tmphex2
                call    printmsgd
                inc     esi
                endm

; --------------------------------------------------------------------
                
                ; print the current line

                mov     eax,current_line
                call    convhex4
                mov     eax,offset tmphex4
                COORD   46,3
                call    printmsgd

; --------------------------------------------------------------------
                
                jmp     blit_screen

; --------------------------------------------------------------------

debug:          
                ;call    init_compiler
                call    set_com_baseaddr
                call    clear_text
                cmp     startdebugger,1
                je      debug_loop
                jmp     command_s
debug_loop:                
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
                cmp     al,'9'
                je      command_9
                cmp     al,'M'
                je      command_m
                cmp     al,'U'
                je      command_u
                cmp     al,'X'
                je      command_x
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
                cmp     al,'I'
                je      command_i
                cmp     al,'G'
                je      command_g
                cmp     al,'T'
                je      command_t
                cmp     al,'1'
                je      command_1
                cmp     al,'2'
                je      command_2
                cmp     al,'3'
                je      command_3
                cmp     al,'4'
                je      command_4
                cmp     al,'5'
                je      command_5
                cmp     al,'6'
                je      command_6
                cmp     al,'V'
                je      command_v
                ;cmp     al,'Z'
                ;je      command_z
                cmp     al,'N'
                je      command_n
                cmp     al,'E'
                je      command_e
                ;cmp     al,'W'
                ;je      command_w
                cmp     al,'Q'
                je      command_exit
                cmp     al,27
                je      command_exit
                jmp     debug_loop

command_extended:
                call    crlf
                cmp     ah,59 ;F1
                je      command_help
                cmp     ah,60 ;F2
                je      command_save
                cmp     ah,61 ;F3
                je      command_load
                cmp     ah,65 ;F7
                je      command_t
                cmp     ah,66 ;F8
                je      command_stepover
                cmp     ah,72
                je      command_up
                cmp     ah,80
                je      command_down
                cmp     ah,73 ;page up
                je      command_pgup
                cmp     ah,81 ;page down
                je      command_pgdown
                jmp     debug_loop

; --------------------------------------------------------------------

command_pgup:
                cmp     debugtype,2
                je      command_pgup_2
                cmp     debugtype,4
                je      command_pgup_4
                
                sub     memdump,32
                and     memdump,0FFFFh
                jmp     debug_loop
command_pgup_2:
                sub     memdump,16*8
                and     memdump,0FFFFh
                jmp     debug_loop
command_pgup_4:
                sub     vmemdump,16*4
                and     vmemdump,01FFFFh ;03FFFh
                jmp     debug_loop

; --------------------------------------------------------------------

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

; --------------------------------------------------------------------

command_pgdown:
                cmp     debugtype,2
                je      command_pgdown_2
                cmp     debugtype,4
                je      command_pgdown_4

                add     memdump,32
                and     memdump,0FFFFh
                jmp     debug_loop
command_pgdown_2:
                add     memdump,16*8
                and     memdump,0FFFFh
                jmp     debug_loop
command_pgdown_4:
                add     vmemdump,16*4
                and     vmemdump,01FFFFh ;03FFFh
                jmp     debug_loop

; --------------------------------------------------------------------

command_n:
                call    changesession
                jmp     debug_loop

; --------------------------------------------------------------------

command_d:
                cmp     debugtype,4
                je      command_d_4
                
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0FFFFh
                mov     memdump,eax
                jmp     debug_loop

command_d_4:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0FFFFh
                mov     ebx,eax
                shl     ebx,8
                push    ebx
                call    gethex2
                pop     ebx
                and     eax,0FFh
                or      eax,ebx
                and     eax,01FFFFh ; 03FFFh
                mov     vmemdump,eax
                jmp     debug_loop

; --------------------------------------------------------------------

command_u:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0FFFFh
                mov     disasm_address,eax
                jmp     debug_loop

; --------------------------------------------------------------------

command_e:
                cmp     debugtype,4
                je      command_e_vram
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0FFFFh
                push    eax
                call    printspace
                call    gethex2
                and     eax,0FFh
                pop     ecx
                call    writemem
                jmp     debug_loop

command_e_vram:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                mov     ebx,eax
                and     ebx,0ffffh
                shl     ebx,8
                push    ebx
                call    gethex2
                pop     ebx
                and     eax,0FFh
                or      eax,ebx
                push    eax
                call    printspace
                call    gethex2
                and     eax,0FFh
                pop     ecx
                ; and     ecx,03FFFh
                ; Fudeba requested this !
                and     ecx,01FFFFh
                add     ecx,msxvram
                mov     [ecx],al
                jmp     debug_loop

; --------------------------------------------------------------------

command_y:              
                call    change_vsync
                jmp     debug_loop

; --------------------------------------------------------------------

command_z:
                call    UART_init
                call    UART_send_idstring
                jmp     debug_loop

; --------------------------------------------------------------------

command_r:
                COORD   14,23
                call    set_cursor_position
                call    getchar
                call    toupper
                call    printasc
                mov     byte ptr [offset debug_reg+1],al
                call    getchar
                call    toupper
                call    printasc
                mov     byte ptr [offset debug_reg],al
                COORD   17,23
                call    set_cursor_position

                cmp     debug_reg,'AF'
                je      command_r_af
                
                cmp     debug_reg,'BC'
                je      command_r_bc
                
                cmp     debug_reg,'DE'
                je      command_r_de
                
                cmp     debug_reg,'HL'
                je      command_r_hl
                
                cmp     debug_reg,'IX'
                je      command_r_ix
                
                cmp     debug_reg,'IY'
                je      command_r_iy
                
                cmp     debug_reg,'PC'
                je      command_r_pc
                
                cmp     debug_reg,'SP'
                je      command_r_sp
                
                cmp     debug_reg,'AX'
                je      command_r_ax
                
                cmp     debug_reg,'BX'
                je      command_r_bx
                
                cmp     debug_reg,'DX'
                je      command_r_dx
                
                cmp     debug_reg,'HX'
                je      command_r_hx
                
                jmp     debug_loop


command_r_af:
                call    gethex4
                mov     regaf,ax
                jmp     debug_loop

command_r_bc:
                call    gethex4
                mov     regbc,ax
                jmp     debug_loop

command_r_de:
                call    gethex4
                mov     regde,ax
                jmp     debug_loop

command_r_hl:
                call    gethex4
                mov     reghl,ax
                jmp     debug_loop

command_r_ix:
                call    gethex4
                mov     regix,ax
                jmp     debug_loop

command_r_iy:
                call    gethex4
                mov     regiy,ax
                jmp     debug_loop

command_r_pc:
                call    gethex4
                mov     regpc,ax
                jmp     debug_loop

command_r_sp:
                call    gethex4
                mov     regsp,ax
                jmp     debug_loop

command_r_ax:
                call    gethex4
                mov     regafl,ax
                jmp     debug_loop

command_r_bx:
                call    gethex4
                mov     regbcl,ax
                jmp     debug_loop

command_r_dx:
                call    gethex4
                mov     regdel,ax
                jmp     debug_loop

command_r_hx:
                call    gethex4
                mov     reghll,ax
                jmp     debug_loop

; --------------------------------------------------------------------

command_up:
                dec     disasm_address
                and     disasm_address,0FFFFh
                jmp     debug_loop

; --------------------------------------------------------------------

command_down:
                mov     eax,disasm_down
                mov     disasm_address,eax
                jmp     debug_loop

; --------------------------------------------------------------------

command_x:
                call    change_scc
                jmp     debug_loop

; --------------------------------------------------------------------

command_help:
                mov     esi,offset help_screen
                call    uncompress_screen
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,temp_screen 
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es

                call    getchar
                jmp     debug_loop

; --------------------------------------------------------------------

command_g:
                call    checkpentium
                jc      debug_loop
                call    changebargraph
                jmp     debug_loop

; --------------------------------------------------------------------

command_f:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0ffffh
                mov     framerate,eax
                mov     on_off,eax
                call    crlf
                jmp     debug_loop

; --------------------------------------------------------------------

command_j:
                call    change_joystick
                jmp     debug_loop

; --------------------------------------------------------------------

command_v:      
                call    changevideomode
                jmp     debug_loop
                
; --------------------------------------------------------------------

command_i:
                xor     imagetype,1
                jmp     debug_loop

; --------------------------------------------------------------------

command_save:
                call    save_state
                jmp     debug_loop

; --------------------------------------------------------------------

command_load:
                call    load_state
                mov     edi,regepc
                mov     disasm_address,edi
                jmp     debug_loop

; --------------------------------------------------------------------

command_m:      
                call    changemode
                jmp     debug_loop

; --------------------------------------------------------------------

command_b:
                COORD   14,23
                call    set_cursor_position
                call    gethex4
                and     eax,0ffffh
                mov     breakpoint,eax
                call    crlf
                call    setgraphmode
                call    turnon_irq
                call    turnon_kb_irq
                call    sound_on
                call    emulate_break
                call    sound_off
                call    turnoff_kb_irq
                call    turnoff_irq
                call    settextmode
                call    crlf
                mov     edi,regepc
                mov     disasm_address,edi
                jmp     debug_loop

; --------------------------------------------------------------------

command_stepover:
                mov     eax,nextbp
                mov     breakpoint,eax
                call    crlf
                call    setgraphmode
                call    turnon_irq
                call    turnon_kb_irq
                call    sound_on
                call    emulate_break
                call    sound_off
                call    turnoff_kb_irq
                call    turnoff_irq
                call    settextmode
                call    crlf
                mov     edi,regepc
                mov     disasm_address,edi
                jmp     debug_loop

; --------------------------------------------------------------------

command_p:
                call    change_sound
                jmp     debug_loop

; --------------------------------------------------------------------

command_h:
                call    setgraphmode
                call    clear
                call    turnon_kb_irq
                call    turnon_irq
                call    sound_on
                call    emulate_histogr
                call    sound_off
                call    turnoff_irq
                call    turnoff_kb_irq
                call    settextmode
                jmp     debug_loop

; --------------------------------------------------------------------

command_w:
                call    setgraphmode
                call    clear
                call    turnon_kb_irq
                call    turnon_irq
                call    sound_on
                call    emulate_compiler
                call    sound_off
                call    turnoff_irq
                call    turnoff_kb_irq
                call    settextmode
                jmp     debug_loop

; --------------------------------------------------------------------

command_0:
                call    setgraphmode
                mov     eax,nametable
                push    eax

command_0_loop:
                call    clear
                mov     firstscreen,1
                mov     first_line,0
                mov     last_line,211
                call    render
                call    sprite_render
                call    blit
                call    getchar
                call    toupper
                cmp     al,'+'
                jne     command_0_saveshot

                mov     eax,nametable
                add     eax,08000h
                and     eax,01FFFFh
                mov     nametable,eax
                jmp     command_0_loop

command_0_saveshot:
                cmp     al,'S'
                jne     command_0_exit

                call    save_snapshot_raw
                jmp     command_0_loop

command_0_exit:
                pop     eax
                mov     nametable,eax
                call    settextmode
                jmp     debug_loop

; --------------------------------------------------------------------

command_9:
                call    setgraphmode
                call    sprite_collision
                call    render_col
                call    getchar
                call    settextmode
                jmp     debug_loop

; --------------------------------------------------------------------

command_s:      
                cmp     sessionmode,2
                je      emulate_client
                cmp     sessionmode,1
                jne     command_s_go
                mov     esi,offset server_screen
                call    uncompress_screen
                push    es
                mov     ax,gs
                mov     es,ax
                mov     esi,temp_screen 
                mov     edi,0b8000h
                mov     ecx,80*24*2/4
                rep     movsd
                pop     es

                call    UART_init
                call    UART_receive_idstring
command_s_go:
                call    setgraphmode
                call    clear
                call    turnon_kb_irq
                call    turnon_irq
                call    sound_on
                call    emulate
                call    sound_off
                call    turnoff_irq
                call    turnoff_kb_irq
                call    settextmode
                mov     edi,regepc
                mov     disasm_address,edi
                jmp     debug_loop

; --------------------------------------------------------------------

command_c:       
                ;call    calibrate_joystick
                ;mov     joyenable,1
                jmp     debug_loop

; --------------------------------------------------------------------

command_k:
                inc     comport
                cmp     comport,5
                jne     command_k_print
                mov     comport,1
command_k_print:
                call    set_com_baseaddr
                jmp     debug_loop

; --------------------------------------------------------------------

command_1:
                mov     debugtype,1
                jmp     debug_loop

; --------------------------------------------------------------------

command_2:
                mov     debugtype,2
                jmp     debug_loop

; --------------------------------------------------------------------

command_3:
                mov     debugtype,3
                jmp     debug_loop

; --------------------------------------------------------------------

command_4:
                mov     debugtype,4
                jmp     debug_loop

; --------------------------------------------------------------------

command_5:
                mov     debugtype,5
                jmp     debug_loop

; --------------------------------------------------------------------

command_6:
                mov     debugtype,6
                jmp     debug_loop

; --------------------------------------------------------------------

command_t:
                mov     edi,regepc
                mov     edx,regeaf
                mov     ebp,clockcounter
                mov     eax,0
                call    trace
                mov     edi,regepc
                mov     disasm_address,edi
                jmp     debug_loop

; --------------------------------------------------------------------

command_exit:
                ret

; --------------------------------------------------------------------

code32          ends
                end



