#include "riscv_test.h"
#include "test_macros.h"
#include "instructions.h"

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
# Setup test data
# ---------------------------
li s0, 0xaaaaaaaaaaaaaaaa
la a0, tdata
sd s0, 0(a0)
# Calc masked data (zero & one extended)
li t1, 0x00000000ffffffff
li t2, 0x000000000000ffff
li t3, 0x00000000000000ff
li t4, 0xffffffff00000000
li t5, 0xffffffffffff0000
li t6, 0xffffffffffffff00
and s1, s0, t1
and s2, s0, t2
and s3, s0, t3
or s4, s0, t4
or s5, s0, t5
or s6, s0, t6

# Set "Supervisor previous virtual privilage" to supervisor
li t0, HSTATUS_SPVP
csrs hstatus, t0
# Allow U-mode hypervisor load/store
li t0, HSTATUS_HU
csrs hstatus, t0
# Return into U-mode
la a0, tcode
SPA2GPA_UCODE(a0)
RVTEST_MRET_U(a0)

# ---------------------------
# Test hlv instructions
# ---------------------------
tcode:
# Convert address
la a0, tdata
SPA2GPA_VDATA(a0)
PA2VA_SDATA(a0)

li TESTNUM, 1
HLV_D(t0, a0)
bne t0, s0, fail

li TESTNUM, 2
HLV_W(t0, a0)
bne t0, s4, fail

li TESTNUM, 3
HLV_H(t0, a0)
bne t0, s5, fail

li TESTNUM, 4
HLV_B(t0, a0)
bne t0, s6, fail

li TESTNUM, 5
HLV_WU(t0, a0)
bne t0, s1, fail

li TESTNUM, 6
HLV_HU(t0, a0)
bne t0, s2, fail

li TESTNUM, 7
HLV_BU(t0, a0)
bne t0, s3, fail

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
  csrr t0, hstatus
  # Load test data so its value is visible in debug traces
  la t0, tdata
  ld t0, 0(t0)
  # Exception occured => test failed
  j fail

TEST_PASSFAIL
RVTEST_CODE_END

.data
.align RISCV_PGSHIFT # Align data section on page
#----------------------------
# Test data
#----------------------------
tdata: .dword 0x0

# ---------------------------
# Output data section.
# ---------------------------
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
