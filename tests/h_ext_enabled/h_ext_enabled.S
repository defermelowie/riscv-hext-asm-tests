/**
 * File: h_ext_enabled.S
 * Description: Verify that the hypervisor extension is enabled
 */

#include "riscv_test.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

li TESTNUM, 1
csrr t1, misa       # Read misa
andi t1, t1, 0x80   # Mask H bit
beqz t1, fail       # Failure if H bit is 0
j pass

RVTEST_PASSFAIL
RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
