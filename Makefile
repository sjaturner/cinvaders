main: main.c
	gcc $^ -DDEBUG -g -Wall -Wextra -Wno-unused-parameter -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -L/usr/lib/x86_64-linux-gnu -lSDL2 -o $@
.PHONY: all
invaders.bin: invaders.h invaders.g invaders.f invaders.e 
	cat $^ > $@
invaders.asm: invaders.bin
	z80dasm -l -b blockfile -g0 -t -a $^ > $@
	cat $@ | python3 align.py | sponge $@
all: main
.PHONY: clean
clean:
	rm -f main invaders.asm invaders.bin
