/**
 * File: time_soft_VU_to_VS.S
 * Description: Let a software interrupt cause a trap into VS-mode
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
csrsi mie, MIP_MSIP | MIP_VSSIP
// csrsi mideleg, MIP_VSSIP // Has no effect since VS interrupts are always delegated when H-ext is enabled
csrsi hideleg, MIP_VSSIP
la a0, 1f
MRET_VU(a0)
1: // Trigger machine software interrupt via CLINT
li a0, 1
SET_MSIP(a0)
// Loop until interrupt (or timeout after n iterations)
mv t0, zero
li t1, 2500 // Note: For optimization purposes, Spike only checks clint every 5000 instructions
loop:
  addi t0, t0, 1
  blt t0, t1, loop
// Interrupt was not triggered
j fail

.align 2
mtvec_handler:
  // Promote if machine software interrupt
  csrr a0, mcause
  PROMOTE_MSI_TO_VSSI(a0)
  // Fail on unexpected trap cause
  j fail

.align 2
vstvec_handler:
  // Load regs & CSRs so their value is visible in traces
  addi TESTNUM, TESTNUM, 0
  csrr a0, scause
  csrr a1, sepc
  csrr t0, stval
  // Check if virtual supervisor software interrupt appears as supervisor software interrupt for VS-mode
  li TESTNUM, 2
  li t0, CAUSE_SUPERVISOR_SOFTWARE_I
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
result: .dword -1
RVTEST_DATA_END
