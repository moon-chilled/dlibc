module string;

import plat_version;

extern (C):
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
