.intel_syntax
.globl _start
.extern main

_start:
pop %rdi
mov %rsi, %rsp
call main

mov %rdi, %rax
mov %rax, 231 # sys_exit_group
syscall
