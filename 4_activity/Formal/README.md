# Verificación formal

Verificación formal del transmisor UART con SymbiYosys. La prueba tiene su propia carpeta con el módulo (`.v`, con las propiedades dentro de `` `ifdef FORMAL ``) y su archivo `.sby`.

> **Pendiente:** al terminar la corrida, agregar dentro de la carpeta una **captura de pantalla de la ejecución** que muestre que las tres tareas pasaron.

## Pruebas

| Carpeta | Módulo | Qué se verifica |
|---|---|---|
| `Prueba_TX/` | `uart_tx_ctrl` | Ver la tabla de propiedades abajo. |

### Propiedades (`assert`)

| Grupo | Qué se comprueba |
|---|---|
| Invariantes | El estado está entre IDLE y STOP; `CUENTA_TICK` nunca pasa de `FIN_BIT_N` (ni de `FIN_STOP_N` en STOP) y vale 0 en IDLE; `CUENTA_BIT` nunca pasa de `ULTIMO_BIT` en DATOS y vale 0 fuera de DATOS; `FIN_BIT_N` es 12 o 15. |
| Línea | START → 0, IDLE y STOP → 1, DATOS → `TSR[0]`, PARIDAD → `BIT_PARIDAD`; con `bc = 1` la línea es 0; con `loop = 1`, `txd = 1`; fuera de loopback `txd = tx_serial_loop`; `tsr_empty = 1` solo en IDLE. |
| `tx_pop` | Solo ocurre con dato en el FIFO, `utrst = 1`, `bclk_tick = 1` y en IDLE o STOP. Al ciclo siguiente: estado START, TSR con el dato tomado, contador en 0 y sin un segundo `tx_pop`. |
| Ritmo | Si no hay `bclk_tick`, no cambian el estado, el contador de ticks ni el TSR. |
| Reset | `rst = 1` o `utrst = 0` llevan a IDLE. |

### Coberturas (`cover`)

| Cover | Qué demuestra |
|---|---|
| `presente == DATOS` | Se puede llegar a enviar datos. |
| `presente == PARIDAD` | Se puede llegar al bit de paridad. |
| `presente == STOP` | Se puede completar una trama. |
| `tx_pop && presente == STOP` | Se pueden enviar dos tramas seguidas sin pasar por IDLE. |

## Suposiciones

| Suposición | Razón |
|---|---|
| `rst` activo en el primer ciclo | Partir de un estado conocido. |

No hace falta suponer que el LCR (`wls`, `pen`, `eps`, `sp`, `stb`, `osm_sel`) se mantiene estable, porque el módulo toma una "foto" de la configuración en el `tx_pop` y la trama en curso usa esa copia.

## Ejecución

Dentro de la carpeta:

```text
sby -f tx.sby          # ejecuta las tres tareas (bmc, prove, cover)
sby -f tx.sby bmc      # ejecuta una sola tarea
```

| Tarea | Profundidad | Por qué |
|---|---|---|
| `bmc` | 40 | Cubre el arranque y varios bits completos. |
| `prove` | 20 | La inducción se apoya en las invariantes, no en la profundidad. |
| `cover` | 120 | La trama más corta (5 bits, sin paridad, 1 stop, 13×) dura 7 bits × 13 ticks = 91 ciclos si hay un `bclk_tick` en cada ciclo; con 120 alcanza para llegar al segundo `tx_pop`. |
