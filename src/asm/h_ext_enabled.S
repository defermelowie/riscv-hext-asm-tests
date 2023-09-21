#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

li TESTNUM, 1
csrr t1, misa       # Read misa
andi t1, t1, 0x80   # Extract H bit
beqz t1, fail       # Failure if H bit is 0
RVTEST_PASS

fail:
    RVTEST_FAIL

RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
