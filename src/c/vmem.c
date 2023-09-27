#include "../encoding.h"

#ifndef __riscv_xlen
#define RISCV_PGSHIFT 12
#define RISCV_PGSIZE (0x1 << RISCV_PGSHIFT)
#endif

#define PAGECOUNT 4
#define PTECOUNT RISCV_PGSIZE/8

/**
 * @brief Type for an 8-byte RV64 page table entry
 */
typedef unsigned long pte_t;

/**
 * @brief Setup of (V)S-level page table
 * @details
 * Sets up a page table where:
 * - 0x000_0000_0000_0xxx is mapped to paddr_base as user page
 * - 0xfff_ffff_ffff_fxxx is mapped to paddr_base as supervisor page
 * @param pt_base Page table base address
 */
void setup_spt(pte_t pt[PAGECOUNT][PTECOUNT], unsigned long paddr_base)
{
  pt[0][0] = ((pte_t)pt[1] >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[1][0] = ((pte_t)pt[2] >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[2][0] = ((pte_t)paddr_base >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_D | PTE_A;

  pt[0][PTECOUNT-1] = ((pte_t)pt[3] >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[3][PTECOUNT-1] = ((pte_t)pt[4] >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[4][PTECOUNT-1] = ((pte_t)paddr_base >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_W | PTE_X | PTE_D | PTE_A;
}
