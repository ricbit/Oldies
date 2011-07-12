.AUTODEPEND

.PATH.obj = C:\EXE

#		*Translator Definitions*
CC = bcc +PSGP.CFG
TASM = TASM
TLINK = tlink


#		*Implicit Rules*
.c.obj:
  $(CC) -c {$< }

.cpp.obj:
  $(CC) -c {$< }

#		*List Macros*


EXE_dependencies =  \
  error.obj \
  xms.obj \
  timer.obj \
  vesa.obj \
  filesys.obj \
  keyboard.obj \
  color.obj \
  linmem.obj \
  sb.obj \
  screen.obj \
  slide.obj \
  psgp.obj

#		*Explicit Rules*
c:\exe\psgp.exe: psgp.cfg $(EXE_dependencies)
  $(TLINK) /v/s/i/c/P-/LC:\BORLANDC\LIB @&&|
c0l.obj+
c:\exe\error.obj+
c:\exe\xms.obj+
c:\exe\timer.obj+
c:\exe\vesa.obj+
c:\exe\filesys.obj+
c:\exe\keyboard.obj+
c:\exe\color.obj+
c:\exe\linmem.obj+
c:\exe\sb.obj+
c:\exe\screen.obj+
c:\exe\slide.obj+
c:\exe\psgp.obj
c:\exe\psgp,c:\exe\psgp
fp87.lib+
mathl.lib+
cl.lib
|


#		*Individual File Dependencies*
error.obj: ..\boss\error.cpp 
	$(CC) -c ..\boss\error.cpp

xms.obj: ..\boss\xms.cpp 
	$(CC) -c ..\boss\xms.cpp

timer.obj: ..\boss\timer.cpp 
	$(CC) -c ..\boss\timer.cpp

vesa.obj: ..\boss\vesa.cpp 
	$(CC) -c ..\boss\vesa.cpp

filesys.obj: ..\boss\filesys.cpp 
	$(CC) -c ..\boss\filesys.cpp

keyboard.obj: ..\boss\keyboard.cpp 
	$(CC) -c ..\boss\keyboard.cpp

color.obj: ..\boss\color.cpp 
	$(CC) -c ..\boss\color.cpp

linmem.obj: ..\boss\linmem.cpp 
	$(CC) -c ..\boss\linmem.cpp

sb.obj: ..\boss\sb.cpp 
	$(CC) -c ..\boss\sb.cpp

psgp.obj: psgp.cpp 

#		*Compiler Configuration File*
psgp.cfg: psgp.mak
  copy &&|
-ml
-2
-f287
-v
-G
-O
-Z
-rd
-V0
-vi
-wamb
-wasm
-nC:\EXE
-IC:\BORLANDC\INCLUDE;C:\BORLANDC\BOSS
-LC:\BORLANDC\LIB
| psgp.cfg


