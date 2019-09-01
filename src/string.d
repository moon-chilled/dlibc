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
