#ifndef __riscv_xlen
#define RISCV_PGSHIFT 12
#define RISCV_PGSIZE (0x1 << RISCV_PGSHIFT)
#define RISCV_PGLEVEL_BITS 9
#endif

#define G_STAGE_AT // Debug only

#ifdef G_STAGE_AT
#define GPA_BASE 0x0
/**
 * @brief Convert a spa to gpa
 * @param spa_reg Register holding the supervisor physical address
 * @param base Base of guest physical address
 * @param mask Mask of offset bits (`0xfff` unless superpage)
 * @details Clobbered registers
 * - `t0`
 * - `t1`
 * @return Guest physical address inside `spa_reg`
 */
#define ASM_SPA2GPA(spa_reg, base, mask) \
  li t0, mask;                           \
  li t1, base;                           \
  and spa_reg, spa_reg, t0;              \
  or spa_reg, spa_reg, t1;
/**
 * @brief Convert a SLAT structure spa to gpa
 * @param spa Supervisor physical address
 * @param base Base of guest physical address
 * @param mask Mask of offset bits (`0xfff` unless superpage)
 * @return Guest physical address
 */
#define C_SPA2GPA(spa, base, mask) ((spa & mask) | base)
#else
#define GPA_BASE DRAM_BASE
#define ASM_SPA2GPA(spa_reg, base, mask) nop;
#define C_SPA2GPA(spa, base, mask) (spa)
#endif

#define PTESIZE 8
#define PTECOUNT (RISCV_PGSIZE / PTESIZE)

#define RISCV_L1_SPGSHIFT (RISCV_PGSHIFT + RISCV_PGLEVEL_BITS)
#define RISCV_L2_SPGSHIFT (RISCV_L1_SPGSHIFT + RISCV_PGLEVEL_BITS)

#define ASM_SPA2GPA_VCODE(spa_reg) ASM_SPA2GPA(spa_reg, 0x0000, 0xfff)
#define ASM_SPA2GPA_HCODE(spa_reg) ASM_SPA2GPA(spa_reg, 0x1000, 0xfff)
#define ASM_SPA2GPA_HDATA(spa_reg) ASM_SPA2GPA(spa_reg, 0x2000, 0xfff)
#define ASM_SPA2GPA_VDATA(spa_reg) ASM_SPA2GPA(spa_reg, 0x3000, 0xfff)
#define ASM_SPA2GPA_SLAT(spa_reg) ASM_SPA2GPA(spa_reg, 0x200000, 0x1fffff)

#define C_SPA2GPA_VCODE(spa) C_SPA2GPA(spa, 0x0000, 0xfff)
#define C_SPA2GPA_HCODE(spa) C_SPA2GPA(spa, 0x1000, 0xfff)
#define C_SPA2GPA_HDATA(spa) C_SPA2GPA(spa, 0x2000, 0xfff)
#define C_SPA2GPA_VDATA(spa) C_SPA2GPA(spa, 0x3000, 0xfff)
#define C_SPA2GPA_SLAT(spa) C_SPA2GPA(spa, 0x200000, 0x1fffff)

#define ASM_GPA2VA_UCODE(gpa_reg) ASM_SPA2GPA(gpa_reg, 0x0000, 0xfff)
#define ASM_GPA2VA_UDATA(gpa_reg) ASM_SPA2GPA(gpa_reg, 0x1000, 0xfff)
#define ASM_GPA2VA_SCODE(gpa_reg) ASM_SPA2GPA(gpa_reg, 0xfffffffffffff000, 0xfff)
#define ASM_GPA2VA_SDATA(gpa_reg) ASM_SPA2GPA(gpa_reg, 0xffffffffffffe000, 0xfff)
