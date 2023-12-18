/**
 * File: htime_delta.S
 * Description: Verify that accessing a time when V=1 returns the sum of mtime & htimedelta
 * Bug: This test only works as long as the timer does not fire between the first & last read of time
 */

#include "riscv_test.h"
#include "test_macros.h"
#include "instructions.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
// ---------------------------
// Init stack
// ---------------------------
la sp, stack

// ---------------------------
// Setup page table
// ---------------------------
la a0, spt
li a1, GPA_BASE
li a2, 3
jal setup_vspt
la a0, spt
SPA2GPA_SLAT(a0)
srl a0, a0, RISCV_PGSHIFT
li a1, SATP_MODE_SV39 * (SATP_MODE & ~(SATP_MODE<<1))
or a0, a0, a1
csrw vsatp, a0
// ------------------------
la a0, gpt
la a1, .text.init
la a2, .data
la a3, .data.pt // AT structure superpage
jal setup_gpt
la t1, gpt
srl t1, t1, RISCV_PGSHIFT
li t0, HGATP_MODE_SV39X4 * (HGATP_MODE & ~(HGATP_MODE<<1))
or t0, t0, t1
csrw hgatp, t0
csrw satp, t0 // Reuse G-stage pages for S-stage AT

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

mtime: csrr s1, time

la a0, hstime
SPA2GPA_HCODE(a0)
RVTEST_MRET_HS(a0)

hstime: csrr s2, time
bne s1, s2, fail

la a0, vstime
PA2VA_SCODE(a0)
RVTEST_SRET_VS(a0)

vstime: csrr s3, time
add t0, s2, s0
bne t0, s3, fail

j pass

TEST_PASSFAIL
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
