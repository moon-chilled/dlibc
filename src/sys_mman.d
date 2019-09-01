module sys_mman;

import plat_version;

static if (plat_os == OS.Linux) {
	public import linux.sys_mman;
}

extern (C):
