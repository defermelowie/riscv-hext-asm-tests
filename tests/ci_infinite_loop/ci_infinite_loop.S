#include "riscv_test.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
li TESTNUM, 1

loop:
  j loop

RVTEST_PASSFAIL
RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
