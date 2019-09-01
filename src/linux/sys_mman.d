module linux.stdio;

import plat_version;
import syscaller;

extern (C):

static if (plat_arch == Architecture.AMD64) {
	void *mmap(void *addr, size_t len, int prot, int flags, int filedes, ulong off) {
		return cast(void*)syscall(9, addr, len, prot, flags, filedes, off);
	}
	int mprotect(void *addr, size_t len, int prot) {
		return cast(int)syscall(10, addr, len, prot);
	}
	int munmap(void *addr, size_t len) {
		return cast(int)syscall(11, addr, len);
	}
}
