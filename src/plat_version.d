module plat_version;

enum Architecture {
	AMD64,
}

enum OS {
	Linux,
}

version (X86_64) {
	enum plat_arch = Architecture.AMD64;
} else {
	pragma(error, "Unsupported arch");
}

version (linux) {
	enum plat_os = OS.Linux;
} else {
	pragma(error, "Unsupported os");
}