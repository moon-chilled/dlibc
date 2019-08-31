.intel_syntax
.global _start
.extern main

_start:
mov %rax, 231 #exit_group.  Quits all threads (not just the current one)
mov %rdi, 17  #exit value
syscall
