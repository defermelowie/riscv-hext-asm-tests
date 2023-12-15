/**
 * File: high_half_CSR_ill_instr.S
 * Description: Verify that accessing a high half CSR when V=1 causes an illegal instruction on a RV64 system
 * Note: Test only valid when VSXLEN=VUXLEN=64
 */

#include "riscv_test.h"
#include "test_macros.h"
#include "vmem_common.h"
#include "instructions.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
li TESTNUM, -1

// ---------------------------
// Setup environment
// ---------------------------
// Init stack
la sp, stack

// Setup VS-stage page table
la a0, spt
li a1, GPA_BASE
li a2, VMEM_SV39_LEVELS
jal setup_vspt
la a0, spt
SPA2GPA_SLAT(a0)
srl a0, a0, RISCV_PGSHIFT
li a1, SATP_MODE_SV39 * (SATP_MODE & ~(SATP_MODE<<1))
or a0, a0, a1
csrw vsatp, a0
// Setup G-stage page table
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
// Fence to make sure changes are committed
HFENCE_GVMA(zero, zero)
HFENCE_VVMA(zero, zero)
sfence.vma

// ---------------------------
// Test loaders
// ---------------------------

test_from_vs:
  li t0, 0x5
  csrs mcounteren, t0
  csrs hcounteren, t0
  li TESTNUM, 0x00
  la a1, testcode
  SPA2GPA_VCODE(a1)
  PA2VA_SCODE(a1)
  RVTEST_MRET_VS(a1)

test_from_vu:
  li t0, 0x5
  csrs mcounteren, t0
  csrs scounteren, t0
  csrs hcounteren, t0
  li TESTNUM, 0x10
  la a1, testcode
  SPA2GPA_VCODE(a1)
  PA2VA_UCODE(a1)
  RVTEST_MRET_VU(a1)

// ---------------------------
// Actual test code
// ---------------------------

// Note: The CSRRS_RAW macro is needed because the assembler
//       complains about the use of high-half CSRs for RV64
testcode:
  // Read of normal CSR should pass
  li t0, 0x1
  andi TESTNUM, TESTNUM, -0x10
  or TESTNUM, TESTNUM, t0
  CSRRS_RAW(t0, CSR_CYCLE, zero)
  // Read of high-half CSR should fail
  li t0, 0x2
  andi TESTNUM, TESTNUM, -0x10
  or TESTNUM, TESTNUM, t0
  CSRRS_RAW(t0, CSR_CYCLEH, zero)
  j fail

// ---------------------------
// Test trap handler
// ---------------------------
mtvec_handler:
  # Load CSRs so their value is visible in debug traces
  csrr a0, mcause
  csrr t0, mepc
  csrr t0, mtval
  csrr t0, mtval2
  csrr t0, mtinst
  csrr t0, htval
  csrr t0, htinst
  # Check if test 0x.2 causes illegal instruction
  andi t0, TESTNUM, 0x0f
  li t1, 0x2
  bne t0, t1, fail # fail if not second (minor) test
  li t0, CAUSE_ILLEGAL_INSTRUCTION
  bne a0, t0, fail # fail if cause not illegal instruction
  # Determine next test
  andi t0, TESTNUM, 0xf0
  li t1, 0x00
  bne t0, t1, 1f
  j test_from_vu
1:j pass

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
