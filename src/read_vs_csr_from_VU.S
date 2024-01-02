#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

# Go to VU-mode
la t1, vucode
RVTEST_MRET_VU(t1)
unimp

vucode:
    csrr t0, vsstatus # Illegal access should trigger virtual instruction exception
    unimp

mtvec_handler:
    csrr t0, mcause
    li t1, CAUSE_VIRTUAL_INSTRUCTION
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
