.section .text.startup
.global _start

#include "irq.h"

_start:
    # Make sure all interrupts are masked.
    li   t0, -1            # 0xFFFFFFFF
    picorv32_maskirq_insn(t0, t0)

    call main

.global hang
hang:
    j hang

