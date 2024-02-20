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
li a4, 3
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
j 1f
.align 3 // Double word should be aligned to 8 bytes
testcode: .dword 0xaaaaaaaaaaaaaaaa
1:la a0, testcode
  ld s0, 0(a0)
  # Calc masked data (zero extended)
  li t1, 0x00000000ffffffff
  li t2, 0x000000000000ffff
  and s1, s0, t1
  and s2, s0, t2

# ---------------------------
# Test hlv instructions
# ---------------------------

# Set "Supervisor Previous Virtual Privilege" to VU
li t0, HSTATUS_SPVP
csrc hstatus, t0
# Convert address to VU-mode code addr
la a0, testcode
SPA2GPA_VCODE(a0)
PA2VA_UCODE(a0)

li TESTNUM, 0x01
HLVX_HU(t0, a0)
bne t0, s2, fail

li TESTNUM, 0x02
HLVX_WU(t0, a0)
bne t0, s1, fail

# ---------------------------

# Set "Supervisor Previous Virtual Privilege" to VS
li t0, HSTATUS_SPVP
csrs hstatus, t0
# Convert address to vs-mode code addr
la a0, testcode
SPA2GPA_VCODE(a0)
PA2VA_SCODE(a0)

li TESTNUM, 0x03
HLVX_HU(t0, a0)
bne t0, s2, fail

li TESTNUM, 0x04
HLVX_WU(t0, a0)
bne t0, s1, fail

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
  la t0, testcode
  ld t0, 0(t0)
  # Exception occured => test failed
  j fail

RVTEST_PASSFAIL
RVTEST_CODE_END

.data
.align RISCV_PGSHIFT # Align data section on page

# ---------------------------
# Output data section.
# ---------------------------
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
