#include "riscv_test.h"
#include "test_macros.h"
#include "instructions.h"

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

# Cause load page fault on load
t_lpf_pre:
  la a0, HDATA_LEAF_PTE
  ld t0, 0(a0)
  la t1, pte_data
  sd t0, 0(t1)
  li a1, (PTE_V | !PTE_R | PTE_D | PTE_A)
  UPDATE_PTE_BITS(a0, a1)
  sfence.vma
  la a0, test_loads
  SPA2GPA_HCODE(a0)
  RVTEST_MRET_HS(a0)
t_lpf_post:
  la t1, pte_data
  ld t0, 0(t1)
  la a0, HDATA_LEAF_PTE
  sd t0, 0(a0)

# TODO: setup en cleanup of load-access-fault tests
t_laf_pre:
unimp
t_laf_post:
unimp

# TODO: setup en cleanup of load-guest-page-fault tests
t_lgpf_pre:
unimp
t_lgpf_post:
unimp

# ------------------------

test_loads:
    la s1, test_data
    addi TESTNUM, TESTNUM, 0x1
l1: lb a0, 0(s1)
    addi TESTNUM, TESTNUM, 0x1
l2: lh a0, 0(s1)
    addi TESTNUM, TESTNUM, 0x1
l3: lw a0, 0(s1)
    addi TESTNUM, TESTNUM, 0x1
l4: ld a0, 0(s1)
    addi TESTNUM, TESTNUM, 0x1
l5: .option rvc; c.lw a0, 0(s1); .option norvc; .align 2
    addi TESTNUM, TESTNUM, 0x1
l6: .option rvc; c.ld a0, 0(s1); .option norvc; .align 2
    addi TESTNUM, TESTNUM, 0x1
l7: lbu a0, 0(s1)
    addi TESTNUM, TESTNUM, 0x1
l8: lhu a0, 0(s1)
    addi TESTNUM, TESTNUM, 0x1
l9: lwu a0, 0(s1)
    andi TESTNUM, TESTNUM, 0x0f
    addi TESTNUM, TESTNUM, 0x10
    ebreak

# ------------------------

#define CHECK_TINST(inst, mask, xtinst) \
  li t0, (mask);                        \
  and t0, inst, t0;                     \
  csrr t1, xtinst;                      \
  beq t0, t1, c;                        \
  j fail;

mtvec_handler:
  # Load regs & CSRs so their value is visible in traces
  addi TESTNUM, TESTNUM, 0
  csrr a0, mcause
  csrr a1, mepc
  csrr a2, mtval
  csrr a3, mtval2
  csrr a4, mtinst
  # Test next error type if breakpoint
  li t0, CAUSE_BREAKPOINT
  bne a0, t0, 1f
  j pass # TODO: test next error type
  # Check if trap cause is expected
1:li t0, CAUSE_LOAD_PAGE_FAULT
  beq a0, t0, 1f
  li t0, CAUSE_LOAD_ACCESS
  beq a0, t0, 1f
  li t0, CAUSE_LOAD_GUEST_PAGE_FAULT
  beq a0, t0, 1f
  j fail
  # Check tval, tval2 & tinst value
1:li t0, 0x1
  andi t1, TESTNUM, 0xf
  bne t1, t0, 1f

  la t0, l1
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE, mtinst)
1:li t0, 0x2
  andi t1, TESTNUM, 0xf
  bne t1, t0, 1f

  la t0, l2
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE, mtinst)
1:li t0, 0x3
  andi t1, TESTNUM, 0xf
  bne t1, t0, 1f

  la t0, l3
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE, mtinst)
1:li t0, 0x4
  andi t1, TESTNUM, 0xf
  bne t1, t0, 1f

  la t0, l4
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE, mtinst)
1:li t0, 0x5
  andi t1, TESTNUM, 0xf
  bne t1, t0, 1f

  la t0, l3 # Uncompressed version: lw a0, 0(s1)
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | (INSN_FIELD_OPCODE ^ 0b10), mtinst)
1:li t0, 0x6
  andi t1, TESTNUM, 0xf
  bne t1, t0, 1f

  la t0, l4 # Uncompressed version: ld a0, 0(s1)
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | (INSN_FIELD_OPCODE ^ 0b10), mtinst)
1:li t0, 0x7
  andi t1, TESTNUM, 0xf
  bne t1, t0, 1f

  la t0, l7
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE, mtinst)
1:li t0, 0x8
  andi t1, TESTNUM, 0xf
  bne t1, t0, 1f

  la t0, l8
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE, mtinst)
1:li t0, 0x9
  andi t1, TESTNUM, 0xf
  bne t1, t0, 1f

  la t0, l9
  lw t2, 0(t0)
  CHECK_TINST(t2, INSN_FIELD_FUNCT3 | INSN_FIELD_RD | INSN_FIELD_OPCODE, mtinst)
1:j fail # TESTNUM is unknown
c:# Skip faulting inst & continue
  addi a1, a1, 0x4
  csrw mepc, a1
  mret


# ------------------------

TEST_PASSFAIL
RVTEST_CODE_END

# ---------------------------
# Test data section.
# ---------------------------
.data
RVTEST_DATA_BEGIN
.align 3
pte_data:  .dword 0x0
test_data: .dword 0xc0ffee
result:    .dword -1
RVTEST_DATA_END
