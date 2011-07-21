# RBCPP 1.4 by Ricardo Bittencourt

CFLAGS = -O2 -Wall -Wno-unused -Wno-implicit
YACC = bison
LEX = flex
CC = gcc
LIB = -lfl
OBJS = rbc_tab.o lexyy.o rbcmain.o

all : rbc.exe

rbc_tab.c rbc_tab.h : rbc.y rbc.h
	$(YACC) -d -v $<

lexyy.c : rbc.l rbc.h rbc_tab.h
	$(LEX) $<

%.o : %.c
	$(CC) $(CFLAGS) -c $^ -o $@

rbc.exe : $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LIB)

clean :
	del lexyy.c
	del *.exe
	del rbc_*.*
	del *.out
	del *.o
