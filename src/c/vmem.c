#include "../encoding.h"
#include "vmem_common.h"

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
  pt[0][0] = (C_SPA2GPA_SLAT((pte_t)pt[1]) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[1][0] = (C_SPA2GPA_SLAT((pte_t)pt[2]) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[2][0] = (C_SPA2GPA_SLAT((pte_t)paddr_base + 0x0000) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | 0x000 | PTE_X | PTE_U | PTE_D | PTE_A;
  pt[2][1] = (C_SPA2GPA_SLAT((pte_t)paddr_base + 0x3000) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_W | 0x000 | PTE_U | PTE_D | PTE_A;

  pt[0][PTECOUNT-1] = (C_SPA2GPA_SLAT((pte_t)pt[3]) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[3][PTECOUNT-1] = (C_SPA2GPA_SLAT((pte_t)pt[4]) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[4][PTECOUNT-1] = (C_SPA2GPA_SLAT((pte_t)paddr_base + 0x0000) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | 0x000 | PTE_X | PTE_D | PTE_A;
  pt[4][PTECOUNT-2] = (C_SPA2GPA_SLAT((pte_t)paddr_base + 0x3000) >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_W | 0x000 | PTE_D | PTE_A;
}

/**
 * @brief Simplified setup of G-stage page table
 *
 * @details Sets up a page table where:
 * - `0x000_0000_0000_0xxx` --> paddr_code_base (user/supervisor code page)
 * - `0x000_0000_0000_1xxx` --> paddr_code_base (hypervisor code page)
 * - `0x000_0000_0000_2xxx` --> paddr_code_base (hypervisor data page)
 * - `0x000_0000_0000_3xxx` --> paddr_data_base (user/supervisor data page)
 * - `0x000_0000_002x_xxxx` --> paddr_data_base (user/supervisor data superpage for SLAT structures)
 *
 * @param pt Page table base address
 * @param paddr_code_base Supervisor physical base address of code
 * @param paddr_data_base Supervisor physical base address of data
 */
void setup_gpt(pte_t pt[3][PTECOUNT], unsigned long paddr_code_base, unsigned long paddr_data_base)
{
  pt[0][0] = ((pte_t)pt[1] >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[1][0] = ((pte_t)pt[2] >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V;
  pt[1][1] = ((pte_t)paddr_data_base >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_W | PTE_X | PTE_U | PTE_D | PTE_A;
  pt[2][0] = ((pte_t)paddr_code_base >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | 0x000 | PTE_X | PTE_U | PTE_D | PTE_A;
  pt[2][1] = ((pte_t)paddr_code_base >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | 0x000 | PTE_X | 0x000 | PTE_D | PTE_A;
  pt[2][2] = ((pte_t)paddr_data_base >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_W | 0x000 | 0x000 | PTE_D | PTE_A;
  pt[2][3] = ((pte_t)paddr_data_base >> RISCV_PGSHIFT << PTE_PPN_SHIFT) | PTE_V | PTE_R | PTE_W | 0x000 | PTE_U | PTE_D | PTE_A;
}
