# Transmitter Timing and Control del UART

Este repositorio contiene el diseño, la simulación con Verilator y la verificación formal del bloque **Transmitter Timing and Control** de un UART (tipo 16550 / TI KeyStone, guía SPRUGP1).

El módulo toma una letra en paralelo (8 bits a la vez) del TX FIFO y la envía **en serie** por el cable `txd`: un bit de **start**, los **datos** (5 a 8 bits, el menos significativo primero), un bit de **paridad** opcional y 1, 1,5 o 2 bits de **stop**. Cada bit dura 16 pulsos de `bclk_tick` (13 si `osm_sel = 1`). La explicación completa está en [`SRC/README.md`](SRC/README.md).

## Estructura de directorios

```text
4_activity/
├── README.md
├── SRC/                   # Código fuente del transmitter timing and control
│   ├── README.md
│   ├── uart_tx_ctrl.sv    # versión principal (SystemVerilog)
│   ├── uart_tx_ctrl.v     # la misma lógica en Verilog
│   └── uart_tx_simple.sv  # versión corta
├── Formal/                # Verificación formal con SymbiYosys
│   ├── Prueba_TX/
│   │   ├── uart_tx_ctrl.v # el módulo con sus propiedades dentro de `ifdef FORMAL
│   │   └── tx.sby
│   └── README.md
├── verificacion/          # Simulación con Verilator (testbench, Makefile, asserts)
│   └── README.md
└── docs/                  # Páginas HTML interactivas
    └── README.md
```

## Ejecución de la verificación formal

Para ejecutar la verificación formal con SymbiYosys, corre el siguiente comando dentro de la carpeta de prueba:

```text
cd Formal/Prueba_TX
sby -f tx.sby
```

| Opción | Propósito |
|---|---|
| `-f` | Obliga a SymbiYosys a sobrescribir los directorios de salida anteriores y a ejecutar una corrida limpia. |

## Estructura de la configuración `.sby`

Cada archivo `.sby` se divide en secciones:

| Sección | Propósito |
|---|---|
| `[tasks]` | Nombres de las tareas que se ejecutan (`bmc`, `prove`, `cover`). |
| `[options]` | Modo de verificación y profundidad de cada tarea. |
| `[engines]` | Solver usado para comprobar las propiedades. |
| `[script]` | Archivos RTL a leer y módulo superior bajo prueba. |
| `[files]` | Archivos fuente locales que se copian al espacio de trabajo de SymbiYosys. |

```text
[options]
bmc: mode bmc
bmc: depth 40

[engines]
smtbmc

[script]
read -formal -sv uart_tx_ctrl.v
prep -top uart_tx_ctrl

[files]
uart_tx_ctrl.v
```

## Comandos de verificación formal

Estas construcciones se escriben al final del módulo, envueltas en `` `ifdef FORMAL ``, por lo que solo las usa SymbiYosys y se ignoran en la síntesis y en Verilator.

| Comando | Propósito |
|---|---|
| `assume` | Restringe las **entradas**: le indica al solver qué comportamientos de entrada están permitidos. |
| `assert` | Verifica las **salidas y el comportamiento interno**: la propiedad que debe cumplirse en cada ciclo alcanzable. |
| `cover` | Obliga al solver a encontrar al menos una ejecución que alcance una condición. Demuestra que el caso es alcanzable. |
| `f_past_valid` | Bandera que vale `0` solo en el primer ciclo y `1` después. Permite usar `$past` y forzar el reset en el primer ciclo. |

```verilog
reg f_past_valid = 1'b0;
always @(posedge clk) f_past_valid <= 1'b1;

always @* if (!f_past_valid) assume (rst);   // siempre empezar con reset
```

### `$past`

`$past(x)` es el valor que tenía `x` en el ciclo de reloj anterior. En este módulo se usa, por ejemplo, para comprobar que después de un `tx_pop` el TSR contiene el dato que había en `tx_data` en ese momento:

```verilog
always @(posedge clk) if (f_past_valid && $past(tx_pop))
    assert (TSR == $past(tx_data));
```

## Tipos de pruebas

| Tarea | Descripción |
|---|---|
| `bmc` | Verificación de modelo acotada (*bounded model checking*). Parte del reset y comprueba las propiedades hasta `depth` ciclos. Encuentra errores, pero no demuestra el diseño para todos los ciclos. |
| `prove` | Prueba por k-inducción. El paso inductivo puede partir de **cualquier estado**, por eso se agregan invariantes (estado y contadores en rango). Demuestra las propiedades para todos los ciclos. |
| `cover` | Análisis de alcanzabilidad. Comprueba que se pueda alcanzar cada sentencia `cover`. |

Si `prove` falla en el paso inductivo mientras `bmc` pasa, el contraejemplo normalmente parte de un estado inalcanzable. Revisa el primer instante del `.vcd` generado antes de asumir que hay un error de diseño.

## Simulación con Verilator

Requiere Verilator 5.x (probado con 5.026) y `make`. La ruta de la carpeta **no debe tener espacios**.

```text
cd verificacion
make lint         # lint -Wall de los módulos
make sim          # testbench contra SRC/uart_tx_ctrl.sv   -> PASS
make all          # el testbench contra las 4 versiones del módulo
make bug          # mete un bug de paridad a propósito: un assert debe fallar
make trace        # igual que sim, y genera uart_tx.vcd para GTKWave
make clean
```

Los resultados y la descripción del testbench están en [`verificacion/README.md`](verificacion/README.md).
