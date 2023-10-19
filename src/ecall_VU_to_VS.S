#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

# Overwrite trap_vector
la t1, trap_vector_overwrite
csrw vstvec, t1
# Delegate USER_ECALL
li t1, 0x100
csrw medeleg, t1
csrw hedeleg, t1

# Set MPP to User (0b00) & MPV to 0b1
csrr t1, mstatus
li t2, 0xffffff7fffffe7ff
and t1, t1, t2
li t2, 0x0000008000000000
or t1, t1, t2
csrw mstatus, t1
# Load address into exception program counter
la t1, do_ecall
csrw mepc, t1
# Return into VU-mode
mret
unimp

do_ecall:
    ecall
    ret
    unimp

trap_vector_overwrite:
    csrr t0, scause
    li t1, CAUSE_USER_ECALL
    beq t0, t1, success
    mv  TESTNUM, t0
    j fail
    unimp

success:
    # RVTEST_PASS uses ecall and stops working after xtvec is overwritten
    fence
    la t0, tohost
    li TESTNUM, 0x1
    sw TESTNUM, 0(t0)
    sw zero, 4(t0)
    unimp

fail:
    # RVTEST_FAIL uses ecall and stops working after xtvec is overwritten
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
