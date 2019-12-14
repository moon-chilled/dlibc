module linux.sys_mman;

import plat_version;
import syscaller;

extern (C):
__gshared:

static if (plat_arch == Architecture.AMD64) {
	enum {
		PROT_READ = 0x1,
		PROT_WRITE = 0x2,
		PROT_EXEC = 0x4,
		PROT_NONE = 0x0,
		PROT_GROWSDOWN = 0x01000000,
		PROT_GROWSUP = 0x02000000,

		MAP_FILE = 0,
		MAP_SHARED = 0x1,
		MAP_PRIVATE = 0x2,
		MAP_SHARED_VALIDATE = 0x3,
		MAP_TYPE = 0x0f,
		MAP_FIXED = 0x10,
		MAP_ANONYMOUS = 0x20,
		MAP_ANON = MAP_ANONYMOUS,
		MAP_HUGE_SHIFT = 26, //wat
		MAP_HUGE_MASK = 0x3f,
	}

	enum MAP_FAILED = cast(void*)-1;

	void *mmap64(void *addr, size_t len, int prot, int flags, int filedes, ulong off) {
		return cast(void*)syscall!9(addr, len, prot, flags, filedes, off);
	}
	void *function(void*, size_t, int, int, int, ulong) mmap = &mmap64;

	int mprotect(void *addr, size_t len, int prot) {
		return cast(int)syscall!10(addr, len, prot);
	}
	int munmap(void *addr, size_t len) {
		return cast(int)syscall!11(addr, len);
	}
}
