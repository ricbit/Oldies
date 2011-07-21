CFLAGS = -O2 -Wall -fomit-frame-pointer -finline-functions -finline
LIB = -lfl -lm 
OBJS = rbrtlex.o rbrt_tab.o rbrtmain.o object.o sphere.o \
       render.o plane.o light.o surface.o vesa.o circle.o \
       cylinder.o poliedra.o

all: rbrt.exe

rbrt_tab.c rbrt_tab.h : rbrt.y
	bison -d -v rbrt.y

rbrtlex.c : rbrt.l rbrt_tab.h
	flex -orbrtlex.c rbrt.l

vesa.o : vesa.c
	gcc $(CFLAGS) -x c -c $^ -o $@

%.o : %.cpp
	gcc -x c++ $(CFLAGS) -c $^ -o $@

%.o : %.c
	gcc -x c++ $(CFLAGS) -c $^ -o $@

rbrt.exe : $(OBJS)
	gxx $(CFLAGS) $^ -o $@ $(LIB)

clean : 
	del *.o
	del *.exe
	del rbrtlex.c
	del rbrt_tab.*
	del *.out
