#define G_STAGE_AT // Can be disabled for debugging

#ifndef __riscv_xlen
#define RISCV_PGSHIFT 12
#define RISCV_PGSIZE (0x1 << RISCV_PGSHIFT)
#define RISCV_PGLEVEL_BITS 9
#endif

#define PTESIZE 8
#define PTECOUNT (RISCV_PGSIZE / PTESIZE)

#define RISCV_L1_SPGSHIFT (RISCV_PGSHIFT + RISCV_PGLEVEL_BITS)
#define RISCV_L2_SPGSHIFT (RISCV_L1_SPGSHIFT + RISCV_PGLEVEL_BITS)

/**
 * @brief Convert a physical address to virtual address in C
 * @param pa Physical address
 * @param base Base of virtual address page
 * @param mask Mask of offset bits (`0xfff` unless superpage)
 * @return Guest physical address
 */
#define C_PA2VA(pa, base, mask) ((pa & mask) | base)

/**
 * @brief Convert a physical address to virtual address in assembly
 * @param pa_reg Register holding the physical address
 * @param base Base of virtual address page
 * @param mask Mask of offset bits (`0xfff` unless superpage)
 * @details Clobbered registers
 * - `t0`
 * - `t1`
 * @return Physical address inside `pa_reg`
 */
#define ASM_PA2VA(pa_reg, base, mask) \
  li t0, mask;                        \
  li t1, base;                        \
  and pa_reg, pa_reg, t0;             \
  or pa_reg, pa_reg, t1;

//-----------------------------------------------------------------------------
// (V)S-stage address translation
//-----------------------------------------------------------------------------
#define ASM_PA2VA_UCODE(pa_reg) ASM_PA2VA(pa_reg, 0x0000, 0xfff)
#define ASM_PA2VA_UDATA(pa_reg) ASM_PA2VA(pa_reg, 0x1000, 0xfff)
#define ASM_PA2VA_SCODE(pa_reg) ASM_PA2VA(pa_reg, 0xfffffffffffff000, 0xfff)
#define ASM_PA2VA_SDATA(pa_reg) ASM_PA2VA(pa_reg, 0xffffffffffffe000, 0xfff)

#define C_PA2VA_UCODE(pa) C_PA2VA(pa, 0x0000, 0xfff)
#define C_PA2VA_UDATA(pa) C_PA2VA(pa, 0x1000, 0xfff)
#define C_PA2VA_SCODE(pa) C_PA2VA(pa, 0xfffffffffffff000, 0xfff)
#define C_PA2VA_SDATA(pa) C_PA2VA(pa, 0xffffffffffffe000, 0xfff)

//-----------------------------------------------------------------------------
// G-stage address translation
//-----------------------------------------------------------------------------
#ifdef G_STAGE_AT
#define GPA_BASE 0x0
#define SPA_CODE_BASE DRAM_BASE
#define ASM_SPA2GPA(spa_reg, base, mask) ASM_PA2VA(spa_reg, base, mask)
#define C_SPA2GPA(spa, base, mask) C_PA2VA(spa, base, mask)
#else
#define GPA_BASE DRAM_BASE
#define ASM_SPA2GPA(spa_reg, base, mask) nop;
#define C_SPA2GPA(spa, base, mask) (spa)
#endif

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
