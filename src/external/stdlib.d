module stdlib;

import plat_version;
static if (plat_os == OS.Linux) {
	import linux.stdlib;
}
public import allocator;

extern (C):

// TODO: atexit()
void exit(int status) {
	_Exit(status);
}
