#include "riscv_test.h"

#ifndef HTIF_H
#define HTIF_H

// Source: OpenSBI
#define HTIF_DATA_BITS 48
#define HTIF_DATA_MASK ((1ULL << HTIF_DATA_BITS) - 1)
#define HTIF_DATA_SHIFT 0
#define HTIF_CMD_BITS 8
#define HTIF_CMD_MASK ((1ULL << HTIF_CMD_BITS) - 1)
#define HTIF_CMD_SHIFT 48
#define HTIF_DEV_BITS 8
#define HTIF_DEV_MASK ((1ULL << HTIF_DEV_BITS) - 1)
#define HTIF_DEV_SHIFT 56

#define HTIF_DEV_SYSTEM 0
#define HTIF_DEV_CONSOLE 1
#define HTIF_CONSOLE_CMD_GETC 0
#define HTIF_CONSOLE_CMD_PUTC 1

#endif

RVTEST_RV64M
RVTEST_CODE_BEGIN

.align 2
li TESTNUM, 1
la s0, tohost
la s1, fromhost

// TEST: Read 10 characters from HTIF console
li a1, 10
loop:
  // Write cmd to htif.tohost and read htif.fromhost
  li a0, (HTIF_DEV_CONSOLE << HTIF_DEV_SHIFT) | (HTIF_CONSOLE_CMD_GETC << HTIF_CMD_SHIFT)
  sd a0, 0(s0)
  ld t1, 0(s1)
  // Decrease loop counter & jump
  addi a1, a1, -1
  bnez a1, loop

// FIXME: Succeeds unconditionally
j pass

RVTEST_PASSFAIL
RVTEST_CODE_END

.data

# Output data section.
RVTEST_DATA_BEGIN
        .align 3

result:
        .dword -1
RVTEST_DATA_END
