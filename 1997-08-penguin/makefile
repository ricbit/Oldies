LIBDIR=-L/djgpp/allegro2/lib/djgpp
INCDIR=-I/djgpp/allegro2
CFLAGS=-O2 -x c++ -Wall -m486 -g
LIBS=-lalleg
CC=gcc
OBJ=pengbot.o bot.o main.o timer.o

default: penguin.exe editor.exe

glove: penglove.exe 

mpc: pc.exe

pengbot.cc : penguin.bot pc.exe
	pc <penguin.bot

%.o : %.cc
	$(CC) $(CFLAGS) $(INCDIR) -c $^ -o $@

timer.o : timer.c
	$(CC) -x c -c $^ -o $@

penguin.exe : $(OBJ)
	$(CC) $(LIBDIR) $^ -o $@ $(LIBS)

penglove.exe : pengbot.o bot.o mainglov.o timer.o glove.o
	$(CC) $(LIBDIR) $^ -o $@ $(LIBS)

editor.exe : editor.c
	$(CC) -Wall $(LIBDIR) $(INCDIR) $^ -o $@ $(LIBS)

pc.y: ;
pc.l: ;

clean :
	del *.o
	del *.exe
	del *.out
	del pc_tab.*
	del lexyy.c

pc.exe: pc.y pc.l
	bison -d -v pc.y
	flex pc.l
	gcc pc_tab.c lexyy.c -Wall -lfl -o pc.exe
