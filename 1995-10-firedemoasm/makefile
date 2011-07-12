.asm.obj:
  tasm /ml/m2/q $<

demon.exe: start32.obj kb32.obj demon.obj argc32.obj pdosstr.obj
  tlink /3/m/C/c start32+kb32+argc32+pdosstr+demon,demon

argc32.obj: argc32.asm
pdosstr.obj: pdosstr.asm
start32.obj: start32.asm
kb32.obj: kb32.asm start32.inc
demon.obj: demon.asm rand320.inc random5.inc


