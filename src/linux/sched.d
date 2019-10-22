module linux.sched;

import plat_version;
import syscaller;

extern (C):

static if (plat_arch == Architecture.AMD64) {
	int sched_get_priority_max(int policy) {
		return cast(int)syscall!146(policy);
	}
	int sched_get_priority_min(int policy) {
		return cast(int)syscall!147(policy);
	}
}
