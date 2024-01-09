#ifndef VMEM_UTIL_H
#define VMEM_UTIL_H

//-----------------------------------------------------------------------------
// Helper macros
//-----------------------------------------------------------------------------

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
#define PA2VA(pa_reg, base, mask)                                              \
  li t0, mask;                                                                 \
  li t1, base;                                                                 \
  and pa_reg, pa_reg, t0;                                                      \
  or pa_reg, pa_reg, t1;

//-----------------------------------------------------------------------------
// (V)S-stage address translation
//-----------------------------------------------------------------------------

#define PA2VA_UCODE(pa_reg) PA2VA(pa_reg, 0x0000, 0xfff)
#define PA2VA_UDATA(pa_reg) PA2VA(pa_reg, 0x1000, 0xfff)
#define PA2VA_SCODE(pa_reg) PA2VA(pa_reg, 0xfffffffffffff000, 0xfff)
#define PA2VA_SDATA(pa_reg) PA2VA(pa_reg, 0xffffffffffffe000, 0xfff)

#define C_PA2VA_UCODE(pa) C_PA2VA(pa, 0x0000, 0xfff)
#define C_PA2VA_UDATA(pa) C_PA2VA(pa, 0x1000, 0xfff)
#define C_PA2VA_SCODE(pa) C_PA2VA(pa, 0xfffffffffffff000, 0xfff)
#define C_PA2VA_SDATA(pa) C_PA2VA(pa, 0xffffffffffffe000, 0xfff)

//-----------------------------------------------------------------------------
// G-stage address translation
//-----------------------------------------------------------------------------

#define GPA_BASE 0x0
#define SPA2GPA(spa_reg, base, mask) PA2VA(spa_reg, base, mask)
#define C_SPA2GPA(spa, base, mask) C_PA2VA(spa, base, mask)

#define SPA2GPA_VCODE(spa_reg) SPA2GPA(spa_reg, 0x0000, 0xfff)
#define SPA2GPA_HCODE(spa_reg) SPA2GPA(spa_reg, 0x1000, 0xfff)
#define SPA2GPA_HDATA(spa_reg) SPA2GPA(spa_reg, 0x2000, 0xfff)
#define SPA2GPA_VDATA(spa_reg) SPA2GPA(spa_reg, 0x3000, 0xfff)
#define SPA2GPA_UCODE(spa_reg) SPA2GPA(spa_reg, 0x4000, 0xfff)
#define SPA2GPA_UDATA(spa_reg) SPA2GPA(spa_reg, 0x5000, 0xfff)
#define SPA2GPA_SLAT(spa_reg) SPA2GPA(spa_reg, 0x200000, 0x1fffff)

#define C_SPA2GPA_VCODE(spa) C_SPA2GPA(spa, 0x0000, 0xfff)
#define C_SPA2GPA_HCODE(spa) C_SPA2GPA(spa, 0x1000, 0xfff)
#define C_SPA2GPA_HDATA(spa) C_SPA2GPA(spa, 0x2000, 0xfff)
#define C_SPA2GPA_VDATA(spa) C_SPA2GPA(spa, 0x3000, 0xfff)
#define C_SPA2GPA_SLAT(spa) C_SPA2GPA(spa, 0x200000, 0x1fffff)

//-----------------------------------------------------------------------------
// Macros for modifying address translation structures
//-----------------------------------------------------------------------------

/**
 * @brief Update page table entry (pte) bits
 * @param pte_reg Register with pte address
 * @param bits_reg Register with updated pte bits
 * @details Clobbered registers:
 * - `t0`
 * - `t1`
 * - `t2`
 */
#define UPDATE_PTE_BITS(pte_reg, bits_reg)                                     \
  li t0, 0x3ff;                                                                \
  and t1, bits_reg, t0;                                                        \
  not t0, t0;                                                                  \
  ld t2, 0(pte_reg);                                                           \
  and t2, t2, t0;                                                              \
  or t0, t1, t2;                                                               \
  sd t0, 0(pte_reg);

// (V)S-stage PTE handles for tests /* FIXME: Is only correct for SV39 */
#define UCODE_LEAF_PTE                                                         \
  spt + (2 * RISCV_PGSIZE) + (0 * PTESIZE) /* user code leaf pte */
#define UDATA_LEAF_PTE                                                         \
  spt + (2 * RISCV_PGSIZE) + (1 * PTESIZE) /* user data leaf pte */
#define SDATA_LEAF_PTE                                                         \
  spt + (4 * RISCV_PGSIZE) +                                                   \
      (RISCV_PGSIZE - (2 * PTESIZE)) /* supervisor data leaf pte */
#define SCODE_LEAF_PTE                                                         \
  spt + (4 * RISCV_PGSIZE) +                                                   \
      (RISCV_PGSIZE - (1 * PTESIZE)) /* supervisor code leaf pte */

// G-stage PTE handles for tests /* FIXME: Is only correct for SV39x4 */
#define PTR_PTE                                                                \
  gpt + (1 * RISCV_PGSIZE) +                                                   \
      (0 * PTESIZE) /* pointer pte */ /* TODO: Rename to make clear this is    \
                                         G-stage*/
#define SLAT_LEAF_PTE                                                          \
  gpt + (1 * RISCV_PGSIZE) + (1 * PTESIZE) /* S-stage at structure leaf pte */
#define VCODE_LEAF_PTE                                                         \
  gpt + (2 * RISCV_PGSIZE) + (0 * PTESIZE) /* user/supervisor code leaf pte */
#define HCODE_LEAF_PTE                                                         \
  gpt + (2 * RISCV_PGSIZE) + (1 * PTESIZE) /* hypervisor code leaf pte */
#define HDATA_LEAF_PTE                                                         \
  gpt + (2 * RISCV_PGSIZE) + (2 * PTESIZE) /* hypervisor data leaf pte */
#define VDATA_LEAF_PTE                                                         \
  gpt + (2 * RISCV_PGSIZE) + (3 * PTESIZE) /* user/supervisor data leaf pte */

#endif
