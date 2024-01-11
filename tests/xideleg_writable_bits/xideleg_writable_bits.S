/**
 * Check that writes to mideleg & hideleg do not set read-only bits
 */

#include "riscv_test.h"
#include "riscv_util.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

// ---------------------------
// Test setup
// ---------------------------
li TESTNUM, 1
li t0, MIP_VSEIP | MIP_VSSIP | MIP_VSTIP | MIP_SGEIP
csrr t1, mideleg
bne t0, t1, fail // Check initial value

li TESTNUM, 2
li t0, MIP_VSEIP | MIP_VSSIP | MIP_VSTIP | MIP_SGEIP
csrc mideleg, t0
csrr t1, mideleg
bne t0, t1, fail // Check read-only bits

li TESTNUM, 3
csrr t1, hideleg
bnez t1, fail // Check initial value

li TESTNUM, 4
li t0, MIP_VSEIP | MIP_VSSIP | MIP_VSTIP
li t1, -1
csrs hideleg, t1
csrr t1, hideleg
bne t0, t1, fail // Check read-only bits

j pass

RVTEST_PASSFAIL
RVTEST_CODE_END

// ---------------------------
// Data section.
// ---------------------------
.data
.align RISCV_PGSHIFT // Align data section on page
RVTEST_DATA_BEGIN
.align 3
result: .dword -1
RVTEST_DATA_END
