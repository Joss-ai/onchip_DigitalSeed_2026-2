# Formal Verification

Formal verification of the UART receiver modules with SymbiYosys. Each test has its own folder with the module (`.v`, with the properties inside `` `ifdef FORMAL ``) and its `.sby` file.

Inside each folder there is also a **screenshot of the run**, showing that the test passed.

## Tests

| Folder | Module | What is verified |
|---|---|---|
| `Prueba_CTICKS/` | `C_TICKS` | `tick_cnt` never exceeds 15 (16x) or 12 (13x), and `sample` is generated only after a `bclk_tick`, at tick 7 (16x) or 5 (13x). |
| `Prueba_CBITS/` | `C_BITS` | `count` never exceeds `n_bits = 5 + WLS + PEN`, `Done` rises only when all bits were counted, and `clr`/reset set `count` to 0. |
| `Prueba_FSM/` | `FSM` | Only the 5 valid states exist, the outputs match the current state, and every transition follows the state diagram. |

## Assumptions

| Module | Assumption | Reason |
|---|---|---|
| All | `rst` active in the first cycle | Start from a known state. |
| `C_TICKS` | `osm_sel` stable | The 16x/13x mode does not change during reception. |
| `C_BITS` | `wls` and `pen` stable | `n_bits` does not change while a character is received. |
| `C_BITS` | no `bit_en` when `count == n_bits` | The FSM stops counting once all bits have arrived. |

## Run

Inside each folder:

```text
sby -f ticks.sby     # Prueba_CTICKS
sby -f bits.sby      # Prueba_CBITS
sby -f fsm.sby       # Prueba_FSM
```

Each `.sby` runs three tasks: `bmc`, `prove` and `cover`.
