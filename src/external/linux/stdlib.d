module linux.stdlib;

import plat_version;
import syscaller;

extern (C):

static if (plat_arch == Architecture.AMD64) {
	void _Exit(int status) {
		syscall!60(status);
	}
}
