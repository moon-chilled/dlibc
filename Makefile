DC ?= dmd
# TODO: figure out how to turn off -fPIC for static builds
# TODO: ldc uses -relocation-model=pic
DFLAGS := -betterC -O -Isrc/ -fPIC
LD ?= ld
LDFLAGS :=

#TODO: autodetect these
PLAT := linux
ARCH := amd64

START_OBJ := src/$(PLAT)/start_$(ARCH).o
OBJ := src/plat_version.o src/syscaller.o src/unistd.o src/linux/unistd.o
ALL_OBJ := $(OBJ) $(START_OBJ)

default: all

.SUFFIXES: .d

.d.o:
	$(DC) -c $(DFLAGS) -of=$@ $<

all: static dynamic

static: $(ALL_OBJ)
	ar rcs libdlibc.a $(ALL_OBJ)

dynamic: $(OBJ)
	ld -shared -o libdlibc.so $(OBJ)

clean:
	rm -f libdlibc.so libdlibc.a $(OBJ)
