#include "riscv_test.h"
#include "test_macros.h"

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
ASM_SPA2GPA_SLAT(a0)
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
#define VCODE_LEAF_PTE gpt+(2*RISCV_PGSIZE)       # user/supervisor code leaf pte
#define VDATA_LEAF_PTE gpt+(2*RISCV_PGSIZE)+(3*8) # user/supervisor data leaf pte

# Guest-page-fault due to missing execute permission in supervisor code page
t1_pre:
  li TESTNUM, 1
  la a0, VCODE_LEAF_PTE
  li a1, (PTE_V | !PTE_X | PTE_U | PTE_D | PTE_A)
  ASM_UPDATE_PTE_BITS(a0, a1)
  j ret_vs
t1_post:
  j t2_pre

# Guest-page-fault due to missing execute permission in user code page
t2_pre:
  li TESTNUM, 2
  j ret_vu
t2_post:
  la a0, VCODE_LEAF_PTE
  li a1, (PTE_V | PTE_X | PTE_U | PTE_D | PTE_A)
  ASM_UPDATE_PTE_BITS(a0, a1)
  j t3_pre

# Guest-page-fault due to missing write permission in supervisor data page
t3_pre:
  li TESTNUM, 3
  la a0, VDATA_LEAF_PTE
  li a1, (PTE_V | PTE_R | !PTE_W | PTE_U | PTE_D | PTE_A)
  ASM_UPDATE_PTE_BITS(a0, a1)
  j ret_vs
t3_post:
  j t4_pre

# Guest-page-fault due to missing write permission in user data page
t4_pre:
  li TESTNUM, 4
  j ret_vu
t4_post:
  la a0, VDATA_LEAF_PTE
  li a1, (PTE_V | PTE_R | PTE_W | PTE_U | PTE_D | PTE_A)
  ASM_UPDATE_PTE_BITS(a0, a1)
  j t5_pre

# Guest-page-fault due to missing read permission in supervisor data page
t5_pre:
  li TESTNUM, 5
  la a0, VDATA_LEAF_PTE
  li a1, (PTE_V | !PTE_R | !PTE_W | PTE_U | PTE_D | PTE_A)
  ASM_UPDATE_PTE_BITS(a0, a1)
  j ret_vs
t5_post:
  j t6_pre

# Guest-page-fault due to missing read permission in user data page
t6_pre:
  li TESTNUM, 6
  j ret_vu
t6_post:
  la a0, VDATA_LEAF_PTE
  li a1, (PTE_V | PTE_R | PTE_W | PTE_U | PTE_D | PTE_A)
  ASM_UPDATE_PTE_BITS(a0, a1)
  j pass # Last test, exit success

# ---------------------------
# Machine trap vector
# ---------------------------
mtvec_handler:
  # Load CSRs so their value is visible in debug traces
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
  li t0, CAUSE_FETCH_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t2_post
1:li t0, 3
  bne t0, TESTNUM, 1f
  li t0, CAUSE_STORE_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t3_post
1:li t0, 4
  bne t0, TESTNUM, 1f
  li t0, CAUSE_STORE_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t4_post
1:li t0, 5
  bne t0, TESTNUM, 1f
  li t0, CAUSE_LOAD_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t5_post
1:li t0, 6
  bne t0, TESTNUM, 1f
  li t0, CAUSE_LOAD_GUEST_PAGE_FAULT
  bne t0, a0, fail
  j t6_post
  # Other exception occured => test failed
1:j fail

# ---------------------------
# VS-mode
# ---------------------------
ret_vs:
  li t0, MSTATUS_MPP | MSTATUS_MPV
  csrc mstatus, t0
  li t0, 0x800 | MSTATUS_MPV
  csrs mstatus, t0
  la a0, vscode
  ASM_SPA2GPA_VCODE(a0)
  ASM_PA2VA_SCODE(a0)
  csrw mepc, a0
  mret

vscode:
  nop
  la a0, vsdata
  ASM_PA2VA_SDATA(a0)
  ld t0, 0(a0)
  not t0, t0
  sw t0, 0(a0)
  j fail

# ---------------------------
# VU-mode
# ---------------------------
ret_vu:
  li t0, MSTATUS_MPP | MSTATUS_MPV
  csrc mstatus, t0
  li t0, MSTATUS_MPV
  csrs mstatus, t0
  la a0, vucode
  ASM_SPA2GPA_VCODE(a0)
  ASM_PA2VA_UCODE(a0)
  csrw mepc, a0
  mret

vucode:
  nop
  la a0, vudata
  ASM_PA2VA_UDATA(a0)
  ld t0, 0(a0)
  not t0, t0
  sw t0, 0(a0)
  j fail

TEST_PASSFAIL
RVTEST_CODE_END

.data
.align RISCV_PGSHIFT # Align data section on page
#----------------------------
# Test data
#----------------------------
vudata: .dword 0x0
vsdata: .dword 0x0
hsdata: .dword 0x0

# ---------------------------
# Output data section.
# ---------------------------
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END

