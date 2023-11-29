# CC = riscv64-unknown-elf-gcc -march=rv64g
CC = clang --target=riscv64 -march=rv64gch # LLVM assembler supports hypervisor-specific instructions
CCFLAGS = -mabi=lp64 -mcmodel=medany -I$(ENVDIR)

LD = riscv64-unknown-elf-ld
LDFLAGS = -static -nostdlib

OBJDUMP = riscv64-unknown-elf-objdump

OSIMFLAGS = -enable-hext -enable-dirty-update -mtval-has-illegal-inst-bits -xtinst-has-transformed-inst -enable-pmp
OSIM64 = "./../sail-riscv/ocaml_emulator/riscv_ocaml_sim_RV64 $(OSIMFLAGS)"
OSIM32 = "./../sail-riscv/ocaml_emulator/riscv_ocaml_sim_RV64 $(OSIMFLAGS)"

CSIMFLAGS = --enable-dirty-update --mtval-has-illegal-inst-bits --enable-pmp #--xtinst-has-transformed-inst
CSIM64 = "./../sail-riscv/c_emulator/riscv_sim_RV64 $(CSIMFLAGS)"
CSIM32 = "./../sail-riscv/c_emulator/riscv_sim_RV32 $(CSIMFLAGS)"

ENVDIR = ./env/slat
SCRDIR = ./src

OBJDIR = ./target
TARGETDIR = ./target
DUMPDIR = ./target
LOGDIR = ./log

EMULATOR = $(CSIM64)

RISCV_SVADU ?= false
ifeq ($(RISCV_SVADU), true)
	CCFLAGS += -D SVADU_EXT
endif

#-------------------------------------------------#
#                  List of tests                  #
#-------------------------------------------------#

TARGETS += h_ext_enabled h_ext_csr_defined
TARGETS += mret_M_to_HS mret_M_to_U mret_M_to_VS mret_M_to_VU
TARGETS += sret_HS_to_U sret_HS_to_VS sret_HS_to_VU sret_VS_to_VU
TARGETS += ecall_HS_to_M ecall_VS_to_M ecall_VS_to_HS
TARGETS += ecall_U_to_M ecall_U_to_HS ecall_VU_to_M ecall_VU_to_HS ecall_VU_to_VS
TARGETS += vs_csr_substitute_s_csr
TARGETS += read_h_csr_from_U read_h_csr_from_VS read_h_csr_from_VU
TARGETS += read_s_csr_from_U read_s_csr_from_VS read_s_csr_from_VU
TARGETS += read_vs_csr_from_U read_vs_csr_from_VS read_vs_csr_from_VU
TARGETS += hfence_vvma_ill_inst hfence_vvma_virt_inst
TARGETS += vmem_VU_at_independent_from_satp vmem_U_at_independent_from_vsatp vmem_S_at_independent_from_vsatp vmem_VS_at_independent_from_satp
TARGETS += at_S_U_39 at_S_U_48 # at_S_U_57
TARGETS += at_S_39_update_pte_A at_S_39_update_pte_D
TARGETS += slat_HS_39_VS_VU_39 slat_HS_39_VS_VU_48 # slat_HS_39_VS_VU_57
TARGETS += slat_VS_39_update_pte_A slat_VS_39_update_pte_D
TARGETS += slat_HS_39_VS_39_gpage_fault
TARGETS += hlv_M hlv_HS_spvp_1 hlv_HS_spvp_0 hlv_U_spvp_1 hlv_U_spvp_0
# TARGETS += hsv_M hsv_HS_spvp_1 hsv_HS_spvp_0 hsv_U_spvp_1 hsv_U_spvp_0
# TARGETS += hlvx_M hlvx_HS_spvp_1 hlvx_HS_spvp_0 hlvx_U_spvp_1 hlvx_U_spvp_0
TARGETS += tinst_load tinst_store tinst_amo tinst_vm_load_store
TARGETS += misaligned_pmp

# TARGETS += ci_infinite_loop ci_direct_fail # Only for CI debug

#-------------------------------------------------#
#            Targets for model testing            #
#-------------------------------------------------#

.PONY: all
all: setup clean build dump test

.PONY: setup
setup:
	mkdir -p $(OBJDIR)
	mkdir -p $(TARGETDIR)
	mkdir -p $(DUMPDIR)
	mkdir -p $(LOGDIR)

.PONY: clean
clean:
	rm -f $(OBJDIR)/*.o
	rm -f $(TARGETDIR)/*.elf
	rm -f $(DUMPDIR)/*.dump
	rm -f $(LOGDIR)/*.log

.PONY: build
build: $(TARGETS:%=$(TARGETDIR)/%.elf)

.PONY: dump
dump: $(TARGETS:%=$(DUMPDIR)/%.dump)

.PONY: test
test: build
	./script/run_tests.sh $(EMULATOR) $(TARGETDIR) $(LOGDIR) $(TARGETS)

# Support for G-stage virtual memory
$(OBJDIR)/vmem.o: $(ENVDIR)/vmem.c
	$(CC) -c $(CCFLAGS) -o $@ $<

$(OBJDIR)/%.o: $(SCRDIR)/%.S
	$(CC) -c $(CCFLAGS) -o $@ $<

$(DUMPDIR)/%.dump: $(TARGETDIR)/%.elf
	$(OBJDUMP) -D $< > $@

$(LOGDIR)/%.test.log: $(TARGETDIR)/%.elf
	$(EMULATOR) $< > $@

$(TARGETDIR)/%.elf: $(OBJDIR)/%.o $(OBJDIR)/vmem.o
	$(LD) $(LDFLAGS) -script $(ENVDIR)/link.ld -o $@ $^

#-------------------------------------------------#
#       Targets for test verification (CI)        #
#-------------------------------------------------#

.PONY: spike
spike:
	./script/verif_on_spike.sh spike $(TARGETDIR) $(LOGDIR) $(TARGETS)
