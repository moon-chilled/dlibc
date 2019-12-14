module dlibc.external.strings;

import plat_version;

extern (C):
//TODO: make fast
void bcopy(const(void) *src, void *dest, size_t n) {
	while (n > ulong.sizeof) {
		*cast(ulong*)dest = *cast(ulong*)src;
		dest = cast(ulong*)dest + 1;
		src = cast(ulong*)src + 1;
		n -= ulong.sizeof;
	}

	while (n > 1) {
		*cast(ubyte*)dest = *cast(ubyte*)src;
		dest = cast(ubyte*)dest + 1;
		src = cast(ubyte*)src + 1;
		n -= 1;
	}
}
