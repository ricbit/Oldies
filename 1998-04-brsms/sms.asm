; -------------------------------------------------------------------- 
; BrMSX v:1.32                                                         
; Copyright (C) 1997 by Ricardo Bittencourt                            
; module: BRMSX.ASM
; -------------------------------------------------------------------- 

        .386p
code32  segment para public use32
        assume cs:code32, ds:code32

include pmode.inc
include pentium.inc
include io.inc
include z80.inc
include debug.inc
include psg.inc
include mouse.inc
include vesa.inc
include vdp.inc
include joystick.inc
include gui.inc
include drive.inc
include serial.inc
include z80sing.inc
include z80fd.inc
include blit.inc
include saveload.inc
include bit.inc
include z80core.inc

public _main
public msxram
public msxvram
public blitbuffer
public transf_buffer
public diskimage
public cart1
public dirtycode
public compbuffer
public dmabuffer
public dmatemp
public filenamelist
public read_rom
public vesaheader
public vesamodeinfo
public soundbuffer
public timebuffer
public sccram
public tapeimage
public staticbuffer
public gamegear
public cartname
public tilecache
public redbuffer
public bluebuffer
public lcdbuffer
public cart_sram
public speaker
public sg1000
public collisionfield
public log_music
public log_name
public sc3000
public coleco
public codetable

extrn detect_cpu: near
extrn pentiumfound: dword
extrn mmxfound: dword
extrn iset: dword
extrn isetFDCBxx: dword
extrn guess_table: byte
extrn entry_basic: byte
extrn entry_music: byte

; DATA ---------------------------------------------------------------

DMABUFFERSIZE   equ     800*20

msg00           db      'BrSMS 1.21 REGISTERED',13,10
                db      'Copyright (C) 1998,1999 by Ricardo Bittencourt'
                db      13,10,'Contributors: '
                db      'Marcelo Furtado, Ryan Novak, Omar Mosqueda and '
                db      'Derek Liauw'
                db      13,10,10,'$'
msg01           db      'Not enough memory',13,10,'$'
msg02           db      'Error in ROM file',13,10,'$'
msg03           db      'Disk size not supported',13,10,'$'
msg04           db      'Low memory free: $'
msg05           db      'High memory free: $'
msg06           db      'Processor type: $'
msg07           db      'Clock: $'
msg08           db      ' Mhz',13,10,'$'
msg09           db      ' kb',13,10,'$'
msg10           db      'Press ENTER to start. $'
msg11           db      'Cannot reset Sound Blaster',13,10,'$'
msg12           db      'Sound Blaster reseted succesfully',13,10,'$'
msg13           db      'Mouse driver detected',13,10,'$'
msg14           db      'BLASTER environment string not found',13,10,'$'
msg15           db      'Error in BLASTER environment string',13,10,'$'
msg16           db      'Sound Blaster at base address $'
msg17           db      'h, IRQ $'
msg18           db      ', DMA $'
msg19           db      'VESA not found',13,10,'$'
msg20           db      'VESA version: $'
msg21           db      'VESA2 512x384x8 not found',13,10,'$'
msg22           db      'BrSMS 1.21 REGISTERED',13,10
                db      'Copyright (C) 1998,1999 by Ricardo Bittencourt'
                db      13,10,'Contributors: '
                db      'Marcelo Furtado, Ryan Novak, Omar Mosqueda and '
                db      'Derek Liauw'
                db      13,10
                db      'Official site: http://www.lsi.usp.br/'
                db      '~ricardo/brsms.htm',13,10
                db      'Send bugs, comments and suggestions to '
                db      'ricardo@lsi.usp.br',13,10,'$'
msg23           db      'Cartridge 1: $'
msg24           db      'Cartridge 2: $'
msg25           db      13,10,'Game: $'
msg26           db      'Compatibility list:',13,10,10
                db      '"." means perfect emulation',13,10
                db      '"-" means playable, with minor bugs',13,10
                db      '"*" means not playable',13,10,10,'$'
msg27           db      'VESA2 400x300x8 not found',13,10,'$'
msg28           db      ' -> 0$'
msg29           db      'h',13,10,'$'
msg30           db      'Known bugs: $'
msg31           db      '  $'
msg32           db      'VESA2 512x384x15 not found',13,10,'$'
msg33           db      13,10,'WARNING: This game is a bad dump.',13,10
                db      '         Your ROM has $'
msg34           db      'kb, but it should have $'
msg35           db      'kb.',13,10
                db      '         Download SMSFIX.EXE from BrSMS home page '
                db      'to fix this problem.',13,10,'$'
msg36           db      'Could not find COLECO.ROM',13,10,'$'
help_message    db      'Usage: BRSMS [-options] '
                db      '[cart1.sms]' 
                db      13,10,10,'Options:',13,10
                db      '-sms           force Sega Master System '
                db      'emulation',13,10
                db      '-gg            force Game Gear emulation',13,10
                db      '-sg1000        force SG1000 emulation',13,10
                db      '-sc3000        force SC3000 emulation',13,10
                db      '-coleco        force Colecovision emulation',13,10
                db      '-noguess       disable automatic ROM '
                db      'identification',13,10
                db      '-listrom       display compatibility list',13,10
                db      '-vsync         sync with the monitor and the '
                db      'internal timer',13,10
                db      '-truevsync     sync only with the monitor '
                db      '(require monitor with 60Hz refresh)',13,10
                db      '-res <mode>    select screen resolution',13,10
                db      '               0 = 320x200x8  (default, '
                db      'allows border emulation)',13,10
                db      '               1 = 400x300x8  (large Game Gear '
                db      'screen)',13,10
                db      '               2 = 512x384x8  (Master System or SG1000' 
                db      ' with scanlines)',13,10
                db      '               4 = 512x384x15 (' 
                db      'bilinear filtering)',13,10
                db      '               6 = 512x384x15 (' 
                db      '"Parrot" engine)',13,10
                db      '               8 = 512x384x15 (' 
                db      '"2xSaI" engine)',13,10
                db      '-frame <n>     frame skipping (1 means all '
                db      'frames rendered, default=auto)',13,10
                db      'Press enter to continue...$'
help_message2:
                db      13
                db      '-3d            enable 3D glasses emulation',13,10
                db      '-2d            special mode to play 3D games in '
                db      '2D',13,10
                db      '-line          select line-by-line video engine '
                db      '(slower, more accurate)',13,10
                db      '-block         select block-based video engine '
                db      '(faster, less accurate)',13,10
                db      '-palraster     enable palette raster effects '
                db      '(implies -line)',13,10
                db      '-border        enable border raster effects '
                db      '(implies -palraster)',13,10
                db      '-sprcol        enable sprite collision '
                db      'detection',13,10
                db      '-nosprcol      disable sprite collision '
                db      'detection',13,10
                db      '-lcd           enable LCD persistence emulation '
                db      '(require 15-bit color mode)',13,10
                db      '-nocache       disable video cache',13,10
                db      '-nommx         disable MMX optimizations',13,10
                db      '-cpugraph      enable CPU performance graph',13,10
                db      '-psggraph      enable PSG graph (require '
                db      '-nocache)',13,10
                db      '-lightgun      enable lightgun emulation',13,10
                db      '-joy           enable joystick',13,10
                db      '-joysens       adjust joystick sensibility '
                db      '(range is 0 to 7, default is 3)',13,10
                db      '-paddle        enable paddle emulation',13,10
                db      '-mousepad      enable paddle emulation through '
                db      'the mouse',13,10
                db      '-snespad       enable SNES joypad connected '
                db      'to parallel port',13,10
                db      '-lpt <n>       select parallel port for SNES '
                db      'joypad [1-2]',13,10
                db      '-speaker       enable sound through the PC '
                db      'Speaker',13,10
                db      '-server        computer is server',13,10
                db      '-client        computer is client',13,10
                db      '-com <n>       select COM serial port [1-4]',13,10
                db      'Press enter to continue...$'
help_message3:
                db      13
                db      '-eng           select english mode (default)',13,10
                db      '-jap           select japanese mode',13,10
                db      '-nosound       disable the sound engine',13,10
                db      '-nomouse       disable mouse driver detection',13,10
                db      '-novesa        disable VESA detection',13,10
                db      '-nopentium     disable pentium extensions and '
                db      'cpu autodetect',13,10
                db      '-noenter       disable enter pressing at '
                db      'start',13,10
                db      '-help          show this help page',13,10
                db      '$'
msgnocpuid      db      '486 or below $'
msg386          db      '386 $'
msg486          db      '486 $'
msg586          db      'Pentium $'
msg686          db      'Pentium Pro or better $'
msgMMX          db      '(MMX)$'
msgpoint        db      '.$'
rom_name        db      'MSX.ROM',0
disk_rom_name   db      'DISK.ROM',0
coleco_bios_name db     'COLECO.ROM',0
blasterenv      db      'BLASTER',0
addrstr         db      3 dup (0)

emptyspace      db      128 dup (0)
argnumber       dd      0
argpos          dd      081h
argcount        dd      0

secondarg       dd      0
second_callback dd      0

cartridge1      db      'ELITE.SMS',0;128 dup (0)
cartridge2      db      128 dup (0)
log_name        db      128 dup (0)
tape_name       db      128 dup (0)
cartname        db      128 dup (0)
sramname        db      128 dup (0)

switch_nommx     db      '-nommx',0
switch_truevsync db      '-truevsync',0
switch_guess     db      '-guess',0
switch_speaker   db      '-speaker',0
switch_psgg      db      '-psggraph',0
switch_cpug      db      '-cpugraph',0
switch_help      db      '-help',0
switch_line      db      '-line',0
switch_nosound   db      '-nosound',0
switch_vsync     db      '-vsync',0
switch_nocache   db      '-nocache',0
switch_nomouse   db      '-nomouse',0
switch_novesa    db      '-novesa',0
switch_noenter   db      '-noenter',0
switch_sg1000    db      '-sg1000',0
switch_block     db      '-block',0
switch_palraster db      '-palraster',0
switch_border    db      '-border',0
switch_res       db      '-res',0
switch_sprcol    db      '-sprcol',0
switch_nosprcol  db      '-nosprcol',0
switch_joy       db      '-joy',0
switch_com       db      '-com',0
switch_server    db      '-server',0
switch_client    db      '-client',0
switch_frame     db      '-frame',0
switch_lpt       db      '-lpt',0
switch_nopent    db      '-nopentium',0
switch_log       db      '-log',0
switch_gg        db      '-gg',0
switch_eng       db      '-eng',0
switch_jap       db      '-jap',0
switch_joysens   db      '-joysens',0
switch_noguess   db      '-noguess',0
switch_3d        db      '-3d',0
switch_listrom   db      '-listrom',0
switch_sms       db      '-sms',0
switch_snespad   db      '-snespad',0
switch_sc3000    db      '-sc3000',0
switch_lightgun  db      '-lightgun',0
switch_2d        db      '-2d',0
switch_lcd       db      '-lcd',0
switch_paddle    db      '-paddle',0
switch_mousepad  db      '-mousepad',0
switch_coleco    db      '-coleco',0
                 
switch_table:    
                dd      offset switch_nommx
                dd      offset switch_truevsync
                dd      offset switch_guess
                dd      offset switch_speaker
                dd      offset switch_psgg
                dd      offset switch_cpug
                dd      offset switch_help
                dd      offset switch_line
                dd      offset switch_nosound
                dd      offset switch_vsync
                dd      offset switch_nocache
                dd      offset switch_nomouse
                dd      offset switch_novesa
                dd      offset switch_noenter
                dd      offset switch_sg1000
                dd      offset switch_block
                dd      offset switch_palraster
                dd      offset switch_border
                dd      offset switch_res
                dd      offset switch_sprcol
                dd      offset switch_nosprcol
                dd      offset switch_joy
                dd      offset switch_com
                dd      offset switch_server
                dd      offset switch_client
                dd      offset switch_frame
                dd      offset switch_lpt
                dd      offset switch_nopent
                dd      offset switch_log
                dd      offset switch_gg
                dd      offset switch_eng
                dd      offset switch_jap
                dd      offset switch_joysens
                dd      offset switch_noguess
                dd      offset switch_3d
                dd      offset switch_listrom
                dd      offset switch_sms
                dd      offset switch_snespad
                dd      offset switch_sc3000
                dd      offset switch_lightgun
                dd      offset switch_2d
                dd      offset switch_lcd
                dd      offset switch_paddle
                dd      offset switch_mousepad
                dd      offset switch_coleco

switch_total    dd      45

switch_callback: 
                dd      offset callback_nommx
                dd      offset callback_truevsync
                dd      offset callback_guess
                dd      offset callback_speaker
                dd      offset callback_psgg
                dd      offset callback_cpug
                dd      offset callback_help
                dd      offset callback_line
                dd      offset callback_nosound
                dd      offset callback_vsync
                dd      offset callback_nocache
                dd      offset callback_nomouse
                dd      offset callback_novesa
                dd      offset callback_noenter
                dd      offset callback_sg1000
                dd      offset callback_block
                dd      offset callback_palraster
                dd      offset callback_border
                dd      offset callback_res
                dd      offset callback_sprcol
                dd      offset callback_nosprcol
                dd      offset callback_joy
                dd      offset callback_com
                dd      offset callback_server
                dd      offset callback_client
                dd      offset callback_frame
                dd      offset callback_lpt
                dd      offset callback_nopent
                dd      offset callback_log
                dd      offset callback_gg
                dd      offset callback_eng
                dd      offset callback_jap
                dd      offset callback_joysens
                dd      offset callback_noguess
                dd      offset callback_3d
                dd      offset callback_listrom
                dd      offset callback_sms
                dd      offset callback_snespad
                dd      offset callback_sc3000
                dd      offset callback_lightgun
                dd      offset callback_2d
                dd      offset callback_lcd
                dd      offset callback_paddle
                dd      offset callback_mousepad
                dd      offset callback_coleco

lptaddress      dd      0378h
                dd      0278h

align 4

msxram          dd      ?
msxvram         dd      ?
blitbuffer      dd      ?
msxrom          dd      ?
cart1           dd      ?
transf_buffer   dd      ?
diskimage       dd      ?
compbuffer      dd      ?
cart_sram       dd      ?
dirtycode       dd      ?
dmabuffer       dd      ?
dmatemp         dd      ?
filenamelist    dd      ?
vesaheader      dd      ?
vesamodeinfo    dd      ?
diskrom         dd      ?
soundbuffer     dd      ?
timebuffer      dd      ?
sccram          dd      ?
idlerom         dd      ?
tapeimage       dd      ?
staticbuffer    dd      ?
tilecache       dd      ?
redbuffer       dd      ?
lcdbuffer       dd      ?
bluebuffer      dd      ?
collisionfield  dd      ?
colecorom       dd      ?
codetable       dd      ?

diskenabled     dd      0
cpugraphok      dd      0
nosound         dd      0
nomouse         dd      0
novesa          dd      0
noenter         dd      0
filesize        dd      0
nopentium       dd      0
gamegear        dd      0
sg1000          dd      0
sc3000          dd      0
coleco          dd      1
guess           dd      1
forcedselection dd      0
nommx           dd      0
guessnow        dd      0
speaker         dd      0
force_block     dd      0
force_nosprcol  dd      0
log_music       dd      0

; --------------------------------------------------------------------

_main:          sti

                ; print startup message
                mov     eax,offset msg00
                call    printmsg

                ;call    parse_command_line
                                               
                ; print info on free low memory
                mov     eax,offset msg04
                call    printmsg
                call    _lomemsize
                shr     eax,10
                call    printdecimal
                mov     eax,offset msg09
                call    printmsg

                ; print info on free high memory
                mov     eax,offset msg05
                call    printmsg
                call    _himemsize
                shr     eax,10
                call    printdecimal
                mov     eax,offset msg09
                call    printmsg

                cmp     nopentium,1
                je      _main_nopentium
                
                ; print processor type
                mov     eax,offset msg06
                call    printmsg
                call    detect_cpu
                or      eax,eax
                jnz     _main_386
                mov     eax,offset msgnocpuid
                call    printmsg
                jmp     _main_cpuexit
_main_386:
                cmp     eax,3
                jnz     _main_486
                mov     eax,offset msg386
                call    printmsg
                jmp     _main_cpuexit
_main_486:
                cmp     eax,4
                jnz     _main_586
                mov     eax,offset msg486
                call    printmsg
                jmp     _main_cpuexit
_main_586:
                cmp     eax,5
                jnz     _main_686
                mov     eax,offset msg586
                call    printmsg
                jmp     _main_cpuexit
_main_686:
                mov     eax,offset msg686
                call    printmsg

_main_cpuexit:
                cmp     mmxfound,1
                jne     _main_cpu_nommx

                mov     eax,offset msgMMX
                call    printmsg
                mov     enginetype,2
                cmp     nommx,1
                jne     _main_cpu_nommx
                mov     enginetype,0

_main_cpu_nommx:
                call    crlf


_main_nopentium:
                
                cmp     cpugraphok,1
                jne     _main_nocpugraph
                call    changebargraph
_main_nocpugraph:

                ; allocate 757+ bytes of low memory to sound DMA transfer
                ; these bytes must not cross a 64kb boundary

                mov     eax,DMABUFFERSIZE
                call    _getlomem
                jc      no_memory
                mov     dmabuffer,eax
                mov     edx,eax
                add     edx,_code32a
                mov     ebx,edx
                add     ebx,DMABUFFERSIZE
                and     ebx,0F0000h
                and     edx,0F0000h
                xor     ebx,edx
                test    ebx,(1 shl 16)
                jz      main_getdma2

                mov     eax,DMABUFFERSIZE
                call    _getlomem
                jc      no_memory
                mov     dmabuffer,eax

main_getdma2:
                ; second dma buffer can be on any memory
                mov     eax,DMABUFFERSIZE
                call    _getlomem
                jc      no_memory
                mov     dmatemp,eax

                ; allocate 32kb to transfer buffer
                mov     eax,32768
                call    _getlomem
                jc      no_memory
                mov     transf_buffer,eax

                ; alloc 512 bytes to vesa header
                mov     eax,512
                call    _getlomem
                jc      no_memory
                mov     vesaheader,eax
                
                ; alloc 256 bytes to vesa mode info block
                mov     eax,256
                call    _getlomem
                jc      no_memory
                mov     vesamodeinfo,eax
                
                ; allocate 16kb to msx vram
                mov     eax,16384
                call    _getmem
                jc      no_memory
                mov     msxvram,eax

                ; allocate 8kb to msx ram
                mov     eax,32*1024 ;8*1024
                call    _getmem
                jc      no_memory
                mov     msxram,eax
                mov     dword ptr [offset mem+6*4],eax
                mov     dword ptr [offset mem+7*4],eax

                ; clear msx ram
                mov     ecx,8*1024/4
                mov     edi,msxram
                mov     eax,0
                rep     stosd

                ; alloc 64kb to sound buffer
                mov     eax,64*1024
                call     _getmem
                jc      no_memory
                mov     soundbuffer,eax

                ; alloc 32kb to cartridge sram
                mov     eax,64*1024
                call     _getmem
                jc      no_memory
                mov     cart_sram,eax

                mov     edi,cart_sram
                mov     eax,0
                mov     ecx,32768/4
                rep     stosd

                ; alloc 128kb to time buffer
                mov     eax,128*1024
                call     _getmem
                jc      no_memory
                mov     timebuffer,eax

                ; alloc always 1024kb to cart1                
                mov     eax,1024*1024
                call     _getmem
                jc      no_memory
                mov     cart1,eax

                ; print cartridge name
                cmp     byte ptr [offset cartridge1],0
                je      error_in_rom                

main_has_cart1:
                mov     eax,offset msg23
                call    printmsg
                mov     al,'"'
                call    printasc
                mov     eax,offset cartridge1
                call    printnul
                mov     al,'"'
                call    printasc
                call    crlf

                call    decode_cartridge

                ; read cartridge 1 from disk
                mov     edx,offset cartridge1
                mov     eax,cart1
                mov     ebp,offset mem
                call    read_rom
                jc      error_in_rom                

                ; check for SRAM 

                call    decode_cartridge_sram
                call    load_sram

                ; allocate 64kb to blit buffer
                mov     eax,65536+256
                call    _getmem
                jc      no_memory
                add     eax,256
                mov     blitbuffer,eax

                ; allocate 2*64kb to red buffer
                mov     eax,2*65536
                call    _getmem
                jc      no_memory
                mov     redbuffer,eax

                mov     edi,redbuffer
                mov     eax,0
                mov     ecx,2*65536/4
                rep     stosd

                ; allocate 64kb to blue buffer
                mov     eax,65536*2
                call    _getmem
                jc      no_memory
                mov     bluebuffer,eax

                mov     edi,bluebuffer
                mov     eax,0
                mov     ecx,2*65536/4
                rep     stosd

                ; allocate 64kb to lcd buffer
                mov     eax,65536*2
                call    _getmem
                jc      no_memory
                mov     lcdbuffer,eax

                mov     edi,lcdbuffer
                mov     eax,0
                mov     ecx,2*65536/4
                rep     stosd

                ; allocate 64kb to static buffer
                mov     eax,65536
                call    _getmem
                jc      no_memory
                mov     staticbuffer,eax

                ; clear static buffer
                mov     ecx,65536/4
                mov     eax,01010101h
                mov     edi,staticbuffer
                rep     stosd

                ; allocate 64kb*4 for the code table
                ;mov     eax,65536*4
                ;call    _getmem
                ;jc      no_memory
                ;mov     codetable,eax

                ; clear code table
                ;mov     ecx,65536
                ;mov     eax,offset fetch_me
                ;mov     edi,codetable
                ;rep     stosd

                ; allocate 8kb for collision field
                mov     eax,8192
                call    _getmem
                jc      no_memory
                mov     collisionfield,eax

                ; clear collision field
                mov     edi,collisionfield
                mov     eax,0
                mov     ecx,8192/4
                rep     stosd

                ; allocate (256+256)*64*2 to tile cache
                mov     eax,(256+256)*64*2
                call    _getmem
                jc      no_memory
                mov     tilecache,eax

                mov     eax,0
                mov     ecx,512*64*2/4
                mov     edi,tilecache
                rep     stosd

                ; allocate 8kb to file name list
                mov     eax,8192
                call    _getmem
                jc      no_memory
                mov     filenamelist,eax

                ; if the computer is a pentium
                ; then measure its speed
                cmp     pentiumfound,1
                jne     _main_dontmeasure
                mov     eax,offset msg07
                call    printmsg
                call    measurespeed                
                xor     edx,edx
                mov     eax,dword ptr [offset clockrate]
                mov     ebx,16666
                div     ebx
                call    printdecimal
                mov     eax,offset msg08
                call    printmsg

_main_dontmeasure:

                cmp     nomouse,1
                je      _main_nomouse

                ; init the mouse
                call    init_mouse
                cmp     mousedriver,0
                je      _main_nomouse
                mov     eax,offset msg13
                call    printmsg
_main_nomouse:

                cmp     nosound,1
                je      _main_nosound

                ;call    search_blaster
                stc
                ;;
                jc      blaster_not_found
                call    parse_blaster_string
                jc      error_in_blaster
                mov     sounddetected,1
                mov     soundenabled,1

                mov     eax,offset msg16
                call    printmsg
                mov     eax,sbbaseaddr
                call    printhex4
                mov     eax,offset msg17
                call    printmsg
                mov     eax,sbirq
                call    printhex2
                mov     eax,offset msg18
                call    printmsg
                mov     eax,sbdma
                call    printhex2
                call    crlf

                ; init the sound blaster
                call    init_sound_blaster
                jc      soundblaster_failed
                mov     eax,offset msg12
                call    printmsg
                mov     sounddetected,1

_main_nosound:

                cmp     novesa,1
                je      _main_novesa

                ; create the log file
                call    create_log_file

                ; init the VESA driver
                call    init_vesa
                jc      no_vesa
                mov     eax,offset msg20
                call    printmsg
                mov     eax,vesaheader
                mov     eax,[eax+4]
                push    eax
                movzx   eax,ah
                call    printdecimal
                mov     eax,offset msgpoint
                call    printmsg
                pop     eax
                and     eax,0FFh
                call    printdecimal
                call    crlf
                mov     eax,vesaheader
                mov     eax,[eax+4]
                cmp     ax,0200h
                jb      vesa2_512x384_not_found

                ; search for mode 512x384x8 linear
                call    search_vesa_mode
                jc      vesa2_512x384_not_found

                or      vesa2found,1
_main_novesa_512:

                ; search for mode 400x300x8 linear
                call    search_vesa_mode_400
                jc      vesa2_400x300_not_found

                or      vesa2found,2
_main_novesa_400:
                
                ; search for mode 512x384x15 linear
                call    search_vesa_mode_512_15
                jc      vesa2_512x384x15_not_found

                or      vesa2found,4
_main_novesa_512_15:

_main_novesa:

                cmp     videomode,0
                je      _main_notrouble
                cmp     vesa2found,0
                jne     _main_notrouble
                mov     videomode,0

_main_notrouble:

                ; PSG graph is not available under video cache modes
                cmp     imagetype,0
                je      _main_videocache
                mov     psggraph,0

_main_videocache:

                cmp     gamegear,1
                jne     _main_nogamegear

                ; game gear patches

                ; START button
                mov     eax,offset inemul00_gg
                mov     dword ptr [offset inportxx+00h*4],eax

                ; communications DATA byte
                mov     eax,offset outemul01_gg
                mov     dword ptr [offset outportxx+01h*4],eax
                mov     eax,offset inemul01_gg
                mov     dword ptr [offset inportxx+01h*4],eax

                ; communications STATUS byte
                mov     eax,offset inemul05_gg
                mov     dword ptr [offset inportxx+05h*4],eax

                ; PALETTE with 2 bytes
                mov     eax,offset outemulBE_gg
                mov     dword ptr [offset outportxx+0BEh*4],eax

_main_nogamegear:

                call    check_bad_dump
                call    guess_cartridge
                cmp     guessnow,1
                je      _exit
                
                ; check if user forced block-based engine
                mov     eax,force_block
                xor     eax,1
                and     linebyline,eax
                and     palette_raster,eax

                ; check if user forced no sprite collision detection
                mov     eax,force_nosprcol
                xor     eax,1
                and     do_collision,eax

                ; check for sg1000 emulation
                cmp     sg1000,1
                jne     _main_nosg1000

                ; VDP data port
                mov     eax,offset outemul98
                mov     dword ptr [offset outportxx+0BEh*4],eax
                mov     eax,offset inemul98
                mov     dword ptr [offset inportxx+0BEh*4],eax

                ; VDP address port
                mov     eax,offset outemul99
                mov     dword ptr [offset outportxx+0BFh*4],eax
                mov     eax,offset inemul99
                mov     dword ptr [offset inportxx+0BFh*4],eax

_main_nosg1000:

                ; check for sc3000 emulation
                cmp     sc3000,1
                jne     _main_nosc3000

                mov     eax,msxram
                irp     i,<4,5,6,7>
                mov     dword ptr [offset mem+i*4],eax
                add     eax,2000h
                endm
                irp     i,<4,5,6,7>
                mov     dword ptr [offset memlock+i*4],0
                endm

                mov     eax,offset outemulDE
                mov     dword ptr [offset outportxx+0DEh*4],eax

                mov     eax,offset inemulDE
                mov     dword ptr [offset inportxx+0DEh*4],eax

                mov     eax,offset keyboardtable_sc3000
                mov     keyboard_actual,eax

                mov     eax,offset keyboard_ext_sc3000
                mov     keyboard_extended,eax

                mov     byte ptr [offset smsjoya+2],0FFh

                ;call    decrypt

_main_nosc3000:

                ; check for colecovision emulation
                cmp     coleco,1
                jne     _main_nocoleco

                ; allocate 8kb to coleco bios rom
                mov     eax,8*1024
                call    _getmem
                jc      no_memory
                mov     colecorom,eax

                ; read coleco bios rom from disk
                mov     edx,offset coleco_bios_name
                call    open_file
                jc      coleco_rom_error

                call    read_size_file
                cmp     eax,02000h
                jne     coleco_rom_error

                mov     edx,transf_buffer
                mov     ecx,8*1024
                call    read_file
                call    close_file

                mov     edi,colecorom
                mov     esi,transf_buffer
                mov     ecx,8*1024/4
                rep     movsd

                ; init coleco memory map
                mov     eax,colecorom
                mov     dword ptr [offset mem+0*4],eax
                mov     dword ptr [offset mem+1*4],eax
                mov     dword ptr [offset mem+2*4],eax

                mov     eax,msxram
                mov     dword ptr [offset mem+3*4],eax

                mov     eax,cart1
                mov     dword ptr [offset mem+4*4],eax
                add     eax,2000h
                mov     dword ptr [offset mem+5*4],eax
                add     eax,2000h
                mov     dword ptr [offset mem+6*4],eax
                add     eax,2000h
                mov     dword ptr [offset mem+7*4],eax

                mov     dword ptr [offset memlock+0*4],1
                mov     dword ptr [offset memlock+1*4],1
                mov     dword ptr [offset memlock+2*4],1
                mov     dword ptr [offset memlock+3*4],3
                mov     dword ptr [offset memlock+4*4],1
                mov     dword ptr [offset memlock+5*4],1
                mov     dword ptr [offset memlock+6*4],1
                mov     dword ptr [offset memlock+7*4],1

                ; init coleco I/O map

                ; video output

                mov     eax,offset outemul98
                mov     ebx,offset outemul99
                mov     edi,offset outportxx+0A0h*4
                mov     ecx,10h
coleco_video_io_loop:
                mov     dword ptr [edi],eax
                mov     dword ptr [edi+4],ebx
                add     edi,8
                dec     ecx
                jnz     coleco_video_io_loop

                ; video input

                mov     eax,offset inemul98
                mov     ebx,offset inemul99
                mov     edi,offset inportxx+0A0h*4
                mov     ecx,10h
coleco_video_io_loop_2:
                mov     dword ptr [edi],eax
                mov     dword ptr [edi+4],ebx
                add     edi,8
                dec     ecx
                jnz     coleco_video_io_loop_2

                ; joystick input

                mov     eax,offset inemulE0_coleco
                mov     ebx,offset inemulXX
                mov     edi,offset inportxx+0E0h*4
                mov     ecx,8
coleco_control_loop:
                mov     dword ptr [edi],eax
                mov     dword ptr [edi+4],eax
                mov     dword ptr [edi+8],ebx
                mov     dword ptr [edi+12],ebx
                add     edi,16
                dec     ecx
                jnz     coleco_control_loop

                ; joystick selection

                mov     eax,offset outemul80_coleco
                mov     ebx,offset outemulC0_coleco
                mov     ecx,020h
                mov     edi,offset outportxx+080h*4
coleco_select_loop:
                mov     dword ptr [edi],eax
                mov     dword ptr [edi+(0C0h-080h)*4],ebx
                add     edi,4
                dec     ecx
                jnz     coleco_select_loop

                ; sound

                mov     eax,offset outemul7F
                mov     ecx,20h
                mov     edi,offset outportxx+0E0h*4
                rep     stosd

                ; unmapped

                mov     eax,offset outemulXX
                mov     ecx,080h
                mov     edi,offset outportxx
                rep     stosd

                ; init keyboard handler

                mov     eax,offset keyboardtable_coleco
                mov     keyboard_actual,eax

                mov     eax,offset keyboard_ext_coleco
                mov     keyboard_extended,eax

                mov     byte ptr [offset smsjoya+2],0FFh

                ; init dynamic recompiler

                ;mov     edi,codetable
                ;mov     eax,offset compile_me
                ;mov     ecx,8192
                ;rep     stosd

                ;mov     edi,codetable
                ;add     edi,08000h*4
                ;mov     eax,offset compile_me
                ;mov     ecx,32768
                ;rep     stosd

_main_nocoleco:

                cmp     noenter,1
                je      _main_noenter

                call    crlf
                mov     eax,offset msg10
                call    printmsg
                call    getchar
                cmp     al,27
                jne     _main_noenter
                mov     startdebugger,1

_main_noenter:
                call    debug

main_getout:

                cmp     mmxfound,1
                jne     main_nommx
                emms
main_nommx:

                call    settextmode

                call    close_log_file

                ; print end message
                mov     eax,offset msg22
                call    printmsg

                cmp     has_sram,1
                jne     main_nosram

                call    save_sram

main_nosram:
                
                ; exit to dos
                jmp     _exit

no_memory:      
                mov     eax,offset msg01
                call    printmsg
                jmp     _exit

error_in_rom:
                mov     eax,offset msg02
                call    printmsg
                jmp     _exit

disk_size_not_supported:
                mov     eax,offset msg03
                call    printmsg
                jmp     _exit

soundblaster_failed:
                mov     eax,offset msg11
                call    printmsg
                jmp     _main_nosound

blaster_not_found:
                mov     eax,offset msg14
                call    printmsg
                jmp     _main_nosound

error_in_blaster:
                mov     eax,offset msg15
                call    printmsg
                jmp     _main_nosound

no_vesa:
                mov     eax,offset msg19
                call    printmsg
                jmp     _main_novesa

vesa2_512x384_not_found:
                mov     eax,offset msg21
                call    printmsg
                jmp     _main_novesa_512

vesa2_400x300_not_found:
                mov     eax,offset msg27
                call    printmsg
                jmp     _main_novesa_400

vesa2_512x384x15_not_found:
                mov     eax,offset msg32
                call    printmsg
                jmp     _main_novesa_512_15

coleco_rom_error:
                mov     eax,offset msg36
                call    printmsg
                jmp     _exit

; search_blaster -----------------------------------------------------
; search the environment vars for BLASTER settings
; return: carry flag if BLASTER not found
;         edi = address of first byte after "=" if BLASTER found

search_blaster:

                ; find the start address of environment strings
                mov     esi,02Ch
                add     esi,_pspa
                sub     esi,_code32a
                movzx   eax,word ptr [esi]
                shl     eax,4
                sub     eax,_code32a
                mov     edi,eax

search_blaster_loop:
                mov     ebx,edi
                mov     al,[edi]
                or      al,al
                jz      search_blaster_failed

                mov     esi,offset blasterenv
                mov     ecx,7
                repz    cmpsb
                or      ecx,ecx
                jz      search_blaster_success

                mov     edi,ebx
search_blaster_skip0:
                inc     edi
                cmp     byte ptr [edi],0
                jne     search_blaster_skip0
                inc     edi
                jmp     search_blaster_loop

search_blaster_success:
                inc     edi
                or      eax,eax
                ret

search_blaster_failed:
                stc
                ret

; parse_blaster_string -----------------------------------------------
; parse the blaster string to get the parameters "A", "I" and "D"
; enter edi = start of string
; exit = c flag if error in blaster settings

parse_blaster_string:
                mov     esi,edi
                mov     al,'A'

parse_blaster_loop_A:
                cmp     al,[esi]
                je      parse_blaster_found_A
                inc     esi
                cmp     byte ptr [esi-1],0
                je      parse_blaster_string_error
                jmp     parse_blaster_loop_A

parse_blaster_found_A:
                mov     eax,0
                movzx   edx,byte ptr [esi+1]
                sub     edx,'0'
                add     eax,edx
                shl     eax,4
                
                movzx   edx,byte ptr [esi+2]
                sub     edx,'0'
                add     eax,edx
                shl     eax,4
                
                movzx   edx,byte ptr [esi+3]
                sub     edx,'0'
                add     eax,edx
                mov     sbbaseaddr,eax

                mov     esi,edi
                mov     al,'I'
parse_blaster_loop_I:
                cmp     al,[esi]
                je      parse_blaster_found_I
                inc     esi
                cmp     byte ptr [esi-1],0
                je      parse_blaster_string_error
                jmp     parse_blaster_loop_I

parse_blaster_found_I:
                movzx   eax,byte ptr [esi+1]
                sub     eax,'0'
                movzx   ebx,byte ptr [esi+2]
                cmp     ebx,'0'
                jb      parse_blaster_write_I
                cmp     ebx,'9'
                ja      parse_blaster_write_I
                lea     eax,[eax+eax*4]
                lea     eax,[ebx+eax*2]
                sub     eax,'0'
parse_blaster_write_I:
                mov     sbirq,eax
                
                mov     esi,edi
                mov     al,'D'
parse_blaster_loop_D:
                cmp     al,[esi]
                je      parse_blaster_found_D
                inc     esi
                cmp     byte ptr [esi-1],0
                je      parse_blaster_string_error
                jmp     parse_blaster_loop_D

parse_blaster_found_D:
                movzx   eax,byte ptr [esi+1]
                sub     eax,'0'
                mov     sbdma,eax
                
                or      eax,eax
                ret

parse_blaster_string_error:
                stc
                ret
                
; parse_command_line -------------------------------------------------
; parse the command line and retrieve the correct ROM name
                
                
parse_command_line:                
                mov     esi,argpos
                add     esi,_pspa
                sub     esi,_code32a
                movzx   ecx,byte ptr [esi-1]
                cmp     ecx,0
                je      _ret
                mov     argcount,ecx

parse_command_line_loop:
                mov     al,[esi]
                cmp     al,32
                ja      parse_command_line_found

parse_command_line_next:
                inc     esi
                dec     ecx
                jnz     parse_command_line_loop

                ret

parse_command_line_found:
                push    ecx eax
                mov     edi,offset emptyspace
                mov     eax,0
                mov     ecx,128/4
                rep     stosd
                pop     eax ecx

                mov     edi,offset emptyspace

parse_command_line_found_loop:
                cmp     al,32
                jbe     parse_command_line_out

                mov     [edi],al
                inc     edi

                inc     esi
                mov     al,[esi]

                dec     ecx
                jnz     parse_command_line_found_loop


parse_command_line_out:
                cmp     byte ptr [offset emptyspace],'-'
                je      parse_command_line_switch

                cmp     secondarg,1
                je      parse_command_line_second
                
                cmp     argnumber,0
                jne     parse_command_line_out_1
                push    edi esi ecx
                mov     esi,offset emptyspace
                mov     edi,offset cartridge1
                mov     ecx,128/4
                rep     movsd
                pop     ecx esi edi
                inc     argnumber
                
parse_command_line_out_1:
                cmp     argnumber,1
                jne     parse_command_line_out_2
                push    edi esi ecx
                mov     esi,offset emptyspace
                mov     edi,offset cartridge2
                mov     ecx,128/4
                rep     movsd
                pop     ecx esi edi
                inc     argnumber
                
parse_command_line_out_2: 
                cmp     ecx,0
                je      _ret
                jmp     parse_command_line_next

parse_command_line_second:
                pushad
                call    dword ptr [offset second_callback]
                mov     secondarg,0
                popad
                jmp     parse_command_line_out_2

parse_command_line_switch:
                pushad
                mov     ebp,offset switch_table
                mov     esi,[ebp]
                mov     edi,offset emptyspace
                mov     edx,0

parse_command_line_switch_outer:
                mov     al,[esi]
                cmp     al,[edi]
                jne     parse_command_line_next_switch
                or      al,al
                jz      parse_command_line_switch_found
                inc     esi
                inc     edi
                jmp     parse_command_line_switch_outer

parse_command_line_switch_end:
                popad
                jmp     parse_command_line_out_2

parse_command_line_next_switch:
                inc     edx
                cmp     edx,switch_total
                je      parse_command_line_switch_end
                add     ebp,4
                mov     esi,[ebp]
                mov     edi,offset emptyspace
                jmp     parse_command_line_switch_outer

parse_command_line_switch_found:
                sub     ebp,offset switch_table
                add     ebp,offset switch_callback
                call    dword ptr [ebp]
                jmp     parse_command_line_switch_end

; callbacks ----------------------------------------------------------

callback_nommx:
                mov     nommx,1
                ret

callback_guess:
                mov     guessnow,1
                ret

callback_speaker:
                mov     speaker,1
                mov     nosound,1
                ret

callback_psgg:  
                ;mov     psggraph,1
                ret

callback_cpug:
                mov     cpugraphok,1
                ret

callback_help:
                mov     eax,offset help_message
                call    printmsg
                call    getchar
                mov     eax,offset help_message2
                call    printmsg
                call    getchar
                mov     eax,offset help_message3
                call    printmsg
                jmp     _exit

callback_line:
                mov     linebyline,1
                ret

callback_nosound:
                mov     nosound,1
                ret

callback_vsync:
                mov     vsyncflag,1
                ret

callback_nocache:
                mov     imagetype,0
                ret

callback_nomouse:
                mov     nomouse,1
                ret

callback_novesa:        
                mov     novesa,1
                ret

callback_noenter:
                mov     noenter,1
                ret

callback_sg1000:
                mov     sg1000,1
                ;mov     imagetype,0
                mov     forcedselection,1
                ret

callback_block:
                mov     force_block,1
                ret

callback_palraster:
                mov     linebyline,1
                mov     palette_raster,1
                ret

callback_border:
                mov     noborder,0
                mov     linebyline,1
                mov     palette_raster,1
                ret

callback_res:
                mov     secondarg,1
                mov     eax,offset callback_res_second
                mov     second_callback,eax
                ret

callback_res_second:
                mov     bl,byte ptr [offset emptyspace]
                cmp     bl,'1'
                je      callback_res_400x300
                cmp     bl,'2'
                je      callback_res_512x384
                cmp     bl,'4'
                je      callback_res_512x384_inter
                cmp     bl,'6'
                je      callback_res_512x384_15
                cmp     bl,'8'
                je      callback_res_512x384_15_2xsai
                mov     videomode,0
                ret

callback_res_400x300:
                mov     videomode,1
                ret

callback_res_512x384:
                mov     videomode,2
                ret

callback_res_512x384_inter:
                mov     videomode,4
                mov     linebyline,1
                ret

callback_res_512x384_15:
                mov     videomode,6
                mov     linebyline,1
                ret

callback_res_512x384_15_2xsai:
                mov     videomode,8
                mov     linebyline,1
                ret

callback_sprcol:
                mov     linebyline,1
                mov     do_collision,1
                ret

callback_nosprcol:
                mov     force_nosprcol,1
                ret

callback_joy:
                call    calibrate_joystick
                mov     joyenable,1
                ret

callback_com:
                mov     secondarg,1
                mov     eax,offset callback_com_second
                mov     second_callback,eax
                ret

callback_com_second:
                movzx   ebx,byte ptr [offset emptyspace]
                cmp     bl,'1'
                jb      _ret
                cmp     bl,'4'
                ja      _ret
                sub     bl,'0'
                mov     comport,ebx
                ret

callback_server:
                mov     sessionmode,1
                ret

callback_client:
                mov     sessionmode,2
                ret

callback_frame:
                mov     secondarg,1
                mov     eax,offset callback_frame_second
                mov     second_callback,eax
                ret

callback_frame_second:
                mov     autoframe,0
                mov     eax,0
                mov     ebx,eax
                mov     esi,offset emptyspace

callback_frame_loop:
                mov     bl,[esi]
                cmp     bl,0
                je      callback_frame_set

                lea     eax,[eax+eax*4]
                lea     eax,[ebx+eax*2]
                sub     eax,'0'
                inc     esi
                jmp     callback_frame_loop

callback_frame_set:
                cmp     eax,0
                je      _ret
                mov     framerate,eax
                ret

callback_lpt:
                mov     secondarg,1
                mov     eax,offset callback_lpt_second
                mov     second_callback,eax
                ret

callback_lpt_second:
                mov     al,byte ptr [offset emptyspace]
                cmp     al,'1'
                jb      _ret
                cmp     al,'2'
                ja      _ret
                and     eax,0FFh
                sub     eax,'1'
                mov     eax,dword ptr [offset lptaddress+eax*4]
                mov     lptport,eax
                ret

callback_nopent:
                mov     nopentium,1
                ret

callback_log:
                mov     secondarg,1
                mov     eax,offset callback_log_second
                mov     second_callback,eax
                ret

callback_log_second:
                mov     edi,offset log_name
                mov     esi,offset emptyspace
                mov     ecx,128/4
                rep     movsd
                mov     log_music,1
                mov     eax,offset outemul7F_log
                mov     dword ptr [offset outportxx+7Eh*4],eax
                mov     dword ptr [offset outportxx+7Fh*4],eax
                ret

callback_gg:    
                mov     gamegear,1
                mov     forcedselection,1
                ret

callback_eng:    
                mov     country,0
                ret

callback_jap:    
                mov     country,0FFh
                ret

callback_joysens:
                mov     secondarg,1
                mov     eax,offset callback_joysens_second
                mov     second_callback,eax
                ret

callback_joysens_second:
                mov     bl,byte ptr [offset emptyspace]
                sub     bl,'0'
                mov     joysens,bl
                call    calibrate_joystick
                ret

callback_noguess:
                mov     guess,0
                ret

callback_3d:    
                mov     system3d,1
                mov     imagetype,0
                mov     autoframe,0
                ret

callback_listrom:    
                jmp     list_roms

callback_sms:    
                mov     gamegear,0
                mov     forcedselection,1
                ret

callback_snespad:    
                mov     snespad,1
                mov     joyenable,1
                ret

callback_truevsync:
                mov     truevsync,1
                mov     autoframe,0
                ret

callback_sc3000:
                mov     sg1000,1
                mov     forcedselection,1
                mov     sc3000,1
                ret

callback_lightgun:
                mov     linebyline,1
                mov     palette_raster,1
                mov     lightgun,1
                ret

callback_2d:
                mov     linebyline,1
                mov     palette_raster,1
                mov     framerate,2
                mov     autoframe,0
                ret

callback_lcd:
                mov     lcdfilter,1
                ret

callback_paddle:
                mov     pad_enabled,1
                ret

callback_mousepad:
                mov     pad_enabled,1
                mov     mouse_enabled,1
                ret

callback_coleco:
                mov     sg1000,1
                mov     coleco,1
                mov     forcedselection,1
                ret

; read_rom -----------------------------------------------------------
; read a ROM file from the disk
; enter: edx = offset of rom name 
;        eax = offset of read buffer
;        ebp = slot
; exit: carry flag on any error
                
read_rom:
                call    open_file
                jc      _ret

                ; read ROM size from disk
                push    eax
                call    read_size_file
                mov     filesize,eax
                pop     eax

                ; check for 512 byte header
                mov     ecx,filesize
                and     ecx,0200h
                jz      read_rom_noheader

                ; skip 512 byte header
                mov     edx,transf_buffer
                mov     ecx,512
                call    read_file

read_rom_noheader:

                mov     edi,eax
                mov     ebx,filesize
                shr     ebx,13

read_rom_megarom_loop:
                ; read a 8kb chunk
                mov     edx,transf_buffer
                mov     ecx,2000h
                call    read_file

                ; place 8kb chunk in buffer
                mov     esi,transf_buffer
                mov     ecx,02000h/4
                rep     movsd

                dec     ebx
                jnz     read_rom_megarom_loop

                ; place ROM in memory
                irp     i,<0,1,2,3,4,5>
                mov     dword ptr [ebp+i*4],eax
                add     eax,2000h
                endm
                
                ; generate rom mask
                mov     eax,filesize
                and     eax,0FFFFFC00h
                shr     eax,14
                dec     eax
                cmp     eax,031h
                jne     read_rom_mask
                ; special case: street fighter
                mov     eax,03Fh
read_rom_mask:
                mov     rommask,eax

                call    close_file
                or      eax,eax
                ret

; enable_megaram -----------------------------------------------------
; enable the megaram and the scc

enable_megaram:                
                mov     eax,2
                mov     dword ptr [offset slot1+16+4],eax
                mov     dword ptr [offset slot1+16+4+8],eax
                mov     dword ptr [offset slot1+16+4+16],eax
                mov     dword ptr [offset slot1+16+4+24],eax
                ret


; enable_rom ---------------------------------------------------------
; enable the ROM

enable_rom:                
                mov     eax,1
                mov     dword ptr [offset slot1+16+4],eax
                mov     dword ptr [offset slot1+16+4+8],eax
                mov     dword ptr [offset slot1+16+4+16],eax
                mov     dword ptr [offset slot1+16+4+24],eax
                ret

; decode_cartridge ---------------------------------------------------
; decode the cartridge name, retrieving a name for the save state

decode_cartridge:
                mov     esi,offset cartridge1
                mov     edi,offset cartname

decode_cartridge_loop:
                mov     al,[esi]
                cmp     al,':'
                je      decode_cartridge_restart
                cmp     al,'/'
                je      decode_cartridge_restart
                cmp     al,'\'
                je      decode_cartridge_restart
                cmp     al,0
                je      decode_cartridge_append
                cmp     al,'.'
                je      decode_cartridge_append
                mov     [edi],al
                inc     esi
                inc     edi
                jmp     decode_cartridge_loop

decode_cartridge_restart:
                inc     esi
                mov     edi,offset cartname
                jmp     decode_cartridge_loop

decode_cartridge_append:
                mov     byte ptr [edi],'.'
                mov     byte ptr [edi+1],'S'
                mov     byte ptr [edi+2],'T'
                mov     byte ptr [edi+3],'A'
                mov     byte ptr [edi+4],0

                mov     bx,word ptr [esi+1]
                and     bx,0DFDFh
                
                cmp     forcedselection,1
                je      _ret

                cmp     bx,'GG'
                jne     decode_cartridge_sg1000

                mov     gamegear,1
                ret

decode_cartridge_sg1000:
                cmp     bx,'GS'
                jne     decode_cartridge_sc3000

                mov     sg1000,1
                ret

decode_cartridge_sc3000:
                cmp     bx,'CS'
                jne     decode_cartridge_coleco

                mov     sg1000,1
                mov     sc3000,1
                ret

decode_cartridge_coleco:
                cmp     bx,'OR'
                jne     _ret

                mov     sg1000,1
                mov     coleco,1
                ret

; decode_cartridge_sram ----------------------------------------------
; decode the cartridge name, retrieving a name for the sram

decode_cartridge_sram:
                mov     esi,offset cartridge1
                mov     edi,offset sramname

decode_cartridge_loop_sram:
                mov     al,[esi]
                cmp     al,':'
                je      decode_cartridge_restart_sram
                cmp     al,'/'
                je      decode_cartridge_restart_sram
                cmp     al,'\'
                je      decode_cartridge_restart_sram
                cmp     al,0
                je      decode_cartridge_append_sram
                cmp     al,'.'
                je      decode_cartridge_append_sram
                mov     [edi],al
                inc     esi
                inc     edi
                jmp     decode_cartridge_loop_sram

decode_cartridge_restart_sram:
                inc     esi
                mov     edi,offset sramname
                jmp     decode_cartridge_loop_sram

decode_cartridge_append_sram:
                mov     byte ptr [edi],'.'
                mov     byte ptr [edi+1],'S'
                mov     byte ptr [edi+2],'R'
                mov     byte ptr [edi+3],'M'
                mov     byte ptr [edi+4],0

                ret

; guess_cartridge ----------------------------------------------------
; guess the name of cartridge based on CRC
; enable custom CPU optimizations for this cartdridge

savebyte        db      0

guess_cartridge:
                cmp     guess,1
                jne     _ret
                
                pushad

                mov     esi,cart1
                mov     al,[esi]
                mov     savebyte,al
                mov     byte ptr [esi],0C3h

                call    evaluate_crc

                cmp     eax,0C9976820h
                je      guess_basic_3

                cmp     eax,07E2E6590h
                je      guess_music

                mov     al,savebyte
                mov     esi,cart1
                mov     [esi],al

                call    evaluate_crc

                mov     esi,offset guess_table

guess_try_again:
                cmp     eax,dword ptr [esi]
                je      guess_found
                add     esi,12
                cmp     dword ptr [esi],012345678h
                jne     guess_try_again

                ; cartridge was not found

                cmp     guessnow,1
                jne     guess_ret

                push    eax
                mov     eax,offset msg25
                call    printmsg

                mov     edi,offset cartridge1
                mov     al,0
                mov     ecx,128
                repnz   scasb

                mov     byte ptr [edi-1],'$'

                mov     eax,offset cartridge1
                call    printmsg
                mov     eax,offset msg28
                call    printmsg
                pop     eax

                push    eax
                shr     eax,16
                call    convhex4
                mov     eax,offset tmphex4
                call    printmsg
                pop     eax

                call    convhex4
                mov     eax,offset tmphex4
                call    printmsg

                mov     eax,offset msg29
                call    printmsg

                popad
                ret

                ; cartridge was found

guess_found:
                mov     eax,offset msg25
                call    printmsg
                mov     eax,dword ptr [esi+8]
                call    printmsg
                call    crlf
                mov     eax,offset msg30
                call    printmsg
                mov     ecx,100
                mov     al,'$'
                mov     edi,dword ptr [esi+8]
                repnz   scasb
                mov     eax,edi
                call    printmsg
                call    crlf
                
                cmp     guessnow,1
                je      guess_ret

                mov     eax,dword ptr [esi+4]
                call    eax

guess_ret:
                popad
                ret

evaluate_crc:
                mov     edx,filesize
                and     edx,0FFFFFC00h
                shr     edx,2
                mov     eax,0
                mov     esi,cart1
                mov     ecx,0

guess_loop:
                mov     ebp,[esi]
                shl     ebp,cl
                xor     eax,ebp
                add     esi,4
                inc     ecx
                cmp     ecx,7
                jne     guess_modulo_7
                mov     ecx,0
guess_modulo_7:
                dec     edx
                jnz     guess_loop

                ret

guess_basic_3:
                mov     esi,offset entry_basic
                jmp     guess_found

guess_music:
                mov     esi,offset entry_music
                jmp     guess_found

; list_roms ----------------------------------------------------------
; print a list of customized roms

list_roms:
                mov     eax,offset msg26
                call    printmsg

                mov     esi,offset guess_table

list_roms_loop:
                push    esi esi
                mov     al,'$'
                mov     ecx,80
                mov     edi,dword ptr [esi+8]
                repnz   scasb
                cmp     dword ptr [edi],'enoN'
                jne     list_roms_buggy
                mov     byte ptr [offset msg31],'.'
                jmp     list_roms_name
list_roms_buggy:
                cmp     dword ptr [edi],' toN'
                je      list_roms_very_buggy
                mov     byte ptr [offset msg31],'-'
                jmp     list_roms_name
list_roms_very_buggy:
                mov     byte ptr [offset msg31],'*'
list_roms_name:
                mov     eax,offset msg31
                call    printmsg
                pop     esi
                mov     eax,dword ptr [esi+8]
                call    printmsg
                call    crlf
                pop     esi
                add     esi,12
                cmp     dword ptr [esi],012345678h
                jne     list_roms_loop

                jmp     _exit

; save_sram ----------------------------------------------------------
; save the SRAM in the disk

save_sram:
                ; create file
                mov     edx,offset sramname
                call    create_file

                ; place in correct place
                mov     esi,cart_sram
                mov     edi,transf_buffer
                mov     ecx,32768/4
                rep     movsd

                ; write to disk
                mov     ecx,32768
                mov     edx,transf_buffer
                call    write_file

                ; close the file and exit
                call    close_file
                ret

; load_sram ----------------------------------------------------------
; load sram from disk if needed

load_sram:
                ; check if file exists
                mov     edx,offset sramname
                call    open_file
                jc      _ret

                ; read from disk
                mov     ecx,32768
                mov     edx,transf_buffer
                call    read_file

                ; place in correct place
                mov     edi,cart_sram
                mov     esi,transf_buffer
                mov     ecx,32768/4
                rep     movsd

                ; close the file 
                call    close_file

                ret

; check_bad_dump -----------------------------------------------------
; check if the game is a bad dump
; by searching for duplicates 

check_bad_dump:
                mov     esi,cart1
                mov     ecx,filesize
                and     ecx,0FFFFFC00h
                shr     ecx,1
                lea     edi,[esi+ecx]

check_bad_dump_loop:
                push    ecx
                repz    cmpsb
                pop     ecx
                jnz     check_bad_dump_exit

                shr     ecx,1
                mov     esi,cart1
                lea     edi,[esi+ecx]
                jmp     check_bad_dump_loop

check_bad_dump_exit:
                add     ecx,ecx
                mov     eax,filesize
                and     eax,0FFFFFC00h
                cmp     eax,ecx
                je      _ret

                push    ecx

                mov     eax,offset msg33
                call    printmsg

                mov     eax,filesize
                and     eax,0FFFFFC00h
                shr     eax,10
                call    printdecimal
                
                mov     eax,offset msg34
                call    printmsg

                pop     ecx
                push    ecx

                mov     eax,ecx
                shr     eax,10
                call    printdecimal
                
                mov     eax,offset msg35
                call    printmsg

                pop     ecx
                mov     filesize,ecx

                ret

; decrypt ------------------------------------------------------------
; decrypt the sc3000 rom

decrypt_key:
                db      'G.0rw3lL'

decrypt:
                mov     esi,cart1
                mov     ecx,32768
                mov     edi,0
                mov     edx,0
decrypt_loop:
                mov     al,[esi]
                xor     al,dl
                mov     ah,[offset decrypt_key+edi]
                xor     al,ah
                mov     [esi],al

                inc     dl
                inc     edi
                and     edi,7
                inc     esi
                dec     ecx
                jnz     decrypt_loop

                ret

code32          ends
                end


