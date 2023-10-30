/**
 * File: at_39_update_pte_A.S
 * Description: Check that pte.A is updated by Sv39 page walk
 * Remark: Automatic update of pte.A is not required by the spec. but allowed
 */
#include "riscv_test.h"
#include "test_macros.h"
#include "vmem_common.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
li TESTNUM, -1
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
li t0, MENVCFG_HADE
csrs menvcfg, t0

# ---------------------------
# Actual test
# ---------------------------
li TESTNUM, 1

# Clear pte.A in data & code page table entry
la a0, VDATA_LEAF_PTE
li a1, (PTE_V | PTE_R | PTE_W | PTE_U | PTE_D | !PTE_A)
UPDATE_PTE_BITS(a0, a1)
la a0, VCODE_LEAF_PTE
li a1, (PTE_V | PTE_X | PTE_U | PTE_D | !PTE_A)
UPDATE_PTE_BITS(a0, a1)
HFENCE_GVMA(zero, zero)
# Enable AT (Return into S-mode)
la a0, testcode
SPA2GPA_VCODE(a0)
PA2VA_SCODE(a0)
RVTEST_MRET_VS(a0)
# Read data
testcode:
  la a0, testdata
  SPA2GPA_VDATA(a0)
  PA2VA_SDATA(a0)
  ld t1, 0(a0)
  ebreak
# Assert pte.A == 0b1
mtvec_handler:
  csrr a0, mcause
  li t0, CAUSE_BREAKPOINT
  beq t0, a0, 1f
  j fail
1:la a1, VDATA_LEAF_PTE
  la a2, VCODE_LEAF_PTE
  ld a1, 0(a1)
  ld a2, 0(a2)
  li t0, PTE_A
  and t1, t0, a1
  and t2, t0, a2
  and t0, t1, t2
  beq t0, zero, fail

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
