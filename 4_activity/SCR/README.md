# Receptor del UART: *Receiver Timing and Control*

## 1. Descripción

Este bloque es la parte receptora de un UART basado en el TL16C550 (guía de TI *KeyStone Architecture UART*, SPRUGP1). Recibe la línea serial `RXD`, muestrea cada bit en su centro usando los pulsos del generador de baudios (16× o 13× la velocidad), arma el carácter en el registro de desplazamiento (RSR), verifica la paridad y detecta los errores de *framing*, *break* y *overrun*. Al terminar entrega al FIFO de recepción el carácter junto con sus bits de error, y controla la señal RTS del control de flujo automático.

Formato de trama que recibe:

```
1 bit de start (0) + 5 a 8 bits de dato (LSB primero) + 1 bit de paridad (opcional) + 1 bit de stop (1)
```

Solo se verifica el primer bit de stop; si el transmisor envía 1,5 o 2, el resto se toma como reposo, igual que en la guía.

| Archivo | Módulo | Función |
|---|---|---|
| `RX_timming_Control.v` | Top | Une todo, sincroniza `rxd_in`, genera las salidas y el RTS |
| `FSM.v` | Máquina de estados | Controla la secuencia de recepción |
| `C_TICKS.v` | Contador de ticks | Mide el tiempo dentro de cada bit |
| `C_BITS.v` | Contador de bits | Cuenta los bits recibidos |
| `Registro_Desplazamiento.v` | RSR | Arma el carácter y verifica la paridad |

---

## 2. Ciclo de recepción

La figura sale de la simulación real del diseño: una trama **8O1** (8 datos, paridad impar, 1 stop) con el dato `0x4B`, en modo 16× (`osm_sel = 0`).

![Ciclo de recepción](img/ciclo_recepcion.png)

**Cómo leer la figura**

1. **Flanco de bajada.** Con la línea en reposo (1), `rxd_in` cae a 0. La FSM sale de INICIAL y pasa a REVISIÓN; el contador de ticks arranca.
2. **Ticks.** `tick_cnt` cuenta de 0 a 15: 16 ticks son un bit. La señal `sample` se activa en el tick 8, es decir, en el centro del bit (en modo 13× se activa en el tick 6 de 13).
3. **Start.** En el primer `sample` la FSM comprueba que la línea siga en 0. Si ya subió, fue ruido y vuelve a INICIAL.
4. **Datos y paridad.** En cada `sample` siguiente (uno por bit) se lee `rxd_in` y se desplaza al RSR. `C_BITS` cuenta los bits recibidos; al llegar a 9 (8 datos + paridad) activa `Done`.
5. **Stop.** El siguiente `sample` cae en el centro del bit de stop. Ahí la FSM activa `char_done`, y se calculan `fe`, `bi`, `pe` y si hay `oe`.
6. **Salida.** Un ciclo de reloj después se activa `rx_push`, con `rx_data`, `pe`, `fe` y `bi` ya registrados y estables. El FIFO guarda el carácter al ver `rx_push`.

### Entradas y salidas

| Señal | Dir. | Descripción |
|---|---|---|
| `clk`, `rst` | Entrada | Reloj del sistema y reset (síncrono, activo en 1) |
| `urrst` | Entrada | `PWREMU_MGMT.URRST`. 1 = receptor activo, 0 = receptor en reset |
| `rxd_in` | Entrada | Línea serial: pin RXD o, en loopback, la salida serial del TSR |
| `bclk_tick` | Entrada | Pulso de 1 ciclo del generador de baudios, 16 (o 13) por bit |
| `osm_sel` | Entrada | `MDR.OSM_SEL`. 0 = 16× (muestreo en el tick 8), 1 = 13× (tick 6) |
| `wls[1:0]` | Entrada | Bits de dato: 00 = 5, 01 = 6, 10 = 7, 11 = 8 |
| `pen`, `eps`, `sp` | Entrada | Paridad: habilitada, par (1) o impar (0), y paridad fija (*stick*) |
| `fifo_full`, `fifo_empty` | Entrada | Estado del FIFO de recepción |
| `trig_reached` | Entrada | El FIFO llegó al nivel de trigger |
| `rxfiftl[1:0]` | Entrada | Nivel de trigger (`FCR.RXFIFTL`): 1, 4, 8 o 14 bytes |
| `afe`, `rts_en` | Entrada | Autoflow (`MCR.AFE`) y bit RTS (`MCR.RTS`) |
| `rx_data[7:0]` | Salida | Carácter recibido, alineado a la derecha (bits altos en 0) |
| `rx_push` | Salida | Pulso de 1 ciclo: el carácter está listo para el FIFO |
| `pe`, `fe`, `bi` | Salida | Errores de paridad, *framing* y *break*; viajan junto con el dato |
| `oe` | Salida | Pulso de 1 ciclo: *overrun* (llegó un carácter con el FIFO lleno) |
| `rx_activity` | Salida | Pulso que reinicia el contador de *time-out* de las interrupciones |
| `rts_n` | Salida | Pin RTS (activo en bajo) |
| `rx_busy` | Salida | 1 mientras la FSM no está en INICIAL (opcional) |

---

## 3. Máquina de estados

<table>
<tr>
<th align="center">Esquema original (borrador)</th>
<th align="center">Versión final (optimizada)</th>
</tr>
<tr>
<td width="38%"><img src="img/fsm_borrador.png" alt="FSM borrador" width="100%"></td>
<td width="62%"><img src="img/fsm_final.png" alt="FSM final" width="100%"></td>
</tr>
</table>

**Qué cambió respecto al borrador**

- **Se agregó el estado ESPERA.** Si el stop llega en 0 (error de *framing*), el receptor espera a que la línea suba a 1 antes de buscar otro start. Sin esto, un *break* (línea en 0 por mucho tiempo) generaría caracteres falsos.
- **SALIDA ya no vuelve a ENTRADA BITS.** En SALIDA se está leyendo el bit de stop; un 0 ahí no significa "más datos", sino error de *framing*.
- **SALIDA espera el `sample` del stop** antes de decidir. En el borrador decidía en cuanto llegaba `Done`, sin leer el stop.

| Estado | Salidas de control | Qué hace | Sale cuando |
|---|---|---|---|
| INICIAL | `clr = 1` | Mantiene contadores y RSR en 0, vigila la línea | `rxd_in = 0` → REVISIÓN |
| REVISIÓN | ninguna | Cuenta ticks hasta el centro del start | `sample = 1`: si `rxd_in = 0` → ENTRADA BITS; si no → INICIAL |
| ENTRADA BITS | `shift_en = 1`, `bit_en = sample` | Desplaza cada bit al RSR y lo cuenta | `Done = 1` → SALIDA |
| SALIDA | `char_done = sample` | Lee el bit de stop y entrega el carácter | `sample = 1`: si `rxd_in = 1` → INICIAL; si no → ESPERA |
| ESPERA | `clr = 1` | Espera a que la línea vuelva a 1 | `rxd_in = 1` → INICIAL |

---

## 4. Módulos

### `C_TICKS.v`: contador de ticks

Mide el tiempo dentro de un bit. Es un contador circular que **solo avanza cuando `bclk_tick = 1`**: va de 0 a 15 en modo 16× y de 0 a 12 en modo 13×. Genera `sample` (pulso de 1 ciclo) cuando llega al punto de muestreo, el tick 8 (o el 6). Como el contador es circular, `sample` se repite en el centro de cada bit siguiente sin tener que reiniciarlo. La FSM lo mantiene en 0 con `clr` mientras está en reposo.

- Entradas: `clk`, `rst`, `urrst`, `bclk_tick`, `osm_sel`, `clr`
- Salidas: `tick_cnt[3:0]`, `sample`

### `C_BITS.v`: contador de bits

Cuenta cuántos bits se han recibido (cada pulso `bit_en` de la FSM suma 1) y avisa con `Done` cuando llegaron todos. El total es `wls + 5 + pen`: de 5 a 8 bits de dato, más 1 si hay paridad. `Done` se registra, así que sube un ciclo después del último bit.

- Entradas: `clk`, `rst`, `urrst`, `clr`, `bit_en`, `wls`, `pen`
- Salida: `Done`

### `Registro_Desplazamiento.v`: RSR y verificación de paridad

Registro de desplazamiento de 9 bits. En cada `sample` con `shift_en = 1`, el bit de `rxd_in` entra por la izquierda y todo se corre a la derecha (los bits llegan LSB primero). Después lo alinea a la derecha según `4 - wls - pen`, de modo que `rx_data` queda con los bits de dato en los bits bajos y ceros arriba.

La paridad se verifica internamente:

| Configuración | Bit de paridad esperado |
|---|---|
| Par (`eps = 1`, `sp = 0`) | XOR de los bits de dato |
| Impar (`eps = 0`, `sp = 0`) | Negado del XOR |
| Fija (`sp = 1`) | `~eps` (0 si `eps = 1`, 1 si `eps = 0`) |

`pe = pen & (paridad recibida ≠ paridad esperada)`. Este módulo solo verifica y reporta; no corrige nada.

- Entradas: `clk`, `rst`, `urrst`, `rxd_in`, `sample`, `shift_en`, `clr`, `wls`, `pen`, `eps`, `sp`
- Salidas: `rx_dataP[8:0]` (bits recibidos con paridad), `rx_data[7:0]` (solo dato), `pe`

### `FSM.v`: máquina de estados

Implementa los 5 estados de la sección 3 con reset síncrono. Genera las señales que gobiernan a los demás módulos:

| Salida | Para qué sirve |
|---|---|
| `clr` | Pone en 0 los contadores y el RSR (en INICIAL y ESPERA) |
| `shift_en` | Habilita el desplazamiento del RSR (en ENTRADA BITS) |
| `bit_en` | Pulso hacia `C_BITS`: un bit fue recibido (`= sample` en ENTRADA BITS) |
| `char_done` | Pulso: se muestreó el stop, el carácter está completo |
| `busy` | 1 si el estado no es INICIAL |

- Entradas: `clk`, `rst`, `urrst`, `rxd_in`, `sample`, `Done`

### `RX_timming_Control.v`: módulo principal

Une los cuatro módulos anteriores y agrega lo que falta para cumplir la especificación:

- **Sincronizador de 2 flip-flops** para `rxd_in`, que es asíncrona respecto a `clk`.
- **Reset interno** `rx_rst = ~urrst`: la guía define `URRST = 0` como receptor en reset.
- **Registro de salidas.** Al activarse `char_done`, captura `rx_data`, `pe`, `fe` y `bi`, y un ciclo después se ve `rx_push`. Así el FIFO recibe dato y errores estables en el mismo ciclo.
  - `fe = ~rxd_in` (el stop debía valer 1).
  - `bi` = todos los bits recibidos en 0 y stop en 0 (la línea estuvo en 0 toda la trama).
  - Si `fifo_full = 0`: `rx_push = 1`. Si `fifo_full = 1`: `oe = 1`, el carácter se pierde y no se sobreescribe el FIFO.
- **`rx_activity = rx_push`**, para reiniciar el temporizador de *time-out*.
- **Lógica de RTS** (autoflow): con `afe = 1` y `rts_en = 1`, `rts_n` se desactiva al llegar `trig_reached` y se reactiva cuando el FIFO queda vacío (triggers de 1, 4 y 8) o al bajar del trigger (14 bytes), como describe la guía. Sin autoflow, `rts_n = ~rts_en`.

---

## 5. Verificación

Se simuló con Icarus Verilog usando un transmisor simulado, un modelo de referencia y fase aleatoria entre el flanco de bajada y `bclk_tick`.

| Prueba | Resultado |
|---|---|
| 396 tramas: 4 longitudes, con y sin paridad (par, impar, fija), 16× y 13×, datos `00`, `FF`, `55` y aleatorios | Todas correctas |
| Paridad invertida | `pe = 1`, el dato se entrega igual |
| Stop en 0 | `fe = 1`, un solo push |
| *Break* largo | Un solo push con `bi = 1` y `fe = 1`; se recupera al subir la línea |
| *Overrun* | `oe = 1`, sin push |
| Tramas consecutivas, glitch corto, `urrst` a mitad de trama | Correcto |
| RTS con triggers de 1 y de 14 | Se desactiva y reactiva como indica la guía |
| `bclk_tick` cada 1, 2, 4 y 8 ciclos de `clk` | Mismos resultados |
| Desviación del baud rate (8N1, 16×) | Recibe bien hasta ±6 %; falla desde ±7 % |

---

## 6. Notas de integración

- **`urrst` es activo en 1** (receptor habilitado), igual que en el Control Logic; el módulo la invierte internamente.
- **`oe` sale como pulso.** El registro LSR debe retenerlo hasta que la CPU lo lea (`OE_STICKY = 1` en el Control Logic), y si el bloque de interrupciones lo necesita, debe recibir la versión retenida.
- **`rxfiftl` debe conectarse también a este módulo**, además de al FIFO de recepción, porque define cuándo se reactiva RTS.
- **El FIFO de recepción debe exportar** `full`, `empty` y `trig_reached`.
- **El multiplexor de loopback** (`loop ? salida serial del TSR : pin RXD`) va fuera de este módulo, antes de `rxd_in`.
- `rts_n = ~rts_en` cuando no hay autoflow es una suposición: la guía no especifica el nivel del pin en ese caso.
