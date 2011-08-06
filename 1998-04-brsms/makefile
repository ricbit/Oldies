OBJECTS = pmode.o debug.o patch.o sms.o io.o \
	  saveload.o gui.o psg.o vdp.o blit.o vdp_sg.o blit_sg.o \
	  serial.o mouse.o pentium.o vesa.o joystick.o winsock.o guess.o \
	  z80.o z80sing.o z80cb.o z80dd.o z80ed.o z80fd.o z80core.o \
	  print.o printcb.o printdd.o printfd.o
TASM = tasm
TASMFLAGS = /ml /m2 /q /la
ECHO = rbecho

all : rbecho.exe brsms.exe

rbecho.exe: rbecho.c
	gcc $^ -o $@ 

2xsai.o : 2xsai.cpp
	gcc -O2 -S $^ -o 2xsai.s -fomit-frame-pointer
	att2intl 2xsai.s > lixo
	$(TASM) $(TASMFLAGS) a2itmpfl.asm,$@

brsms.exe : $(OBJECTS) 2xsai.o 
	$(ECHO) objects.lst $^
	tlink /3 /x @objects.lst , $@

%.o : %.asm
	$(TASM) $(TASMFLAGS) $^,$@

clean :
	del *.o
	del *.exe
	del *.lst
