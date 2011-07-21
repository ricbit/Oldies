@echo off
rbc %1.c %1.i
rbcc %1.i %1.p
rblo %1.p %1.o
rbat 8088.cfg %1.o %1.asm
\borlandc\bin\tasm /c /ml /zi %1
\borlandc\bin\tlink /c /C /v %1

