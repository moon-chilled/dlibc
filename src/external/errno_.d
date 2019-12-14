module errno_;
import plat_version;

static if (plat_os == OS.Linux) {
	public import linux.errno_;
	public import internal.linux.errno_;
}

extern (C):
__gshared int errno;

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
