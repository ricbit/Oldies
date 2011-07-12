.asm.obj:
  tasm /ml/m2/q $<

descent.exe: start32.obj file32.obj pdosstr.obj init.obj graph.obj \
             descent.obj kb32.obj globals.obj project.obj draw.obj \
             runloop.obj keyboard.obj makefile
  tlink /3/m/C/c start32+file32+pdosstr+globals+init+runloop+\
                 graph+kb32+project+descent+draw+keyboard,descent

start32.obj: start32.asm
file32.obj: file32.asm start32.inc
runloop.obj: runloop.asm start32.inc keyboard.inc project.inc draw.inc \
             globals.inc kb32.inc graph.inc
kb32.obj: kb32.asm start32.inc
pdosstr.obj: pdosstr.asm start32.inc
keyboard.obj: keyboard.asm start32.inc
draw.obj: draw.asm start32.inc globals.inc graph.inc
project.obj: project.asm start32.inc globals.inc
globals.inc: globals.asm start32.inc
init.obj: init.asm start32.inc file32.inc \
          globals.inc pdosstr.inc graph.inc kb32.inc
graph.obj: graph.asm start32.inc globals.inc
descent.obj: descent.asm init.inc runloop.inc


