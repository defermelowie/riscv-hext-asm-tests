#include "riscv_test.h"


RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

# Go to HS-mode
la t1, hscode
RVTEST_MRET_HS(t1)
unimp

hscode:
    # Set sstatus.SPP to Supervisor (0b1)
    csrr t1, sstatus
    li t2, 0x0000000000000100
    or t1, t1, t2
    csrw sstatus, t1
    # Set hstatus.SPV to V=1
    csrr t1, hstatus
    li t2, 0x0000000000000080
    or t1, t1, t2
    csrw hstatus, t1
    # Load addres of 'vscode' into the machine exception program counter
    la t1, vscode
    csrw sepc, t1
    sret              # Go to VS-mode
    unimp

vscode:
    RVTEST_PASS

RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
