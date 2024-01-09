#include "riscv_test.h"
#include "riscv_util.h"
#include "vmem_common.h"
#include "vmem_utils.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
.option norvc
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
csrw satp, t0 # Reuse G-stage pages & mode for S-stage AT

# ------------------------
# Actual test
# ------------------------

# Cause store-page-faults
t_spf_pre:
  la a0, SDATA_LEAF_PTE
  ld t0, 0(a0)
  la t1, cfg_data
  sd t0, 0(t1)
  li a1, (PTE_V | PTE_R | !PTE_W | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  j test_entry
t_spf_post:
  la t1, cfg_data
  ld t0, 0(t1)
  la a0, SDATA_LEAF_PTE
  sd t0, 0(a0)
  sfence.vma

# Cause store-access-faults
t_saf_pre:
  la t0, cfg_data
  csrr t1, pmpcfg0
  sd t1, 0(t0)
  csrr t1, pmpaddr0
  sd t1, 8(t0)

  la t0, .text.init + (1 << (RISCV_PGSHIFT-1) - 1)   # Testcode
  srli t0, t0, PMP_SHIFT
  csrw pmpaddr0, t0
  la t0, .data + (1 << (RISCV_PGSHIFT-1) - 1)        # Testdata
  srli t0, t0, PMP_SHIFT
  csrw pmpaddr1, t0
  la t0, .data.pt + (1 << (RISCV_L1_SPGSHIFT-1) - 1) # Page table data
  srli t0, t0, PMP_SHIFT
  csrw pmpaddr2, t0
  li t0, (PMP_NAPOT | PMP_R | PMP_W| PMP_X) | ((PMP_NAPOT | PMP_R | !PMP_W) << 8) | ((PMP_NAPOT | PMP_R | PMP_W | PMP_X) << 16)
  csrw pmpcfg0, t0
  j test_entry
t_saf_post:
  la t1, cfg_data
  ld t0, 0(t1)
  csrw pmpcfg0, t0
  ld t0, 8(t1)
  csrw pmpaddr0, t0
  sfence.vma

# Cause store-guest-page-faults
t_sgpf_pre:
  la a0, VDATA_LEAF_PTE
  ld t0, 0(a0)
  la t1, cfg_data
  sd t0, 0(t1)
  li a1, (PTE_V | PTE_R | !PTE_W | PTE_U | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  j test_entry
t_sgpf_post:
  la t1, cfg_data
  ld t0, 0(t1)
  la a0, VDATA_LEAF_PTE
  sd t0, 0(a0)
  sfence.vma

j pass # All tests finished, exit success

# ------------------------

test_entry:
  sfence.vma
  la a0, test_amo
  SPA2GPA_VCODE(a0)
  PA2VA_SCODE(a0)
  RVTEST_MRET_VS(a0)

test_amo:
    la s1, test_data
    SPA2GPA_VDATA(s1)
    PA2VA_SDATA(s1)
    li s2, 0x3333333333333333
    addi TESTNUM, TESTNUM, 0x1
t1: amoswap.w t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t2: amoswap.d t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t3: amoadd.w t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t4: amoadd.d t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t5: amoand.w t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t6: amoand.d t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t7: amoor.w t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t8: amoor.d t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t9: amoxor.w t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t10:amoxor.d t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t11:amomax.w t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t12:amomax.d t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t13:amomin.w t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
t14:amomin.d t0, s2, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x02 # Add to TESTNUM in order to reach next multiple of 0x10
    ebreak

# ------------------------

mtvec_handler:
  # Load regs & CSRs so their value is visible in traces
  add TESTNUM, TESTNUM, zero
  csrr a0, mcause
  csrr a1, mepc
  csrr a2, mtval
  csrr a3, mtval2
  csrr a4, mtinst
  # Test next error type if breakpoint
  li t0, CAUSE_BREAKPOINT
  bne a0, t0, 2f
1:li t0, 0x10
  bne TESTNUM, t0, 1f
  j t_spf_post
1:li t0, 0x20
  bne TESTNUM, t0, 1f
  j t_saf_post
1:li t0, 0x30
  bne TESTNUM, t0, 1f
  j t_sgpf_post
  1:j fail                # TESTNUM is unkown
  # Check if trap cause is expected
2:li t0, CAUSE_STORE_PAGE_FAULT
  beq a0, t0, 1f
  li t0, CAUSE_STORE_ACCESS
  beq a0, t0, 1f
  li t0, CAUSE_STORE_GUEST_PAGE_FAULT
  beq a0, t0, 1f
  j fail
  # Check tinst value
1:andi t1, TESTNUM, 0xf # t1 = testnum % 16
  li t0, 14
  bgt t1, t0, 1f
  j check_tinst
1:j fail                # TESTNUM is unknown

#define CHECK_TINST(instreg, mask)\
  li t0, (mask);                  \
  and t0, instreg, t0;            \
  csrr t1, mtinst;                \
  beq t1, zero, continue;         \
  beq t0, t1, continue;           \
  j fail;

check_tinst:
  # Read faulting instruction from memory
  csrr t0, mepc
  li t1, HSTATUS_SPVP
  csrs hstatus, t1
  HLVX_WU(t2, t0)
  csrc hstatus, t1
  # Check if xtinst fields are equal to those of faulting inst
  CHECK_TINST(t2, INSN_FIELD_AMOOP | INSN_FIELD_AQRL | INSN_FIELD_RS2 | INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE)

continue:# Skip faulting inst & j fail
  addi a1, a1, 0x8
  csrw mepc, a1
  mret

# ------------------------

RVTEST_PASSFAIL
RVTEST_CODE_END

# ---------------------------
# Test data section.
# ---------------------------
.data
RVTEST_DATA_BEGIN
.align 3
cfg_data:  .dword 0x0; .dword 0x0
test_data: .dword 0x1111111111111111
result:    .dword -1
RVTEST_DATA_END
