# CC = riscv64-unknown-elf-gcc
CC = clang --target=riscv64 # LLVM supports hypervisor-specific instructions & CSRs
CCFLAGS = -g -march=rv64gc -mabi=lp64 -mcmodel=medany -I$(ENVDIR)

LD = riscv64-unknown-elf-ld
LDFLAGS = -static -nostdlib

OBJDUMP = riscv64-unknown-elf-objdump
DUMPFLAGS = -D

ENVDIR = ./common/asm-env/p

%.o: %.S $(ENVDIR)/*.h
	$(CC) -c $(CCFLAGS) -o $@ $<

%.elf: %.o
	$(LD) $(LDFLAGS) -script $(ENVDIR)/link.ld -o $@ $^

%.dump: %.elf
	$(OBJDUMP) -D $< > $@
