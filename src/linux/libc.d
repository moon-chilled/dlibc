module linux.libc;
import linux.unistd;

extern (C):

void __stack_chk_fail() {
	enum msg = "ERROR Stack overflowed.\0";
	write(1, msg.ptr, msg.length);
	exit_group(-1);
}
