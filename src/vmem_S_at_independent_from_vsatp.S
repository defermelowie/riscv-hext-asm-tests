#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

li TESTNUM, 1
# Tamper with VS-mode address translation
li t1, ((SATP_MODE_SV39 << 60) | (0xaaaa << 44) | 0xfffffffffff)
csrw vsatp, t1
# Go to S-mode
la a0, scode
RVTEST_MRET_HS(a0)
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
