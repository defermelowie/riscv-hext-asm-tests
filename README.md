# RISC-V Hypervisor Tests

[![pipeline status](https://gitlab.kuleuven.be/u0165022/riscv-hyp-tests/badges/main/pipeline.svg)](https://gitlab.kuleuven.be/u0165022/riscv-hyp-tests/-/commits/main)

## About

This repo hosts the unit tests that are used for verifying the RISC-V hypervisor extension [sail model](https://github.com/defermelowie/sail-riscv)

## Test verification

These unit tests are verified using the following H-extension capable emulators/models:
- [x] [spike](https://github.com/riscv-software-src/riscv-isa-sim/tree/master)
- [ ] [minho-pulp/cva6](https://github.com/minho-pulp/cva6) fork of [openhwgroup/cva6](https://github.com/openhwgroup/cva6)
- [ ] [rocket-chip](https://github.com/chipsalliance/rocket-chip) instance

*Details on exact versions etc. can be found in [riscv-ci-env](https://gitlab.kuleuven.be/u0165022/riscv-ci-env)*
