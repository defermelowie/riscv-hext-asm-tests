#include "riscv_test.h"


RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

li TESTNUM, 1
# Set mstatus.MPP to User (0b00) & mstatus.MPV to 0b1
csrr t1, mstatus
li t2, 0xffffff7fffffe7ff # Reset
and t1, t1, t2
li t2, 0x0000008000000000 # Set
or t1, t1, t2
csrw mstatus, t1
# Load address of 'vucode' into the machine exception program counter
la t1, vucode
csrw mepc, t1
mret              # Go to VU-mode
unimp

vucode:
    RVTEST_PASS

RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
