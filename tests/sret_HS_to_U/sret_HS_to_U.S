#include "riscv_test.h"


RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

# Go to HS-mode
la t1, hscode
RVTEST_MRET_HS(t1)
unimp

hscode:
    # Set sstatus.SPP to User (0b0)
    csrr t1, sstatus
    li t2, 0xfffffffffffffeff
    and t1, t1, t2
    csrw sstatus, t1
    # Set hstatus.SPV to V=0
    csrr t1, hstatus
    li t2, 0xffffffffffffff7f
    and t1, t1, t2
    csrw hstatus, t1
    # Load addres of 'ucode' into the machine exception program counter
    la t1, ucode
    csrw sepc, t1
    sret              # Go to U-mode
    unimp

ucode:
    RVTEST_PASS

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
