#include "riscv_test.h"
#include "test_macros.h"

#define PTESIZE 8

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
la a0, spt0
li a1, DRAM_BASE
jal setup_pt
la t1, spt0
srl t1, t1, RISCV_PGSHIFT
li t0, SATP_MODE_SV39 * (SATP_MODE & ~(SATP_MODE<<1))
or t0, t0, t1
csrw vsatp, t0
# ---------------------------
li t0, HGATP_MODE_OFF * (HGATP_MODE & ~(SATP_MODE<<1))
csrw hgatp, t0

# ---------------------------
# Return into VS-mode
# ---------------------------
li t0, MSTATUS_MPP | MSTATUS_MPV
csrc mstatus, t0
li t0, 0x8000000800
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
j pass

TEST_PASSFAIL
RVTEST_CODE_END

.data
# ---------------------------
# Page table data (empty)
# ---------------------------
.align RISCV_PGSHIFT
spt0: .zero RISCV_PGSIZE
spt1: .zero RISCV_PGSIZE
spt2: .zero RISCV_PGSIZE
spt3: .zero RISCV_PGSIZE
spt4: .zero RISCV_PGSIZE

# Output data section.
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END

# ---------------------------
# "Stack" of size PGSIZE
# ---------------------------
.skip RISCV_PGSIZE; .global stack; stack:
