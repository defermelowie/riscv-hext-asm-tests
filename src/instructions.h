//-----------------------------------------------------------------------------
// Instructions unkown to the assembler
//-----------------------------------------------------------------------------
#ifndef __INSTR_H
#define __INSTR_H

#define HFENCE_VVMA(asid, vaddr) .insn r 0x73, 0x0, 0x11, x0, vaddr, asid
#define HFENCE_GVMA(vmid, gaddr) .insn r 0x73, 0x0, 0x31, x0, gaddr, vmid

#define HLV_B(rd, rs1)  .insn r 0b1110011, 0b100, 0b0110000, rd, rs1, x0
#define HLV_BU(rd, rs1) .insn r 0b1110011, 0b100, 0b0110000, rd, rs1, x1
#define HLV_H(rd, rs1)  .insn r 0b1110011, 0b100, 0b0110010, rd, rs1, x0
#define HLV_HU(rd, rs1) .insn r 0b1110011, 0b100, 0b0110010, rd, rs1, x1
#define HLV_W(rd, rs1)  .insn r 0b1110011, 0b100, 0b0110100, rd, rs1, x0
#define HLV_WU(rd, rs1) .insn r 0b1110011, 0b100, 0b0110100, rd, rs1, x1
#define HLV_D(rd, rs1)  .insn r 0b1110011, 0b100, 0b0110110, rd, rs1, x0

#endif
