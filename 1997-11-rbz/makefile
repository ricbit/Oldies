CFLAGS = -O2 -Wall -fomit-frame-pointer
LIBDIR = -L d:/djgpp/allegro2/lib/djgpp
INCDIR = -I d:/djgpp/allegro2
LIBS = -lalleg -lm

rbz.exe : rbz.c
	gcc $(CFLAGS) $(LIBDIR) $(INCDIR) $^ -o $@ $(LIBS)

