#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

# Overwrite trap_vector
la t1, trap_vector_overwrite
csrw stvec, t1
# Delegate VIRTUAL_SUPERVISOR_ECALL
li t1, 0x400
csrw medeleg, t1

# Return into VS-mode
la a0, do_ecall
RVTEST_MRET_VS(a0)
unimp

do_ecall:
    ecall
    ret

.align 2
trap_vector_overwrite:
    csrr t0, scause
    li t1, CAUSE_VIRTUAL_SUPERVISOR_ECALL
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
