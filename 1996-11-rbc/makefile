ROOT = \djgpp\progs\rbc
VERSION = 1.4

msdos: 
	cd $(ROOT)\cpp
	$(MAKE)
	copy rbc.exe ..
	cd $(ROOT)\cc
	$(MAKE)
	copy rbcc.exe ..
	cd $(ROOT)\at
	$(MAKE)
	copy rbat.exe ..
	cd $(ROOT)\lo
	$(MAKE)
	copy rblo.exe ..

clean :
	del *.exe
	cd $(ROOT)\cpp
	$(MAKE) clean
	cd $(ROOT)\cc
	$(MAKE) clean
	cd $(ROOT)\at
	$(MAKE) clean
	cd $(ROOT)\lo
	$(MAKE) clean

vupdate:
	cd $(ROOT)\cpp
	for %%f in (*.*) do call \djgpp\progs\vupdate\vup %%f $(VERSION)
	cd $(ROOT)\cc
	for %%f in (*.*) do call \djgpp\progs\vupdate\vup %%f $(VERSION)
	cd $(ROOT)\at
	for %%f in (*.*) do call \djgpp\progs\vupdate\vup %%f $(VERSION)
