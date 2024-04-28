main: main.c
	gcc $^ -DDEBUG -g -Wall -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT -L/usr/lib/x86_64-linux-gnu -lSDL2 -o $@
