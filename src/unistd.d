module unistd;

import plat_version;

static if (plat_os == OS.Linux) {
	public import linux.unistd;
}

extern (C):
