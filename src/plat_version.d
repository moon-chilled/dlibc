module plat_version;

enum Architecture {
	AMD64,
}

enum OS {
	Linux,
	FreeBSD,
}

version (X86_64) {
	enum plat_arch = Architecture.AMD64;
} else {
	pragma(error, "Unsupported arch");
}

version (linux) {
	enum plat_os = OS.Linux;
} else version (FreeBSD) {
	enum plat_os = OS.FreeBSD;
} else {
	static assert(0, "Unsupported os");
}


alias ssize_t = ptrdiff_t;
