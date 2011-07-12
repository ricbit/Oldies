.asm.obj:
  tasm /ml/m2/q $<

engine.exe: start32.obj kb32.obj engine.obj
  tlink /3/m/C/c start32+kb32+engine,engine

start32.obj: start32.asm
kb32.obj: kb32.asm start32.inc
engine.obj: engine.asm sintable.inc


