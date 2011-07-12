.AUTODEPEND

.PATH.obj = C:\EXE

#		*Translator Definitions*
CC = bcc +RAY.CFG
TASM = TASM
TLINK = tlink


#		*Implicit Rules*
.c.obj:
  $(CC) -c {$< }

.cpp.obj:
  $(CC) -c {$< }

#		*List Macros*


EXE_dependencies =  \
  yomath.obj \
  video.obj \
  surface.obj \
  objects.obj \
  esfera.obj \
  plano.obj \
  lampada.obj \
  scene.obj \
  render.obj \
  raytest.obj

#		*Explicit Rules*
c:\exe\ray.exe: ray.cfg $(EXE_dependencies)
  $(TLINK) /v/x/c/P-/LC:\BORLANDC\LIB @&&|
c0s.obj+
c:\exe\yomath.obj+
c:\exe\video.obj+
c:\exe\surface.obj+
c:\exe\objects.obj+
c:\exe\esfera.obj+
c:\exe\plano.obj+
c:\exe\lampada.obj+
c:\exe\scene.obj+
c:\exe\render.obj+
c:\exe\raytest.obj
c:\exe\ray
		# no map file
emu.lib+
maths.lib+
cs.lib
|


#		*Individual File Dependencies*
yomath.obj: ..\include\yomath.cpp 
	$(CC) -c ..\include\yomath.cpp

video.obj: ..\include\video.cpp 
	$(CC) -c ..\include\video.cpp

surface.obj: surface.cpp 

objects.obj: objects.cpp 

esfera.obj: esfera.cpp 

plano.obj: plano.cpp 

lampada.obj: lampada.cpp 

scene.obj: scene.cpp 

render.obj: render.cpp 

raytest.obj: raytest.cpp 

#		*Compiler Configuration File*
ray.cfg: ray.mak
  copy &&|
-v
-nC:\EXE
-IC:\BORLANDC\INCLUDE
-LC:\BORLANDC\LIB
-P.CPP
| ray.cfg


