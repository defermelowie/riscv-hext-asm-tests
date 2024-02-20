/**
 * File: wfi_M.S
 * Description: Check that wfi from M mode causes MTI eventually
 */

#include "riscv_test.h"

#include "riscv_util.h"

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
// Set mtimecmp to mtime + 2
GET_MTIME(a0)
addi a0, a0, 2 // Note: 1 timer tick corresponds with 100 instructions in Sail model
SET_MTIMECMP(a0)
// Enable machine-timer-interrupts
li a0, MIP_MTIP
csrs mie, a0
csrsi mstatus, MSTATUS_MIE
// Loop until interrupt (or timeout after n iterations)
li t1, 2500 // Note: For optimization purposes, Spike only checks clint every 5000 instructions
loop:
  addi t1, t1, -1
  wfi
  bgtz t1, loop
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
  csrr t0, mip
  // Check trap cause
  li t0, CAUSE_MACHINE_TIMER_I
  beq a0, t0, pass
  // Fail if unexpected trap cause
  j fail

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
