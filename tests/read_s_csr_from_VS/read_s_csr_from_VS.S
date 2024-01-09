#include "riscv_test.h"


RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

# Go to VS-mode
la t1, vscode
RVTEST_MRET_VS(t1)
unimp

vscode:
    csrr t0, sstatus # Access should be legal
    RVTEST_PASS
    unimp

RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
