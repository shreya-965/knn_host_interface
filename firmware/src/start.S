.section .text.startup
.global _start

#include "irq.h"

_start:
    # GPIO init: set all pins to output (0)
    li   t6, 0x05000000    # GPIO register
    li   t0, 0x0
    sw   t0, 4(t6)

    # Make sure all interrupts are masked.
    li   t0, -1            # 0xFFFFFFFF
    picorv32_maskirq_insn(t0, t0)

    call main

.global hang
hang:
    j hang

