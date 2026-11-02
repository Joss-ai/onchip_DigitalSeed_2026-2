# FIFO Design and Figure of Merit (FoM) Optimization

This activity is part of **DigitalSeed**, a training initiative developed within the **OnChip Research Group**. It focuses on the design and implementation of a FIFO (First-In, First-Out) memory architecture, exploring its hardware structure and optimization in terms of the Figure of Merit (FoM).

The main objective is to investigate how different RTL design choices and hardware architectures affect the physical implementation metrics, particularly maximum operating frequency, power consumption, and silicon area.

For this activity, the FoM is defined as:

$$
FoM = \frac{f_{\max}}{P_{\max} \cdot Area}
$$

Where:

$f_{\max}$: Maximum operating frequency.
$P_{\max}$: Maximum power consumption.
$Area$: Physical area occupied by the design.

A higher FoM represents a more favorable trade-off between operating frequency, power consumption, and area.

## Directory Structure

```text
2_activity/
│
├── src/
│   ├── ANDGATE.v
│   ├── FFD.v
│   ├── FIFO.v
│   ├── modFull.v
│   └── MUX.v
│
├── GDSI/
│   └── Configuration files
│
└── README.md
```

## Directory Description

- **`src/`** — Contains the Verilog source files describing the FIFO architecture and its internal components, including D-type flip-flops (DFFs), multiplexers, logic gates, and full-condition detection logic.

- **`GDSI/`** — Contains the configuration files required to execute the RTL-to-GDSII implementation flow using open-source EDA tools.

## Design and Implementation

The proposed architecture uses basic sequential and combinational logic components to explore a register-based FIFO implementation. The design is intended to be evaluated using the **JKU IIC-OSIC Tools container**, which provides an open-source environment for digital IC design and physical implementation.

The general implementation flow is:

**RTL Description → Functional Verification → Logic Synthesis → Physical Design → PPA Analysis → FoM Evaluation**

## Implementation Status

**Status: Under development.**

The current RTL implementation serves as an initial architectural exploration and is not yet considered a fully functional FIFO implementation.

Although the source files and initial physical design configuration are available, the design requires further modifications and verification to ensure that it correctly satisfies the expected FIFO operating behavior.

In particular, the implementation must be reviewed to ensure correct data ordering, read/write control, full and empty conditions, and proper synchronization of the internal control signals before proceeding with physical implementation and FoM evaluation.

The next stage involves refining the RTL architecture, validating its functional behavior, and subsequently evaluating its PPA metrics to identify potential optimization opportunities.
