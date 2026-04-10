#include "rtl_platform.inc"

.section .text
.global gpio_init
.global uart_init
.global uart_write_u8

gpio_init:
    ret
    
# UART base comes from rtl_platform.inc
uart_init:
    li   t0, UART_BASE
    li   t1, 0x80
    sb   t1, UART_LCR_OFFSET(t0)

    li   t1, 0x00
    sb   t1, UART_DLM_IER_OFFSET(t0)
    li   t1, 0x36
    sb   t1, UART_RBR_THR_DLL_OFFSET(t0)

    li   t1, 0x03
    sb   t1, UART_LCR_OFFSET(t0)

    li   t1, 0xC6
    sb   t1, UART_FCR_IIR_OFFSET(t0)
    ret

# a0 = byte
uart_write_u8:
    li   t0, UART_BASE
uart_wait_thre:
    lbu  t1, UART_LSR_OFFSET(t0)
    andi t1, t1, UART_LSR_THRE_MASK
    beqz t1, uart_wait_thre
    sb   a0, UART_RBR_THR_DLL_OFFSET(t0)
    ret

#ifdef FLASH_PATH
.global flash_init
.global flash_prepare
.global flash_read_words

# Flash base comes from rtl_platform.inc
flash_init:
    ret

# No dynamic arguments needed
flash_prepare:
    li   t0, FLASH_INIT_DELAY_LOOPS
flash_delay_loop:
    addi t0, t0, -1
    bnez t0, flash_delay_loop
    ret

# a0 = flash_offset, a1 = dst_ptr, a2 = word_count
flash_read_words:
    beqz a2, flash_read_done
    li   t2, FLASH_IF_BASE
    add  t0, t2, a0
flash_read_loop:
    lw   t1, 0(t0)
    sw   t1, 0(a1)
    addi t0, t0, 4
    addi a1, a1, 4
    addi a2, a2, -1
    bnez a2, flash_read_loop
flash_read_done:
    ret
#endif
