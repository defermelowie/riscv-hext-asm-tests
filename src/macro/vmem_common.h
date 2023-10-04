/**
 * @file vmem_common.h
 * @brief Common vmem macros
 * @version 0.1
 * @date 2023-09-28
 */

#ifdef G_STAGE_AT

#define GPA_BASE 0x0

/**
 * @brief Convert a supervisor physical address to guest physical address
 * @param spa_reg Register holding the supervisor physical address
 * @par Clobbered registers
 * - `t0`
 * - `t1`
 * @return The guest physical address inside `spa_reg`
 */
#define SPA2GPA_ASM(spa_reg) \
  li t0, 0x00000000001fffff; \
  li t1, 0x0000000000200000; \
  and spa_reg, spa_reg, t0;  \
  or spa_reg, spa_reg, t1

/**
 * @brief Convert a supervisor physical address to guest physical address
 * @param spa Supervisor physical address to convert
 * @return Guest physical address
 */
#define SPA2GPA_C(spa) ((spa & 0x00000000001fffff) | 0x0000000000200000)

#else

#define GPA_BASE 0x80000000

#define SPA2GPA_ASM(spa_reg) nop;

#define SPA2GPA_C(spa) (spa)

#endif
