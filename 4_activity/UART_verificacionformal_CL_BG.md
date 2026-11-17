# Verificación formal – Control Logic y Baud Generator

> Bloques propios: **Control Logic** (decodificación, registros, estados de espera, pulsos de acceso, LSR/RDATA) y **Baud Generator** (divisor `{DLH,DLL}` → `bclk_tick`).
> Herramienta: **SymbiYosys** (Yosys 0.33 + `smtbmc` + **yices 2.6.4**).
> Los bloques de los compañeros no se verifican aquí; solo se revisó que **conecten** con estos dos.

## 1. Estructura del repositorio

```
ControlLogic/
  control_logic.sv     # RTL + bloque `ifdef FORMAL (assume / assert / cover)
  control_logic.sby    # tareas: bmc, prove, cover
BaudGen/
  baud_gen.sv
  baud_gen.sby         # tareas: bmc, prove, cover
```

Igual que en los ejemplos (`abs8`, `bcd_inc`, `mod1000`, `sticky_flag`): una carpeta por módulo, el RTL y el `.sby` juntos, y las propiedades dentro de `` `ifdef FORMAL `` para que **no** se sinteticen.

## 2. Cómo ejecutarlo

```bash
cd ControlLogic && sby -f control_logic.sby          # corre bmc, prove y cover
cd ControlLogic && sby -f control_logic.sby prove    # solo una tarea
cd BaudGen      && sby -f baud_gen.sby
```

| Tarea | Qué hace | Qué significa PASS |
|---|---|---|
| `bmc` | Busca un contraejemplo en los primeros N ciclos desde el reset | Ningún `assert` se rompe en N ciclos (25 / 20) |
| `prove` | Inducción en k pasos (k = 6 / 8) | El `assert` vale **siempre**, no solo en N ciclos |
| `cover` | Busca una traza que alcance cada `cover` | La situación **sí es posible** → los `assert` no pasan "en vacío" |

> **Nota de entorno:** el solver por defecto de SymbiYosys es `yices`. Con `z3 4.8.12` y `cvc4` el modelo SMT de `control_logic` no terminaba (el solver se quedaba leyendo la relación de transición), con yices las tres tareas terminan en menos de 1 s. Si `sby` dice `yices: command not found`, hay que instalar yices2.

## 3. Resultados

| Módulo | bmc | prove (k-inducción) | cover |
|---|---|---|---|
| `control_logic` | PASS (25 ciclos) | PASS (k = 6) | PASS – los 8 covers alcanzados |
| `baud_gen` | PASS (20 ciclos) | PASS (k = 8) | PASS – los 4 covers alcanzados |

### Pruebas de mutación (¿las propiedades de verdad detectan errores?)

Se rompió el RTL a propósito y se volvió a correr `bmc`:

| Mutación | Resultado |
|---|---|
| `control_logic`: `ready` con 1 espera en vez de 2 | FAIL (grupo 2) |
| `control_logic`: `oe_lat` deja de ser retenido | FAIL (grupo 5) |
| `control_logic`: `rxclr` usa `wdata[2]` en vez de `wdata[1]` | FAIL (grupo 4) |
| `baud_gen`: `>=` cambiado a `>` | FAIL |
| `baud_gen`: el contador reinicia en 1 en vez de 0 | FAIL |
| `baud_gen`: se quita `div_valid` de `bclk_tick` | PASS → es un **mutante equivalente**: con `divisor = 0`, `last = 0xFFFF` y `cnt = 0` nunca lo alcanza, así que `div_valid` es redundante (se deja por claridad) |

## 4. Control Logic

### 4.1 Qué se asume (`assume`, solo ENTRADAS)

| # | Asunción | Por qué |
|---|---|---|
| A0 | `rst = 1` en el primer ciclo | Todos los registros parten de un estado conocido. Igual que `assume(rst)` en los ejemplos. |
| A1 | `!(rd && wr)` | El bus de la CPU no lee y escribe a la vez. |

Se asume **lo mínimo**: cuanto menos se asume, más fuerte es la prueba.

### 4.2 Qué se afirma (`assert`)

| Grupo | Propiedad | Idea |
|---|---|---|
| 1. Decodificación | `rbr_rd`, `thr_wr`, `fcr_wr`, `iir_rd`, `lsr_rd` son exactamente `sel & rd/wr & addr (& dlab)`; con `DLAB=1` no hay `rbr_rd` ni `thr_wr`; nunca hay más de un pulso a la vez | Cada acceso de la CPU produce **un** pulso y solo el correcto |
| 2. Estados de espera | `wait_cnt ≤ 2`; `dl_wr_req` solo en DLL/DLH; `ready=0` en los 2 primeros ciclos de escritura al divisor, `ready=1` al tercero; la cuenta va 0→1→2→0 | Cumple los 2 wait states de la guía de TI |
| 3. Registros | Tras reset valen su valor inicial; tras una escritura válida (`ready=1`) toman `wdata`; sin escritura **mantienen** su valor (LCR, MCR, IER, DLL, DLH, SCR, FCR, PWREMU, MDR) | Es el equivalente a "el contador no cambia solo" |
| 4. Limpieza de FIFO | `rxclr`/`txclr` = escritura válida a FCR con `FIFOEN=1` y bit 1 / bit 2 | Pulsos de un ciclo, registrados para no generar glitches en el reset asíncrono de las FIFOs |
| 5. OE retenido | `oe_lat` sube con `OE` y baja solo al leer LSR | Es la versión **correcta** del `sticky_flag` de clase (ver 4.4) |
| 6. Lectura | `rdata` = el registro apuntado por `addr`/`dlab`; los bits 31:8 siempre en 0; LSR con `BI/FE/PE` enmascarados por `DR` | La CPU lee lo que debe |

### 4.3 Qué se cubre (`cover`)

Escritura a DLL con espera (segunda espera alcanzada), lectura de LSR con OE retenido, LSR con error de paridad y `DR`, escritura a FCR con `rxclr`, con `txclr`, etc. (8 en total). Si alguno fuera inalcanzable, los asserts correspondientes estarían pasando en vacío.

### 4.4 Relación con los ejemplos de clase

| Ejemplo de clase | Dónde aparece aquí |
|---|---|
| `abs8` (propiedad de salida pura) | Grupo 1 y 6: salida = función combinacional de entradas |
| `bcd_inc` / `mod1000` (contador con wrap) | `wait_cnt` (0→1→2→0) y el contador de `baud_gen` |
| `sticky_flag` (bandera que se retiene) | `oe_lat`. En clase el diseño **falla** a propósito porque no retiene; aquí el diseño sí retiene y se prueba que se limpia **solo** con la lectura de LSR |
| `f_past_valid` + `$past` | Todas las propiedades de "mantener / cambiar" |

## 5. Baud Generator

`bclk_tick` es un pulso de un ciclo cada `divisor` ciclos de `clk`.

| Propiedad | Parte |
|---|---|
| `divisor = 0` → nunca hay tick | A (cualquier divisor) |
| `divisor = 1` y sin reset → tick en **todos** los ciclos | A |
| En reset nunca hay tick | A |
| Un tick solo sale si `cnt ≥ divisor−1` | A |
| Tras reset o `divisor = 0` el contador vale 0; tras un tick vuelve a 0 | A |
| **Periodo exacto:** el tick sale cuando han pasado `divisor−1` ciclos desde el último tick/reset | B (modelo de referencia `f_gap`) |
| `cnt == f_gap` y `cnt ≤ divisor−1` siempre | B |

**Parte B asume que el divisor no cambia fuera de reset** (`assume($stable(divisor))`). Es razonable: el software programa DLL/DLH una vez y la Control Logic mantiene el valor. La Parte A **no** necesita esa asunción; por eso el RTL usa `>=` y no `==`: si el divisor baja a mitad de cuenta, se recupera solo.

`osm_sel` (16×/13×) **no** entra al baud gen; lo usan TX y RX para saber cuántos ticks dura un bit.

## 6. Compatibilidad con los módulos de los compañeros

| Bloque | Estado | Notas |
|---|---|---|
| Receiver FIFO / Transmitter FIFO | Compatible | `dout` es combinacional en el puntero de lectura, `pop` en el mismo ciclo (por eso `rbr_rd` es pulso combinacional). El TX FIFO no tiene `clr` → ver 7. |
| Event / Interrupt control | Compatible | Recibe `iir_rd`, `lsr_rd`, `rbr_rd`, `thr_wr`; entrega `iir_data`. |
| Receiver timing/control | Compatible | `OE` llega como pulso de 1 ciclo → por eso `oe_lat`. |
| **Transmitter (uart_tx_ctrl)** | **Compatible, sin problemas encontrados** | Usa `wls/stb/pen/eps/sp/bc` (salen directo del LCR), `bclk_tick` del baud gen, `tsr_empty` (entra a `TEMT`), y toma el dato del TX FIFO. No necesita cambios en ningún lado. |

## 7. Notas para la integración (sin construir el top)

1. `urrst`: la Control Logic lo entrega con polaridad TI (1 = activo); `event_control` lo necesita como `~urrst`.
2. `line_err = OE | (rx_push & (PE|FE|BI))` (pulso) hacia `event_control`.
3. `THRE = tx_empty`, `TEMT = tx_empty & tsr_empty`, `DR = ~rx_empty`.
4. El TX FIFO no tiene `clr`: usar `fifo_en & ~txclr` como reset (la Control Logic ya entrega `txclr` registrado).
5. Las FIFOs quedan en reset con `fifo_en = 0` → no hay modo sin FIFO (limitación heredada de sus módulos).
6. El timeout de `event_control` cuenta en ticks y el de la guía en bits: hace falta un divisor ticks→bits.
7. Loopback (`loop`): `rxd_in = loop ? tx_serial : rxd`, fuera del receptor.

## 8. Cambios respecto a la primera versión (`.v`)

- Pasó a SystemVerilog con bloque `` `ifdef FORMAL ``.
- `rxclr` / `txclr` ahora son registros (un ciclo, sin glitches).
- LSR enmascara `BI/FE/PE` con `DR`.
- `OE` retenido con `oe_lat` (parámetro `OE_STICKY`).
- Puerto `addr` de 4 bits (`offset/4`).

## 9. Preguntas abiertas

- Mapeo exacto de PWREMU_MGMT (bits 0, 13, 14 en TI) vs. el empaquetado de 8 bits usado aquí.
- Si el docx espera que `OE` sea sticky o pulso (el parámetro `OE_STICKY` permite cambiarlo).
