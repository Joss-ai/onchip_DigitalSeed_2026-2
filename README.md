# OnChip_DigitalSeed_2026-2

This repository documents the activities, experiments, and hardware implementations developed within the **OnChip Research Group** during the 2026-2 academic period.

The main focus is on digital integrated circuit (IC) design, exploring open-source tools and methodologies for RTL design, physical implementation, performance optimization, and hardware verification.

The repository is organized into four main activities covering different stages of the digital design process, from RTL description to formal verification.

## Activities

### 1. RTL-to-GDSII: Open-Source Digital Design Flow

**Directory:** `1_activity/`

The first activity explores an open-source RTL-to-GDSII digital design flow using the JKU container environment and the `sky130A` Process Design Kit (PDK).

As a case study, an encoder was designed for an Analog-to-Digital Converter (ADC) application. This exercise introduces the initial stages of digital hardware implementation, starting from RTL description and progressing toward physical design.

The directory contains:

- **RTL:** Hardware description of the encoder, including its corresponding testbench and expected simulation waveforms.
- **GDS:** Configuration files for the physical implementation flow, including `config.json`, which contains the initial parameters required to execute the process.

### 2. FIFO Design and PPA Optimization

**Directory:** `2_activity/`

This activity focuses on the design and implementation of a FIFO (First-In, First-Out) memory, exploring different RTL architectures and their impact on hardware performance and area.

The initial implementation uses D-type flip-flops (DFFs) to construct an 8-bit-wide FIFO with 16 storage locations.

The main objective is to investigate architectural improvements and optimize the Figure of Merit (FOM), defined for this activity as:

\[
FOM = \frac{f_{max}}{P \cdot A}
\]

Where:

- \(f_{max}\): Maximum operating frequency.
- \(P\): Power consumption.
- \(A\): Physical area.

The directory contains:

- **src:** RTL hardware descriptions and design components.
- **GDSI:** Configuration files for the digital implementation flow, including additional parameters compared to the previous activity.

### 3. Introduction to UVM-Based Verification

**Directory:** `3_activity/`

This activity introduces the fundamentals of the Universal Verification Methodology (UVM), focusing on the development of structured verification environments using SystemVerilog and open-source tools.

As an initial exercise, two fundamental components were developed:

- **Transaction:** Defines the data structures used to represent verification transactions.
- **Generator:** Produces the stimulus transactions that will be used during the verification process.

Verilator is used as the simulation tool to explore the execution of the verification environment.

The directory includes RTL descriptions, testbench components, simulation files, figures, and supplementary documentation related to the verification interface.

**Status:** In progress. Integration of the remaining verification components and the configuration files required to complete the verification environment is still pending.

### 4. Introduction to Formal Verification

**Directory:** `4_activity/`

This activity explores the fundamentals of formal hardware verification using SystemVerilog, focusing on property specification, design behavior, and formal checking techniques.

As the main application, formal verification of the input and output FIFOs used in a UART communication system is planned.

The initial FIFO implementation is described in Verilog, with the intention of migrating the design to SystemVerilog to incorporate formal properties and enable a more comprehensive verification process.

**Status:** In progress. The next stage involves integrating formal verification of the UART transmission and reception FIFOs.

## Repository Structure

The repository is organized as follows:

```text
OnChip_DigitalSeed_2026-2/
│
├── 1_activity/
│   ├── RTL/
│   ├── GDS/
│   └── README.md
│
├── 2_activity/
│   ├── src/
│   ├── GDSI/
│   └── README.md
│
├── 3_activity/
│   ├── rtl/
│   ├── tb/
│   ├── sim/
│   ├── figs/
│   ├── README.md
│   ├── README_driver.md
│   └── README_interfaz.md
│
├── 4_activity/
│   ├── formal/
│   └── README.md
│
└── README.md
```

## Tools and Technologies

The activities make use of open-source tools and technologies for digital IC design and verification.

| Category | Tools / Technologies |
|---|---|
| Hardware Description Languages | Verilog, SystemVerilog |
| RTL Design | Digital hardware description and implementation |
| Process Design Kit | SkyWater `sky130A` |
| Digital Design Flow | Open-source RTL-to-GDSII tools |
| Simulation | Verilator |
| Functional Verification | UVM |
| Formal Verification | SystemVerilog Assertions and formal checking |
| Physical Implementation | GDSII generation and layout analysis |

## General Objective

To strengthen theoretical and practical knowledge of digital integrated circuit design through progressive hardware development activities involving RTL description, physical implementation, PPA (Power, Performance, and Area) optimization, and functional and formal verification methodologies, using open-source tools and technologies.