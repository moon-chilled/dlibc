module dlibc.external.assert_;

import plat_version;
import unistd;

extern (C):
void __assert(const(char) *file, int line, const(char) *msg) {
	//fprintf(stderr, "Assertion failure at %s:%d - '%s'\n", file, line, msg);
	//fflush(stderr);
	//abort();
	_Exit(-1);
}
