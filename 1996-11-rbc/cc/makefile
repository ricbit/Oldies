# RBCPP 1.4 by Ricardo Bittencourt
# module RBCC

CFLAGS = -O2 -Wall -Wno-unused -Wno-implicit -ansi
YACC = bison
LEX = flex
CC = gcc
LIB = -lfl
OBJS = lexyy.o rbcc_tab.o rbccmain.o

all : rbcc.exe

rbcc_tab.c rbcc_tab.h : rbcc.y rbcc.h
	$(YACC) -d -v $<

lexyy.c : rbcc.l rbcc_tab.h rbcc.h
	$(LEX) $<

%.o : %.c
	$(CC) $(CFLAGS) -c $^ -o $@

rbcc.exe : $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LIB)

clean :
	del lexyy.c
	del *.exe
	del rbcc_*.*
	del *.out
	del *.o
