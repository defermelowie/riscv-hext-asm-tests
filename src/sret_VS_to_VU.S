#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

# Go to HS-mode
la t1, vscode
RVTEST_MRET_VS(t1)
unimp

vscode:
    # Set sstatus.SPP to User (0b0)
    csrr t1, sstatus
    li t2, 0xfffffffffffffeff
    and t1, t1, t2
    csrw sstatus, t1
    # Load addres of 'vucode'
    la t1, vucode
    csrw sepc, t1
    sret              # Go to VU-mode
    unimp

vucode:
    RVTEST_PASS

RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
