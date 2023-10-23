/**
 * File: hfence_vvma_virt_inst.S
 * Description: Verify that `hfence.vvma` from VS-mode & from VU-mode causes an illegal instruction exception
 */

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN
.align 2

vs_test:
  li TESTNUM, 1
  la a0, testcode
  RVTEST_MRET_VU(a0)

vu_test:
  li TESTNUM, 2
  la a0, testcode
  RVTEST_MRET_VU(a0)

testcode:
  hfence.vvma
  j fail

mtvec_handler:
  # Load regs & CSRs so their value is visible in traces
  addi TESTNUM, TESTNUM, 0
  csrr a0, mcause
  csrr a1, mepc
  # Check TESTNUM, exeception cause and exception program counter
  li t0, 1
  bne t0, TESTNUM, 1f
  li t0, CAUSE_VIRTUAL_INSTRUCTION
  bne t0, a0, f
  la t0, testcode
  bne t0, a1, f
  j vu_test
1:li t0, 2
  bne t0, TESTNUM, f
  li t0, CAUSE_VIRTUAL_INSTRUCTION
  bne t0, a0, f
  la t0, testcode
  bne t0, a1, f
  j pass
f:j fail

TEST_PASSFAIL
RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
