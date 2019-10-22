module stdio;

import allocator;
import errnor;
import fcntl;
import plat_version;
import string;
import unistd;

static if (plat_os == OS.Linux) {
	public import linux.stdio;
}

__gshared extern (C):

//TODO: on linux, stdin/out/err are declared as 'extern FILE *whatever'
// but on other platforms, this is not the case.  On freebsd, for instance,
// stdio.h says 'extern FILE __sF[]; #define stdin   (&__sF[0])' (then stdout,
// stderr in following indices)

struct FILE {
	int fd;
}
FILE __stdin = {fd:0};
FILE __stdout = {fd:1};
FILE __stderr = {fd:2};
FILE *stdin = &__stdin;
FILE *stdout = &__stdout;
FILE *stderr = &__stderr;

FILE *fopen(const(char) *pathname, const(char) *mode) {
	int flags;

	//TODO: handle 'b' correctly on windows (do newline re-adjustment unless 'b' is there)
	if (!strcmp(mode, "r") || !strcmp(mode, "rb")) {
		flags = O_RDONLY;
	} else if (!strcmp(mode, "r+") || !strcmp(mode, "r+b") || !strcmp(mode, "rb+")) {
		flags = O_RDWR;
	} else {
		errno = EINVAL;
		return null;
	}

	// 0x1b6 == 0o666
	int fd = open(pathname, flags, 0x1b6);
	if (fd < 0) {
		return null;
	}

	FILE *ret = cast(FILE*)malloc(FILE.sizeof);
	if (!ret) return null;

	ret.fd = fd;
	return ret;
}

int fclose(FILE *stream) {
	if (!stream) {
		errno = EBADF;
		return -1;
	}

	if (close(stream.fd) < 0) {
		free(stream);
		return -1;
	}

	free(stream);
	return 0;
}

/*
size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream) {
	if (
	*/
