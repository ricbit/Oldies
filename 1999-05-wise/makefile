LIB = -lfl -lm -ljpeg
OPTIONS = -Wall -O2 -fomit-frame-pointer -ansi -Ijpeg-6b -Ljpeg-6b

start: wise.exe

sg1000: wisesg.exe

wise.exe: wise_tab.o lexyy.o wise_grp.o wise_rle.o wise_gen.o
	gcc $^ -o $@ $(OPTIONS) $(LIB)

wisesg.exe: wisg_tab.o lexyy.o wise_grp.o wise_rle.o wise_gen.o
	gcc $^ -o $@ $(OPTIONS) $(LIB)

%.o : %.c        
	gcc -c $^ -o $@ $(OPTIONS)

lexyy.c: wise_tab.h wise.l
	flex -8 -olexyy.c wise.l

wise_tab.c wise_tab.h: wise.y
	bison -d -v $^ -o wise_tab.c

wisg_tab.c wisg_tab.h: wisesg.y
	bison -d -v $^ -o wisg_tab.c


