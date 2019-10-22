LD ?= ld
LDFLAGS :=

DC ?= dmd
# TODO: figure out how to turn off -fPIC for static builds
DFLAGS := -betterC -O -Isrc/ -g
ifeq ($(DC),ldc)
	DFLAGS += -relocation-model=pic -flto=full
	LD := clang
	LDFLAGS += -flto=full -nodefaultlibs
else
	DFLAGS += -fPIC
endif

#TODO: autodetect these
PLAT := linux
ARCH := amd64

linux_OBJ := src/linux/unistd.o src/linux/stdio.o src/linux/libc.o src/linux/fcntl.o src/linux/sys_mman.o src/linux/sched.o
freebsd_OBJ := src/freebsd/unistd.o

START_OBJ := src/$(PLAT)/start_$(ARCH).o
OBJ := src/errnor.o src/assert_.o src/string.o src/strings.o src/allocator.o src/plat_version.o src/syscaller.o src/unistd.o src/fcntl.o src/sys_mman.o src/stdio.o $($(PLAT)_OBJ)
ALL_OBJ := $(OBJ) $(START_OBJ)

default: all

.SUFFIXES: .d

.d.o:
	$(DC) -c $(DFLAGS) -of=$@ $<

all: static dynamic

static: $(ALL_OBJ)
	ar rcs libdlibc.a $(ALL_OBJ)

dynamic: $(OBJ)
	$(LD) $(LDFLAGS) -shared -o libdlibc.so $(OBJ)

clean:
	rm -f libdlibc.so libdlibc.a $(ALL_OBJ)
