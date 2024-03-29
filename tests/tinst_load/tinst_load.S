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
li a2, VMEM_SV39_LEVELS
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
li a4, VMEM_SV39x4_LEVELS
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

# Cause load-page-fault on loads
t_lpf_pre:
  la a0, SDATA_LEAF_PTE
  ld t0, 0(a0)
  la t1, cfg_data
  sd t0, 0(t1)
  li a1, (PTE_V | !PTE_R | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  j test_entry
t_lpf_post:
  la t1, cfg_data
  ld t0, 0(t1)
  la a0, SDATA_LEAF_PTE
  sd t0, 0(a0)

# Cause load-access-fault on loads
t_laf_pre:
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
  li t0, (PMP_NAPOT | PMP_R | PMP_W| PMP_X) | ((PMP_NAPOT) << 8) | ((PMP_NAPOT | PMP_R | PMP_W | PMP_X) << 16)
  csrw pmpcfg0, t0
  j test_entry
t_laf_post:
  la t1, cfg_data
  ld t0, 0(t1)
  csrw pmpcfg0, t0
  ld t0, 8(t1)
  csrw pmpaddr0, t0

# Cause load-guest-page-fault on loads
t_lgpf_pre:
  la a0, VDATA_LEAF_PTE
  ld t0, 0(a0)
  la t1, cfg_data
  sd t0, 0(t1)
  li a1, (PTE_V | !PTE_R | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  j test_entry
t_lgpf_post:
  la t1, cfg_data
  ld t0, 0(t1)
  la a0, VDATA_LEAF_PTE
  sd t0, 0(a0)

j pass # All tests finished, exit success

# ------------------------

test_entry:
  // Flush TLBs
  HFENCE_GVMA(zero, zero)
  HFENCE_VVMA(zero, zero)
  // Jump to VS-mode test
  la a0, test_loads
  SPA2GPA_VCODE(a0)
  PA2VA_SCODE(a0)
  RVTEST_MRET_VS(a0)

test_loads:
    la s1, test_data
    SPA2GPA_VDATA(s1)
    PA2VA_SDATA(s1)
    addi TESTNUM, TESTNUM, 0x1
l1: lb a0, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
l2: lh a0, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
l3: lw a0, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
l4: ld a0, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
l5: .option rvc;
    c.lw a0, 0(s1)
    c.nop
    .option norvc; .align 2
    j fail
    addi TESTNUM, TESTNUM, 0x1
l6: .option rvc;
    c.ld a0, 0(s1)
    c.nop
    .option norvc; .align 2
    j fail
    addi TESTNUM, TESTNUM, 0x1
l7: lbu a0, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
l8: lhu a0, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
l9: lwu a0, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
l10:lr.w a0, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x1
l11:lr.d a0, 0(s1)
    j fail
    addi TESTNUM, TESTNUM, 0x05 # Add to TESTNUM in order to reach next multiple of 0x10
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
  j t_lpf_post
1:li t0, 0x20
  bne TESTNUM, t0, 1f
  j t_laf_post
1:li t0, 0x30
  bne TESTNUM, t0, 1f
  j t_lgpf_post
1:j fail                # TESTNUM is unkown
  # Check if trap cause is expected
2:li t0, CAUSE_LOAD_PAGE_FAULT
  beq a0, t0, 1f
  li t0, CAUSE_LOAD_ACCESS
  beq a0, t0, 1f
  li t0, CAUSE_LOAD_GUEST_PAGE_FAULT
  beq a0, t0, 1f
  j fail
  # Check tinst value
1:andi t1, TESTNUM, 0xf # t1 = testnum % 16
  li t0, 0x1
  bne t1, t0, 1f
  j check_t1
1:li t0, 0x2
  bne t1, t0, 1f
  j check_t2
1:li t0, 0x3
  bne t1, t0, 1f
  j check_t3
1:li t0, 0x4
  bne t1, t0, 1f
  j check_t4
1:li t0, 0x5
  bne t1, t0, 1f
  j check_t5
1:li t0, 0x6
  bne t1, t0, 1f
  j check_t6
1:li t0, 0x7
  bne t1, t0, 1f
  j check_t7
1:li t0, 0x8
  bne t1, t0, 1f
  j check_t8
1:li t0, 0x9
  bne t1, t0, 1f
  j check_t9
1:li t0, 0xa
  bne t1, t0, 1f
  j check_t10
1:li t0, 0xb
  bne t1, t0, 1f
  j check_t11
1:j fail                # TESTNUM is unknown

#define CHECK_TINST(inst, mask)\
  li t0, (mask);               \
  and t0, inst, t0;            \
  csrr t1, mtinst;             \
  beq t1, zero, continue;      \
  beq t0, t1, continue;        \
  j fail;

check_t1:
  la t0, l1
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE)

check_t2:
  la t0, l2
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE)

check_t3:
  la t0, l3
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE)

check_t4:
  la t0, l4
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE)

check_t5:
  la t0, l3 # Uncompressed version: lw a0, 0(s1)
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | (INSN_FIELD_OPCODE ^ 0b10))

check_t6:
  la t0, l4 # Uncompressed version: ld a0, 0(s1)
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | (INSN_FIELD_OPCODE ^ 0b10))

check_t7:
  la t0, l7
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE)

check_t8:
  la t0, l8
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE)

check_t9:
  la t0, l9
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE)

check_t10:
  la t0, l10
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_AMOOP | INSN_FIELD_AQRL | INSN_FIELD_RS2 | INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE)

check_t11:
  la t0, l11
  lw t2, 0(t0)
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
test_data: .dword 0x0
result:    .dword -1
RVTEST_DATA_END
