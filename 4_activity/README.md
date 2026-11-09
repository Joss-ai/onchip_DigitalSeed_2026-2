# UART Reciver timing and control

This repository contains the design and formal verification of the reciver timing and control for a UART system.

## Directory Structure

```text
4_activity/
├── README.md
├── Formal/                # Source code and .sby configuration for the receiver timing and control
│   ├── Prueba_CBITS/
│   ├── Prueba_CTICKS/
│   ├── Prueba_FSM/
│   └── README.md
└── SRC/                   # Source code for the Receiver FIFO
    └── README.md
```

## Running the Formal Verification

To run formal verification on the SystemVerilog modules using SymbiYosys, run the following command inside each test folder:

```text
sby -f archivo.sby
```

| Flag | Purpose |
|---|---|
| `-f` | Forces SymbiYosys to overwrite any previous output directories and execute a clean run. |

## `.sby` Configuration Structure

Each `.sby` file is divided into sections:

| Section | Purpose |
|---|---|
| `[options]` | Verification mode and depth. |
| `[engines]` | Solver used to check the properties. |
| `[script]` | RTL files to read and the top-level module under test. |
| `[files]` | Local source files copied into the SymbiYosys workspace. |

```text
[options]
mode bmc
depth 1

[engines]
smtbmc

[script]
read -formal bcd.sv
prep -top bcd_inc

[files]
bcd.sv
```

### `[options]`

## Formal Verification Commands

These constructs are written inside each module, wrapped in `` `ifdef FORMAL ``, so they are only used by SymbiYosys and ignored in synthesis.

| Command | Purpose |
|---|---|
| `assume` | Restricts the **inputs**: tells the solver which input behaviors are allowed. |
| `assert` | Checks the **outputs and internal behavior**: the property that must hold in every reachable cycle. |
| `cover` | Forces the solver to find at least one execution that reaches a condition. It proves the case is reachable, so the assumptions are not too strict. |
| `f_past_valid` | Flag that is `0` only in the first cycle and `1` afterwards. It allows using past values (`$past`) and defining initial conditions, for example reset active in the first cycle. |

```verilog
reg f_past_valid = 1'b0;
always @(posedge clk) f_past_valid <= 1'b1;

always @* if (!f_past_valid) assume (rst);   // always start with reset
```

### `$stable`

`$stable(x)` is true when `x` has the same value as in the previous clock cycle. It is a shorthand for `x == $past(x)`.

```verilog
always @(posedge clk) if (f_past_valid) assume ($stable(osm_sel));
```

While `assume (d <= 9)` limits the **value** of an input, `$stable` limits **how it changes over time**. In this design it models configuration signals (`osm_sel`, `wls`, `pen`) that do not change while a character is being received. It is wrapped in `f_past_valid` because the first cycle has no previous cycle.

## Types of Proofs

| Task | Description |
|---|---|
| `bmc` | Bounded model checking. Always starts from reset (the first cycle is forced with `f_past_valid`) and checks the properties up to `depth` clock cycles. Finds bugs, but does not prove the design for all cycles. |
| `prove` | Proof by k-induction. The base case starts from reset, but the induction step can start from **any state**, so it does not rely on `f_past_valid` to start at reset. Proves the properties for all cycles. |
| `cover` | Reachability analysis. Checks that every `cover` statement can be reached. |

If `prove` fails in the induction step while `bmc` passes, the counterexample usually starts from an unreachable state. Check the first instant of the generated `.vcd` before assuming a design bug.

## Execution

```text
sby -f nombre.sby          # runs all tasks (bmc, prove, cover)
sby -f nombre.sby bmc      # runs a single task
```
