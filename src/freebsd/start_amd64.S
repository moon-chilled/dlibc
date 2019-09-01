.intel_syntax
.globl _start
.extern main

_start:
lea %rsi, [%rdi+8]
mov %rdi, [%rdi]
call main

mov %rdi, %rax
mov %rax, 1 # AUE_EXIT
syscall
