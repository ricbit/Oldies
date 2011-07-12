.AUTODEPEND

.PATH.obj = \EXE

#		*Translator Definitions*
CC = bcc +GR256.CFG
TASM = TASM
TLINK = tlink


#		*Implicit Rules*
.c.obj:
  $(CC) -c {$< }

.cpp.obj:
  $(CC) -c {$< }

#		*List Macros*


EXE_dependencies =  \
  gr256.obj \
  fgraph.obj \
  mouse.obj \
  cursor.obj

#		*Explicit Rules*
\exe\gr256.exe: gr256.cfg $(EXE_dependencies)
  $(TLINK) /v/x/c/P-/L\BORLANDC\LIB @&&|
c0l.obj+
\exe\gr256.obj+
\exe\fgraph.obj+
\exe\mouse.obj+
\exe\cursor.obj
\exe\gr256
		# no map file
emu.lib+
mathl.lib+
cl.lib+
graphics.lib
|


#		*Individual File Dependencies*
gr256.obj: gr256.cpp 

fgraph.obj: ..\doom\fgraph.asm 
	$(TASM) /MX /ZI /O ..\DOOM\FGRAPH.ASM,\EXE\FGRAPH.OBJ

mouse.obj: mouse.cpp 

cursor.obj: cursor.cpp 

#		*Compiler Configuration File*
gr256.cfg: gr256.mak
  copy &&|
-ml
-v
-n\EXE
-I\BORLANDC\INCLUDE
-L\BORLANDC\LIB
| gr256.cfg


