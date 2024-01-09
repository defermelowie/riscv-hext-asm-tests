/**
 * Check that writes to mie, sie, hie & vsie do not set read-only bits
 */

#include "riscv_test.h"
#include "riscv_util.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

// ---------------------------
// Test setup
// ---------------------------

// Disable interrupts globally
csrci mstatus, MSTATUS_MIE
// Load all ones to a0
li a0, -1
// Set mtimecmp as high as possible to make sure MTI won't be triggered
SET_MTIMECMP(a0)
// Delegate as much as possible
csrw mideleg, a0
csrw hideleg, a0

// ---------------------------
// Actual tests
// ---------------------------

li TESTNUM, 1
li t0, MIP_SSIP | MIP_VSSIP | MIP_MSIP | \
       MIP_STIP | MIP_VSTIP | MIP_MTIP | \
       MIP_SEIP | MIP_VSEIP | MIP_MEIP | MIP_SGEIP
csrs mie, a0       // Try to set all bits
csrr t1, mie
bne t0, t1, fail   // Check if written bits are expected
csrc mie, a0       // Clear all bits
csrr t1, mie
bnez t1, fail    // Fail if unable to clear

li TESTNUM, 2
li t0, MIP_SSIP | MIP_STIP| MIP_SEIP
csrs sie, a0       // Try to set all bits
csrr t1, mie
bne t0, t1, fail   // Check if written bits are expected
csrc sie, a0       // Clear all bits
csrr t1, mie
bnez t1, fail    // Fail if unable to clear

li TESTNUM, 3
li t0, MIP_VSSIP | MIP_VSTIP | MIP_VSEIP | MIP_SGEIP
csrs hie, a0       // Try to set all bits
csrr t1, mie
bne t0, t1, fail   // Check if written bits are expected
csrc hie, a0       // Clear all bits
csrr t1, mie
bnez t1, fail    // Fail if unable to clear

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

result:
        .dword -1
RVTEST_DATA_END
