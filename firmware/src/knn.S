#include "dsq.h"
#include "irq.h"

.text
.globl main
main:
    
    li x5,0x05000000
    li x31,00000001
    sw x31,0(x5)
    
    li   x3, 130              # Total training images
    li   x4, 5                # K = 5
    li   x5, 8               # Test images
    li   x6, 0                # test_idx = 0

test_loop:
    bge  x6, x5, end

    la   x7, train_data
    la   x8, test_data
    li   x9, 68
    mul  x10, x6, x9
    add  x8, x8, x10          # test_ptr

    la   x11, dist_label_pairs
    la   x12, label_counts
    li   x13, 0               # train_idx

# Clear distance-label pairs
    li   x14, 0
clear_dlp:
    bge  x14, x4, after_clear
    slli x15, x14, 3
    add  x16, x11, x15
    sw   x0, 0(x16)
    sw   x0, 4(x16)
    addi x14, x14, 1
    j    clear_dlp

after_clear:
    li   x17, -1              # max_dist
    li   x18, -1              # max_idx

# ===================== Training Loop =====================
train_loop:
    bge  x13, x3, after_train
    lw   x19, 0(x7)           # train label
    addi x20, x7, 4           # train pixels
    addi x21, x8, 4           # test pixels
    li   x22, 0               # dist
    li   x23, 0

pix_loop:
    li   x24, 64
    bge  x23, x24, insert_k
    lw  x25, 0(x20)
    lw  x26, 0(x21)
    INSN_DSQ(27,25,26)
    add  x22, x22, x27
    addi x20, x20, 4
    addi x21, x21, 4
    addi x23, x23, 4
    j    pix_loop

insert_k:
    blt  x13, x4, store_new
    slli x28, x18, 3
    add  x29, x11, x28
    lw   x30, 0(x29)
    bge  x22, x30, next_train
    sw   x22, 0(x29)
    sw   x19, 4(x29)
    li   x17, -1
    li   x18, -1
    li   x31, 0

find_max:
    bge  x31, x4, next_train
    slli x28, x31, 3
    add  x29, x11, x28
    lw   x30, 0(x29)
    blt  x17, x30, set_max
    addi x31, x31, 1
    j    find_max
set_max:
    mv   x17, x30
    mv   x18, x31
    addi x31, x31, 1
    j    find_max

store_new:
    slli x28, x13, 3
    add  x29, x11, x28
    sw   x22, 0(x29)
    sw   x19, 4(x29)
    beqz x13, set_first
    lw   x30, 0(x29)
    blt  x17, x30, update_max
    j    next_train
set_first:
    mv   x17, x22
    mv   x18, x13
    j    next_train
update_max:
    mv   x17, x22
    mv   x18, x13

next_train:
    addi x7, x7, 68
    addi x13, x13, 1
    j    train_loop

# ===================== Voting =====================
after_train:
# Clear label_counts
    li   x13, 0
clear_labels:
    li   x14, 10
    bge  x13, x14, vote_loop
    slli x15, x13, 2
    add  x16, x12, x15
    sw   x0, 0(x16)
    addi x13, x13, 1
    j    clear_labels

vote_loop:
    li   x13, 0
    li   x14, 0               # max_votes
    li   x15, -1              # predicted label
vote_count:
    bge  x13, x4, check_all_one
    slli x16, x13, 3
    add  x17, x11, x16
    lw   x18, 4(x17)          # label
    slli x19, x18, 2
    add  x19, x12, x19
    lw   x20, 0(x19)
    addi x20, x20, 1
    sw   x20, 0(x19)
    blt  x14, x20, set_pred
    j    next_vote
set_pred:
    mv   x14, x20
    mv   x15, x18
next_vote:
    addi x13, x13, 1
    j    vote_count

# ===================== Check for Rule 2 =====================
check_all_one:
    li x13, 0
    li x21, 0
check_loop:
    bge x13, x4, rule2_check_done
    slli x22, x13, 3
    add  x23, x11, x22
    lw   x24, 4(x23)
    slli x25, x24, 2
    add  x25, x12, x25
    lw   x26, 0(x25)
    li   x27, 1
    bne  x26, x27, not_all_ones
    addi x21, x21, 1
    addi x13, x13, 1
    j    check_loop
not_all_ones:
    li x21, -1
rule2_check_done:
    beq x21, x4, fallback_nn

# ===================== Check if Tie Exists (Rule 3) =====================
    li   x13, 0
    li   x28, 0
    li   x29, -1
tie_loop:
    bge  x13, x4, check_tie_done
    slli x30, x13, 3
    add  x31, x11, x30
    lw   x20, 4(x31)
    slli x21, x20, 2
    add  x21, x12, x21
    lw   x22, 0(x21)
    blt  x28, x22, new_max
    beq  x28, x22, inc_max_count
    j    next_tie
new_max:
    mv   x28, x22
    li   x29, 1
    j    next_tie
inc_max_count:
    addi x29, x29, 1
next_tie:
    addi x13, x13, 1
    j tie_loop

check_tie_done:
    li x21, 1
    ble x29, x21, store_result

# ===================== Sort KNN =====================
    li   x13, 0
sort_outer:
    bge  x13, x4, pick_sorted_max
    mv   x14, x13
    addi x15, x13, 1
sort_inner:
    bge  x15, x4, sort_check
    slli x16, x14, 3
    add  x17, x11, x16
    lw   x18, 0(x17)
    slli x19, x15, 3
    add  x20, x11, x19
    lw   x21, 0(x20)
    blt  x21, x18, set_new_min
    j    skip_sort
set_new_min:
    mv x14, x15
skip_sort:
    addi x15, x15, 1
    j sort_inner
sort_check:
    beq x13, x14, skip_swap
    slli x22, x13, 3
    add  x23, x11, x22
    lw   x24, 0(x23)
    lw   x25, 4(x23)
    slli x26, x14, 3
    add  x27, x11, x26
    lw   x28, 0(x27)
    lw   x29, 4(x27)
    sw   x28, 0(x23)
    sw   x29, 4(x23)
    sw   x24, 0(x27)
    sw   x25, 4(x27)
skip_swap:
    addi x13, x13, 1
    j sort_outer

pick_sorted_max:
    li   x13, 0
    li   x28, -1
pick_loop:
    bge  x13, x4, store_result
    slli x29, x13, 3
    add  x30, x11, x29
    lw   x31, 4(x30)
    slli x20, x31, 2
    add  x20, x12, x20
    lw   x21, 0(x20)
    blt  x28, x21, update_final
    j    next_final
update_final:
    mv x28, x21
    mv x15, x31
next_final:
    addi x13, x13, 1
    j pick_loop

# ===================== Fallback (Rule 2) =====================
fallback_nn:
    li   x13, 0
    li   x27, 0
fallback_loop:
    bge  x13, x4, store_result
    slli x28, x13, 3
    add  x29, x11, x28
    lw   x30, 0(x29)
    blt  x27, x30, skip_fb
    mv   x27, x30
    lw   x15, 4(x29)
skip_fb:
    addi x13, x13, 1
    j fallback_loop

# ===================== Store Predicted Label =====================
store_result:
    la   x16, Predicted_label
    slli x17, x6, 2
    add  x16, x16, x17
    sw   x15, 0(x16)
    
    li   x18, 0x20020000       # UART
    sw   x15, 4(x18)
    
    # LED output                #to display the index of test image
    li   x2, 0x05000000
    sw   x15, 0(x2)             # stores the index/ counter value of x30

    # Program timer and wait for interrupt to create delay between outputs
#ifdef TARGET_FPGA
    # ~0.5s delay for FPGA (assuming 100MHz clock)
    li   x10, 100000000 / 2
#else
    # 8 cycle delay for sim
    li   x10, 8
#endif

    picorv32_timer_insn(x0, x10)
timer_wait_irq0:
    picorv32_waitirq_insn(x31)
    andi x31, x31, 1
    beqz x31, timer_wait_irq0

    addi x6, x6, 1
    j    test_loop

end:    
    li   x5, 0x05000000  
    li  x31,10000000
    sw   x31, 0(x5)
    j hang
