@echo off
rbc %1.c %1.i
rbcc %1.i %1.p
rbat z80.cfg %1.p %1.mac

