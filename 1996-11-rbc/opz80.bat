@echo off
rbc %1.c %1.i
rbcc %1.i %1.p
rblo %1.p %1.o
rbat z80.cfg %1.o %1.mac


