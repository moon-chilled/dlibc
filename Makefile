LD ?= ld
LDFLAGS :=

DC ?= dmd
# TODO: figure out how to turn off -fPIC for static builds
DFLAGS := -betterC -Isrc/external -Isrc/internal -Isrc -g
ifeq ($(DC),ldc2)
	DFLAGS += -relocation-model=pic -Oz
else
	DFLAGS += -fPIC -O
endif

#TODO: autodetect these
PLAT ?= linux
ARCH ?= amd64

linux_OBJ := src/internal/linux/errno_.o src/external/linux/errno_.o src/external/linux/unistd.o src/external/linux/libc.o src/external/linux/fcntl.o src/external/linux/sys_mman.o src/external/linux/sched.o
freebsd_OBJ := src/external/freebsd/unistd.o

START_OBJ := src/external/$(PLAT)/start_$(ARCH).o
OBJ :=	src/internal/syscaller.o src/internal/plat_version.o \
	src/external/errno_.o src/external/assert_.o src/external/string.o src/external/strings.o src/external/allocator.o src/external/unistd.o src/external/fcntl.o src/external/sys_mman.o src/external/stdio.o $($(PLAT)_OBJ)

ALL_OBJ := $(OBJ) $(START_OBJ)

default: all

.SUFFIXES: .d

.d.o:
	$(DC) -c $(DFLAGS) -of=$@ $<

all: static dynamic

static: $(ALL_OBJ)
	$(AR) rcs libdlibc.a $(ALL_OBJ)

dynamic: $(OBJ)
	$(LD) $(LDFLAGS) -shared -o libdlibc.so $(OBJ)

clean:
	rm -f libdlibc.so libdlibc.a $(ALL_OBJ)
