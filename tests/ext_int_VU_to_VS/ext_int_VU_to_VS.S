/**
 * Description: Let a virtual supervisor external interrupt (VSEI) cause a trap into VS-mode
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
// Do not delegate traps due to ebreak
li t0, 1 << CAUSE_BREAKPOINT
csrc medeleg, t0

// ------------------------
// Actual test
// ------------------------
.option norvc
li TESTNUM, 1
// Enable & delegate VSEI
li t0, MIP_VSEIP
csrs hie, t0
csrs hideleg, t0
// Jump to VU-mode
la a0, 1f
MRET_VU(a0)
1: // Trigger VSEI via ebreak (see mtvec_handler)
ebreak
// Loop until interrupt (or timeout after n iterations)
mv t0, zero
li t1, 2500 // Note: For optimization purposes, Spike only checks clint every 5000 instructions
loop:
  addi t0, t0, 1
  blt t0, t1, loop
// Interrupt was not triggered
j fail
.option rvc

.align 2
mtvec_handler:
  // Trigger VSEI on ebreak
  csrr a0, mcause
  li t0, CAUSE_BREAKPOINT
  bne a0, t0, 1f
  li t0, MIP_VSEIP
  csrs hvip, t0
  // Set mepc to next instruction & return from trap
  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0
  mret
  // Fail on unexpected trap cause
  1: j fail

.align 2
vstvec_handler:
  // Load regs & CSRs so their value is visible in traces
  addi TESTNUM, TESTNUM, 0
  csrr a0, scause
  csrr a1, sepc
  csrr t0, stval
  // Pass if expected trap cause (VSEI should appear as SEI from VS-mode)
  li t0, CAUSE_SUPERVISOR_EXTERNAL_I
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
