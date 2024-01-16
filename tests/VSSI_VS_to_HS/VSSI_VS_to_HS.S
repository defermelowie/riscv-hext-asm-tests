/**
 * Description: Let a VSSI cause a trap into HS-mode
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

// Do not delegate (V)U-mode or VS-mode ecall to HS-mode trap handler
li t0, (1 << CAUSE_USER_ECALL | 1 << CAUSE_VIRTUAL_SUPERVISOR_ECALL)
csrc medeleg, t0

// ------------------------
// Actual test
// ------------------------
li TESTNUM, 1

// Return into HS-mode
la a0, 1f
MRET_HS(a0); 1:
// Enable VSSIE, VSSIP but disable HS-mode interrupts globally
csrsi hie, MIP_VSSIP
csrsi hip, MIP_VSSIP
csrci sstatus, MSTATUS_SIE

// Return into VS-mode loop
la a0, loop
li a1, 2500 // Timeout after n loopings
SRET_VS(a0)
loop:
  addi a1, a1, -1
  bnez t1, loop
// Interrupt was not triggered
j fail

.align 2
stvec_handler:
  // Load regs & CSRs so their value is visible in traces
  addi TESTNUM, TESTNUM, 0
  csrr a0, scause
  csrr a1, sepc
  csrr t0, stval
  csrr t0, htval
  csrr t0, htinst
  // Check if virtual supervisor software interrupt appears as supervisor software interrupt for VS-mode
  li TESTNUM, 2
  li t0, CAUSE_VIRTUAL_SUPERVISOR_SOFTWARE_I
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
