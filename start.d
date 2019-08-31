extern (C) void _start() {
	long x = 15;

	asm {
		mov RAX, 231;
		mov RDI, x;
		syscall;
	}
}
