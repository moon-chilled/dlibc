DC ?= dmd
DFLAGS := -betterC -O -Isrc/
LD ?= ld
LDFLAGS :=

OBJ := src/plat_version.o src/start.o src/syscaller.o src/unistd.o src/linux/unistd.o

default: all

.SUFFIXES: .d

.d.o:
	$(DC) -c $(DFLAGS) -of=$@ $<

all: $(OBJ)
	$(LD) $(LDFLAGS) -o start $(OBJ)

clean:
	rm -f start $(OBJ)
