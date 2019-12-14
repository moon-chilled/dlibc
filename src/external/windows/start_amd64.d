// basic windows startup code
enum STD_OUTPUT_HANDLE = 0xFFFFFFF5;
alias HANDLE = void*;
extern (Windows) HANDLE GetStdHandle(uint stdHandle);
extern (Windows) int WriteFile(HANDLE file, const(char) *data, uint length, uint *written, void *overlapped = null);
extern (Windows) int mainCRTStartup() {
	auto result = GetStdHandle(STD_OUTPUT_HANDLE);
	uint written;
	WriteFile(result, "Hello!".ptr, 6, &written);
	return 0;
}
