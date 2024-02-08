#include "riscv_test.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
la s1, fromhost

// Read from fromhost succeeds
li TESTNUM, 1
ld t1, 0(s1)

// Write to fromhost succeeds
li TESTNUM, 2
sd t1, 0(s1)
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
