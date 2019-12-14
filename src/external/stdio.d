module stdio;

import allocator;
import errno_;
import fcntl;
import plat_version;
import string;
import unistd;

__gshared extern (C):

//TODO: on linux/glibc, stdin/out/err are declared as 'extern FILE *whatever'
// but on other platforms, this is not the case.  On freebsd, for instance,
// stdio.h says 'extern FILE __sF[]; #define stdin   (&__sF[0])' (then stdout,
// stderr in following indices).  Figure out what other platforms do.

struct FILE {
	int fd;
	bool eof = false;
	bool error = false;
}

FILE __stdin = {fd:0};
FILE __stdout = {fd:1};
FILE __stderr = {fd:2};

static if (plat_os == OS.Linux) {
	FILE *stdin = &__stdin;
	FILE *stdout = &__stdout;
	FILE *stderr = &__stderr;
} else static if (plat_os == OS.FreeBSD) {
	FILE[3] __sF = [__stdin, __stdout, __stderr];
}

enum EOF = -1;

FILE *fopen(const(char) *pathname, const(char) *mode) {
	int flags;

	//TODO: handle 'b' correctly on windows (do newline re-adjustment unless 'b' is there)
	if (!strcmp(mode, "r") || !strcmp(mode, "rb")) {
		flags = O_RDONLY;
	} else if (!strcmp(mode, "r+") || !strcmp(mode, "rb+") || !strcmp(mode, "r+b")) {
		flags = O_RDWR;
	} else if (!strcmp(mode, "w") || !strcmp(mode, "wb")) {
		flags = O_WRONLY | O_CREAT | O_TRUNC;
	} else if (!strcmp(mode, "w+") || !strcmp(mode, "wb+") || !strcmp(mode, "w+b")) {
		flags = O_RDWR | O_CREAT | O_TRUNC;
	} else if (!strcmp(mode, "a") || !strcmp(mode, "ab")) {
		flags = O_WRONLY | O_CREAT | O_APPEND;
	} else if (!strcmp(mode, "a+") || !strcmp(mode, "ab+") || !strcmp(mode, "a+b")) {
		flags = O_RDWR | O_CREAT | O_APPEND;
	} else {
		errno = Errno.EINVAL;
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
		errno = Errno.EBADF;
		return -1;
	}

	if ((fflush(stream) < 0) || (close(stream.fd) < 0)) {
		free(stream);
		return -1;
	}

	free(stream);
	return 0;
}


//TODO: automatically generate these locked stdio funcs

// !IMPORTANT!
// all stdio is implemented in terms of the *_unlocked() functions
// at no point should a _unlocked() function _EVER_ generate a call to a stdio
// function which isn't _unlocked().  Otherwise, the whole program will freeze up.

// getc has the same behaviour as fgetc, except that is may be a macro that evaluates its stream multiple times.
// so the platform may implement it in a header, but in case it doesn't: here you go
int function(FILE*) getc_unlocked = &fgetc_unlocked;
int function(FILE*) getc = &fgetc;

int getchar_unlocked() {
	return getc_unlocked(stdin);
}
int getchar() {
	flockfile(stdin);
	auto ret = getchar_unlocked();
	funlockfile(stdin);
	return ret;
}

// putc is analogous to getc
int function(int, FILE*) putc_unlocked = &fputc_unlocked;
int function(int, FILE*) putc = &fputc;

// int putchar_unlocked(int c)
int putchar_unlocked(int c) {
	return fputc(c, stdout);
}
int putchar(int c) {
	flockfile(stdout);
	auto ret = putchar_unlocked(c);
	funlockfile(stdout);
	return ret;
}

void clearerr_unlocked(FILE *stream) {
	flockfile(stream);
	stream.eof = stream.error = false;
	funlockfile(stream);
}
void function(FILE*) clearerr = &clearerr_unlocked;

int feof_unlocked(FILE *stream) {
	return stream.eof;
}
int function(FILE*) feof = &feof_unlocked;

//TODO: set appropriately
int ferror_unlocked(FILE *stream) {
	return stream.error;
}
int function(FILE*) ferror = &ferror_unlocked;

int fileno_unlocked(FILE *stream) {
	return stream.fd;
}
int function(FILE*) fileno = &fileno_unlocked;

//TODO: add buffering so this is useful
int fflush_unlocked(FILE *stream) {
	// or other reasons why stream might be bad
	if (!stream) {
		errno = Errno.EBADF;
		return EOF;
	}

	return 0;
}
int fflush(FILE *stream) {
	flockfile(stream);
	auto ret = fflush_unlocked(stream);
	funlockfile(stream);
	return ret;
}

int fgetc_unlocked(FILE *stream) {
	char ret;
	fread(&ret, 1, 1, stream);
	return ret;
}
int fgetc(FILE *stream) {
	flockfile(stream);
	auto ret = getc_unlocked(stream);
	funlockfile(stream);
	return ret;
}

int fputc_unlocked(int c, FILE *stream) {
	char r = cast(char)c;
	if (!fwrite_unlocked(&r, 1, 1, stream)) {
		return EOF;
	} else {
		return c;
	}
}
int fputc(int c, FILE *stream) {
	flockfile(stream);
	auto ret = fputc_unlocked(c, stream);
	funlockfile(stream);
	return ret;
}

size_t fread_unlocked(void *ptr, size_t size, size_t nmemb, FILE *stream) {
	// size * nmemb would overflow
	if (size > (size_t.max / nmemb)) {
		return 0;
	}
	// no point in doing anything
	if ((size * nmemb) == 0) {
		return 0;
	}

	ssize_t bytes_read = read(stream.fd, ptr, size * nmemb);
	if (bytes_read == 0) {
		stream.eof = true;
	} else if (bytes_read < 0) {
		// TODO: check errno, act appropriately
		return 0;
	}

	return bytes_read / size;
}
size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream) {
	flockfile(stream);
	auto ret = fread_unlocked(ptr, size, nmemb, stream);
	funlockfile(stream);
	return ret;
}

size_t fwrite_unlocked(const void *ptr, size_t size, size_t nmemb, FILE *stream) {
	// overflow
	if (size > (size_t.max / nmemb)) {
		return 0;
	}
	// pointless
	if ((size * nmemb) == 0) {
		return 0;
	}

	ssize_t bytes_written = write(stream.fd, ptr, size * nmemb);
	if (bytes_written < 0) {
		//TODO: handle errno
		return 0;
	}

	return bytes_written / size;
}
size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream) {
	flockfile(stream);
	auto ret = fwrite_unlocked(ptr, size, nmemb, stream);
	funlockfile(stream);
	return ret;
}


//TODO: make this work once threads are a thing
void flockfile(FILE *filehandle) {
}
int ftrylockfile(FILE *filehandle) {
	return 0; // 1 => failure (can't obtain lock)
}
void funlockfile(FILE *filehandle) {
}
