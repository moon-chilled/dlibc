module linux.fcntl;

import plat_version;
import syscaller;

extern (C):

static if (plat_arch == Architecture.AMD64) {
	enum {
		O_RDONLY = 0,
		O_WRONLY = 1,
		O_RDWR = 2,
		O_CREAT = 0x40,
		O_TRUNC = 0x200,
	}

	// the official signature of open is int(const char*, int, ...)
	// but the third argument fits in a register so it doesn't mess up the
	// stack to do this.  Yay.
	int open(const(char) *path, int flags, uint mode) {
		return cast(int)syscall!2(path, flags, mode);
	}
	int close(int fd) {
		return cast(int)syscall!3(fd);
	}
}
