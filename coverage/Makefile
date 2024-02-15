BRANCH_TAKEN := $(wildcard ../tests/*/*.cov)
BRANCH_ALL   := ../../sail-riscv/generated_definitions/c/all_branches
SAIL_SRC     := $(wildcard ../../sail-riscv/model/*.sail)

coverage: $(BRANCH_ALL) $(BRANCH_TAKEN) $(SAIL_SRC)
	sailcov --index index -a $(BRANCH_ALL) $(BRANCH_TAKEN:%=-t %) $(SAIL_SRC)

clean:
	rm *.html
