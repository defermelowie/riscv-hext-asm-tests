#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

li TESTNUM, 1
csrr t1, hstatus
csrr t1, hedeleg
csrr t1, hideleg
csrr t1, hie
csrr t1, hcounteren
csrr t1, hgeie
csrr t1, htval
csrr t1, hip
csrr t1, hvip
csrr t1, htinst
csrr t1, hgeip
csrr t1, henvcfg
# csrr t1, henvcfgh
csrr t1, hgatp
csrr t1, htimedelta
# csrr t1, htimedeltah
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
