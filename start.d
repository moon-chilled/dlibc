import plat_version;

extern (C):
	
void _start() {
	long x = 15;

	exit_group(x);
}

static if (plat_os == OS.Linux) {
	static if (plat_arch == Architecture.AMD64) {
		extern (D) pragma(inline, true) long syscall(T...)(long which, T args) {
			enum param_regs = ["RDI", "RSI", "RDX", "R10", "R8", "R9"];

			asm {
				mov RAX, which;
			}

			static foreach (i; 0 .. args.length) {
				mixin("asm {
					mov " ~ param_regs[i] ~ ", args[" ~ i.stringof ~ "];
					}");
			}
			asm { syscall; }

			asm { ret; }
		}
		void exit_group(long status) {
			syscall(231, status);
		}
	}
}
