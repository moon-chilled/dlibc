import plat_version;
import unistd;

extern (C):
	
void _start() {
	int x = 15;

	exit_group(x);
}
