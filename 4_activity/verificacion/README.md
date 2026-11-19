# Verificación con Verilator

Pruebas del módulo `uart_tx_ctrl` con un testbench en SystemVerilog que se compila y se ejecuta con **Verilator 5.x** (`--binary --timing --assert`; probado con 5.026).

## Archivos

| Archivo | Descripción |
|---|---|
| `tb_uart_tx_ctrl.sv` | Testbench |
| `uart_tx_ctrl_assert.sv` | El mismo módulo con propiedades (`assert`) que se comprueban en cada flanco de reloj durante la simulación. Se activan con `+define+ASSERTIONS`. Sus señales internas tienen nombres en inglés (`state`, `tsr`, `tick_cnt`, `bit_cnt`) |
| `Makefile` | Comandos para compilar y correr todo |

El testbench solo usa los puertos del módulo, así que sirve igual para las cuatro versiones: `SRC/uart_tx_ctrl.sv`, `SRC/uart_tx_ctrl.v`, `SRC/uart_tx_simple.sv` y `uart_tx_ctrl_assert.sv`.

## Cómo correrlo

La ruta de la carpeta no debe tener espacios.

```
make lint         # lint -Wall (sin warnings)
make sim          # testbench contra SRC/uart_tx_ctrl.sv
make sim-v        # contra SRC/uart_tx_ctrl.v
make sim-simple   # contra SRC/uart_tx_simple.sv
make sim-assert   # contra uart_tx_ctrl_assert.sv con los asserts activos
make all          # las cuatro simulaciones anteriores
make bug          # prueba de mutación: debe fallar un assert
make trace        # como sim, y genera uart_tx.vcd para GTKWave
make clean
```

## Resultado

Las cuatro versiones dan exactamente el mismo resultado:

```
=============== RESUMEN ===============
 tramas verificadas tick a tick : 298
 tramas consecutivas sin idle   : 211
 tx_pop totales                 : 300
 configuraciones sin cubrir     : 0 de 80
 errores                        : 0
=======================================
PASS
```

Son 298 tramas comparadas de 300 porque la trama del test de break y la que se aborta con `utrst` no se comparan completas.

## El testbench

- **Modelo del TX FIFO**: una cola que responde a `tx_pop` y entrega `tx_data` y `tx_empty`. Cuando está vacía, `tx_data` lleva basura aleatoria para comprobar que el módulo no la usa.
- **Generador de `bclk_tick`**: un tick cada 1 a 3 ciclos de reloj, o ticks aleatorios (cerca de uno cada tres ciclos), para probar ritmos irregulares.
- **Scoreboard**: en cada `tx_pop` guarda la letra y la configuración (`wls`, `pen`, `eps`, `sp`, `stb`, `osm_sel`) de ese instante.
- **Monitor**: reconstruye la forma de onda esperada de cada trama, un valor por tick, y la compara con `tx_serial_loop` **en cada tick**. Así comprueba a la vez el valor y la duración exacta de cada bit, incluidos 1.5 stop (24 ticks con 16×, 19 con 13×) y 2 stop.
- **Otras comprobaciones continuas**: `txd` igual a `tx_serial_loop` fuera de loopback, `txd = 1` en loopback, y `tsr_empty = 0` mientras hay una trama en curso.

## Pruebas

| Prueba | Qué comprueba |
|---|---|
| T1 | Barrido de las **80 configuraciones** (2 oversampling × 4 largos de letra × 5 modos de paridad × 2 stop), con 3 bytes seguidos cada una y ticks de ritmo variable. Modos de paridad: sin, impar, par, fija en 1 y fija en 0 |
| T2 | Valores extremos `00`, `FF`, `55`, `AA`, `80` y `01` en 8E2 y en 5O1.5 |
| T3 | El LCR cambia en **cada ciclo**: cada trama debe usar el LCR del momento del `tx_pop` (la foto de configuración) |
| T4 | Loopback: la trama sale por `tx_serial_loop` y `txd` se queda en 1 |
| T5 | Break a mitad de trama: la línea se fuerza a 0, la FSM sigue y termina |
| T6 | Auto-CTS: con `cts_n = 1` no arranca nada; si sube a mitad de una letra, esa letra termina y la siguiente espera |
| T7 | `utrst = 0` a mitad de trama: la FSM vuelve a IDLE, `txd = 1` y no hay `tx_pop`; luego sigue con el resto |

El resultado es `PASS` solo si no hay errores, se cubren las 80 configuraciones y hubo tramas consecutivas sin pasar por IDLE.

## Propiedades dentro del módulo (`uart_tx_ctrl_assert.sv`)

Con `+define+ASSERTIONS` y `--assert`, Verilator comprueba en cada flanco de reloj:

- el estado y los contadores están siempre en rango;
- la configuración capturada coincide con la del momento de `tx_pop`;
- el contenido del TSR sigue el desplazamiento esperado;
- cada bit de datos es el correcto (LSB primero);
- el bit de paridad cumple la especificación (par, impar o fija);
- `txd` vale 1 en IDLE, STOP y loopback, y 0 en START y con break;
- `tx_pop` solo ocurre cuando es legal (hay dato, hay tick, `utrst = 1`, CTS lo permite, el TSR está libre) y nunca dos veces seguidas;
- nada cambia si no hay `bclk_tick`, y cada bit dura exactamente sus ticks;
- reset y `utrst = 0` llevan a IDLE;
- dos propiedades escritas como SVA concurrente (`assert property ... |=>`), que Verilator soporta.

## Prueba de mutación

`make bug` compila `uart_tx_ctrl_assert.sv` con `+define+BUG_PARITY`, que invierte a propósito el cálculo de la paridad par/impar. Un assert tiene que fallar:

```
%Error: uart_tx_ctrl_assert.sv:206: Assertion failed in TOP.tb_uart_tx_ctrl.dut: [uart_tx_ctrl] paridad impar incorrecta
```

Esto confirma que el testbench y los asserts detectan un error real y no se limitan a pasar siempre.

## Simulación frente a verificación formal

La simulación solo revisa las secuencias de entrada que genera el testbench. Una verificación **formal** demuestra las propiedades para *todas* las secuencias posibles. Esa parte está en la carpeta [`../Formal/`](../Formal/README.md).

## Decisión de diseño

Con 13 ticks por bit, 1.5 bits de stop serían 19.5 ticks, que no se puede representar; el diseño usa **19 ticks**. El testbench comprueba ese valor.
