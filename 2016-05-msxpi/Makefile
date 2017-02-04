all : msxpi.com

run : msxpi.com
	./openmsx -machine Panasonic_FS-A1GT -diska disk

msxpi.com : msxpi.asm
	./sjasmplus msxpi.asm --lst=msxpi.lst --sym=msxpi.sym
	mkdir -p disk
	cp msxpi.com disk

