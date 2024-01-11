/**
 * Description: Check that hgeie[0] is read-only zero. Note that the
 *              writability of the other bits depend on GEILEN
 */

#include "riscv_test.h"
#include "riscv_util.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

// ---------------------------
// Actual tests
// ---------------------------
li TESTNUM, 1

li t0, -1
csrs hgeie, t0
csrr t0, hgeie
andi t0, t0, 1 // Mask hgeie[0]
bnez t0, fail  // Check that hgeie[0] is read-only zero
j pass

RVTEST_PASSFAIL
RVTEST_CODE_END

// ---------------------------
// Data section.
// ---------------------------
.data
.align RISCV_PGSHIFT // Align data section on page
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
