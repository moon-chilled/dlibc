module errnor;

import plat_version;

extern (C) __gshared int errno;

static if (plat_os == OS.Linux && plat_arch == Architecture.AMD64) {
	enum {
		EBADF = 9,
		EINVAL = 22,
	}
}
