module syscaller;

import plat_version;
import errnor;

//TODO: fix error detection under freebsd (on error, it sets carry flag and puts the error code into rax)
//TODO: no compiler likes inlining functions which have inline asm, so turn this into a mixin template
static if ((plat_os == OS.Linux || plat_os == OS.FreeBSD) && plat_arch == Architecture.AMD64) {
	long syscall(T...)(long which, T args) {
		enum param_regs64 = ["RDI", "RSI", "RDX", "R10",  "R8",   "R9"];
		enum param_regs32 = ["EDI", "ESI", "EDX", "R10D", "R8D", "R9D"];
		enum param_regs16 = ["DI",  "SI",  "DX",  "R10W", "R8W", "R9W"];
		enum param_regs08 = ["DIL", "SIL", "DL",  "R10B", "R8B", "R9B"];
		enum param_regserror = []; // indexing into this should cause a compile-time error

		asm {
			mov RAX, which;
		}

		static foreach (i; 0 .. args.length) {
			mixin("asm {
				mov " ~ ((args[i].sizeof == 8) ? param_regs64 :
					 (args[i].sizeof == 4) ? param_regs32 :
					 (args[i].sizeof == 2) ? param_regs16 :
					 (args[i].sizeof == 1) ? param_regs08 :
					 param_regserror)[i] ~ ",
					 args[" ~ i.stringof ~ "];
				}");
		}


		long ret_from_syscall;
		asm {
			syscall;

			cmp RAX, -4096;
			jl error;

			mov RSP, RBP;
			pop RBP;
			ret;

			// mov errno, -RAX does not work because errno is global and we are PIC.
			// The error path is not performance-critical so I'm ok with this moderate
			// indirection.  Fixes could include figuring out how to PIC from assembly
			// or giving up PIC and forcing only static linkage, but I think this is fine.
error:
			mov ret_from_syscall, RAX;
		}

		errno = cast(int)-ret_from_syscall;
		return -1;
	}
}
