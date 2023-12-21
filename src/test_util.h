//-----------------------------------------------------------------------------
// Instructions unknown to the assembler
//-----------------------------------------------------------------------------
#ifndef __INSTR_H
#define __INSTR_H

#define HFENCE_VVMA(asid, vaddr) .insn r 0x73, 0x0, 0x11, x0, vaddr, asid
#define HFENCE_GVMA(vmid, gaddr) .insn r 0x73, 0x0, 0x31, x0, gaddr, vmid

#define HLV_B(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110000, rd, vaddr, x0
#define HLV_BU(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110000, rd, vaddr, x1
#define HLV_H(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110010, rd, vaddr, x0
#define HLV_HU(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110010, rd, vaddr, x1
#define HLV_W(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110100, rd, vaddr, x0
#define HLV_WU(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110100, rd, vaddr, x1
#define HLV_D(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110110, rd, vaddr, x0

#define HSV_B(vaddr, data) .insn r 0b1110011, 0b100, 0b0110001, x0, vaddr, data
#define HSV_H(vaddr, data) .insn r 0b1110011, 0b100, 0b0110011, x0, vaddr, data
#define HSV_W(vaddr, data) .insn r 0b1110011, 0b100, 0b0110101, x0, vaddr, data
#define HSV_D(vaddr, data) .insn r 0b1110011, 0b100, 0b0110111, x0, vaddr, data

#define HLVX_HU(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110010, rd, vaddr, x3
#define HLVX_WU(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110100, rd, vaddr, x3

#endif

//-----------------------------------------------------------------------------
// Instructions known to the assembler which raise build errors when used
// incorrectly (which is what we want to test sometimes)
//-----------------------------------------------------------------------------
#ifndef __INSTR_RAW
#define __INSTR_RAW

// Note: Since .insn i expects a signed value, `csr` should be converted

#define CSRRW_RAW(rd, csr, rs1)                                                \
  .if 0x800 > csr;                                                             \
  .insn i 0b1110011, 0b001, rd, rs1, csr;                                      \
  .else;                                                                       \
  .insn i 0b1110011, 0b001, rd, rs1, 0x800 - csr;                              \
  .endif;

#define CSRRS_RAW(rd, csr, rs1)                                                \
  .if 0x800 > csr;                                                             \
  .insn i 0b1110011, 0b010, rd, rs1, csr;                                      \
  .else;                                                                       \
  .insn i 0b1110011, 0b010, rd, rs1, 0x800 - csr;                              \
  .endif;

#define CSRRC_RAW(rd, csr, rs1)                                                \
  .if 0x800 > csr;                                                             \
  .insn i 0b1110011, 0b011, rd, rs1, csr;                                      \
  .else;                                                                       \
  .insn i 0b1110011, 0b011, rd, rs1, 0x800 - csr;                              \
  .endif;

#endif

//-----------------------------------------------------------------------------
// Convenience routines for interrupt setup
//-----------------------------------------------------------------------------

#ifndef __INT_MACRO
#define __INT_MACRO

#define GET_MTIME(rreg)                                                        \
  li rreg, CLINT_BASE | 0xbff8;                                                \
  ld rreg, 0(rreg)

#define SET_MTIME(areg)                                                        \
  li t0, CLINT_BASE | 0xbff8;                                                  \
  sd areg, 0(t0)

#define SET_MTIMECMP(areg)                                                     \
  li t0, CLINT_BASE | 0x4000;                                                  \
  sd areg, 0(t0)

/**
 * @brief Let a machine-timer-interrupt cause a supervisor-timer-interrupt
 * @param cause General purpose register holding the trap cause
 */
#define PROMOTE_MTI_TO_STI(cause)                                              \
  li t0, CAUSE_MACHINE_TIMER_I;                                                \
  bne cause, t0, skip;                                                         \
  li t0, MIP_MTIP;                                                             \
  csrc mie, t0;                                                                \
  li t0, MIP_STIP;                                                             \
  csrw mip, t0;                                                                \
  mret;                                                                        \
  nop;                                                                         \
  skip:

#endif
