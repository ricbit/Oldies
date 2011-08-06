OBJECTS = pentium.o rbdmain.o vesa.o video.o runloop.o tcltk.o graphics.o \
	  fractal.o
OBJBUILD = lexyy.o rbd_tab.o build.o
CFLAGS = -O2 -finline -fomit-frame-pointer -g -Wall
# LIBSLINUX = -ltcl -ltk -lX11
LIBS = $(LIBSLINUX) -lm
LIBSBUILD = -lfl

all : rbd

mbuild : build.exe

%.o : %.c
	gcc $(CFLAGS) -c $^ -o $@

rbd : $(OBJECTS)
	gcc $(CFLAGS) $^ -o $@ $(LIBS)
#       stubedit $@ dpmi=cwsdpr0.exe

build.exe : $(OBJBUILD)
	gcc $(CFLAGS) $^ -o $@ $(LIBSBUILD)

lexyy.c : rbd.l rbd_tab.h
	flex rbd.l

rbd_tab.h rbd_tab.c : rbd.y
	bison -d -v $^

clean :
	del *.exe 
	del *.o
	del lexyy.c
	del rbd_tab.*

cleanl : 
	rm *.o
	rm lexyy.c
	rm rbd_tab.*
	rm *.exe

