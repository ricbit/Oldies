# Makefile for PSG Player
# Ricardo Bittencourt

CC = gcc
OPTIONS = -O3 -m486 -Wall -g -finline-functions -Werror
LIB = -lm

all : psgp.exe

asc2h.exe : asc2h.c
	$(CC) $(OPTIONS) $< -o $@ $(LIB)

psgp.h : psgp.asc asc2h.exe
	asc2h $< MainScreen >$@

slide.h : slide.asc asc2h.exe
	asc2h $< SlideScreen >$@

psgp.exe : psgp.c psgp.h slide.h
	$(CC) $(OPTIONS) $< -o $@ $(LIB)

clean : 
	del *.h 
	del *.exe
