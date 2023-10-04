#include "riscv_test.h"
#include "test_macros.h"
#include "vmem_common.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
li TESTNUM, 1
# ---------------------------
# Init stack
# ---------------------------
la sp, stack

# ---------------------------
# Setup page table
# ---------------------------
la a0, spt
li a1, GPA_BASE
jal setup_spt
la a0, spt
SPA2GPA_ASM(a0)
srl a0, a0, RISCV_PGSHIFT
li a1, SATP_MODE_SV39 * (SATP_MODE & ~(SATP_MODE<<1))
or a0, a0, a1
csrw vsatp, a0

li t0, SSTATUS_SUM
csrs vsstatus, t0
# ------------------------
la a0, gpt
li a1, DRAM_BASE
jal setup_gpt
la t1, gpt
srl t1, t1, RISCV_PGSHIFT
li t0, HGATP_MODE_SV39X4 * (HGATP_MODE & ~(HGATP_MODE<<1))
or t0, t0, t1
csrw hgatp, t0

li t0, SSTATUS_SUM
csrs sstatus, t0
# ---------------------------
# Return into VS-mode
# ---------------------------
li t0, MSTATUS_MPP | MSTATUS_MPV
csrc mstatus, t0
li t0, 0x800 | MSTATUS_MPV
csrs mstatus, t0
la t0, scode
li t1, 0xfff
and t0, t0, t1
li t1, (-1 << RISCV_PGSHIFT)
or t0, t0, t1
csrw mepc, t0
mret

# ---------------------------
# Supervisor code
# ---------------------------
scode:
# Test supervisor load/store
li t0, 0xfffffffffffff250
li t1, 0xaaaaaaaaaaaaaaaa
sd t1, 0(t0)
ld t0, 0(t0)
# Test supervisor load/store of user page
li t0, 0x0000000000000250
ld t1, 0(t0)
not t1, t1
sd t1, 0(t0)
ld t0, 0(t0)
# Goto user-mode
li t0, MSTATUS_MPP
csrc sstatus, t0
la t0, ucode
li t1, 0xfff
and t0, t0, t1
csrw sepc, t0
sret

# ---------------------------
# User code
# ---------------------------
ucode:
# Test user load/store
li t0, 0x0000000000000250
ld t1, 0(t0)
not t1, t1
sd t1, 0(t0)
ld t0, 0(t0)
# Test passed
j pass

# ---------------------------
# Machine trap vector
# ---------------------------
mtvec_handler:
  # Load CSRs so their value is visible in the traces
  csrr t0, mcause
  csrr t0, mepc
  csrr t0, mtval
  csrr t0, mtval2
  csrr t0, mtinst
  j fail

TEST_PASSFAIL
RVTEST_CODE_END

.data
# ---------------------------
# Page table data (empty)
# ---------------------------
.align RISCV_PGSHIFT
spt: .zero (RISCV_PGSIZE * 5)
gpt: .zero (RISCV_PGSIZE * 5)

# ---------------------------
# Output data section.
# ---------------------------
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END

# ---------------------------
# "Stack" of size PGSIZE
# ---------------------------
.skip RISCV_PGSIZE; stack:
