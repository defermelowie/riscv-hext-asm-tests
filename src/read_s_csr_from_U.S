#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

# Overwrite trap_vector
la t1, trap_vector_overwrite
csrw mtvec, t1

# Go to U-mode
csrr t1, mstatus
li t2, 0xffffff7fffffe7ff
and t1, t1, t2
li t2, 0x0000000000000000
or t1, t1, t2
csrw mstatus, t1
la t1, ucode
csrw mepc, t1
mret
unimp

ucode:
    csrr t0, sstatus # Illegal access should trigger illegal instruction exception
    unimp

trap_vector_overwrite:
    csrr t0, mcause
    li t1, CAUSE_ILLEGAL_INSTRUCTION
    beq t0, t1, success
    mv  TESTNUM, t0
    j fail
    unimp

# RVTEST_PASS macro uses ecall and stops working after xtvec is overwritten
success:
    fence
    la t0, tohost
    li TESTNUM, 0x1
    sw TESTNUM, 0(t0)
    sw zero, 4(t0)
    unimp

# RVTEST_FAIL macro uses ecall and stops working after xtvec is overwritten
fail:
    fence
    la t0, tohost
    sll TESTNUM, TESTNUM, 1
    or TESTNUM, TESTNUM, 1
    sw TESTNUM, 0(t0)
    sw zero, 4(t0)
    unimp

RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
