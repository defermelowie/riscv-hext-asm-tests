/**
 * File: slat_VS_39_pseudoinst
 * Description: Check that guest-page-error due to implicit access yields correct pseudoinstruction
 * Remark: Automatic update of A/D bits (only way to get write pseudoinst) depends on Svadu ext
 */
#include "riscv_test.h"
#include "riscv_util.h"
#include "vmem_common.h"
#include "vmem_utils.h"

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
li a4, VMEM_SV39x4_LEVELS
jal setup_gpt
la t1, gpt
srl t1, t1, RISCV_PGSHIFT
li t0, HGATP_MODE_SV39X4 * (HGATP_MODE & ~(HGATP_MODE<<1))
or t0, t0, t1
csrw hgatp, t0

# Enable automatic updates of pte.D & pte.A (Requires Svadu extension)
#ifdef SVADU_EXT
li t0, MENVCFG_HADE
csrs menvcfg, t0
csrs henvcfg, t0
#endif

# ---------------------------
# Test setup
# ---------------------------

clear_slat_pte_W:
  # Clear write permission in slat page
  la a0, SLAT_LEAF_PTE
  li a1, (PTE_V | PTE_R | !PTE_W | PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)

clear_data_pte_A:
  li TESTNUM, 1
  # Clear pte.A in VS-level data page table entry
  la a0, SDATA_LEAF_PTE
  li a1, (PTE_V | PTE_R | PTE_W | PTE_D | !PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_VVMA(zero, zero)
  j ret_to_test

set_data_pte_A:
  # Reset pte.A in VS-level data page table entry
  la a0, SDATA_LEAF_PTE
  li a1, (PTE_V | PTE_R | PTE_W | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_VVMA(zero, zero)
  ret

clear_code_pte_A:
  li TESTNUM, 2
  # Clear pte.A in VS-level code page table entry
  la a0, SCODE_LEAF_PTE
  li a1, (PTE_V | PTE_R | PTE_X | PTE_D | !PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_VVMA(zero, zero)
  j ret_to_test

set_code_pte_A:
  # Reset pte.A in VS-level code page table entry
  la a0, SCODE_LEAF_PTE
  li a1, (PTE_V | PTE_R | PTE_X | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_VVMA(zero, zero)
  ret

clear_slat_pte_r:
  li TESTNUM, 3
  # Clear read permission in G-level slat page
  la a0, SLAT_LEAF_PTE
  li a1, (PTE_V | !PTE_R | PTE_U | PTE_D | !PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_to_test

set_slat_pte_r:
  # Reset read permission in G-level slat page
  la a0, SLAT_LEAF_PTE
  li a1, (PTE_V | PTE_R | PTE_U | PTE_D | !PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  ret

clear_vdata_pte_rw:
  li TESTNUM, 4
  # Clear read/write permissions in G-level data page table entry
  la a0, VDATA_LEAF_PTE
  li a1, (PTE_V | !PTE_R | !PTE_W | PTE_D | !PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_to_test

set_vdata_pte_rw:
  # Reset read/write permissions in G-level data page table entry
  la a0, VDATA_LEAF_PTE
  li a1, (PTE_V | PTE_R | PTE_W | PTE_D | !PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  ret

ret_to_test:
  # Enable SLAT (Return into VS-mode)
  la s0, testcode
  SPA2GPA_VCODE(s0)
  PA2VA_SCODE(s0)
  la s1, testdata
  SPA2GPA_VDATA(s1)
  PA2VA_SDATA(s1)
  RVTEST_MRET_VS(s0)

# ---------------------------
# Actual test
# ---------------------------

.option norvc # Disable compressed inst in order to easily determine expected mepc
.align 2
testcode:
  # Fetch code & read data
  nop
  ld t1, 0(s1)
  j fail
.option rvc

mtvec_handler:
  # DEBUG: Load relevant GPRs & CSRs to make them visible in execution trace
  add TESTNUM, TESTNUM, zero
  csrr a0, mcause
  csrr a1, mepc
  csrr a2, mtval
  csrr a3, mtval2
  csrr a4, mtinst
  csrr a5, htval
  csrr a6, htinst
  # Check trap values
1:li t0, 1
  bne t0, TESTNUM, 1f
  li t1, CAUSE_LOAD_GUEST_PAGE_FAULT  # Cause is load-guest-page-fault
  bne t1, a0, fail
  addi t1, s0, 4                      # Exception pc corresponds with ld inst
  bne t1, a1, fail
  li t1, 0x0003020                    # Pseudoinst is RV64 write
  bne t1, a4, fail
  bne zero, a5, fail                  # htval was not set (trap into M-mode)
  bne zero, a6, fail                  # htinst was not set (trap into M-mode)
  jal set_data_pte_A
  j clear_code_pte_A
1:li t0, 2
  bne t0, TESTNUM, 1f
  li t1, CAUSE_FETCH_GUEST_PAGE_FAULT # Cause is fetch-guest-page-fault
  bne t1, a0, fail
  bne s0, a1, fail                    # Exception pc corresponds with nop inst
  li t1, 0x0003020                    # Pseudoinst is RV64 write
  bne t1, a4, fail
  bne zero, a5, fail                  # htval was not set (trap into M-mode)
  bne zero, a6, fail                  # htinst was not set (trap into M-mode)
  jal set_code_pte_A
  j clear_slat_pte_r
1:li t0, 3
  bne t0, TESTNUM, 1f
  li t1, CAUSE_FETCH_GUEST_PAGE_FAULT  # Cause is fetch-guest-page-fault
  bne t1, a0, fail
  bne s0, a1, fail                     # Exception pc corresponds with nop inst
  li t1, 0x0003000                     # Pseudoinst is RV64 read
  bne t1, a4, fail
  bne zero, a5, fail                  # htval was not set (trap into M-mode)
  bne zero, a6, fail                  # htinst was not set (trap into M-mode)
  jal set_slat_pte_r
  j clear_vdata_pte_rw
1:li t0, 4
  bne t0, TESTNUM, 1f
  li t1, CAUSE_LOAD_GUEST_PAGE_FAULT  # Cause is load-guest-page-fault
  li t1, 0x0003020                    # Trap inst is not RV64 write pseudoinst
  beq t1, a4, fail
  li t1, 0x0003000                    # Trap inst is not RV64 read pseudoinst
  beq t1, a4, fail
  bne zero, a5, fail                  # htval was not set (trap into M-mode)
  bne zero, a6, fail                  # htinst was not set (trap into M-mode)
  jal set_vdata_pte_rw
  j pass
1:j fail

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
