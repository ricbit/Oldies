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
include z80sing.inc
include debug.inc
include psg.inc
include mouse.inc
include vesa.inc
include vdp.inc
include joystick.inc
include gui.inc
include drive.inc
include serial.inc
include z80core.inc
include mount.inc
include symdeb.inc
include v9938.inc
include v9958.inc
include extended.inc

public _main
public msxram
public msxvram
public msxvram_swap
public blitbuffer
public collisionfield
public transf_buffer
public message_buffer
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
public disksize
public codetable
public rommapper
public rommappera
public cart_sram
public mountdir_name
public redbuffer
public bluebuffer
public symbolic_debugger
public prn_name
public dos2enabled
public extendedrom
public msxmodel
public vdplog
public drivea_name
public load_disk_image
public noise_uncompressed
public alf_uncompressed
public temp_screen
public logout

extrn detect_cpu: near
extrn pentiumfound: dword
extrn mmxfound: dword
extrn iset: dword

; DATA ---------------------------------------------------------------

DMABUFFERSIZE   equ     800*20

include guess.inc

msg00           db      'BrMSX 2.10',13,10
                db      'Copyright (C) 1997-2002 by Ricardo Bittencourt'
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
msg10           db      'Press ENTER to start or ESC to debugger. $'
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
msg22           db      'BrMSX 2.10',13,10
                db      'Copyright (C) 1997-2002 by Ricardo Bittencourt'
                db      13,10
                db      'Official site: http://www.lsi.usp.br/'
                db      '~ricardo/brmsx.htm',13,10
                db      'Send bugs, comments and suggestions to '
                db      'ricardo@lsi.usp.br',13,10,'$'
msg23           db      'Cartridge A: $'
msg24           db      'Cartridge B: $'
msg25           db      'Drive A: $'
msg26           db      'MSX.ROM invalid or not found',13,10,'$'
msg27           db      'DISK.ROM invalid or not found',13,10,'$'
msg28           db      'Tape: $'
msg29           db      'Tape image not found',13,10,'$'
msg30           db      'Tape image greater than 64kb',13,10,'$'
msg31           db      'MSXHAN.ROM invalid or not found',13,10,'$'
msg32           db      'I guess this game is $'
msg33           db      'Using MegaROM Mapper #$'
msg34           db      'This game is unknown, using MegaROM Mapper #0',13,10
                db      'Please contact the author at ricardo@lsi.usp.br'
                db      13,10,'$'
msg35           db      'Disk image invalid or not found',13,10,'$'
msg36           db      'VESA2 512x384x15 not found',13,10,'$'
msg37           db      13,10,'This ROM is a bad dump.',13,10
                db      'Please download SMSFIX to fix it.',13,10
                db      'You can get SMSFIX at the BrMSX home page:',13,10
                db      'http://www.lsi.usp.br/~ricardo/brmsx.htm',13,10,'$'
msg38           db      'VESA2 not found',13,10,'$'
msg39           db      'DOS2.ROM invalid or not found',13,10,'$'
msg40           db      'MSX2.ROM invalid or not found',13,10,'$'
msg41           db      'MSX2EXT.ROM invalid or not found',13,10,'$'
msg42           db      'VESA2 640x480x8 not found',13,10,'$'
help_message    db      'Usage: BRMSX [-options] '
                db      '[cartA.rom] [cartB.rom]' 
                db      13,10,10,'Options:',13,10
                db      '-msx1          select MSX 1 emulation '
                db      '(default)',13,10
                db      '-msx2          select MSX 2 emulation',13,10
                db      '-msx2+         select MSX 2+ emulation',13,10
                db      '-normal        normal emulation speed '
                db      '(3.57 MHz, default)',13,10
                db      '-ciel          double emulation speed '
                db      '(7.14 MHz)',13,10
                db      '-fast          fast emulation speed',13,10
                db      '-turbo         turbo emulation speed',13,10
                db      '-roma <n>      select MegaROM Mapper for '
                db      'cartridge A (default=autodetect)',13,10
                db      '-romb <n>      select MegaROM Mapper for '
                db      'cartridge B',13,10
                db      '               0=Generic MegaROM with SCC',13,10
                db      '               1=MSX-DOS 2',13,10
                db      '               2=Konami with SCC',13,10
                db      '               3=Konami without SCC',13,10
                db      '               4=ASCII 8kb',13,10
                db      '               5=ASCII 16kb',13,10
                db      '               6=ASCII 8kb with 8kb SRAM',13,10
                db      '               7=ASCII 16kb with 2kb SRAM',13,10
                db      '               8=Panasonic FM-PAC with 8kb SRAM',13,10
                db      'Press enter to continue.$'
help_message2   db      13
                db      '               9=Konami with 8-bit DAC',13,10
                db      '-ifreq <n>     change interrupt frequency '
                db      '(default is 60)',13,10
                db      '-ramslot <n>   select slot of RAM, can be 2 '
                db      '(default) or 3',13,10
                db      '-korean        enable korean memory layout '
                db      '(require korean MSX.ROM/MSXHAN.ROM)',13,10
                db      '-megaram <n>   select size of MegaRAM '
                db      '(default=1)',13,10
                db      '               0=128kb 1=256kb 2=512kb 3=1Mb 4=2Mb',13,10
                db      '-mapper <n>    select size of Memory Mapper '
                db      '(default=1)',13,10
                db      '               0=64kb 1=128kb 2=256kb 3=512kb '
                db      '4=1Mb 5=2Mb 6=4Mb',13,10
                db      '-res <mode>    select screen resolution',13,10 
                db      '               0 =320x200x8  MSX 1 default',13,10
                db      '               1 =256x200x8  MSX 1 large screen'
                db      13,10
                db      '               2 =512x384x8  MSX 1 TV emulation '
                db      '(interpolation+scanlines)',13,10
                db      '               3 =256x192x8  MSX 1 square pixels'
                db      13,10
                db      '               6 =512x384x15 MSX 1 Parrot engine'
                db      13,10
                db      '               7 =320x200x8  MSX 2 default',13,10
                db      '               8 =512x384x8  MSX 2 full width '
                db      'support',13,10
                db      '               9 =512x384x8  MSX 2 full width '
                db      'support with black scanlines',13,10
                db      '               11=640x480x8  MSX 2 full screen '
                db      'support with black scanlines',13,10
                db      '               12=512x384x15 MSX 2+ with support '
                db      'to YJK system',13,10
                db      '-vsync         sync with the monitor and the '
                db      'internal timer',13,10
                db      '-truevsync     sync with the monitor only '
                db      '(require monitor with 60Hz refresh)',13,10
                db      '-green         enable green monitor emulation',13,10
                db      '-advram        enable ADVRAM emulation',13,10
                db      '-frame <n>     frame skipping (1 means all '
                db      'frames rendered, default)',13,10
                db      'Press enter to continue.$'
help_message3   db      13
                db      '-allspr        disable 5th sprite ocultation',13,10
                db      '-nosprcol      disable sprite collision ',13,10
                db      '-vdptiming     enable emulation of VDP timing '
                db      '(default in MSX-1 mode)',13,10
                db      '-novdptiming   disable emulation of VDP timing '
                db      '(default in MSX-2 and 2+ modes)',13,10
                db      '-trtimer       enable high resolution timer',13,10
                db      '-nocache       disable video cache',13,10
                db      '-nommx         disable MMX optimizations',13,10
                db      '-cpugraph      enable CPU performance graph',13,10
                db      '-psggraph      enable PSG graph',13,10
                db      '-nosound       disable the sound engine',13,10
                db      '-scc           enable SCC sound',13,10
                db      '-fmpac         enable FM-PAC sound (MSX Music)'
                db      13,10
                db      '-sr <n>        select the sample rate '
                db      '(default is 45455)',13,10
                db      '-speaker       sound through the PC speaker',13,10
                db      '-speaq <n>     select quality for PC speaker sound'
                db      ' (range is 1 to 9)',13,10
                db      '-dos2          enable MSX-DOS 2 emulation '
                db      '(require DOS2.ROM)',13,10
                db      '-diska <file>  use <file> as drive A',13,10
                db      '-disklow       low-level, port-based disk '
                db      'emulation (default in MSX-1 mode)',13,10
                db      '-diskhigh      high-level, patch-based disk '
                db      'emulation (default in MSX-2 mode)',13,10
                db      '-mount <dir>   mount the directory <dir> as '
                db      'drive A:',13,10
                db      '-tape <file>   use <file> as cassete image',13,10
                db      '-prn <file>    load <file> to make symbolic '
                db      'debugging',13,10
                db      '-joy           enable joystick emulation',13,10
                db      '-joysens <n>   adjust joystick sensibility '
                db      '(range is 0 to 7, default is 3)',13,10
                db      'Press enter to continue.$'
help_message4   db      13
                db      '-snespad       enable SNES pad connected in '
                db      'LPT1',13,10
                db      '-autofire      enable the automatic fire',13,10
                db      '-autorun       enable the automatic run',13,10
                db      '-autospeed <n> adjust speed for autofire '
                db      '(range is 0 to 9, default is 5)',13,10
                db      '-fakejoy       make the keyboard act as '
                db      'joystick A',13,10
                db      '-nomouse       disable mouse driver detection',13,10
                db      '-com <port>    select COM serial port [1-4]',13,10
                db      '-client        computer is client',13,10
                db      '-server        computer is server',13,10
                db      '-novesa        disable VESA detection',13,10
                db      '-noled         disable LED emulation',13,10
                db      '-nopentium     disable pentium extensions and '
                db      'cpu autodetect',13,10
                db      '-noenter       disable enter pressing at '
                db      'start',13,10
                db      '-help          show this help page',13,10
                db      '$'
                  
msgnocpuid        db      '486 or below $'
msg386            db      '386 $'
msg486            db      '486 $'
msg586            db      'Pentium $'
msg686            db      'Pentium Pro or better $'
msgMMX            db      '(MMX)$'
msgpoint          db      '.$'
rom_name          db      'MSX.ROM',0
disk_rom_name     db      'DISK.ROM',0
disk2_rom_name    db      'DISK2.ROM',0
dos2_rom_name     db      'DOS2.ROM',0
msxhan_name       db      'MSXHAN.ROM',0
msx2_rom_name     db      'MSX2.ROM',0
msx2ext_rom_name  db      'MSX2EXT.ROM',0
msx2p_rom_name    db      'MSX2P.ROM',0
msx2pext_rom_name db      'MSX2PEXT.ROM',0
blasterenv        db      'BLASTER',0
brmsxtmp          db      'BRMSX.TMP',0
addrstr           db      3 dup (0)
model_diskrom     dd     offset disk_rom_name
model_mainrom     dd     offset msx2_rom_name
model_subrom      dd     offset msx2ext_rom_name

emptyspace      db      128 dup (0)
cmdline         dd      0
argnumber       dd      0
argpos          dd      081h
argcount        dd      0

secondarg       dd      0
second_callback dd      0

cartridge1      db      128 dup (0)
cartridge2      db      128 dup (0)
drivea_name     db      128 dup (0)
tape_name       db      128 dup (0)
sramname        db      128 dup (0)
mountdir_name   db      128 dup (0)
prn_name        db      128 dup (0)
                 
switch_nommx     db      '-nommx',0
switch_scc       db      '-scc',0
switch_psgg      db      '-psggraph',0
switch_cpug      db      '-cpugraph',0
switch_help      db      '-help',0
switch_diska     db      '-diska',0
switch_nosound   db      '-nosound',0
switch_vsync     db      '-vsync',0
switch_nocache   db      '-nocache',0
switch_nomouse   db      '-nomouse',0
switch_novesa    db      '-novesa',0
switch_noenter   db      '-noenter',0
switch_normal    db      '-normal',0
switch_fast      db      '-fast',0
switch_turbo     db      '-turbo',0
switch_noled     db      '-noled',0
switch_res       db      '-res',0
switch_disklow   db      '-disklow',0
switch_diskhigh  db      '-diskhigh',0
switch_joy       db      '-joy',0
switch_com       db      '-com',0
switch_server    db      '-server',0
switch_client    db      '-client',0
switch_frame     db      '-frame',0
switch_tape      db      '-tape',0
switch_nopent    db      '-nopentium',0
switch_ramslot   db      '-ramslot',0
switch_joysens   db      '-joysens',0
switch_korean    db      '-korean',0
switch_green     db      '-green',0
switch_roma      db      '-roma',0
switch_romb      db      '-romb',0
switch_speaker   db      '-speaker',0
switch_allspr    db      '-allspr',0
switch_fakejoy   db      '-fakejoy',0
switch_autofire  db      '-autofire',0
switch_autospeed db      '-autospeed',0
switch_autorun   db      '-autorun',0
switch_fmpac     db      '-fmpac',0
switch_nosprcol  db      '-nosprcol',0
switch_mount     db      '-mount',0
switch_megaram   db      '-megaram',0
switch_mapper    db      '-mapper',0
switch_speaq     db      '-speaq',0
switch_sr        db      '-sr',0
switch_ifreq     db      '-ifreq',0
switch_snespad   db      '-snespad',0
switch_vdptiming db      '-vdptiming',0
switch_dos2      db      '-dos2',0
switch_prn       db      '-prn',0
switch_msx2      db      '-msx2',0
switch_vdplog    db      '-vdplog',0
switch_truevsync db      '-truevsync',0
switch_joynet    db      '-joynet',0
switch_msx2p     db      '-msx2+',0
switch_ciel             db      '-ciel',0
switch_advram           db      '-advram',0
switch_trtimer          db      '-trtimer',0
switch_novdptiming      db      '-novdptiming',0
switch_logout           db      '-logout',0
switch_nomegaram        db      '-nomegaram',0

switch_table:
                dd      offset switch_nommx
                dd      offset switch_scc
                dd      offset switch_psgg
                dd      offset switch_cpug
                dd      offset switch_help
                dd      offset switch_diska
                dd      offset switch_nosound
                dd      offset switch_vsync
                dd      offset switch_nocache
                dd      offset switch_nomouse
                dd      offset switch_novesa
                dd      offset switch_noenter
                dd      offset switch_normal
                dd      offset switch_fast
                dd      offset switch_turbo
                dd      offset switch_noled
                dd      offset switch_res
                dd      offset switch_disklow
                dd      offset switch_diskhigh
                dd      offset switch_joy
                dd      offset switch_com
                dd      offset switch_server
                dd      offset switch_client
                dd      offset switch_frame
                dd      offset switch_tape
                dd      offset switch_nopent
                dd      offset switch_ramslot
                dd      offset switch_joysens
                dd      offset switch_korean
                dd      offset switch_green
                dd      offset switch_roma
                dd      offset switch_romb
                dd      offset switch_speaker
                dd      offset switch_allspr
                dd      offset switch_fakejoy
                dd      offset switch_autofire
                dd      offset switch_autospeed
                dd      offset switch_autorun
                dd      offset switch_fmpac
                dd      offset switch_nosprcol
                dd      offset switch_mount
                dd      offset switch_megaram
                dd      offset switch_mapper
                dd      offset switch_speaq
                dd      offset switch_sr
                dd      offset switch_ifreq
                dd      offset switch_snespad
                dd      offset switch_vdptiming
                dd      offset switch_dos2
                dd      offset switch_prn
                dd      offset switch_msx2
                dd      offset switch_vdplog
                dd      offset switch_truevsync
                dd      offset switch_joynet
                dd      offset switch_msx2p
                dd      offset switch_ciel
                dd      offset switch_advram
                dd      offset switch_trtimer
                dd      offset switch_novdptiming
                dd      offset switch_logout
                dd      offset switch_nomegaram

switch_total    dd      61

switch_callback: 
                dd      offset callback_nommx
                dd      offset callback_scc
                dd      offset callback_psgg
                dd      offset callback_cpug
                dd      offset callback_help
                dd      offset callback_diska
                dd      offset callback_nosound
                dd      offset callback_vsync
                dd      offset callback_nocache
                dd      offset callback_nomouse
                dd      offset callback_novesa
                dd      offset callback_noenter
                dd      offset callback_normal
                dd      offset callback_fast
                dd      offset callback_turbo
                dd      offset callback_noled
                dd      offset callback_res
                dd      offset callback_disklow
                dd      offset callback_diskhigh
                dd      offset callback_joy
                dd      offset callback_com
                dd      offset callback_server
                dd      offset callback_client
                dd      offset callback_frame
                dd      offset callback_tape
                dd      offset callback_nopent
                dd      offset callback_ramslot
                dd      offset callback_joysens
                dd      offset callback_korean
                dd      offset callback_green
                dd      offset callback_roma
                dd      offset callback_romb
                dd      offset callback_speaker
                dd      offset callback_allspr
                dd      offset callback_fakejoy
                dd      offset callback_autofire
                dd      offset callback_autospeed
                dd      offset callback_autorun
                dd      offset callback_fmpac
                dd      offset callback_nosprcol
                dd      offset callback_mount
                dd      offset callback_megaram
                dd      offset callback_mapper
                dd      offset callback_speaq
                dd      offset callback_sr
                dd      offset callback_ifreq
                dd      offset callback_snespad
                dd      offset callback_vdptiming
                dd      offset callback_dos2
                dd      offset callback_prn
                dd      offset callback_msx2
                dd      offset callback_vdplog
                dd      offset callback_truevsync
                dd      offset callback_joynet
                dd      offset callback_msx2p
                dd      offset callback_ciel
                dd      offset callback_advram
                dd      offset callback_trtimer
                dd      offset callback_novdptiming
                dd      offset callback_logout
                dd      offset callback_nomegaram

cart1table:
                dd      128*1024
                dd      256*1024
                dd      512*1024
                dd      1024*1024
                dd      2048*1024

cart1mask:
                db      00Fh
                db      01Fh
                db      03Fh
                db      07Fh
                db      0FFh

mapper_table:
                dd      64*1024
                dd      128*1024
                dd      256*1024
                dd      512*1024
                dd      1024*1024
                dd      2048*1024
                dd      4096*1024

mapper_mask:
                db      003h
                db      007h
                db      00Fh
                db      01Fh
                db      03Fh
                db      07Fh
                db      0FFh

align 4

msxram                  dd      ?
msxvram                 dd      ?
msxvram_swap            dd      ?
blitbuffer              dd      ?
collisionfield          dd      ?
msxrom                  dd      ?
msxextrom               dd      ?
cart1                   dd      ?
cart2                   dd      ?
transf_buffer           dd      ?
message_buffer          dd      ?
diskimage               dd      ?
compbuffer              dd      ?
dirtycode               dd      ?
dmabuffer               dd      ?
dmatemp                 dd      ?
filenamelist            dd      ?
vesaheader              dd      ?
vesamodeinfo            dd      ?
diskrom                 dd      ?
soundbuffer             dd      ?
timebuffer              dd      ?
sccram                  dd      ?
idlerom                 dd      ?
tapeimage               dd      ?
msxhan                  dd      ?
codetable               dd      ?
cart_sram               dd      ?
redbuffer               dd      ?
bluebuffer              dd      ?
extendedrom             dd      ?
noise_uncompressed      dd      ?
alf_uncompressed        dd      ?
temp_screen             dd      ?

diskenabled        dd      0
cpugraphok         dd      0
nosound            dd      0
nomouse            dd      0
novesa             dd      0
noenter            dd      0
filesize           dd      0
nopentium          dd      0
korean             dd      0
disksize           dd      0
guess              dd      1
rommappera         dd      2
rommapperb         dd      2
rommapper          dd      2
firsttime          dd      1
nommx              dd      0
dos2enabled        dd      0
symbolic_debugger  dd      0
msxmodel           dd      0          
vdplog             dd      0
logout             dd      0
forcedisk          dd      0     
vramsize           dd      16384
cart1size          dd      512*1024
mappersize         dd      128*1024

; --------------------------------------------------------------------

_main:          
                sti

                ; allocate 2kb to message buffer
                mov     eax,2048
                call    _getlomem
                jc      no_memory
                mov     message_buffer,eax

                ; print startup message
                mov     eax,offset msg00
                call    printmsg

                ; alloc space for command line
                mov     eax,256
                call    _getlomem
                jc      no_memory
                mov     cmdline,eax

                mov     edx,offset brmsxtmp
                call    open_file

                mov     edx,cmdline
                mov     ecx,081h
                call    read_file

                call    close_file

                call    parse_command_line
                                               
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

                cmp     cpugraphok,1
                jne     _main_nocpugraph
                call    changebargraph
_main_nocpugraph:
_main_nopentium:

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

                ; allocate 2kb to message buffer
                mov     eax,2048
                call    _getlomem
                jc      no_memory
                mov     message_buffer,eax

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
                
                ; allocate 8kb to idle rom
                mov     eax,8192
                call    _getmem
                jc      no_memory
                mov     idlerom,eax

                ; fill idle rom with 0FFh
                mov     edi,idlerom
                mov     eax,0FFFFFFFFh
                mov     ecx,8192/4
                rep     stosd
                
                ; fill all slots with idle rom
                mov     eax,idlerom
                mov     ecx,32
                mov     ebx,offset slot0
_main_idlerom:
                mov     [ebx],eax
                add     ebx,8
                loop    _main_idlerom

                ; fill mem with idle rom
                irp     i,<0,1,2,3,4,5,6,7>
                mov     dword ptr [offset mem+i*4],eax
                endm

                ; read the ROMs and select the msx model
                call    read_msx_rom

                ; allocate 2*64kb to red buffer (used in Parrot engine)
                mov     eax,2*65536
                call    _getmem
                jc      no_memory
                mov     redbuffer,eax

                mov     edi,redbuffer
                mov     eax,0
                mov     ecx,2*65536/4
                rep     stosd

                ; allocate 64kb to blue buffer (used in Parrot engine)
                mov     eax,65536*2
                call    _getmem
                jc      no_memory
                mov     bluebuffer,eax

                mov     edi,bluebuffer
                mov     eax,0
                mov     ecx,2*65536/4
                rep     stosd

                ; allocate the msx vram
                mov     eax,vramsize
                call    _getmem
                jc      no_memory
                mov     msxvram,eax

                ; allocate the msx vram swap
                mov     eax,vramsize
                call    _getmem
                jc      no_memory
                mov     msxvram_swap,eax

                ; allocate the saveline (msx2+)
                mov     eax,512*3+32
                call    _getmem
                jc      no_memory
                add     eax,32
                mov     saveline,eax

                ; clear msx vram
                mov     edi,msxvram
                mov     ecx,vramsize
                shr     ecx,2
                mov     eax,0 
                rep     stosd

                ; allocate 16kb to cartridge sram
                mov     eax,16384
                call    _getmem
                jc      no_memory
                mov     cart_sram,eax

                ; allocate 64kb*4 to code table
                ;mov     eax,65536*4
                ;call    _getmem
                ;jc      no_memory
                ;mov     codetable,eax

                ; fill code table with fetch functions
                ;mov     edi,codetable
                ;mov     eax,offset fetchcallback
                ;mov     ecx,65536
                ;rep     stosd

                ; allocate 1Mb to compiler buffer
                ;mov     eax,1048576
                ;call    _getmem
                ;jc      no_memory
                ;mov     compbuffer,eax
                ;mov     comp_position,eax

                ; allocate 8kb to SCC ram
                mov     eax,8192
                call    _getmem
                jc      no_memory
                mov     sccram,eax

                ; fill SCC ram with 0FFh
                mov     edi,sccram
                mov     eax,0FFFFFFFFh
                mov     ecx,8192/4
                rep     stosd

                ; allocate memory to msx ram
                mov     eax,mappersize
                call    _getmem
                jc      no_memory
                mov     msxram,eax
                mov     edi,ramslot
                irp     i,<3,2,1,0>
                mov     dword ptr [edi+i*16],eax
                add     eax,2000h
                mov     dword ptr [edi+i*16+8],eax
                add     eax,2000h
                endm

                ; select RAM slot as pure RAM
                ; and cartridge 2 as pure ROM
                mov     eax,0
                mov     ebx,1
                mov     esi,cart2slot
                irp     i,<0,1,2,3,4,5,6,7>
                mov     dword ptr [edi+i*8+4],eax
                mov     dword ptr [esi+i*8+4],ebx
                endm

                ; clear msx ram
                mov     ecx,mappersize
                shr     ecx,2
                mov     edi,msxram
                mov     eax,0
                rep     stosd

                ; alloc 64kb to sound buffer
                mov     eax,64*1024
                call     _getmem
                jc      no_memory
                mov     soundbuffer,eax

                ; alloc 128kb to time buffer
                mov     eax,128*1024
                call     _getmem
                jc      no_memory
                mov     timebuffer,eax

                ; alloc 16kb to noise table
                mov     eax,16384
                call     _getmem
                jc      no_memory
                mov     noise_uncompressed,eax

                call    uncompress_noise

                ; alloc 16kb to alf table
                mov     eax,16384
                call     _getmem
                jc      no_memory
                mov     alf_uncompressed,eax

                call    uncompress_alf

                ; alloc 3840*2 to temp_screen and inter_screen
                mov     eax,3840*2
                call     _getmem
                jc      no_memory
                mov     temp_screen,eax

                ; alloc always 512kb to cart1                
                mov     eax,cart1size 
                call     _getmem
                jc      no_memory
                mov     cart1,eax

                ; print cartridge name
                cmp     byte ptr [offset cartridge1],0
                jne     main_has_cart1

                call    enable_megaram
                jmp     main_nocart1

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

                ; read cartridge 1 from disk
                mov     edx,offset cartridge1
                mov     eax,cart1
                mov     ebp,offset slot1
                mov     ecx,rommappera
                mov     rommapper,ecx
                call    read_rom
                mov     ecx,rommapper
                mov     rommappera,ecx
                jc      error_in_rom                

                mov     esi,cart1
                call    check_bad_dump
                jnz     error_bad_dump

                ; load sram from disk if needed
                call    load_sram

main_nocart1:

                ; check for cart B
                cmp     byte ptr [offset cartridge2],0
                je      main_nocart2
                
                ; print cartridge B name
                mov     eax,offset msg24
                call    printmsg
                mov     al,'"'
                call    printasc
                mov     eax,offset cartridge2
                call    printnul
                mov     al,'"'
                call    printasc
                call    crlf

                ; alloc always 256kb to cart2
                mov     eax,256*1024
                call     _getmem
                jc      no_memory
                mov     cart2,eax

                ; read cartridge 2 from disk
                mov     edx,offset cartridge2
                mov     eax,cart2
                mov     ebp,cart2slot
                mov     ecx,rommapperb
                mov     rommapper,ecx
                call    read_rom
                jc      error_in_rom                

main_nocart2:

                ; allocate 256kb to blit buffer
                mov     eax,256*1024
                call    _getmem
                jc      no_memory
                mov     blitbuffer,eax

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

                ; allocate 8kb to file name list
                mov     eax,8192
                call    _getmem
                jc      no_memory
                mov     filenamelist,eax

                ; check for symbolic debugging
                call    install_symdeb

                ; check for disk drive emulation
                cmp     diskenabled,0
                je      _main_nodrive

                ; allocate 720kb to disk image
                mov     eax,4*720*1024
                call    _getmem
                jc      no_memory
                mov     diskimage,eax

                ; clear disk image
                mov     edi,diskimage
                mov     ecx,4*(720/4)*1024
                mov     eax,0
                rep     stosd

                ; print drive A name
                cmp     diskenabled,2
                je      main_dont_print_disk_image_name
                mov     eax,offset msg25
                call    printmsg
                mov     al,'"'
                call    printasc
                mov     eax,offset drivea_name
                call    printnul
                mov     al,'"'
                call    printasc
                call    crlf
main_dont_print_disk_image_name:

                ; load disk image from disk
                call    load_disk_image
                jc      invalid_disk_image

                call    read_disk_rom

                ;; fix the error present in all interfaces
                ;; based on the CDX-2
                ;; (this means all brazilian interfaces)
                ;mov     edi,cart2slot
                ;mov     eax,dword ptr [edi+16]
                ;mov     byte ptr [eax+024B0h],0C2h

_main_nodrive:

                ; check for korean support
                cmp     korean,1
                jne     _main_nokorean

                ; allocate 16kb for disk.rom
                mov     eax,16*1024
                call    _getmem
                jc      no_memory
                mov     msxhan,eax

                ; load MSXHAN.ROM from disk
                mov     edx,offset msxhan_name
                call    open_file
                jc      msxhan_error
                call    read_size_file
                cmp     eax,04000h
                jne     msxhan_error
                mov     edx,transf_buffer
                mov     ecx,16*1024
                call    read_file
                call    close_file
                mov     esi,transf_buffer
                mov     edi,msxhan
                mov     ecx,16384/4
                rep     movsd

                mov     eax,msxhan
                mov     dword ptr [offset slot0+16*2],eax
                add     eax,2000h
                mov     dword ptr [offset slot0+16*2+8],eax

_main_nokorean:
                ; check for tape emulation
                cmp     byte ptr [offset tape_name],0
                je      _main_notape
                
                ; print tape name
                mov     eax,offset msg28
                call    printmsg
                mov     al,'"'
                call    printasc
                mov     eax,offset tape_name
                call    printnul
                mov     al,'"'
                call    printasc
                call    crlf

                ; read tape image from disk
                call    read_tape

                ; patch for TAPION
                mov     eax,dword ptr [offset slot0]
                mov     byte ptr [eax+0E1h],0edh
                mov     byte ptr [eax+0E2h],0ffh

                ; patch for TAPIN
                mov     byte ptr [eax+0E4h],0edh
                mov     byte ptr [eax+0E5h],0ffh

                ; patch for TAPIOF
                mov     byte ptr [eax+0E7h],0edh
                mov     byte ptr [eax+0E8h],0ffh

                ; patch for TAPOON
                mov     byte ptr [eax+0EAh],0edh
                mov     byte ptr [eax+0EBh],0ffh

                ; patch for TAPOUT
                mov     byte ptr [eax+0EDh],0edh
                mov     byte ptr [eax+0EEh],0ffh

                ; patch for TAPOOF
                mov     byte ptr [eax+0F0h],0edh
                mov     byte ptr [eax+0F1h],0ffh

_main_notape:

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

                cmp     fmenabled,1
                jne     _main_nofm

                call    init_adlib

_main_nofm:

_main_nosound:

                cmp     novesa,1
                je      _main_novesa

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
                jb      vesa2_not_found

_main_novesa:
                call    check_video_mode

                ; enter debug mode
                
                ; don't ask 
                ;db 365 dup (090h)
                
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
                mov     firsttime,0
                call    debug

main_getout:

                cmp     mmxfound,1
                jne     main_nommx
                emms
main_nommx:

                call    settextmode

                ; print end message
                mov     eax,offset msg22
                call    printmsg

                cmp     diskenabled,1
                jne     main_exit_noflushdisk
                call    flush_dsk
main_exit_noflushdisk:

                cmp     byte ptr [offset tape_name],0
                je      main_exit_notape
                call    flush_tape

main_exit_notape:

                call    save_sram
                call    adjust_clock

                cmp     fmenabled,1
                jne     main_exit_nofm
                call    reset_adlib

main_exit_nofm:

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

error_bad_dump:
                mov     eax,offset msg37
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

vesa2_not_found:
                mov     eax,offset msg38
                call    printmsg
                jmp     _main_novesa

vesa2_512x384_not_found:
                mov     eax,offset msg21
                call    printmsg
                ret

vesa2_640x480_not_found:
                mov     eax,offset msg42
                call    printmsg
                ret

vesa2_512x384_15_not_found:
                mov     eax,offset msg36
                call    printmsg
                ret

msx_rom_error:
                mov     eax,offset msg26
                call    printmsg
                jmp     _exit

msx2_rom_error:
                mov     eax,offset msg40
                call    printmsg
                jmp     _exit

msx2ext_rom_error:
                mov     eax,offset msg41
                call    printmsg
                jmp     _exit

disk_rom_error:
                mov     eax,offset msg27
                call    printmsg
                jmp     _exit

dos2_rom_error:
                mov     eax,offset msg39
                call    printmsg
                jmp     _exit

tape_not_found:
                mov     eax,offset msg29
                call    printmsg
                ret

tape_too_large:
                mov     eax,offset msg30
                call    printmsg
                jmp     _exit

msxhan_error:
                mov     eax,offset msg31
                call    printmsg
                jmp     _exit

invalid_disk_image:
                mov     eax,offset msg35
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
                ;mov     esi,argpos
                ;add     esi,_pspa
                ;sub     esi,_code32a
                mov     esi,cmdline
                ;movzx   ecx,byte ptr [esi-1]
                movzx   ecx,byte ptr [esi]
                inc     esi
                ;
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
                jmp     parse_command_line_out_exit
                
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
parse_command_line_out_exit:
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

callback_scc:
                mov     sccenabled,1
                ret

callback_psgg:  
                mov     psggraph,1
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
                call    getchar
                mov     eax,offset help_message4
                call    printmsg
                jmp     _exit

callback_diska:
                mov     secondarg,1
                mov     eax,offset callback_diska_second
                mov     second_callback,eax
                ret

callback_diska_second:
                mov     edi,offset drivea_name
                mov     esi,offset emptyspace
                mov     ecx,128/4
                rep     movsd
                mov     diskenabled,1
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

callback_normal:
                mov     emulatemode,0
                mov     oldmode,0
                ret

callback_fast:
                mov     emulatemode,1
                mov     oldmode,1
                ret

callback_turbo:
                mov     emulatemode,2
                mov     oldmode,2
                ret

callback_noled:
                mov     noled,1
                ret

callback_res:
                mov     secondarg,1
                mov     eax,offset callback_res_second
                mov     second_callback,eax
                ret

callback_res_second:
                mov     eax,0
                mov     ebx,eax
                mov     esi,offset emptyspace

callback_res_loop:
                mov     bl,[esi]
                cmp     bl,0
                je      callback_res_set

                lea     eax,[eax+eax*4]
                lea     eax,[ebx+eax*2]
                sub     eax,'0'
                inc     esi
                jmp     callback_res_loop

callback_res_set:
                mov     bl,al
                cmp     bl,1
                je      callback_res_256x200
                cmp     bl,2
                je      callback_res_512x384
                cmp     bl,3
                je      callback_res_256x192
                cmp     bl,6
                je      callback_res_512x384_parrot
                cmp     bl,7
                je      callback_res_320x200xmsx2
                cmp     bl,8
                je      callback_res_512x384xmsx2
                cmp     bl,9
                je      callback_res_512x384xmsx2_scanlines
                cmp     bl,11
                je      callback_res_640x480xmsx2_scanlines
                cmp     bl,12
                je      callback_res_512x384x16_scanlines
                mov     videomode,0
                ret

callback_res_256x200:
                mov     videomode,1
                ret

callback_res_512x384:
                mov     videomode,2
                ret

callback_res_256x192:
                mov     videomode,3
                ret

callback_res_512x384_parrot:
                mov     videomode,6
                ret

callback_res_320x200xmsx2:
                mov     videomode,7
                ret

callback_res_512x384xmsx2:
                mov     videomode,8
                ret

callback_res_512x384xmsx2_scanlines:
                mov     videomode,9
                ret

callback_res_640x480xmsx2_scanlines:
                mov     videomode,11
                ret

callback_res_512x384x16_scanlines:
                mov     videomode,12
                ret

callback_disklow:
                mov     portenabled,1
                mov     forcedisk,1
                ret

callback_diskhigh:
                mov     portenabled,0
                mov     forcedisk,1
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

callback_tape:
                mov     secondarg,1
                mov     eax,offset callback_tape_second
                mov     second_callback,eax
                ret

callback_tape_second:
                mov     edi,offset tape_name
                mov     esi,offset emptyspace
                mov     ecx,128/4
                rep     movsd
                ret

callback_nopent:
                mov     nopentium,1
                ret

callback_ramslot:
                mov     secondarg,1
                mov     eax,offset callback_ramslot_second
                mov     second_callback,eax
                ret

callback_ramslot_second:
                cmp     byte ptr [offset emptyspace],'2'
                je      callback_ramslot_second_2
                cmp     byte ptr [offset emptyspace],'3'
                je      callback_ramslot_second_3
                ret

callback_ramslot_second_2:
                mov     eax,offset slot2
                mov     ramslot,eax
                mov     eax,offset slot3
                mov     cart2slot,eax
                mov     allram,0AAh
                ret

callback_ramslot_second_3:
                mov     eax,offset slot3
                mov     ramslot,eax
                mov     eax,offset slot2
                mov     cart2slot,eax
                mov     allram,0FFh
                ret

callback_joysens:
                mov     secondarg,1
                mov     eax,offset callback_joysens_second
                mov     second_callback,eax
                ret

callback_joysens_second:
                mov     al,byte ptr [offset emptyspace]
                sub     al,'0'
                mov     joysens,al
                call    calibrate_joystick
                ret

callback_korean:
                mov     korean,1
                ret

callback_green:
                mov     greenflag,1
                mov     eax,offset palette_green
                mov     pal_normal,eax
                mov     eax,offset filtered_palette_green
                mov     pal_filtered,eax
                mov     eax,offset gui_palette_green
                mov     pal_gui,eax
                ret

callback_roma:
                mov     guess,0
                mov     secondarg,1
                mov     eax,offset callback_roma_second
                mov     second_callback,eax
                ret

callback_roma_second:
                mov     al,byte ptr [offset emptyspace]
                sub     al,'0'

                cmp     al,9
                ja      _ret

                add     al,2
                and     eax,0FFh
                mov     rommappera,eax
                ret

callback_romb:
                mov     guess,0
                mov     secondarg,1
                mov     eax,offset callback_romb_second
                mov     second_callback,eax
                ret

callback_romb_second:
                mov     al,byte ptr [offset emptyspace]
                sub     al,'0'
                
                cmp     al,1
                je      _ret
                cmp     al,9
                ja      _ret

                add     al,2
                and     eax,0FFh
                mov     rommapperb,eax
                ret

callback_speaker:
                mov     nosound,1
                mov     speaker,1
                ret

callback_allspr:
                mov     all_sprites,1
                ret

callback_fakejoy:
                mov     fakejoy,1
                ret

callback_autofire:
                mov     autofire,1
                ret

callback_autospeed:
                mov     secondarg,1
                mov     eax,offset callback_autospeed_second
                mov     second_callback,eax
                ret

callback_autospeed_second:
                mov     al,byte ptr [offset emptyspace]
                sub     al,'0'
                inc     al
                and     eax,0FFh
                mov     autospeed,eax
                ret

callback_autorun:
                mov     autorun,7+16
                ret

callback_fmpac:
                mov     fmenabled,1
                ret

callback_nosprcol:
                mov     no_collision,1
                ret

callback_mount:
                mov     secondarg,1
                mov     eax,offset callback_mount_second
                mov     second_callback,eax
                ret

callback_mount_second:
                mov     edi,offset mountdir_name
                mov     esi,offset emptyspace
                mov     ecx,128/4
                rep     movsd
                mov     diskenabled,2
                ret

callback_megaram:
                mov     secondarg,1
                mov     eax,offset callback_megaram_second
                mov     second_callback,eax
                ret

callback_megaram_second:
                mov     al,byte ptr [offset emptyspace]
                sub     al,'0'
                and     eax,0FFh
                mov     ecx,dword ptr [offset cart1table+eax*4]
                mov     cart1size,ecx
                movzx   ecx,byte ptr [offset cart1mask+eax]
                mov     megamask,ecx
                ret

callback_mapper:
                mov     secondarg,1
                mov     eax,offset callback_mapper_second
                mov     second_callback,eax
                ret

callback_mapper_second:
                mov     al,byte ptr [offset emptyspace]
                sub     al,'0'
                and     eax,0FFh
                mov     ecx,dword ptr [offset mapper_table+eax*4]
                mov     mappersize,ecx
                movzx   ecx,byte ptr [offset mapper_mask+eax]
                mov     mappermask,ecx
                ret

callback_speaq:
                mov     secondarg,1
                mov     eax,offset callback_speaq_second
                mov     second_callback,eax
                ret

callback_speaq_second:
                mov     al,byte ptr [offset emptyspace]
                sub     al,'0'
                jnz     callback_speaq_noadjust
                inc     al
callback_speaq_noadjust:
                and     eax,0FFh
                mov     speaq,eax
                ret

callback_sr:
                mov     secondarg,1
                mov     eax,offset callback_sr_second
                mov     second_callback,eax
                ret

callback_sr_second:
                mov     eax,0
                mov     ebx,eax
                mov     esi,offset emptyspace

callback_sr_loop:
                mov     bl,[esi]
                cmp     bl,0
                je      callback_sr_set

                lea     eax,[eax+eax*4]
                lea     eax,[ebx+eax*2]
                sub     eax,'0'
                inc     esi
                jmp     callback_sr_loop

callback_sr_set:
                cmp     eax,0
                je      _ret
                mov     _samplerate,eax
                ret

callback_ifreq:
                mov     secondarg,1
                mov     eax,offset callback_ifreq_second
                mov     second_callback,eax
                ret

callback_ifreq_second:
                mov     eax,0
                mov     ebx,eax
                mov     esi,offset emptyspace

callback_ifreq_loop:
                mov     bl,[esi]
                cmp     bl,0
                je      callback_ifreq_set

                lea     eax,[eax+eax*4]
                lea     eax,[ebx+eax*2]
                sub     eax,'0'
                inc     esi
                jmp     callback_ifreq_loop

callback_ifreq_set:
                cmp     eax,0
                je      _ret
                mov     _verticalrate,eax
                mov     ebx,eax
                mov     eax,036912Eh
                mov     edx,0
                div     ebx
                mov     TC,eax
                mov     ebx,5
                mov     eax,_verticalrate
                mov     edx,0
                div     ebx
                mov     spin_irqs,eax
                ret

callback_snespad:
                mov     snespad,1
                mov     joyenable,1
                ret

callback_vdptiming:
                mov     eax,offset inemul98_timing
                mov     dword ptr [offset inportxx+098h*4],eax
                ret

callback_dos2:
                mov     dos2enabled,1
                ret

callback_prn:
                mov     secondarg,1
                mov     eax,offset callback_prn_second
                mov     second_callback,eax
                ret

callback_prn_second:
                mov     edi,offset prn_name
                mov     esi,offset emptyspace
                mov     ecx,128/4
                rep     movsd
                mov     symbolic_debugger,1
                ret

callback_msx2:
                mov     msxmodel,1
                ret

callback_vdplog:
                mov     vdplog,1
                ret

callback_logout:
                mov     logout,1
                ret

callback_truevsync:
                mov     truevsync,1
                ret

callback_joynet:
                mov     joynet,1
                ret

callback_msx2p:
                mov     msxmodel,2
                mov     model_mainrom,offset msx2p_rom_name
                mov     model_subrom,offset msx2pext_rom_name
                ret

callback_ciel:
                mov     clocks_line,424
                mov     TC,59659*2
                ret

callback_advram:
                mov     advram,1
                mov     imagetype,0
                ret

callback_nomegaram:
                mov     eax,offset _ret
                mov     dword ptr [offset inportxx+08Eh*4],eax
                
                mov     eax,offset _ret
                mov     dword ptr [offset outportxx+08Eh*4],eax

                ret

callback_trtimer:
                mov     eax,offset inemulE6
                mov     dword ptr [offset inportxx+0E6h*4],eax
                
                mov     eax,offset inemulE7
                mov     dword ptr [offset inportxx+0E7h*4],eax
                
                mov     eax,offset outemulE6
                mov     dword ptr [offset outportxx+0E6h*4],eax
                
                mov     eax,offset outemulE7
                mov     dword ptr [offset outportxx+0E7h*4],eax
                
                ret

callback_novdptiming:
                mov     vdptiming,0       
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

                ; check for 8kb roms
                mov     ecx,filesize
                cmp     ecx,8192
                je      read_rom_8kb
                
                ; size must be multiple of 4000h
                and     ecx,03FFFh
                jnz     error_in_rom

                ; read first 16kb
                mov     edx,transf_buffer
                mov     ecx,04000h
                call    read_file

                ; copy first 16kb to correct position
                mov     esi,transf_buffer
                mov     edi,eax
                mov     ecx,04000h/4
                rep     movsd

                ; check ROM header
                cmp     word ptr [eax],04241h
                jne     error_in_rom

                ; check file size
                cmp     filesize,04000h
                jne     read_rom_not_16kb

                ; look into the header to discover correct page
                mov     dx,[eax+2]
                and     edx,0C000h
                shr     edx,13

                ; check for a BASIC cartridge
                or      edx,edx
                jz      read_rom_basic

read_rom_place_16kb:
                ; place rom in correct place
                mov     [ebp+edx*8],eax
                add     eax,2000h
                mov     [ebp+edx*8+8],eax

                call    enable_rom

                call    close_file
                or      eax,eax
                ret
                                            
read_rom_8kb:
                ; read the rom
                mov     edx,transf_buffer
                mov     ecx,02000h
                call    read_file

                ; copy first 16kb to correct position
                mov     esi,transf_buffer
                mov     edi,eax
                mov     ecx,02000h/4
                rep     movsd

                ; mirror the ROM in all pages
                irp     i,<0,1,2,3,4,5,6,7>
                mov     [ebp+i*8],eax
                endm
                
                call    enable_rom    
                
                call    close_file
                or      eax,eax
                ret


read_rom_basic:
                ; check for BASIC header
                cmp     word ptr [eax+8],0    
                je      read_rom_0000

                ; BASIC header found
                mov     edx,4
                jmp     read_rom_place_16kb

read_rom_0000:
                ; mirror the ROM in all pages
                irp     i,<0,1,2,3>
                mov     [ebp+i*16],eax
                endm
                add     eax,2000h
                irp     i,<0,1,2,3>
                mov     [ebp+i*16+8],eax
                endm
                
                call    enable_rom    
                
                call    close_file
                or      eax,eax
                ret

read_rom_not_16kb:
                cmp     filesize,08000h
                jne     read_rom_not_32kb

                ; ROM has 32kb
                ; must read the other 16kb block
                mov     edx,transf_buffer
                mov     ecx,04000h
                call    read_file

                ; place second block in correct location
                mov     esi,transf_buffer
                lea     edi,[eax+04000h]
                mov     ecx,04000h/4
                rep     movsd

                ; place ROM in slot
                ; 32kb ROMs always start at 4000h
                irp     i,<0,1,2,3>
                mov     dword ptr [ebp+2*8+i*8],eax
                add     eax,2000h
                endm
                
                call    enable_rom    
                
                call    close_file
                or      eax,eax
                ret

read_rom_not_32kb:

                ; ROM is a MegaROM
                ; start reading missing blocks
                lea     edi,[eax+4000h]
                mov     ebx,filesize
                shr     ebx,14
                dec     ebx

                ; check for 48kb roms
                cmp     filesize,48*1024
                je      read_rom_megarom_skip_megamask
                
                ; fill the megarom mask
                mov     edx,filesize
                shr     edx,13
                dec     edx
                mov     megamask,edx

read_rom_megarom_skip_megamask:
                call    guess_megarom_type

read_rom_megarom_loop:
                ; read a 16kb chunk
                mov     edx,transf_buffer
                mov     ecx,4000h
                call    read_file

                ; place 16kb chunk in buffer
                mov     esi,transf_buffer
                mov     ecx,04000h/4
                rep     movsd

                dec     ebx
                jnz     read_rom_megarom_loop

                ; check for initial position of banks
                cmp     rommapper,7
                je      read_rom_megarom_0101

                ; initial 0-1-2-3

                ; place ROM in slot
                mov     ecx,eax
                irp     i,<0,1,2,3>
                mov     dword ptr [ebp+2*8+i*8],ecx
                add     ecx,2000h
                endm
                
                ; change ROM status to MegaROM
                mov     ecx,rommapper
                irp     i,<0,1,2,3>
                mov     dword ptr [ebp+2*8+i*8+4],ecx
                mov     dword ptr [offset megablock+2*4+i*4],i
                endm

                jmp     read_rom_megarom_finish

read_rom_megarom_0101:
                
                ; initial 0-1-0-1

                ; place ROM in slot
                mov     ecx,eax
                mov     dword ptr [ebp+2*8+0*8],ecx
                add     ecx,2000h
                mov     dword ptr [ebp+2*8+1*8],ecx
                sub     ecx,2000h
                mov     dword ptr [ebp+2*8+2*8],ecx
                add     ecx,2000h
                mov     dword ptr [ebp+2*8+3*8],ecx
                
                ; change ROM status to MegaROM
                mov     ecx,rommapper
                irp     i,<0,1,0,1>
                mov     dword ptr [ebp+2*8+i*8+4],ecx
                mov     dword ptr [offset megablock+2*4+i*4],i
                endm

read_rom_megarom_finish:

                ; fill the megadump area
                sub     ebp,offset slot0
                shr     ebp,6
                mov     dword ptr [offset megadump+ebp*4],eax

                ; fill the scc area with parts of rom
                mov     esi,transf_buffer
                add     esi,2000h
                mov     edi,sccram
                mov     ecx,1800h/4
                rep     movsd

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
                
                ; fill the megadump area
                mov     eax,cart1
                mov     dword ptr [offset megadump+4],eax
                
                mov     megaram,1
                ret


; enable_rom ---------------------------------------------------------
; enable the ROM

enable_rom:                
                mov     eax,1
                mov     dword ptr [ebp+16+4],eax
                mov     dword ptr [ebp+16+4+8],eax
                mov     dword ptr [ebp+16+4+16],eax
                mov     dword ptr [ebp+16+4+24],eax
                ret

; alloc_tapeimage ----------------------------------------------------
; read tape image from disk
; enter: eax = size of the tape

alloc_tapeimage:
                ; alloc memory to tape image
                push    eax
                add     eax,4
                call    _getmem
                jc      alloc_tapeimage_no_memory
                mov     tapeimage,eax

                ; fill tape image with zeros
                pop     ecx
                shr     ecx,2
                mov     edi,tapeimage
                mov     eax,01A1A1A1Ah
                rep     stosd
                ret

alloc_tapeimage_no_memory:
                pop     eax
                jmp     no_memory

; read_tape ----------------------------------------------------------
; read tape image from disk

read_tape:
                ; open tape file
                mov     edx,offset tape_name
                call    open_file
                jc      tape_not_found

                ; alloc memory for the entire tape
                call    read_size_file
                push    eax
                call    alloc_tapeimage
                pop     eax

                mov     ebp,tapeimage                                
read_tape_loop:
                ; at this point
                ; ebp = pointer to current buffer
                ; eax = remaning bytes to read

                mov     edx,eax
                cmp     eax,32768
                jbe     read_tape_last_iteration
                mov     edx,32768
read_tape_last_iteration:

                ; at this point
                ; edx = amount of bytes to read in this iteration

                push    eax
                push    ebp
                push    edx

                ; read a 32kb max block of tape
                mov     ecx,eax
                mov     edx,transf_buffer
                call    read_file

                ; place this block in correct place
                mov     edi,ebp
                mov     esi,transf_buffer
                mov     ecx,eax
                shr     ecx,2
                rep     movsd

                pop     edx
                pop     ebp
                pop     eax

                add     ebp,edx
                sub     eax,edx
                jz      read_tape_exit
                jc      read_tape_exit
                jmp     read_tape_loop
read_tape_exit:
                call    close_file
                ret

; flush_tape ---------------------------------------------------------
; flush tape image to disk

flush_tape:
                ret ; function disabled
                ;;
                mov     edx,offset tape_name
                call    create_file

                mov     esi,tapeimage
                mov     edi,transf_buffer
                mov     ecx,32768/4
                rep     movsd

                mov     edx,transf_buffer
                mov     ecx,32768
                call    write_file
                
                mov     esi,tapeimage
                add     esi,32768
                mov     edi,transf_buffer
                mov     ecx,32768/4
                rep     movsd

                mov     edx,transf_buffer
                mov     ecx,32768
                call    write_file

                call    close_file
                ret

; guess_megarom_type -------------------------------------------------
; try to guess the megarom type, based on the CRC of the first 8kb

guess_megarom_type:
                cmp     guess,1
                jne     _ret
                
                pushad

                mov     ecx,8192/4
                mov     eax,0
                mov     esi,transf_buffer

guess_loop:
                xor     eax,[esi]
                add     esi,4
                dec     ecx
                jnz     guess_loop

                mov     esi,offset guess_table

guess_try_again:
                cmp     eax,dword ptr [esi]
                je      guess_found
                add     esi,12
                cmp     dword ptr [esi],0
                jne     guess_try_again

                mov     eax,offset msg34
                call    printmsg

                popad
                ret

guess_found:
                mov     eax,dword ptr [esi+4]
                mov     rommapper,eax
                cmp     firsttime,1
                jne     guess_ret

                mov     eax,offset msg32
                call    printmsg
                mov     eax,dword ptr [esi+8]
                call    printmsg
                call    crlf
                mov     eax,offset msg33
                call    printmsg
                mov     eax,dword ptr [esi+4]
                mov     rommapper,eax
                sub     eax,2
                call    printhex2
                call    crlf

guess_ret:
                popad
                ret

; decode_cartridge ---------------------------------------------------
; decode the cartridge name, retrieving a name for the save state

decode_cartridge:
                mov     esi,offset cartridge1
                mov     edi,offset sramname

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
                mov     edi,offset sramname
                jmp     decode_cartridge_loop

decode_cartridge_append:
                mov     byte ptr [edi],'.'
                mov     byte ptr [edi+1],'S'
                mov     byte ptr [edi+2],'R'
                mov     byte ptr [edi+3],'M'
                mov     byte ptr [edi+4],0
                ret

; load_sram ----------------------------------------------------------
; load sram from disk if needed

load_sram:
                ; megarom types with sram are 6 and 7 and 8
                cmp     rommapper,6+2
                jb      _ret

                ; decode cartridge name (.srm)
                call    decode_cartridge

                ; check if file exists
                mov     edx,offset sramname
                call    open_file
                jc      clear_sram

                ; read from disk
                mov     ecx,16384
                mov     edx,transf_buffer
                call    read_file

                ; place in correct place
                mov     edi,cart_sram
                mov     esi,transf_buffer
                mov     ecx,16384/4
                rep     movsd

                ; close the file 
                call    close_file

                ; check for sram initialization
                cmp     rommapper,8
                jne     _ret

                mov     esi,cart_sram
                mov     word ptr [esi+01FFEh],0
                ret

clear_sram:
                mov     edi,cart_sram
                mov     ecx,16384/4
                mov     eax,0
                rep     stosd
                ret

                ret

; save_sram ----------------------------------------------------------
; save sram to disk

save_sram:
                ; megarom types with sram are 6 and 7 and 8
                cmp     rommappera,6+2
                jb      _ret

                ; create file
                mov     edx,offset sramname
                call    create_file

                ; place in correct place
                mov     esi,cart_sram
                mov     edi,transf_buffer
                mov     ecx,16384/4
                rep     movsd

                ; write to disk
                mov     ecx,16384
                mov     edx,transf_buffer
                call    write_file

                ; close the file and exit
                call    close_file
                ret

; load_disk_image ----------------------------------------------------
; load disk image from disk or mount a disk from a directory
; behaviour is defined by the diskenabled variable
; diskenabled = 1   => read .DSK file
; diskenabled = 2   => mount directory

load_disk_image:
                cmp     diskenabled,2
                je      mount_disk_image

                ; read disk image from file
                mov     edx,offset drivea_name
                call    open_file
                jc      _ret

                ; check file size
                call    read_size_file
                ;cmp     eax,720*1024
                ;ja      load_disk_image_error
                mov     ebx,eax
                shr     ebx,10+2
                mov     disksize,ebx

                ; read the file from disk
                mov     ebx,disksize
                mov     edi,diskimage
load_disk_image_loop:
                mov     ecx,4096 
                mov     edx,transf_buffer
                push    ebx
                call    read_file
                pop     ebx
                mov     esi,transf_buffer
                mov     ecx,4096/4 
                rep     movsd
                dec     ebx
                jnz     load_disk_image_loop

                call    close_file

                ; adjust shiftfactor as (number of faces - 1)
                ; discover number of faces by looking into
                ; the disk ID number

                mov     eax,diskimage
                mov     al,[eax+15h]
                and     al,1
                mov     shiftfactor,al

                clc
                ret

load_disk_image_error:
                stc
                ret

; check_bad_dump -----------------------------------------------------
; check if the game is a bad dump
; by searching for duplicates 

check_bad_dump:
                ;mov     esi,cart1
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
                ret
                ;;;

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

; --------------------------------------------------------------------
                
read_disk_rom:
                ;cmp     msxmodel,1
                ;jae     read_disk_rom_msx2

                ; allocate 16kb for disk.rom
                mov     eax,16*1024
                call    _getmem
                jc      no_memory
                mov     diskrom,eax

                ; read disk.rom from disk
                mov     edx,model_diskrom ;offset disk_rom_name
                call    open_file
                jc      disk_rom_error
                call    read_size_file
                cmp     eax,04000h
                jne     disk_rom_error
                mov     edx,transf_buffer
                mov     ecx,16*1024
                call    read_file
                call    close_file
                mov     esi,transf_buffer
                mov     edi,diskrom
                mov     ecx,16384/4
                rep     movsd

                mov     eax,diskrom
                mov     edi,cart2slot
                mov     dword ptr [edi+16],eax
                add     eax,2000h
                mov     dword ptr [edi+16+8],eax

                cmp     portenabled,1
                je      _main_port

                ; patch for PHYDIO
                mov     edi,cart2slot
                mov     eax,dword ptr [edi+16]
                mov     byte ptr [eax+010h],0edh
                mov     byte ptr [eax+011h],0ffh

                ; patch for DSKCHG
                mov     byte ptr [eax+013h],0edh
                mov     byte ptr [eax+014h],0ffh

                ; patch for GETDPB
                mov     byte ptr [eax+016h],0edh
                mov     byte ptr [eax+017h],0ffh

_main_port:
                ; check for MSXDOS-2 emulation
                cmp     dos2enabled,1
                jne     _ret

                ; read dos2.rom from disk
                mov     edx,offset dos2_rom_name
                call    open_file
                jc      dos2_rom_error

                call    read_size_file
                cmp     eax,10000h
                jne     dos2_rom_error

                irp     i,<0,1,2,3>
                mov     edx,transf_buffer
                mov     ecx,16*1024
                call    read_file
                mov     esi,transf_buffer
                mov     edi,cart1
                add     edi,16384*i
                mov     ecx,16384/4
                rep     movsd
                endm

                call    close_file

                ; place ROM in slot
                mov     ecx,cart1
                irp     i,<0,1,2,3>
                mov     dword ptr [offset slot1+2*8+i*8],ecx
                mov     dword ptr [offset slot1+2*8+i*8+4],2+1
                mov     dword ptr [offset megablock+2*4+i*4],i
                add     ecx,2000h
                endm

                ; fill the megadump
                mov     ecx,cart1
                mov     ebp,cart2slot
                sub     ebp,offset slot0
                shr     ebp,6
                mov     dword ptr [offset megadump+ebp*4],ecx

                ; patch the DOS2.ROM to make it run on msx-1 machines
                mov     eax,cart1
                add     eax,07DEh
                mov     byte ptr [eax],0
                
                ret

; --------------------------------------------------------------------

read_msx_rom:
                cmp     msxmodel,1
                jae     read_msx_rom_msx2

                ; allocate 32kb to msx rom
                mov     eax,32768
                call    _getmem
                jc      no_memory
                mov     msxrom,eax
                irp     i,<0,1,2,3>
                mov     dword ptr [offset slot0+i*8],eax
                mov     dword ptr [offset mem+i*4],eax
                add     eax,2000h
                endm

                ; read msx rom 1 from disk
                mov     edx,offset rom_name
                call    open_file
                jc      msx_rom_error
                call    read_size_file
                cmp     eax,08000h
                jne     msx_rom_error
                mov     edx,transf_buffer
                mov     ecx,32768
                call    read_file
                call    close_file
                mov     edi,msxrom
                mov     esi,transf_buffer
                mov     ecx,32768/4
                rep     movsd

                ret

read_msx_rom_msx2:
                ; allocate 32kb to msx2 rom
                mov     eax,32768
                call    _getmem
                jc      no_memory
                mov     msxrom,eax
                irp     i,<0,1,2,3>
                mov     dword ptr [offset slot0+i*8],eax
                mov     dword ptr [offset mem+i*4],eax
                add     eax,2000h
                endm

                ; read msx2 rom from disk
                mov     edx,model_mainrom ;offset msx2_rom_name
                call    open_file
                jc      msx2_rom_error
                call    read_size_file
                cmp     eax,08000h
                jne     msx2_rom_error
                mov     edx,transf_buffer
                mov     ecx,32768
                call    read_file
                call    close_file
                mov     edi,msxrom
                mov     esi,transf_buffer
                mov     ecx,32768/4
                rep     movsd

                ; allocate 8kb to idle extended rom
                mov     eax,8192
                call    _getmem
                jc      no_memory
                mov     extendedrom,eax
                mov     edi,eax
                mov     eax,0FFFFFFFFh
                mov     ecx,8192/4
                rep     stosd

                ; fill the extended slot with idle rom
                mov     ecx,offset extended_slot_0
                mov     edx,extendedrom
                mov     ebx,idlerom
                rept    4
                irp     i,<0,1,2,3,4,5,6>
                mov     dword ptr [ecx+i*8],ebx
                endm
                mov     dword ptr [ecx+7*8],edx
                add     ecx,8*8
                endm

                ; place the msx.rom in the slot 0.0
                mov     eax,msxrom
                irp     i,<0,1,2,3>
                mov     dword ptr [offset extended_slot_0+i*8],eax
                add     eax,02000h
                endm

                ; make the slot0 become an extended slot
                mov     eax,extendedrom
                mov     dword ptr [offset slot0+7*8],eax
                mov     dword ptr [offset slot0+7*8+4],EXTENDED_SLOT
                mov     dword ptr [offset mem+7*4],eax
                mov     dword ptr [offset memlock+7*4],EXTENDED_SLOT
                
                ; allocate 32kb to msx2ext rom
                mov     eax,32768
                call    _getmem
                jc      no_memory
                mov     msxextrom,eax

                ; place msx2ext in slot 0.1 (page 0)
                irp     i,<0,1,2,3>
                mov     dword ptr [offset extended_slot_0+8*4*2+i*8],eax
                add     eax,2000h
                endm

                ; read msx2ext rom from disk
                mov     edx,model_subrom ;offset msx2ext_rom_name
                call    open_file
                jc      msx2ext_rom_error
                call    read_size_file
                ;cmp     eax,04000h
                ;jne     msx2ext_rom_error
                mov     edx,transf_buffer
                mov     ecx,32768 ;;;16384
                call    read_file
                call    close_file
                mov     edi,msxextrom
                mov     esi,transf_buffer
                mov     ecx,32768/4 ;;;;16384/4
                rep     movsd

                ; set the new VDP I/O ports
                mov     eax,offset outemul98_msx2
                mov     dword ptr [offset outportxx+098h*4],eax
                
                mov     eax,offset outemul99_msx2
                mov     dword ptr [offset outportxx+099h*4],eax

                mov     eax,offset outemul9A_msx2
                mov     dword ptr [offset outportxx+09Ah*4],eax

                mov     eax,offset outemul9B_msx2
                mov     dword ptr [offset outportxx+09Bh*4],eax

                mov     eax,offset inemul98_msx2
                mov     dword ptr [offset inportxx+098h*4],eax

                mov     eax,offset inemul99_msx2
                mov     dword ptr [offset inportxx+099h*4],eax

                ; set the RTC ports
                mov     eax,offset outemulB4
                mov     dword ptr [offset outportxx+0B4h*4],eax
                
                mov     eax,offset outemulB5
                mov     dword ptr [offset outportxx+0B5h*4],eax
                
                mov     eax,offset inemulB5
                mov     dword ptr [offset inportxx+0B5h*4],eax
                
                ; init the new IRQ handler
                mov     eax,offset emulFB_MSX2
                mov     dword ptr [offset iset+0FBh*4],eax
                mov     eax,offset emul76_MSX2
                mov     dword ptr [offset iset+076h*4],eax
                
                ; 128kb of VRAM
                mov     vramsize,128*1024

                ; turn off video cache
                mov     imagetype,0

                ; select the DISK2.ROM
                mov     eax,offset disk2_rom_name
                mov     model_diskrom,eax

                ; enable patch-based emulation
                ; if the user hasn't selected a disk-model
                cmp     forcedisk,1
                je      _ret

                mov     portenabled,0

                ret

; --------------------------------------------------------------------

CHECK_VIDEOMODE macro   mode,offset
                local   exit

                cmp     videomode,mode
                jne     exit
                test    vesa2found,offset
                jnz     exit

                mov     videomode,0
exit:

                endm

; --------------------------------------------------------------------

check_video_mode:                
                
                ; search for mode 512x384x8 linear
                or      vesa2found,1
                call    search_vesa_mode
                jnc     check_video_mode_512_ok

                call    vesa2_512x384_not_found
                and     vesa2found,NOT (1)

check_video_mode_512_ok:

                ; search for mode 512x384x15 linear
                or      vesa2found,2
                call    search_vesa_mode_512_15
                jnc     check_video_mode_512_15_ok

                call    vesa2_512x384_15_not_found
                and     vesa2found,NOT (2)

check_video_mode_512_15_ok:

                ; search for mode 640x480x8 linear
                or      vesa2found,4
                call    search_vesa_mode_640
                jnc     check_video_mode_640_ok

                call    vesa2_640x480_not_found
                and     vesa2found,NOT (4)

check_video_mode_640_ok:

                CHECK_VIDEOMODE 2,1
                CHECK_VIDEOMODE 6,2
                CHECK_VIDEOMODE 8,1
                CHECK_VIDEOMODE 9,1
                CHECK_VIDEOMODE 11,4
                CHECK_VIDEOMODE 12,2

                cmp     msxmodel,0
                jne     check_video_mode_msx2

                cmp     videomode,7
                jb      _ret

                mov     videomode,0
                ret

check_video_mode_msx2:
                cmp     videomode,7
                jae     _ret

                mov     videomode,7
                ret

; --------------------------------------------------------------------

code32          ends
                end

