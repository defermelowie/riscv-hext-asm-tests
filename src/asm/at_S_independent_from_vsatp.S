#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

li TESTNUM, 1
# Set mstatus.MPP to Supervisor (0b01) & mstatus.MPV to 0b0
csrr t1, mstatus
li t2, 0xffffff7fffffe7ff # Reset
and t1, t1, t2
li t2, 0x0000000000000800 # Set
or t1, t1, t2
csrw mstatus, t1
# Load address of 'scode' into the machine exception program counter
la t1, scode
csrw mepc, t1
# Tamper with VS-mode address translation
li t1, ((SATP_MODE_SV39 << 60) | (0xaaaa << 44) | 0xfffffffffff)
csrw vsatp, t1
mret              # Go to S-mode
unimp

scode:
    TEST_INSERT_NOPS_10
    RVTEST_PASS

RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
