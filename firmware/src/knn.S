#include "dsq.h"
#include "irq.h"

#ifdef RTL_VERSION_1_1
    .equ UART_BASE, 0x03000000
    .equ UART_LSR_OFFSET, 0xC
    .equ UART_LSR_THRE_MASK, 0x20
    .equ UART_RBR_THR_DLL_OFFSET, 0x0
#else
    .equ UART_BASE, 0x20020000
    .equ UART_TX_OFFSET, 0x4
    .equ TX_EMPTY_MASK, 0x4
#endif

.equ GPIO_BASE , 0x05000000

.text
.globl main
main:

    li   t0, GPIO_BASE
    li   t6, 1
    sw   t6, 0(t0)

    li   s1, 130              # Total training images
    li   s2, 5                # K = 5
    li   s3, 8                # Test images
    li   s4, 0                # test_idx = 0

test_loop:
    bge  s4, s3, end

    la   s5, train_data
    la   s6, test_data
    li   t0, 68
    mul  t1, s4, t0
    add  s6, s6, t1           # test_ptr

    la   s7, dist_label_pairs
    la   s8, label_counts
    li   s9, 0                # train_idx

# Clear distance-label pairs
    li   t2, 0
clear_dlp:
    bge  t2, s2, after_clear
    slli t3, t2, 3
    add  t4, s7, t3
    sw   zero, 0(t4)
    sw   zero, 4(t4)
    addi t2, t2, 1
    j    clear_dlp

after_clear:
    li   s10, -1              # max_dist
    li   s11, -1              # max_idx

# ===================== Training Loop =====================
train_loop:
    bge  s9, s1, after_train
    lw   a7, 0(s5)            # train label
    addi t5, s5, 4            # train pixels
    addi t6, s6, 4            # test pixels
    li   a1, 0                # dist
    li   a2, 0

pix_loop:
    li   a3, 64
    bge  a2, a3, insert_k
    lw   a4, 0(t5)
    lw   a5, 0(t6)
    INSN_DSQ(16,14,15)
    add  a1, a1, a6
    addi t5, t5, 4
    addi t6, t6, 4
    addi a2, a2, 4
    j    pix_loop

insert_k:
    blt  s9, s2, store_new
    slli t3, s11, 3
    add  t4, s7, t3
    lw   t5, 0(t4)
    bge  a1, t5, next_train
    sw   a1, 0(t4)
    sw   a7, 4(t4)
    li   s10, -1
    li   s11, -1
    li   t6, 0

find_max:
    bge  t6, s2, next_train
    slli t3, t6, 3
    add  t4, s7, t3
    lw   t5, 0(t4)
    blt  s10, t5, set_max
    addi t6, t6, 1
    j    find_max
set_max:
    mv   s10, t5
    mv   s11, t6
    addi t6, t6, 1
    j    find_max

store_new:
    slli t3, s9, 3
    add  t4, s7, t3
    sw   a1, 0(t4)
    sw   a7, 4(t4)
    beqz s9, set_first
    lw   t5, 0(t4)
    blt  s10, t5, update_max
    j    next_train
set_first:
    mv   s10, a1
    mv   s11, s9
    j    next_train
update_max:
    mv   s10, a1
    mv   s11, s9

next_train:
    addi s5, s5, 68
    addi s9, s9, 1
    j    train_loop

# ===================== Voting =====================
after_train:
# Clear label_counts
    li   s9, 0
clear_labels:
    li   t2, 10
    bge  s9, t2, vote_loop
    slli t3, s9, 2
    add  t4, s8, t3
    sw   zero, 0(t4)
    addi s9, s9, 1
    j    clear_labels

vote_loop:
    li   s9, 0
    li   t2, 0               # max_votes
    li   s0, -1              # predicted label
vote_count:
    bge  s9, s2, check_all_one
    slli t3, s9, 3
    add  t4, s7, t3
    lw   t5, 4(t4)           # label
    slli t6, t5, 2
    add  t6, s8, t6
    lw   a0, 0(t6)
    addi a0, a0, 1
    sw   a0, 0(t6)
    blt  t2, a0, set_pred
    j    next_vote
set_pred:
    mv   t2, a0
    mv   s0, t5
next_vote:
    addi s9, s9, 1
    j    vote_count

# ===================== Check for Rule 2 =====================
check_all_one:
    li   s9, 0
    li   t0, 0
check_loop:
    bge  s9, s2, rule2_check_done
    slli t1, s9, 3
    add  t2, s7, t1
    lw   t3, 4(t2)
    slli t4, t3, 2
    add  t4, s8, t4
    lw   t5, 0(t4)
    li   t6, 1
    bne  t5, t6, not_all_ones
    addi t0, t0, 1
    addi s9, s9, 1
    j    check_loop
not_all_ones:
    li   t0, -1
rule2_check_done:
    beq  t0, s2, fallback_nn

# ===================== Check if Tie Exists (Rule 3) =====================
    li   s9, 0
    li   t3, 0
    li   t4, -1
tie_loop:
    bge  s9, s2, check_tie_done
    slli t5, s9, 3
    add  t6, s7, t5
    lw   a0, 4(t6)
    slli a1, a0, 2
    add  a1, s8, a1
    lw   a2, 0(a1)
    blt  t3, a2, new_max
    beq  t3, a2, inc_max_count
    j    next_tie
new_max:
    mv   t3, a2
    li   t4, 1
    j    next_tie
inc_max_count:
    addi t4, t4, 1
next_tie:
    addi s9, s9, 1
    j    tie_loop

check_tie_done:
    li   t0, 1
    ble  t4, t0, store_result

# ===================== Sort KNN =====================
    li   s9, 0
sort_outer:
    bge  s9, s2, pick_sorted_max
    mv   t0, s9
    addi t1, s9, 1
sort_inner:
    bge  t1, s2, sort_check
    slli t2, t0, 3
    add  t3, s7, t2
    lw   t4, 0(t3)
    slli t5, t1, 3
    add  t6, s7, t5
    lw   a0, 0(t6)
    blt  a0, t4, set_new_min
    j    skip_sort
set_new_min:
    mv   t0, t1
skip_sort:
    addi t1, t1, 1
    j    sort_inner
sort_check:
    beq  s9, t0, skip_swap
    slli a1, s9, 3
    add  a2, s7, a1
    lw   a3, 0(a2)
    lw   a4, 4(a2)
    slli a5, t0, 3
    add  a6, s7, a5
    lw   a7, 0(a6)
    lw   t2, 4(a6)
    sw   a7, 0(a2)
    sw   t2, 4(a2)
    sw   a3, 0(a6)
    sw   a4, 4(a6)
skip_swap:
    addi s9, s9, 1
    j    sort_outer

pick_sorted_max:
    li   s9, 0
    li   t3, -1
pick_loop:
    bge  s9, s2, store_result
    slli t4, s9, 3
    add  t5, s7, t4
    lw   t6, 4(t5)
    slli a0, t6, 2
    add  a0, s8, a0
    lw   a1, 0(a0)
    blt  t3, a1, update_final
    j    next_final
update_final:
    mv   t3, a1
    mv   s0, t6
next_final:
    addi s9, s9, 1
    j    pick_loop

# ===================== Fallback (Rule 2) =====================
fallback_nn:
    li   s9, 0
    li   t2, 0x7fffffff
fallback_loop:
    bge  s9, s2, store_result
    slli t3, s9, 3
    add  t4, s7, t3
    lw   t5, 0(t4)
    bge  t5, t2, skip_fb
    mv   t2, t5
    lw   s0, 4(t4)
skip_fb:
    addi s9, s9, 1
    j    fallback_loop

# ===================== Store Predicted Label =====================
store_result:
    la   t0, Predicted_label
    slli t1, s4, 2
    add  t0, t0, t1
    sw   s0, 0(t0)

    mv   a0, s0
    call uart_write_u8

    # LED output to display the predicted label.
    li   t0, GPIO_BASE
    sw   s0, 0(t0)

    # Program timer and wait for interrupt to create delay between outputs
#ifdef TARGET_FPGA
    # ~0.5s delay for FPGA (assuming 100MHz clock)
    li   t1, 100000000 / 2
#else
    # 8 cycle delay for sim
    li   t1, 8
#endif

    picorv32_timer_insn(zero, t1)
timer_wait_irq0:
    picorv32_waitirq_insn(t2)
    andi t2, t2, 1
    beqz t2, timer_wait_irq0

    addi s4, s4, 1
    j    test_loop

end:
    li   t0, GPIO_BASE
    li   t6, 0b10000000
    sw   t6, 0(t0)
    j    hang

#ifdef RTL_VERSION_1_1
uart_write_u8:
    li   t0, UART_BASE
uart_wait_thre:
    lbu  t1, UART_LSR_OFFSET(t0)
    andi t1, t1, UART_LSR_THRE_MASK
    beqz t1, uart_wait_thre
    sb   a0, UART_RBR_THR_DLL_OFFSET(t0)
    ret
#else
uart_write_u8:
    li   t0, UART_BASE
uart_wait_tx_empty:
    lw   t1, 0x8(t0)
    andi t1, t1, TX_EMPTY_MASK
    beq  t1, zero, uart_wait_tx_empty
    sb   a0, UART_TX_OFFSET(t0)
    ret
#endif