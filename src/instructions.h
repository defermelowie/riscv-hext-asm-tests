//-----------------------------------------------------------------------------
// Instructions unkown to the assembler
//-----------------------------------------------------------------------------
#ifndef __INSTR_H
#define __INSTR_H

#define HFENCE_VVMA(asid, vaddr) .insn r 0x73, 0x0, 0x11, x0, vaddr, asid
#define HFENCE_GVMA(vmid, gaddr) .insn r 0x73, 0x0, 0x31, x0, gaddr, vmid

#define HLV_B(rd, vaddr)  .insn r 0b1110011, 0b100, 0b0110000, rd, vaddr, x0
#define HLV_BU(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110000, rd, vaddr, x1
#define HLV_H(rd, vaddr)  .insn r 0b1110011, 0b100, 0b0110010, rd, vaddr, x0
#define HLV_HU(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110010, rd, vaddr, x1
#define HLV_W(rd, vaddr)  .insn r 0b1110011, 0b100, 0b0110100, rd, vaddr, x0
#define HLV_WU(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110100, rd, vaddr, x1
#define HLV_D(rd, vaddr)  .insn r 0b1110011, 0b100, 0b0110110, rd, vaddr, x0

#define HSV_B(vaddr, data) .insn r 0b1110011, 0b100, 0b0110001, x0, vaddr, data
#define HSV_H(vaddr, data) .insn r 0b1110011, 0b100, 0b0110011, x0, vaddr, data
#define HSV_W(vaddr, data) .insn r 0b1110011, 0b100, 0b0110101, x0, vaddr, data
#define HSV_D(vaddr, data) .insn r 0b1110011, 0b100, 0b0110111, x0, vaddr, data

#define HLVX_HU(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110010, rd, vaddr, x3
#define HLVX_WU(rd, vaddr) .insn r 0b1110011, 0b100, 0b0110100, rd, vaddr, x3

#endif