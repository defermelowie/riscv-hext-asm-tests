/**
 * File: at_39_update_pte_D.S
 * Description: Check that pte.D is updated after write
 * Remark: Automatic update of pte.D is not required by the spec. but allowed
 */
#include "riscv_test.h"
#include "test_macros.h"
#include "vmem_common.h"
#include "instructions.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
# ---------------------------
# Setup environment
# ---------------------------
# Init stack
la sp, stack

# Setup VS-stage page table
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
# Setup G-stage page table
la a0, gpt
la a1, .text.init
la a2, .data
la a3, .data.pt # AT structure superpage
jal setup_gpt
la t1, gpt
srl t1, t1, RISCV_PGSHIFT
li t0, HGATP_MODE_SV39X4 * (HGATP_MODE & ~(HGATP_MODE<<1))
or t0, t0, t1
csrw hgatp, t0

# Configure menvcfg.adue in order to enable updates of pte.D & pte.A (Requires Svadu extension)
#ifdef SVADU_EXT
li t0, MENVCFG_HADE
csrs menvcfg, t0
csrs henvcfg, t0
#endif

# ---------------------------
# Test setup
# ---------------------------
li TESTNUM, 1

# Clear pte.D
la a0, VDATA_LEAF_PTE
li a1, (PTE_V | PTE_R | PTE_W | PTE_U | !PTE_D | PTE_A)
UPDATE_PTE_BITS(a0, a1)
HFENCE_GVMA(zero, zero)
la a0, SDATA_LEAF_PTE
li a1, (PTE_V | PTE_R | PTE_W | !PTE_D | PTE_A)
UPDATE_PTE_BITS(a0, a1)
HFENCE_VVMA(zero, zero)
# Enable SLAT (Return into VS-mode)
la a0, testcode
SPA2GPA_VCODE(a0)
PA2VA_SCODE(a0)
RVTEST_MRET_VS(a0)

# ---------------------------
# Actual test
# ---------------------------

testcode:
  # Write data
  la a0, testdata
  SPA2GPA_VDATA(a0)
  PA2VA_SDATA(a0)
  li t1, 0xaaaa0000aaaa0000
  sd t1, 0(a0)
  ebreak


mtvec_handler:
  # DEBUG: Load relevant GPRs & CSRs to make them visible in execution trace
  add TESTNUM, TESTNUM, zero
  csrr a0, mcause
  csrr a1, mepc
  csrr a2, mtval
  csrr a3, mtval2
  csrr a4, mtinst
  # Check cause is expected
  csrr a0, mcause
  li t0, CAUSE_BREAKPOINT
  beq t0, a0, 1f
  j fail
  # Assert pte.D == 0b1
1:la a1, VDATA_LEAF_PTE
  la a2, SDATA_LEAF_PTE
  ld a1, 0(a1)
  ld a2, 0(a2)
  li t0, PTE_D
  and a1, t0, a1
  and a2, t0, a2
  and a1, a1, a2
  beq t1, zero, fail

TEST_PASSFAIL
RVTEST_CODE_END

# ---------------------------
# Test data section.
# ---------------------------
.data
RVTEST_DATA_BEGIN
.align 3
testdata: .dword 0xc0ffee00deadbeef
result: .dword -1
RVTEST_DATA_END
