.section .text.startup
.global _start

_start:
    la sp, _stack_top
    call main

.global hang
hang:
    j hang

