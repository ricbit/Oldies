# RBC 1.4 by Ricardo Bittencourt
# module RBAT

CFLAGS = -O2 -Wall -Wno-unused -Wno-implicit -ansi
YACC = bison
LEX = flex
CC = gcc
LIB = -lfl
OBJS = lexyy.o rbat_tab.o rbt_tab.o lexzz.o rbatmain.o

all : rbat.exe

rbat_tab.c rbat_tab.h : rbat.y
	$(YACC) -d -v $<

rbt_tab.c rbt_tab.h : rbt.y
	$(YACC) -d -v -p zz $<

lexyy.c : rbat.l rbat_tab.h
	$(LEX) $<

lexzz.c : rbt.l rbt_tab.h
	$(LEX) -Pzz $<

%.o : %.c
	$(CC) $(CFLAGS) -c $^ -o $@

rbat.exe : $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LIB)

clean :
	del lex??.c
	del *.exe
	del rbat_*.*
	del rbt_*.*
	del *.out
	del *.o
