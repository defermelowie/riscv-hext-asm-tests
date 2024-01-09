/**
 * File: at_39_update_pte_D.S
 * Description: Check that pte.D is updated after write
 * Remark: Automatic update of pte.D is not required by the spec. but allowed
 */
#include "riscv_test.h"
#include "vmem_common.h"
#include "vmem_utils.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
# ---------------------------
# Setup environment
# ---------------------------
# Init stack
la sp, stack

# Setup page table
la a0, spt
la a1, .text.init
la a2, .data
li a3, VMEM_SV39_LEVELS
jal setup_spt
la a0, spt
srl a0, a0, RISCV_PGSHIFT
li a1, SATP_MODE_SV39 * (SATP_MODE & ~(SATP_MODE<<1))
or a0, a0, a1
csrw satp, a0

# Configure menvcfg.adue in order to enable updates of pte.D & pte.A (Requires Svadu extension)
#ifdef SVADU_EXT
li t0, MENVCFG_HADE
csrs menvcfg, t0
#endif

# ---------------------------
# Actual test
# ---------------------------
li TESTNUM, 1

# Clear pte.D
la a0, SDATA_LEAF_PTE
li a1, (PTE_V | PTE_R | PTE_W | !PTE_D | PTE_A)
UPDATE_PTE_BITS(a0, a1)
sfence.vma
# Enable AT (Return into S-mode)
la a0, testcode
PA2VA_SCODE(a0)
RVTEST_MRET_HS(a0)
# Write data
testcode:
  la a0, testdata
  PA2VA_SDATA(a0)
  li t1, 0xaaaa0000aaaa0000
  sd t1, 0(a0)
  ebreak
# Assert pte.D == 0b1
mtvec_handler:
  csrr a0, mcause
  li t0, CAUSE_BREAKPOINT
  beq t0, a0, 1f
  j fail
1:la a1, SDATA_LEAF_PTE
  ld a1, 0(a1)
  li t0, PTE_D
  and t1, t0, a1
  beq t1, zero, fail

RVTEST_PASSFAIL
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
