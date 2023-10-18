RV = riscv64-unknown-elf
ENV = p

# CC = $(RV)-gcc
CC = clang --target=riscv64 # LLVM assembler supports hypervisor-specific instructions
CCFLAGS = -march=rv64g -mabi=lp64 -mcmodel=medany -I$(ENVDIR) -I$(MACROS)
LD = $(RV)-ld
LDFLAGS = -static -nostdlib
OBJDUMP = $(RV)-objdump
OSIM = "./../sail-riscv/ocaml_emulator/riscv_ocaml_sim_RV64 -enable-hext"
CSIM = "./../sail-riscv/c_emulator/riscv_sim_RV64"

SCRDIR = ./src/asm
MACROS = ./src/macro
ENVDIR = ./env/$(ENV)
OBJDIR = ./target
TARGETDIR = ./target
DUMPDIR = ./target
LOGDIR = ./log

EMULATOR = $(CSIM)

TARGETS += h_ext_enabled h_ext_csr_defined
TARGETS += mret_M_to_HS mret_M_to_U mret_M_to_VS mret_M_to_VU
TARGETS += sret_HS_to_U sret_HS_to_VS sret_HS_to_VU sret_VS_to_VU
TARGETS += ecall_HS_to_M ecall_VS_to_M ecall_VS_to_HS
TARGETS += ecall_U_to_M ecall_U_to_HS ecall_VU_to_M ecall_VU_to_HS ecall_VU_to_VS
TARGETS += vs_csr_substitute_s_csr
TARGETS += read_h_csr_from_U read_h_csr_from_VS read_h_csr_from_VU
TARGETS += read_s_csr_from_U read_s_csr_from_VS read_s_csr_from_VU
TARGETS += read_vs_csr_from_U read_vs_csr_from_VS read_vs_csr_from_VU
TARGETS += vmem_VU_at_independent_from_satp vmem_U_at_independent_from_vsatp vmem_S_at_independent_from_vsatp vmem_VS_at_independent_from_satp
TARGETS += vmem_S_U_39 vmem_S_U_48 #vmem_S_U_57
TARGETS += vmem_HS_39_VS_VU_39 vmem_HS_39_VS_VU_48 #vmem_HS_39_VS_VU_57

# TARGETS += ci_infinite_loop ci_direct_fail # Only for CI debug

.PONY: all
all: dump test

.PONY: setup
setup:
	mkdir -p $(OBJDIR)
	mkdir -p $(TARGETDIR)
	mkdir -p $(LOGDIR)

.PONY: clean
clean:
	rm -f $(OBJDIR)/*.o
	rm -f $(TARGETDIR)/*.elf
	rm -f $(TARGETDIR)/*.dump
	rm -f $(LOGDIR)/*.log

.PONY: dump
dump: $(TARGETS:%=$(DUMPDIR)/%.dump)

.PONY: test
test: $(TARGETS:%=$(TARGETDIR)/%.elf)
	./script/run_tests.sh $(EMULATOR) $(TARGETDIR) $(LOGDIR) $(TARGETS)

.PONY: spike
spike:
	./script/verif_on_spike.sh spike $(TARGETDIR) $(LOGDIR) $(TARGETS)

$(OBJDIR)/vmem.o: ./src/c/vmem.c
	$(CC) -c $(CCFLAGS) -o $@ -c $<

$(OBJDIR)/%.o: $(SCRDIR)/%.S
	$(CC) -c $(CCFLAGS) -o $@ -c $<

$(DUMPDIR)/%.dump: $(TARGETDIR)/%.elf
	$(OBJDUMP) -D $< > $@

$(LOGDIR)/%.verif.log: $(TARGETDIR)/%.elf
	$(SPIKE) -l --isa=RV64gh $< 2> $@

$(LOGDIR)/%.test.log: $(TARGETDIR)/%.elf
	$(EMULATOR) $< > $@

ifneq ($(ENV), v)
# Link without support for virtual mem
$(TARGETDIR)/%.elf: $(OBJDIR)/%.o $(OBJDIR)/vmem.o
	$(LD) $(LDFLAGS) -script $(ENVDIR)/link.ld -o $@ $^
else
# Link with virtual memory support
$(TARGETDIR)/%.elf: $(OBJDIR)/%.o vmem-helpers
	$(LD) $(LDFLAGS) -script $(ENVDIR)/link.ld -o $@ $< $(OBJDIR)/vm.o $(OBJDIR)/entry.o $(OBJDIR)/string.o
endif

vmem-helpers:
	$(CC) -c $(CCFLAGS) -o $(OBJDIR)/entry.o $(ENVDIR)/entry.S
	$(CC) -c $(CCFLAGS) -o $(OBJDIR)/string.o $(ENVDIR)/string.c
	$(CC) -c $(CCFLAGS) -DENTROPY=0x36f91523 -o $(OBJDIR)/vm.o $(ENVDIR)/vm.c
