/**
 * File: hlv_ill_inst.S
 * Description: Verify that `hlv` from U-mode causes an illegal instruction exception
 */

#include "riscv_test.h"
#include "riscv_util.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN
.align 2

li TESTNUM, 1
la a0, testcode
la a1, testdata
RVTEST_MRET_U(a0)

testcode:
  HLV_D(a1,a0)
  j fail

mtvec_handler:
  # Load regs & CSRs so their value is visible in traces
  addi TESTNUM, TESTNUM, 0
  csrr a0, mcause
  csrr a1, mepc
  # Check TESTNUM, exeception cause and exception program counter
  li t0, 1
  bne t0, TESTNUM, f
  li t0, CAUSE_ILLEGAL_INSTRUCTION
  bne t0, a0, f
  la t0, testcode
  bne t0, a1, f
  j pass
f:j fail

RVTEST_PASSFAIL
RVTEST_CODE_END

.data
testdata: .dword 0x0

# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
