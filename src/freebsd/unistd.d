module freebsd.unistd;

import plat_version;
import syscaller;

extern (C):

static if (plat_arch == Architecture.AMD64) {
	void _Exit(int status) {
		syscall(1, status);
	}

	ptrdiff_t read(int fd, const void *buf, size_t count) {
		return syscall(3LU, fd, buf, count);
	}
	ptrdiff_t write(int fd, const void *buf, size_t count) {
		return syscall(4LU, fd, buf, count);
	}
}
