# RBC 1.3.3 by Ricardo Bittencourt
# module RBLO

CFLAGS = -O2 -Wall -Wno-unused -Wno-implicit -ansi
YACC = bison
LEX = flex
CC = gcc
LIB = -lfl
OBJS = lexyy.o rblo_tab.o rblomain.o

all : rblo.exe

rblo_tab.c rblo_tab.h : rblo.y
	$(YACC) -d -v $<

lexyy.c : rblo.l rblo_tab.h
	$(LEX) $<

%.o : %.c
	$(CC) $(CFLAGS) -c $^ -o $@

rblo.exe : $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LIB)

clean :
	del lex??.c
	del *.exe
	del rblo_*.*
	del *.out
	del *.o
