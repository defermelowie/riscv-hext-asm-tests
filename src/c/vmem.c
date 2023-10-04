#include "../encoding.h"
#include "vmem_common.h"

#ifndef __riscv_xlen
#define RISCV_PGSHIFT 12
#define RISCV_PGSIZE (0x1 << RISCV_PGSHIFT)
#endif

#define PTESIZE 8
#define PTECOUNT RISCV_PGSIZE/PTESIZE

/**
 * @brief Type for an 8-byte RV64 page table entry
 */
typedef unsigned long pte_t;

/**
 * @brief Simplified setup of (V)S-level page table
 *
 * @details Sets up a page table where:
 * - `0x000_0000_0000_0xxx` --> paddr_base + 0x0000 (user code page)
 * - `0x000_0000_0000_1xxx` --> paddr_base + 0x3000 (user data page)
 * - `0xfff_ffff_ffff_fxxx` --> paddr_base + 0x0000 (supervisor code page)
 * - `0xfff_ffff_ffff_exxx` --> paddr_base + 0x3000 (supervisor data page)
 * @param pt Page table base address
 * @param paddr_base Guest physical base address
 */
void setup_spt(pte_t pt[5][PTECOUNT], unsigned long paddr_base)
{
  pt[0][0] = (SPA2GPA_C((pte_t)pt[1]) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[1][0] = (SPA2GPA_C((pte_t)pt[2]) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[2][0] = (SPA2GPA_C((pte_t)paddr_base + 0x0000) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_X | PTE_U | PTE_D | PTE_A;
  pt[2][1] = (SPA2GPA_C((pte_t)paddr_base + 0x3000) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_W | PTE_U | PTE_D | PTE_A;

  pt[0][PTECOUNT-1] = (SPA2GPA_C((pte_t)pt[3]) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[3][PTECOUNT-1] = (SPA2GPA_C((pte_t)pt[4]) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[4][PTECOUNT-1] = (SPA2GPA_C((pte_t)paddr_base + 0x0000) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_X | PTE_D | PTE_A;
  pt[4][PTECOUNT-2] = (SPA2GPA_C((pte_t)paddr_base + 0x3000) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_W | PTE_D | PTE_A;
}

/**
 * @brief Simplified setup of G-stage page table
 *
 * @details Sets up a page table where:
 * - `0x000_0000_0000_0xxx` --> paddr_base (code page)
 * - `0x000_0000_002x_xxxx` --> paddr_base (data superpage)
 *
 * @param pt Page table base address
 * @param paddr_base Supervisor physical base address
 */
void setup_gpt(pte_t pt[3][PTECOUNT], unsigned long paddr_base)
{
  pt[0][0] = ((pte_t)pt[1] >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[1][0] = ((pte_t)pt[2] >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[1][1] = ((pte_t)paddr_base >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_W | PTE_U | PTE_D | PTE_A;
  pt[2][0] = ((pte_t)paddr_base >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_D | PTE_A;
}
