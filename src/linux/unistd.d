module linux.unistd;

import plat_version;
import syscaller;

extern (C):

static if (plat_arch == Architecture.AMD64) {
	void exit_group(int status) {
		syscall!231(status);
	}

	void _exit(int status) {
		syscall!60(status);
	}
	void _Exit(int status) {
		syscall!60(status);
	}

	ssize_t read(int fd, const void *buf, size_t count) {
		return syscall!0(fd, buf, count);
	}
	ssize_t write(int fd, const void *buf, size_t count) {
		return syscall!1(fd, buf, count);
	}
}
