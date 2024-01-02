#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

# Go to U-mode
la t1, ucode
RVTEST_MRET_U(t1)
unimp

ucode:
    csrr t0, sstatus # Illegal access should trigger illegal instruction exception
    unimp

mtvec_handler:
    csrr t0, mcause
    li t1, CAUSE_ILLEGAL_INSTRUCTION
    beq t0, t1, pass
    mv  TESTNUM, t0
    j fail
    unimp

TEST_PASSFAIL
RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
