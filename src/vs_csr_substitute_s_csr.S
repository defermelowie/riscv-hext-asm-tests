#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

# Todo: Test *atp registers after 2-stage address translation is implemented
# Todo: sie -> vsie is not yet implemented
# Todo: sip -> vsip is not yet implemented

.align 2

test_setup:
    # Overwrite trap_vector
    la t1, test_check
    csrw mtvec, t1
    # Return into HS-mode
    la a0, hscode
    RVTEST_MRET_HS(a0)
    unimp

hscode:
    # Alter s* CSRs
    li t0, 0xaaaaaaaaaaaaaaaa
    csrw sstatus, t0
    csrw sie, t0
    csrw stvec, t0
    csrw sscratch, t0
    csrw sepc, t0
    csrw scause, t0
    csrw stval, t0
    csrw sip, t0
    # Prepare to return into VS-mode
    csrr t1, sstatus
    li t2, 0x0000000000000100
    or t1, t1, t2
    csrw sstatus, t1
    csrr t1, hstatus
    li t2, 0x0000000000000080
    or t1, t1, t2
    csrw hstatus, t1
    la t1, vscode
    csrw sepc, t1
    # Save s* CSRs to memory
    la x1, s_csr
    csrr x2, sstatus
    csrr x3, sie
    csrr x4, stvec
    csrr x5, sscratch
    csrr x6, sepc
    csrr x7, scause
    csrr x8, stval
    csrr x9, sip
    sd x2, 0(x1)
    sd x3, 8(x1)
    sd x4, 16(x1)
    sd x5, 24(x1)
    sd x6, 32(x1)
    sd x7, 40(x1)
    sd x8, 48(x1)
    sd x9, 56(x1)
    # Clear registerfile
    INIT_XREG
    # Return into VS-mode
    sret
    unimp

vscode:
    # Alter vs* CSRs
    li t0, 0xffffffffffffffff
    csrw sstatus, t0
    csrw sie, t0
    csrw stvec, t0
    csrw sscratch, t0
    csrw sepc, t0
    csrw scause, t0
    csrw stval, t0
    csrw sip, t0
    # Save vs* CSRs to memory
    la x1, vs_csr
    csrr x2, sstatus
    csrr x3, sie
    csrr x4, stvec
    csrr x5, sscratch
    csrr x6, sepc
    csrr x7, scause
    csrr x8, stval
    csrr x9, sip
    sd x2, 0(x1)
    sd x3, 8(x1)
    sd x4, 16(x1)
    sd x5, 24(x1)
    sd x6, 32(x1)
    sd x7, 40(x1)
    sd x8, 48(x1)
    sd x9, 56(x1)
    # Clear registerfile
    INIT_XREG
    # Trap into M-mode
    ecall
    unimp

test_check:
    # Only handle ecall from VS-mode
    li TESTNUM, 0xff
    csrr t0, mcause
    li t1, CAUSE_VIRTUAL_SUPERVISOR_ECALL
    bne t0, t1, fail

    # Check vs* CSRs
    la t0, vs_csr
    li TESTNUM, 0x1
    csrr t1, vsstatus
    ld t2, 0(t0)
    bne t1, t2, fail
    # li TESTNUM, 0x2
    # csrr t1, vsie
    # ld t2, 8(t0)
    # bne t1, t2, fail
    li TESTNUM, 0x3
    csrr t1, vstvec
    ld t2, 16(t0)
    bne t1, t2, fail
    li TESTNUM, 0x4
    csrr t1, vsscratch
    ld t2, 24(t0)
    bne t1, t2, fail
    li TESTNUM, 0x5
    csrr t1, vsepc
    ld t2, 32(t0)
    bne t1, t2, fail
    li TESTNUM, 0x6
    csrr t1, vscause
    ld t2, 40(t0)
    bne t1, t2, fail
    li TESTNUM, 0x7
    csrr t1, vstval
    ld t2, 48(t0)
    bne t1, t2, fail
    # li TESTNUM, 0x8
    # csrr t1, vsip
    # ld t2, 56(t0)
    # bne t1, t2, fail

    # Check s* CSRs
    la t0, s_csr
    li TESTNUM, 0x11
    csrr t1, sstatus
    ld t2, 0(t0)
    li t3, 0xfffffffffffffedd # Mask SPP, SIE & SPIE since they are changed by sret
    and t1, t1, t3
    and t2, t2, t3
    bne t1, t2, fail
    # li TESTNUM, 0x12
    # csrr t1, sie
    # ld t2, 8(t0)
    # bne t1, t2, fail
    li TESTNUM, 0x13
    csrr t1, stvec
    ld t2, 16(t0)
    bne t1, t2, fail
    li TESTNUM, 0x14
    csrr t1, sscratch
    ld t2, 24(t0)
    bne t1, t2, fail
    li TESTNUM, 0x15
    csrr t1, sepc
    ld t2, 32(t0)
    bne t1, t2, fail
    li TESTNUM, 0x16
    csrr t1, scause
    ld t2, 40(t0)
    bne t1, t2, fail
    li TESTNUM, 0x17
    csrr t1, stval
    ld t2, 48(t0)
    bne t1, t2, fail
    # li TESTNUM, 0x18
    # csrr t1, sip
    # ld t2, 56(t0)
    # bne t1, t2, fail

    # All checks have passed
    j success
    unimp

fail:
    # RVTEST_FAIL uses ecall and stops working after xtvec is overwritten
    fence
    la t0, tohost
    sll TESTNUM, TESTNUM, 1
    or TESTNUM, TESTNUM, 1
    sw TESTNUM, 0(t0)
    sw zero, 4(t0)
    unimp

success:
    # RVTEST_PASS uses ecall and stops working after xtvec is overwritten
    fence
    la t0, tohost
    li TESTNUM, 0x1
    sw TESTNUM, 0(t0)
    sw zero, 4(t0)
    unimp

# Output data section.
.data
RVTEST_DATA_BEGIN
.align 2
s_csr:
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0

vs_csr:
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0
    .dword 0x0

.align 3
result: .dword -1
RVTEST_DATA_END
