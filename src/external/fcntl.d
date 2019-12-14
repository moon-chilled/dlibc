module dlibc.external.fcntl;

import plat_version;

static if (plat_os == OS.Linux) {
	public import linux.fcntl;
}

extern (C):
