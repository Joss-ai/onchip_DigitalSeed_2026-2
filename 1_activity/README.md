# RTL-to-GDSII Design Flow Using Open-Source EDA Tools

This activity is part of **DigitalSeed**, a training initiative developed within the **OnChip Research Group**. It introduces the RTL-to-GDSII (RTL2GDS) digital design flow using open-source Electronic Design Automation (EDA) tools in a Linux-based environment.

The main objective is to understand the fundamental stages involved in transforming a Register-Transfer Level (RTL) hardware description into a physical integrated circuit layout. The activity uses a digital encoder as a case study, covering its RTL description, functional simulation, synthesis, and physical implementation using the `sky130A` Process Design Kit (PDK).

## Directory Structure

```text
1_activity/
│
├── README.md
│
├── RTL/
│   ├── Encoder.v
│   ├── Encoder_TB.v
│   └── waveforms.vcd
│
└── GDS/
    └── encoder.json
```

### Directory Description

- **`RTL/`** — Contains the Verilog source code for the encoder design (`Encoder.v`), its corresponding testbench (`Encoder_TB.v`), and the generated Value Change Dump (`waveforms.vcd`) file. The waveform data can be inspected using GTKWave to analyze and validate the design's functional behavior during simulation.

- **`GDS/`** — Contains the JSON configuration file (`encoder.json`), which defines the design parameters and settings required to execute the RTL-to-GDSII implementation flow.

## Design Flow Overview

The activity follows the main stages of a digital IC implementation flow:

**RTL Description → Functional Simulation → Logic Synthesis → Physical Design → GDSII Generation**

Each stage contributes to transforming the behavioral hardware description into a physical layout suitable for integrated circuit fabrication.

## Reproducibility

The source files and configuration included in this repository provide the starting point for reproducing the design flow.

Intermediate files and final implementation results are generated during execution by the corresponding open-source EDA tools, using the provided RTL description and configuration parameters.

