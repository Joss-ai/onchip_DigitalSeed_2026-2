# UART Reciver timing and control

This repository contains the design and formal verification of the reciver timing and control for a UART system.

## Directory Structure

```text
4_activity/
├── README.md
├── Formal/
    ├── SRC_Formal/ # Source code and .sby configuration for the reciver timing and control   
    ├── Results/ # Source code and .sby configuration for the Receiver FIFO 
    └── README.md
└── SRC/ # Source code for the Receiver FIFO
    └── README.md


To run formal verification on the SystemVerilog modules using SymbiYosys, use the following command and configuration structure:

sby -f archivo.sby to execute

Note: The -f flag forces SymbiYosys to overwrite any previous output directories and execute a clean run.

sby Configuration Structure:

[options]
# Specifies the verification mode:
# - bmc: Bounded Model Checking (searches for assertion failures within fixed clock cycles)
# - prove: Complete proof / k-induction (verifies the design for all cycles)
# - cover: Reachability analysis (verifies that 'cover' statements can be reached)
mode bmc
depth 1   # Sets the unrolling depth (number of clock cycles to verify)

[engines]
# Selects the solver engine:
# - smtbmc: Standard Yosys solver for SMT-based model checking (default for BMC/prove)
# - abc: Useful for hardware logic optimization and specific proof strategies
smtbmc

[script]
# List of RTL files to compile for formal verification
read -formal bcd.sv

# Prepares and synthesizes the design defining the top-level module under test
prep -top bcd_inc

[files]
# Local source files copied into the SymbiYosys workspace
bcd.sv