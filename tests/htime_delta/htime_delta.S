/**
 * File: htime_delta.S
 * Description: Verify that accessing a time when V=1 returns the sum of mtime & htimedelta
 * Bug: This test only works as long as the timer does not fire between the first & last read of time
 */

#include "riscv_test.h"
#include "riscv_util.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

// ------------------------
// Actual test
// ------------------------
li TESTNUM, 1

// Make time accessible from lower privilege levels
li t0, 0x2
csrs mcounteren, t0
csrs hcounteren, t0
csrs scounteren, t0
// Set Δtime
li s0, 0x1000
csrw htimedelta, s0
// Calculate virtual addresses
la a0, hstime
la a1, vstime
la a2, vutime
// Reset timer
SET_MTIME(zero)
// Read time at different privileges
mtime: csrr s1, time
RVTEST_MRET_HS(a0)
hstime: csrr s2, time
RVTEST_SRET_VS(a1)
vstime: csrr s3, time
RVTEST_SRET_U(a2)
vutime: csrr s4, time
// Check results
bne s1, s2, fail
add t0, s1, s0
bne t0, s3, fail
bne t0, s4, fail
j pass

RVTEST_PASSFAIL
RVTEST_CODE_END

// ---------------------------
// Data section.
// ---------------------------
.data
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
