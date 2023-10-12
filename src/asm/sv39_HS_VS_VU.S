#include "riscv_test.h"
#include "test_macros.h"
#include "vmem_common.h"


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
# Return into HS-mode
# ---------------------------
li t0, MSTATUS_MPP | MSTATUS_MPV
csrc mstatus, t0
li t0, 0x800
csrs mstatus, t0
la a0, hscode
li a1, 0
ASM_SPA2GPA_HCODE(a0)
csrw mepc, a0
li TESTNUM, 1 #-> Supervisor fetch AT
mret

# ---------------------------
# HS-mode code
# ---------------------------
hscode:
nop
li TESTNUM, 2 #-> Supervisor load/store AT
la t3, hsdata
ASM_SPA2GPA_HDATA(t3)
li t1, 0xdeadbeef
sd t1, 0(t3)
ld t3, 0(t3)
li TESTNUM, 3 #-> Supervisor load/store SLAT of virtual supervisor page
li a0, SSTATUS_SUM
csrs sstatus, a0
la t3, vsdata
ASM_SPA2GPA_VDATA(t3)
li t1, 0xdeadbeef
sd t1, 0(t3)
ld t3, 0(t3)
csrc sstatus, a0
li TESTNUM, 4 #-> Supervisor load/store SLAT of virtual user page
li a0, SSTATUS_SUM
csrs sstatus, a0
la t3, vudata
ASM_SPA2GPA_VDATA(t3)
li t1, 0xdeadbeef
sd t1, 0(t3)
ld t3, 0(t3)
csrc sstatus, a0
# Return into VS-mode
li t0, SSTATUS_SUM | SSTATUS_SPP
csrs sstatus, t0
li t0, HSTATUS_SPV
csrs hstatus, t0
la a0, vscode
ASM_PA2VA_SCODE(a0)
csrw sepc, a0
# --- DEBUG START ---
li TESTNUM, 99 #-> DEBUG
li t0, 0x200ff8
ld t1, 0(t0)
li TESTNUM, 5 #-> Virtual supervisor fetch SLAT
sret

# ---------------------------
# VS-mode code
# ---------------------------
vscode:
nop
li TESTNUM, 6 #-> Virtual supervisor load/store SLAT
la t3, vsdata
ASM_PA2VA_SDATA(t3)
li t1, 0xc0ffee
sd t1, 0(t3)
ld t3, 0(t3)
li TESTNUM, 7 #-> Virtual supervisor load/store SLAT of virtual user page
li a0, SSTATUS_SUM
csrs sstatus, a0
la t3, vudata
ASM_PA2VA_UDATA(t3)
li t1, 0xc0ffee
sd t1, 0(t3)
ld t3, 0(t3)
csrc sstatus, a0
# Return into VU-mode
li t0, SSTATUS_SPP
csrc sstatus, t0
la a0, vucode
ASM_PA2VA_UCODE(a0)
csrw sepc, a0
li TESTNUM, 8 #-> Virtual user fetch SLAT
sret

# ---------------------------
# VU-mode code
# ---------------------------
vucode:
nop
li TESTNUM, 9 #-> Virtual user load/store SLAT
la t3, vudata
ASM_PA2VA_UDATA(t3)
li t1, 0xc0ffee
sd t1, 0(t3)
ld t3, 0(t3)
j pass

# ---------------------------
# Machine trap vector
# ---------------------------
mtvec_handler:
  # Load CSRs so their value is visible in debug traces
  csrr t0, mcause
  csrr t0, mepc
  csrr t0, mtval
  csrr t0, mtval2
  csrr t0, mtinst
  csrr t0, htval
  csrr t0, htinst
  # Load test data so their value is visible in debug traces
  la t0, vudata
  la t1, vsdata
  la t2, hsdata
  ld t0, 0(t0)
  ld t1, 0(t1)
  ld t2, 0(t2)
  # Exception occured => test failed
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

# ---------------------------
# "Stack" of size PGSIZE
# ---------------------------
.skip RISCV_PGSIZE; stack:

# ---------------------------
# Page table data (empty)
# ---------------------------
.section ".data.pt"
.align RISCV_L1_SPGSHIFT # Align pt section on superpage
spt: .zero (RISCV_PGSIZE * 5)
.align (RISCV_PGSHIFT + 2) # Sv*x4 root table is 4 times bigger and should be aligned accordingly
gpt: .zero (RISCV_PGSIZE * 3)

