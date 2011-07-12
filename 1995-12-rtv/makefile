.asm.obj:
  tasm /ml/m2/q $<

rtv.exe: start32.obj kb32.obj file32.obj rtv.obj argc32.obj pdosstr.obj
  tlink /3/m/C/c start32+kb32+argc32+pdosstr+file32+rtv,rtv

argc32.obj: argc32.asm
pdosstr.obj: pdosstr.asm
file32.obj: file32.asm
start32.obj: start32.asm
kb32.obj: kb32.asm start32.inc
rtv.obj: rtv.asm

