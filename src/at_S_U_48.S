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
la a1, .text.init
la a2, .data
li a3, 4
jal setup_spt
la a0, spt
srl a0, a0, RISCV_PGSHIFT
li a1, SATP_MODE_SV48 * (SATP_MODE & ~(SATP_MODE<<1))
or a0, a0, a1
csrw satp, a0

# ---------------------------
# Return into S-mode
# ---------------------------
li t0, MSTATUS_MPP
csrc mstatus, t0
li t0, 0x800
csrs mstatus, t0
la a0, scode
PA2VA_SCODE(a0)
csrw mepc, a0
li TESTNUM, 1 #-> Supervisor fetch AT
mret

# ---------------------------
# S-mode code
# ---------------------------
scode:
nop
li TESTNUM, 2 #-> Supervisor load/store AT
la a0, sdata
PA2VA_SDATA(a0)
li t1, 0xdeadbeef
sd t1, 0(a0)
ld t0, 0(a0)
li TESTNUM, 3 #-> Supervisor load/store AT of user page
li a0, SSTATUS_SUM
csrs sstatus, a0
la a1, udata
PA2VA_UDATA(a1)
li t1, 0xdeadbeef
sd t1, 0(a1)
ld t0, 0(a1)
csrc sstatus, a0
# Return into U-mode
li t0, MSTATUS_MPP
csrc sstatus, t0
la a0, ucode
PA2VA_UCODE(a0)
csrw sepc, a0
li TESTNUM, 4 #-> User fetch AT
sret

# ---------------------------
# User code
# ---------------------------
ucode:
nop
li TESTNUM, 5 #-> User load/store AT
la a0, udata
PA2VA_UDATA(a0)
li t1, 0xc0ffee
sd t1, 0(a0)
ld t0, 0(a0)
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
  # Load test data so their value is visible in debug traces
  la t0, udata
  la t1, sdata
  ld t0, 0(t0)
  ld t1, 0(t1)
  # Exception occured => test failed
  j fail

TEST_PASSFAIL
RVTEST_CODE_END

.data
#----------------------------
# Test data
#----------------------------
udata: .dword 0x0
sdata: .dword 0x0

# ---------------------------
# Output data section.
# ---------------------------
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
