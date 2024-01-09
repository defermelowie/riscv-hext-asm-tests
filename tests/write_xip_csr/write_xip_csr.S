/**
 * Check that writes to mip, sip, hip, hvip & vsip do not set read-only bits
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
li t0, MIP_SSIP | MIP_STIP | MIP_SEIP | MIP_VSSIP
csrs mip, a0       // Try to set all bits
csrr t1, mip
bne t0, t1, fail   // Check if written bits are expected
csrc mip, a0       // Clear all bits
csrr t1, mip
bnez t1, fail    // Fail if unable to clear

li TESTNUM, 2
li t0, MIP_SSIP
csrs sip, a0       // Try to set all bits
csrr t1, sip
bne t0, t1, fail   // Check if written bits are expected
csrc sip, a0       // Clear all bits
csrr t1, sip
bnez t1, fail      // Fail if unable to clear

li TESTNUM, 3
li t0, MIP_VSSIP
csrs hip, a0       // Try to set all bits
csrr t1, hip
bne t0, t1, fail   // Check if written bits are expected
csrc hip, a0       // Clear all bits
csrr t1, hip
bnez t1, fail      // Fail if unable to clear

li TESTNUM, 4
li t0, MIP_VSSIP | MIP_VSTIP | MIP_VSEIP
csrs hvip, a0      // Try to set all bits
csrr t1, hvip
bne t0, t1, fail   // Check if written bits are expected
csrc hvip, a0      // Clear all bits
csrr t1, hvip
bnez t1, fail      // Fail if unable to clear

li TESTNUM, 5
li t0, MIP_SSIP
csrs vsip, a0      // Try to set all bits
csrr t1, vsip
bne t0, t1, fail   // Check if written bits are expected
csrc vsip, a0      // Clear all bits
csrr t1, vsip
bnez t1, fail      // Fail if unable to clear

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
