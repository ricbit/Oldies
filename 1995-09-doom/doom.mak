.AUTODEPEND

.PATH.obj = C:\EXE

#		*Translator Definitions*
CC = bcc +DOOM.CFG
TASM = TASM
TLINK = tlink


#		*Implicit Rules*
.c.obj:
  $(CC) -c {$< }

.cpp.obj:
  $(CC) -c {$< }

#		*List Macros*


EXE_dependencies =  \
  fgraph.obj \
  fixed.obj \
  doom.obj

#		*Explicit Rules*
c:\exe\doom.exe: doom.cfg $(EXE_dependencies)
  $(TLINK) /v/s/c/P-/LC:\BORLANDC\LIB @&&|
c0l.obj+
c:\exe\fgraph.obj+
c:\exe\fixed.obj+
c:\exe\doom.obj
c:\exe\doom,c:\exe\doom
emu.lib+
mathl.lib+
cl.lib+
graphics.lib
|


#		*Individual File Dependencies*
fgraph.obj: fgraph.asm 
	$(TASM) /MX /ZI /O FGRAPH.ASM,C:\EXE\FGRAPH.OBJ

fixed.obj: fixed.asm 
	$(TASM) /MX /ZI /O FIXED.ASM,C:\EXE\FIXED.OBJ

doom.obj: doom.cpp 

#		*Compiler Configuration File*
doom.cfg: doom.mak
  copy &&|
-ml
-2
-a
-v
-G
-r-
-vi
-H=DOOM.SYM
-nC:\EXE
-IC:\BORLANDC\INCLUDE
-LC:\BORLANDC\LIB
| doom.cfg


