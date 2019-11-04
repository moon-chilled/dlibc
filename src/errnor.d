module errnor;

import plat_version;

extern (C):
int errno;

static if (plat_os == OS.Linux) {
	int *__errno_location() {
		return &errno;
	}
} else static if (plat_os == OS.FreeBSD) {
	int *__error() {
		return &errno;
	}
}

// openbsd:
//int *__errno();

static if (plat_os == OS.Linux && plat_arch == Architecture.AMD64) {
	enum {
		EBADF = 9,
		EINVAL = 22,
		ERANGE = 34,
	}
}
