module dlibc.external.errnor;

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
} /*else static if (plat_os == OS.OpenBSD) {
	int *__errno() {
		return &errno;
	}
}*/

static if (plat_os == OS.Linux && plat_arch == Architecture.AMD64) {
	enum {
		EBADF = 9,
		EINVAL = 22,
		ERANGE = 34,
	}
}
