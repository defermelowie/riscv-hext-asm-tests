/**
 * File: h_ext_csr_defined.S
 * Description: Attempt to read all CSRs defined by the hypervisor extension
 */

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

li TESTNUM, 1
csrr t1, mtval2
csrr t1, mtinst
li TESTNUM, 2
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
#if __riscv_xlen == 32
  csrr t1, henvcfgh
#endif
csrr t1, hgatp
csrr t1, htimedelta
#if __riscv_xlen == 32
  csrr t1, htimedeltah
#endif
li TESTNUM, 3
csrr t1, vsstatus
csrr t1, vsie
csrr t1, vstvec
csrr t1, vsscratch
csrr t1, vsepc
csrr t1, vscause
csrr t1, vstval
csrr t1, vsip
csrr t1, vsatp
j pass

TEST_PASSFAIL
RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
