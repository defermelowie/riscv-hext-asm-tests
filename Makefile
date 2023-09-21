RV = riscv64-unknown-elf
ENV = p

CC = $(RV)-gcc
CCFLAGS = -march=rv64g -mabi=lp64 -mcmodel=medany -I$(ENVDIR) -I$(MACROS)
LD = $(RV)-ld
LDFLAGS = -static -nostdlib
DUMP = $(RV)-objdump
OSIM = "./../sail-riscv/ocaml_emulator/riscv_ocaml_sim_RV64 -enable-hext"
CSIM = "./../sail-riscv/c_emulator/riscv_sim_RV64"

SCRDIR = ./src/asm
MACROS = ./src/macro
ENVDIR = ./env/$(ENV)
OBJDIR = ./target
TARGETDIR = ./target
LOGDIR = ./log

EMULATOR = $(OSIM)

_TARGETS += h_ext_enabled.elf h_ext_csr_defined.elf
_TARGETS += mret_M_to_HS.elf mret_M_to_U.elf mret_M_to_VS.elf mret_M_to_VU.elf
_TARGETS += sret_HS_to_U.elf sret_HS_to_VS.elf sret_HS_to_VU.elf sret_VS_to_VU.elf
_TARGETS += ecall_HS_to_M.elf ecall_VS_to_M.elf ecall_VS_to_HS.elf
_TARGETS += ecall_U_to_M.elf ecall_U_to_HS.elf ecall_VU_to_M.elf ecall_VU_to_HS.elf ecall_VU_to_VS.elf
_TARGETS += vs_csr_substitute_s_csr.elf
_TARGETS += read_h_csr_from_U.elf read_h_csr_from_VS.elf read_h_csr_from_VU.elf
_TARGETS += read_s_csr_from_U.elf read_s_csr_from_VS.elf read_s_csr_from_VU.elf
_TARGETS += read_vs_csr_from_U.elf read_vs_csr_from_VS.elf read_vs_csr_from_VU.elf
TARGETS = $(_TARGETS:%=$(TARGETDIR)/%)

.PONY: all

all: setup clean test

setup:
	mkdir -p $(OBJDIR)
	mkdir -p $(TARGETDIR)
	mkdir -p $(LOGDIR)

test: $(TARGETS)
	./script/run_tests.sh $(EMULATOR) $(TARGETDIR) $(LOGDIR) $(_TARGETS)

$(OBJDIR)/%.o: $(SCRDIR)/%.S
	$(CC) -c $(CCFLAGS) -o $@ -c $<

ifneq ($(ENV), v)
# Link without support for virtual mem
$(TARGETDIR)/%.elf: $(OBJDIR)/%.o
	$(LD) $(LDFLAGS) -script $(ENVDIR)/link.ld -o $@ $<
	$(DUMP) -D $@ > $@.dump
else
# Link with virtual memory support
$(TARGETDIR)/%.elf: $(OBJDIR)/%.o vmem-helpers
	$(LD) $(LDFLAGS) -script $(ENVDIR)/link.ld -o $@ $< $(OBJDIR)/vm.o $(OBJDIR)/entry.o $(OBJDIR)/string.o
	$(DUMP) -D $@ > $@.dump
endif

vmem-helpers:
	$(CC) -c $(CCFLAGS) -o $(OBJDIR)/entry.o $(ENVDIR)/entry.S
	$(CC) -c $(CCFLAGS) -o $(OBJDIR)/string.o $(ENVDIR)/string.c
	$(CC) -c $(CCFLAGS) -DENTROPY=0x36f91523 -o $(OBJDIR)/vm.o $(ENVDIR)/vm.c

clean:
	rm -f $(OBJDIR)/*.o
	rm -f $(TARGETDIR)/*.elf
	rm -f $(TARGETDIR)/*.dump
	rm -f $(LOGDIR)/*.log
