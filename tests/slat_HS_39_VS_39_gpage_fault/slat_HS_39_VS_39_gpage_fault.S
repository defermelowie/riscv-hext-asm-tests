#include "riscv_test.h"
#include "riscv_util.h"
#include "vmem_common.h"
#include "vmem_utils.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
# ---------------------------
# Init stack
# ---------------------------
la sp, stack

# ---------------------------
# Setup page table
# ---------------------------
la a0, spt
li a1, GPA_BASE
li a2, 3
jal setup_vspt
la a0, spt
SPA2GPA_SLAT(a0)
srl a0, a0, RISCV_PGSHIFT
li a1, SATP_MODE_SV39 * (SATP_MODE & ~(SATP_MODE<<1))
or a0, a0, a1
csrw vsatp, a0
# ------------------------
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
csrw satp, t0 # Reuse G-stage pages for S-stage AT

# ---------------------------
# Actual tests
# ---------------------------

# Fetch-guest-page-fault due to missing execute permission in code pte
t1_pre:
  li TESTNUM, 1
  la a0, VCODE_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (PTE_V | !PTE_X | PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t1_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, VCODE_LEAF_PTE
  sd t0, 0(a0)
  j t2_pre

# Store-guest-page-fault due to missing write permission in data pte
t2_pre:
  li TESTNUM, 2
  la a0, VDATA_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (PTE_V | PTE_R | !PTE_W | PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t2_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, VDATA_LEAF_PTE
  sd t0, 0(a0)
  j t3_pre

# Load-guest-page-fault due to missing read permission in data pte
t3_pre:
  li TESTNUM, 3
  la a0, VDATA_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (PTE_V | !PTE_R | !PTE_W | PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t3_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, VDATA_LEAF_PTE
  sd t0, 0(a0)
  j t4_pre

# Fetch-guest-page-fault due to missing valid in code pte
t4_pre:
  li TESTNUM, 4
  la a0, VCODE_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (!PTE_V | PTE_X | PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t4_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, VCODE_LEAF_PTE
  sd t0, 0(a0)
  j t5_pre

# Load-guest-page-fault due to missing valid in data pte
t5_pre:
  li TESTNUM, 5
  la a0, VDATA_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (!PTE_V | PTE_R | PTE_W | PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t5_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, VDATA_LEAF_PTE
  sd t0, 0(a0)
  j t6_pre

# Fetch-guest-page-fault due to missing valid in pointer pte
t6_pre:
  li TESTNUM, 6
  la a0, PTR_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (!PTE_V)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t6_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, PTR_PTE
  sd t0, 0(a0)
  j t7_pre

# Fetch-guest-page-fault due to missing valid in slat pte
t7_pre:
  li TESTNUM, 7
  la a0, SLAT_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (!PTE_V | PTE_R | PTE_W | PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  HFENCE_VVMA(zero, zero) # hfence.vvma since VS-stage page walk has to happen in order to access slat pte
  j ret_vs
t7_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, SLAT_LEAF_PTE
  sd t0, 0(a0)
  j t8_pre

# Fetch-guest-page-fault due to missing U-bit in code pte
t8_pre:
  li TESTNUM, 8
  la a0, VCODE_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (PTE_V | PTE_X | !PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t8_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, VCODE_LEAF_PTE
  sd t0, 0(a0)
  j t9_pre

# Load-guest-page-fault due to missing U-bit in data pte
t9_pre:
  li TESTNUM, 9
  la a0, VDATA_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (PTE_V | PTE_R | PTE_W | PTE_X | !PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t9_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, VDATA_LEAF_PTE
  sd t0, 0(a0)
  j t10_pre

# Fetch-guest-page-fault due to missing U-bit in slat pte
t10_pre:
  li TESTNUM, 10
  la a0, SLAT_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (PTE_V | PTE_R | PTE_W | PTE_X | !PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t10_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, SLAT_LEAF_PTE
  sd t0, 0(a0)
  j t11_pre

# Fetch-guest-page-fault due to illegal combination in code pte
t11_pre:
  li TESTNUM, 11
  la a0, VCODE_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (PTE_V | !PTE_R | PTE_W | PTE_X | PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t11_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, VCODE_LEAF_PTE
  sd t0, 0(a0)
  j t12_pre

# Load-guest-page-fault due to illegal combination in data pte
t12_pre:
  li TESTNUM, 12
  la a0, VDATA_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (PTE_V | !PTE_R | PTE_W | PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t12_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, VDATA_LEAF_PTE
  sd t0, 0(a0)
  j t13_pre

# Fetch-guest-page-fault due to missing leaf code pte
t13_pre:
  li TESTNUM, 13
  la a0, VCODE_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (PTE_V)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t13_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, VCODE_LEAF_PTE
  sd t0, 0(a0)
  j t14_pre

# Load-guest-page-fault due to missing leaf data pte
t14_pre:
  li TESTNUM, 14
  la a0, VDATA_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (PTE_V)
  UPDATE_PTE_BITS(a0, a1)
  HFENCE_GVMA(zero, zero)
  j ret_vs
t14_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, VDATA_LEAF_PTE
  sd t0, 0(a0)
  j pass # Last test passed, exit success

# ---------------------------
# Machine trap vector
# ---------------------------
mtvec_handler:
  # Load regs & CSRs so their value is visible in traces
  addi TESTNUM, TESTNUM, 0
  csrr a0, mcause
  csrr a1, mepc
  csrr t0, mtval
  csrr t0, mtval2
  csrr t0, mtinst
  csrr t0, htval
  csrr t0, htinst
  # Check TESTNUM and exeception cause
  li t0, 1
  bne t0, TESTNUM, 1f
  li t0, CAUSE_FETCH_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t1_post
1:li t0, 2
  bne t0, TESTNUM, 1f
  li t0, CAUSE_STORE_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t2_post
1:li t0, 3
  bne t0, TESTNUM, 1f
  li t0, CAUSE_LOAD_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t3_post
1:li t0, 4
  bne t0, TESTNUM, 1f
  li t0, CAUSE_FETCH_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t4_post
1:li t0, 5
  bne t0, TESTNUM, 1f
  li t0, CAUSE_LOAD_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t5_post
1:li t0, 6
  bne t0, TESTNUM, 1f
  li t0, CAUSE_FETCH_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t6_post
1:li t0, 7
  bne t0, TESTNUM, 1f
  li t0, CAUSE_FETCH_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t7_post
1:li t0, 8
  bne t0, TESTNUM, 1f
  li t0, CAUSE_FETCH_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t8_post
1:li t0, 9
  bne t0, TESTNUM, 1f
  li t0, CAUSE_LOAD_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t9_post
1:li t0, 10
  bne t0, TESTNUM, 1f
  li t0, CAUSE_FETCH_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t10_post
1:li t0, 11
  bne t0, TESTNUM, 1f
  li t0, CAUSE_FETCH_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t11_post
1:li t0, 12
  bne t0, TESTNUM, 1f
  li t0, CAUSE_LOAD_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t12_post
1:li t0, 13
  bne t0, TESTNUM, 1f
  li t0, CAUSE_FETCH_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t13_post
1:li t0, 14
  bne t0, TESTNUM, 1f
  li t0, CAUSE_LOAD_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t14_post
  # Other exception occured => test failed
1:j fail

ret_vs:
  la a0, vscode
  SPA2GPA_VCODE(a0)
  PA2VA_SCODE(a0)
  RVTEST_MRET_VS(a0)

vscode:
  nop
  la a0, vsdata
  PA2VA_SDATA(a0)
  ld t0, 0(a0)
  not t0, t0
  sw t0, 0(a0)
  j fail

RVTEST_PASSFAIL
RVTEST_CODE_END

.data
.align RISCV_PGSHIFT # Align data section on page
#----------------------------
# Test data
#----------------------------
vsdata: .dword 0x0
pte_data: .dword 0x0

# ---------------------------
# Output data section.
# ---------------------------
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
