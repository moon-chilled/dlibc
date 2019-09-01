module linux.fcntl;

import plat_version;
import syscaller;

extern (C):

static if (plat_arch == Architecture.AMD64) {
	// the official signature of open is int(const char*, int, ...)
	// but the third argument fits in a register so it doesn't mess up the
	// stack to do this.  Yay.
	int open(const char *path, int flags, uint mode) {
		return cast(int)syscall(2, path, flags, mode);
	}
	void close(int fd) {
		syscall(3, fd);
	}
}
