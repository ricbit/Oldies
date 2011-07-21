CC = gcc
OPTIONS = -O2 -Wall -fomit-frame-pointer -m486 -g
LIB = -lalleg -lm -lfl
LEX = flex
YACC = bison
OBJS = doom.o doom_tab.o doom_lex.o

all : doom.exe

doom_tab.c doom_tab.h : doom.y doom.h
	bison -v -d $<

.y.c:
	

doom_lex.c : doom.l doom_tab.h
	$(LEX) -o$@ $<

%.o : %.c        
	$(CC) $(OPTIONS) -c $^ -o $@ 

doom.exe : $(OBJS)
	$(CC) $(OPTIONS) $(OBJS) -o $@ $(LIB)

clean :
	del *.exe
	del doom_tab.*
	del doom_lex.*
	del *.out
	del *.o
