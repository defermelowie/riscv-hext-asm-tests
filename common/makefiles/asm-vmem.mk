# CC = riscv64-unknown-elf-gcc
CC = clang --target=riscv64 # LLVM supports hypervisor-specific instructions & CSRs
CCFLAGS = -g -march=rv64gc -mabi=lp64 -mcmodel=medany -I$(ENVDIR) -I$(VMEMLIB)

LD = riscv64-unknown-elf-ld
LDFLAGS = -static -nostdlib

OBJDUMP = riscv64-unknown-elf-objdump
DUMPFLAGS = -D

ENVDIR = ./common/asm-env/slat
VMEMLIB = ./common/lib-vmem

RISCV_SVADU ?= false
ifeq ($(RISCV_SVADU), true)
	CCFLAGS += -D SVADU_EXT
endif

vmem.o: $(VMEMLIB)/vmem.c $(ENVDIR)/*.h $(VMEMLIB)/*.h
	$(CC) -c $(CCFLAGS) -o $@ $<

%.o: %.S $(ENVDIR)/*.h $(VMEMLIB)/*.h
	$(CC) -c $(CCFLAGS) -o $@ $<

%.elf: %.o vmem.o
	$(LD) $(LDFLAGS) -script $(ENVDIR)/link.ld -o $@ $^

%.dump: %.elf
	$(OBJDUMP) -D $< > $@
