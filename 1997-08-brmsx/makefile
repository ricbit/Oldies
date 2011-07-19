OBJECTS = pmode.o io.o brmsx.o patch.o mount.o \
	  saveload.o gui.o blit.o psg.o vdp.o v9938.o v9958.o drive.o \
	  serial.o mouse.o pentium.o vesa.o joystick.o winsock.o \
	  z80core.o z80.o z80sing.o z80cb.o z80dd.o z80ed.o z80fd.o \
	  symdeb.o print.o printcb.o printdd.o printfd.o
SCREENS = debug1.inc debug2.inc debug3.inc debug4.inc \
	  debug5.inc debug6.inc help.inc server.inc client.inc
TASM = tasm
TASMFLAGS = /ml /m2 /q /la
ECHO = rbecho

all : rbecho.exe asc2aic.exe aic2azc.exe dbize.exe brmsx.exe

rbecho.exe: rbecho.c
	gcc $^ -o $@ 

asc2aic.exe: asc2aic.c
	gcc $^ -o $@ 

aic2azc.exe: aic2azc.c
	gcc $^ -o $@ 

dbize.exe: dbize.c
	gcc $^ -o $@ 

brmsx.exe : $(OBJECTS) debug.o
	$(ECHO) objects.lst $^
	tlink /3 /x @objects.lst , $@

%.o : %.asm
	$(TASM) $(TASMFLAGS) $^,$@

%.aic : %.asc
	asc2aic $^ $@

%.azc : %.aic
	aic2azc $^ $@

%.inc : %.azc
	dbize $^ $@

debug.o : debug.asm $(SCREENS)
	$(TASM) $(TASMFLAGS) debug.asm,$@

clean :
	del *.o
	del *.exe
	del *.lst
	del cart1.rom
	del brmsx.sta
