/**
 * File: time_int_VU_to_M.S
 * Description: Let a timer interrupt cause a trap into HS-mode
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
// Globally enable interrupts
csrsi mstatus, MSTATUS_MIE | MSTATUS_SIE
// Set mtimecmp to mtime + 2
GET_MTIME(a0)
addi a0, a0, 2 // Note: 1 timer tick corresponds with 100 instructions in Sail model
SET_MTIMECMP(a0)
// Enable and delegate timer-interrupts to VS
li a0, MIP_MTIP | !MIP_STIP | MIP_VSTIP
csrs mie, a0
csrs mideleg, a0 // Delegate from M ---> HS
csrs hideleg, a0 // Delegate from HS --> VS
// Ret into VU
la a0, 1f
RVTEST_MRET_VU(a0)
// Loop until interrupt (or timeout after n iterations)
1:
mv t0, zero
li t1, 2500 // Note: For optimization purposes, Spike only checks clint every 5000 instructions
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
  csrr t0, mip
  // Let a machine timer interrupt cause a virtual supervisor timer interrupt
  PROMOTE_MTI_TO_VSTI(a0)
  j fail

.align 2
vstvec_handler:
  // Load regs & CSRs so their value is visible in traces
  addi TESTNUM, TESTNUM, 0
  csrr a0, scause
  csrr a1, sepc
  csrr t0, stval
  csrr t0, sip
  // Check if virtual supervisor timer interrupt appears as supervisor timer interrupt for VS-mode
  li TESTNUM, 2
  li t0, CAUSE_SUPERVISOR_TIMER_I
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
