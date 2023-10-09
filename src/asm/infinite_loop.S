#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2

loop:
  hfence.vvma
  j loop

TEST_PASSFAIL
RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END

# clang --target=riscv64 -march=rv64gch -mabi=lp64 -mcmodel=medany ./src/asm/infinite_loop.S -I env/p/ -I src/macro/ -nostdlib -static -Lscript env/p/link.ld 
