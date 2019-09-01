module unistd;

import plat_version;

static if (plat_os == OS.Linux) {
	public import linux.unistd;
} else static if (plat_os == OS.FreeBSD) {
	public import freebsd.unistd;
}

extern (C):
