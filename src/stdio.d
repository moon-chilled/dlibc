module stdio;

import plat_version;

static if (plat_os == OS.Linux) {
	public import linux.stdio;
}

extern (C):
