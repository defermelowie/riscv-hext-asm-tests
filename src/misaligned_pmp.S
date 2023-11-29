# This is not a hypervisor specific test but one to check the
# functionality of access faults in misaligned memory accesses.

#include "riscv_test.h"
#include "test_macros.h"

#define ALIGNED_LOAD_TEST 1
#define MISALIGNED_LOAD_TEST 2

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
li TESTNUM, 1

# -----------------------------
# Setup access fault
# -----------------------------

la t0, .text.init + (1 << (RISCV_PGSHIFT-1) - 1) # Code
srli t0, t0, PMP_SHIFT
csrw pmpaddr0, t0
la t0, test_data_1                               # Testdata 1
srli t0, t0, PMP_SHIFT
csrw pmpaddr1, t0
la t0, test_data_2                               # Testdata 2
srli t0, t0, PMP_SHIFT
csrw pmpaddr2, t0
la t0, .data + (1 << (RISCV_PGSHIFT-1) - 1)      # Other data
srli t0, t0, PMP_SHIFT
csrw pmpaddr3, t0

li t0, ((PMP_NAPOT | PMP_R | PMP_X))         /* Code may be executed or read */ \
       | ((PMP_NA4 | PMP_R | PMP_W) << 8)    /* Testdata 1 may be read or written */ \
       | ((PMP_NA4) << 16)                   /* Testdata 2 may not be read nor written */ \
       | ((PMP_NAPOT | PMP_R | PMP_W) << 14) /* Rest of data page is readable & writeable */
csrw pmpcfg0, t0

# -----------------------------
# Perform loads
# -----------------------------

la a0, test
RVTEST_MRET_HS(a0)

test:
  la a0, test_data_1
  li TESTNUM, ALIGNED_LOAD_TEST
  lwu t0, 0(a0)      # Aligned load should pass
  li TESTNUM, MISALIGNED_LOAD_TEST
  lwu t0, 2(a0)      # Misaligned load should cause access fault for second part
  j fail

# -----------------------------
# Trap handler overwrite
# -----------------------------

mtvec_handler:
  # Load regs & CSRs so their value is visible in traces
  add TESTNUM, TESTNUM, zero
  csrr a0, mcause
  csrr a1, mepc
  csrr a2, mtval
  # Check testnum & cause
  li t0, MISALIGNED_LOAD_TEST
  bne t0, TESTNUM, fail
  li t0, CAUSE_LOAD_ACCESS
  bne t0, a0, fail
  j pass

TEST_PASSFAIL
RVTEST_CODE_END

.data
test_data_1: .word 0x55555555
test_data_2: .word 0xaaaaaaaa


# Output data section.
RVTEST_DATA_BEGIN
        .align 3
result:
        .dword -1
RVTEST_DATA_END
