module string;

import plat_version;
import errno_;

extern (C):
__gshared:

//TODO: make fast
void *memset(void *s, int c, size_t n) {
	ubyte *ss = cast(ubyte*)s;
	while (n --> 0) {
		ss[n] = cast(ubyte)c;
	}
	return s;
}
//TODO: make fast
int strcmp(const(char) *s1, const(char) *s2) {
	while (*s1 && *s2) {
		if (*s1 > *s2) {
			return 1;
		} else if (*s1 < *s2) {
			return -1;
		}
		s1++;
		s2++;
	}

	if (*s1 == *s2) {
		return 0;
	// s1 is longer
	} else if (*s1) {
		return 1;
	// s2 is longer
	} else if (*s2) {
		return -1;
	}

	assert(0); // stupid compiler
}

void *memcpy(void *dest, const(void) *src, size_t n) {
	while (n % size_t.sizeof) {
		*cast(ubyte*)dest = *cast(ubyte*)src;
		dest = cast(ubyte*)dest + 1;
		src = cast(ubyte*)src + 1;
		n--;
	}

	size_t words_to_copy = n / size_t.sizeof;
	while (words_to_copy) {
		*cast(size_t*)dest = *cast(size_t*)src;
		dest = cast(size_t*)dest + 1;
		src = cast(size_t*)src + 1;
		words_to_copy--;
	}

	return dest;
}

int strncmp(const(char) *s1, const (char) *s2, size_t n) {
	while (*s1 && *s2 && n --> 0) {
		if (*s1 > *s2) {
			return 1;
		} else if (*s1 < *s2) {
			return -1;
		}
		s1++;
		s2++;
	}

	if (*s1 == *s2) {
		return 0;
	// s1 is longer
	} else if (*s1) {
		return 1;
	// s2 is longer
	} else if (*s2) {
		return -1;
	}

	assert(0); // stupid compiler
}
// TODO: make fast
size_t strlen(const(char) *s) {
	size_t ret;
	while (*s++) ret++;
	return ret;
}
//TODO: make fast
char *strcpy(char *dest, const(char) *src) {
	char *og_dest = dest;
	while (*src) {
		*dest++ = *src++;
	}
	return og_dest;
}


// strerror() comes from dlibc.internal.<plat>.errno_, because different platforms have different sets of error codes

int __xsi_strerror_r(int errnum, char *buf, size_t buflen) {
	char *ret = strerror(errnum);
	size_t len;
	memcpy(buf, ret, max(len = strlen(ret), buflen));
	if (len > buflen) return errno = Errno.ERANGE;
	return 0;
}

char *__gnu_strerror_r(int errnum, char *buf, size_t buflen) {
	char *ret = strerror(errnum);
	size_t len;
	memcpy(buf, ret, max(strlen(ret), buflen));
	return buf;
}

static if (plat_os == OS.Linux) {
	// TODO: on musl, strerror_r() is __xsi_strerror_r(), and there is no __gnu_strerror_r().
	int function(int, char*, size_t) __xpg_strerror_r = &__xsi_strerror_r;
	char *function(int, char*, size_t) strerror_r = &__gnu_strerror_r;
} else static if (plat_os == OS.FreeBSD /*|| plat_os == OS.OpenBSD*/) {
	int function(int, char*, size_t) strerror_r = &__xsi_strerror_r;
}
