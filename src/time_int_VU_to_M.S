/**
 * File: time_int_VU_to_M.S
 * Description: Let a timer interrupt cause a trap into M-mode
 */

#include "riscv_test.h"
#include "test_macros.h"
#include "test_util.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
// ---------------------------
// Setup
// ---------------------------
// Disable address translation
csrw hgatp, zero
csrw satp, zero
csrw vsatp, zero

// ------------------------
// Actual test
// ------------------------
li TESTNUM, 1
// Enable time interrupts
csrsi mstatus, MSTATUS_MIE
li a0, MIP_MTIP
csrs mie, a0
// Set mtimecmp to mtime + 2
li a0, CLINT_BASE | 0xbff8 // mtime
ld a0, 0(a0)
addi a0, a0, 2             // Note: 1 timer tick corresponds with 100 instruction in Sail model
li t0, CLINT_BASE | 0x4000 // mtimecmp
sd a0, 0(t0)
// Ret into VU
la a0, 1f
RVTEST_MRET_VU(a0)
// Loop until interrupt (or timeout after 200 iterations)
1:
mv t0, zero
li t1, 200
loop:
  addi t0, t0, 1
  blt t0, t1, loop
// Interrupt was not triggered
j fail

mtvec_handler:
  // Load regs & CSRs so their value is visible in traces
  addi TESTNUM, TESTNUM, 0
  csrr a0, mcause
  csrr a1, mepc
  csrr t0, mtval
  csrr t0, mtval2
  csrr t0, mtinst
  csrr t0, htval
  csrr t0, htinst
  // Check that cause is machine timer interrupt
  li t0, IRQ_M_TIMER | (1 << 63)
  bne a0, t0, fail
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
