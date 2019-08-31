module linux.unistd;

import plat_version;
import syscaller;

extern (C):

static if (plat_arch == Architecture.AMD64) {
	void exit_group(int status) {
		syscall(231, status);
	}
}
