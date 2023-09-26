#include "riscv_test.h"
#include "test_macros.h"

#define PTESIZE 8

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

# ---------------------------
# Setup page table
# ---------------------------
la t0, pt0
la t1, pt1
srl t1, t1, RISCV_PGSHIFT
sll t1, t1, PTE_PPN_SHIFT
ori t1, t1, PTE_V
sd t1, 0(t0)

la t0, pt0
li t2, (0x1 << RISCV_PGSHIFT) - PTESIZE
add t0, t0, t2
la t1, pt3
srl t1, t1, RISCV_PGSHIFT
sll t1, t1, PTE_PPN_SHIFT
ori t1, t1, PTE_V
sd t1, 0(t0)
# ---------------------------
la t0, pt1
la t1, pt2
srl t1, t1, RISCV_PGSHIFT
sll t1, t1, PTE_PPN_SHIFT
ori t1, t1, PTE_V
sd t1, 0(t0)

la t0, pt3
li t2, (0x1 << RISCV_PGSHIFT) - PTESIZE
add t0, t0, t2
la t1, pt4
srl t1, t1, RISCV_PGSHIFT
sll t1, t1, PTE_PPN_SHIFT
ori t1, t1, PTE_V
sd t1, 0(t0)
# ---------------------------
la t0, pt2
li t1, (DRAM_BASE >> RISCV_PGSHIFT << PTE_PPN_SHIFT)
ori t1, t1, PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_D | PTE_A
sd t1, 0(t0)

la t0, pt4
li t2, (0x1 << RISCV_PGSHIFT) - PTESIZE
add t0, t0, t2
li t1, (DRAM_BASE >> RISCV_PGSHIFT << PTE_PPN_SHIFT)
ori t1, t1, PTE_V | PTE_R | PTE_W | PTE_X | PTE_D | PTE_A
sd t1, 0(t0)
# ---------------------------
la t1, pt0
srl t1, t1, RISCV_PGSHIFT
li t0, SATP_MODE_SV39 * (SATP_MODE & ~(SATP_MODE<<1))
or t0, t0, t1
csrw vsatp, t0
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
pt0: .zero 1 << RISCV_PGSHIFT
pt1: .zero 1 << RISCV_PGSHIFT
pt2: .zero 1 << RISCV_PGSHIFT
pt3: .zero 1 << RISCV_PGSHIFT
pt4: .zero 1 << RISCV_PGSHIFT

# Output data section.
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
