CFLAGS = -O2 --omit-frame-pointer -Wall -g
LIB = -lalleg -lm
OBJS = rbvv.o

all : rbvv.exe

%.o : %.c
	gcc $(CFLAGS) -c $^ -o $@ 

rbvv.exe : $(OBJS)
	gcc $(CFLAGS) $^ -o $@ $(LIB)
