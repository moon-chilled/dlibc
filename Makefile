AS ?= as
ASFLAGS :=

LD ?= ld
LDFLAGS :=

default: all

all: start.o
	$(LD) $(LDFLAGS) -o start start.o

start.o: start.S
	$(AS) -o start.o start.S
