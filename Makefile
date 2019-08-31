DC ?= dmd
DFLAGS := -betterC -O
LD ?= ld
LDFLAGS :=

default: all

all: start.o
	$(LD) $(LDFLAGS) -o start start.o

start.o: start.d
	$(DC) $(DFLAGS) -c -of=start.o start.d

clean:
	rm -f start.o start
