#include "riscv_test.h"


RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

li TESTNUM, 1
# Tamper with U-mode address translation
li t1, ((SATP_MODE_SV39 << 60) | (0xaaaa << 44) | 0xfffffffffff)
csrw satp, t1
# Go to VU-mode
la a0, vucode
RVTEST_MRET_VU(a0)
unimp

vucode:
    RVTEST_INSERT_NOPS_10
    RVTEST_PASS

RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
