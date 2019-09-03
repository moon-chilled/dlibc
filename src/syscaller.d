module syscaller;

import plat_version;
import errnor;

//TODO:	fix error detection under freebsd (on error, it sets carry flag and puts the error code into rax)
//	probably want to bring it out into its own function, even if it's mostly the same, in order to
//	avoid too much branching in something that's already too complicated for its own good (like this)

//TODO: no compiler likes inlining functions which have inline asm, so turn this into a mixin template
static if ((plat_os == OS.Linux || plat_os == OS.FreeBSD) && plat_arch == Architecture.AMD64) {
	pragma(inline, false) extern (C) long syscall(long which, T...)(T args) {
		long ret_from_syscall;

		asm {
			mov RAX, which;
		}

		/*
		 * as it turns out, by a mad co-incidence (;o), the parameter
		 * locations for syscalls (under linux/fbsd) and for calling
		 * functions (under sysv/amd64) is almost the same.  The only
		 * difference is the 4th parameter, which is R10 for syscalls
		 * but RCX for functions.  That means that all the other
		 * parameters are /already where they need to be/!  Magic!!
		 */
		static if (args.length >= 4) {
			asm {
				mov R10, RCX;
			}
		}

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
