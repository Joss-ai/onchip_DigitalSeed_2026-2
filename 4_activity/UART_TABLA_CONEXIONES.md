# Tabla de conexiones de mi Control Logic (y el Baud Generator)

> Fuentes: `UART_Signals.docx` (nombres y anchos de señales) y la guía de TI `sprugp1.pdf`
> (para qué sirve cada bit). Lo que **no** viene de ninguna de las dos está marcado como **(propuesta)**.
>
> Cómo leer las tablas: **"Qué hago con ella"** explica el uso dentro de mi bloque y
> **"Por qué la necesito / por qué la genero"** explica la razón de que exista esa conexión.

---

## 1. Mi bloque (control logic)
 
```
                          ┌─────────────────────────────┐
  CPU (bus) ─────────────▶│                             │──▶ configuración ──▶ TX, RX, FIFOs, INT
  addr, wdata, wr, rd, sel│        CONTROL LOGIC        │──▶ pulsos de acceso ─▶ FIFOs, INT
  ◀── rdata, ready ───────│                             │──▶ divisor ─▶ BAUD GEN ─▶ bclk_tick ─▶ TX, RX, INT
                          │                             │
  FIFOs, TX, RX, INT ────▶│  estados (DR, OE, ... ),    │
                          │  rbr_data, iir_data         │
                          └─────────────────────────────┘
```
 
Mi bloque hace de **ventanilla**: lo que la CPU escribe lo convierto en configuración y pulsos
para los demás, y lo que los demás me informan lo convierto en el valor que la CPU lee.
 
---
## 2. ENTRADAS de la Control Logic
 
### 2.1 Reloj, reset y bus de la CPU
 
| Señal | Ancho | De dónde viene | Qué hago con ella | Por qué la necesito |
|---|---|---|---|---|
| `clk` | 1 | Reloj del sistema | Sincroniza todos mis registros y el contador de espera | Es un diseño síncrono |
| `rst` | 1 | Reset del sistema | Pone todos mis registros en su valor inicial (0) | Los registros deben empezar en un estado conocido. **(propuesta)**: síncrono y activo en alto; el docx no dice la polaridad |
| `addr[5:2]` | 4 | CPU | Elige a qué registro se accede. Es el offset dividido entre 4 (offset 14h → `4'h5`) | Todos los registros se acceden por dirección |
| `wdata[7:0]` | 8 | CPU | Dato que se guarda en el registro elegido. **Además va directo al `din` del Transmitter FIFO** | Es el único dato que entra desde la CPU. Yo no tengo salida de dato, por eso el top lo reparte |
| `wr` | 1 | CPU | Indica que la CPU quiere escribir | Distinguir escritura de lectura |
| `rd` | 1 | CPU | Indica que la CPU quiere leer | Distinguir lectura de escritura |
| `sel` | 1 | CPU / decodificador externo | Si vale 0, ignoro `wr` y `rd` | Habilita el acceso solo cuando el bus va dirigido a este UART |
 
### 2.2 Estados de otros bloques (con ellos armo el registro LSR)
 
El **LSR** (Line Status Register, offset 14h) es de solo lectura: la CPU lo lee para saber qué pasa en la línea.
Yo no calculo ninguno de estos estados, **solo los junto en un byte** en este orden:
 
`LSR[7:0] = { RXFIFOE, TEMT, THRE, BI, FE, PE, OE, DR }`
 
| Señal | Bit LSR | Viene de | Cómo la obtiene el top | Qué le dice a la CPU |
|---|---|---|---|---|
| `DR` | 0 | Receiver FIFO | `~empty` | Hay al menos un byte listo para leer en RBR |
| `OE` | 1 | Receiver T&C | `oe` | Overrun: llegó un carácter con el FIFO lleno y se perdió. **Yo lo retengo hasta que se lea el LSR** (**propuesta**, ver nota) |
| `PE` | 2 | Receiver FIFO | `err_top` | El carácter que se va a leer tuvo error de paridad |
| `FE` | 3 | Receiver FIFO | `err_top` | El carácter tuvo error de trama (bit de stop incorrecto) |
| `BI` | 4 | Receiver FIFO | `err_top` | Se detectó una condición de *break* |
| `THRE` | 5 | Transmitter FIFO | `empty` | El FIFO de transmisión está vacío: la CPU puede escribir más en THR |
| `TEMT` | 6 | Transmitter FIFO + Transmitter T&C | `tx_empty & tsr_empty` | El transmisor terminó del todo (FIFO y registro de desplazamiento vacíos) |
| `RXFIFOE` | 7 | Receiver FIFO | `any_err` | Hay algún carácter con error dentro del FIFO RX |
 
> **Nota sobre `OE`:** si el receptor la entrega como un pulso de un ciclo, se perdería antes de que la CPU lea
> el LSR. Por eso mi bloque la retiene (`oe_lat`) hasta que ve `lsr_rd`. Es el único bloque que tiene a la vez
> `OE` y la información de lectura del LSR. El parámetro `OE_STICKY = 0` la desactiva si el receptor ya la mantiene.
 
### 2.3 Datos que debo mostrar a la CPU
 
| Señal | Ancho | Viene de | Qué hago con ella | Por qué la necesito |
|---|---|---|---|---|
| `rbr_data` | 8 | Receiver FIFO (`dout`) | La pongo en `rdata` cuando la CPU lee RBR (offset 0h con DLAB=0) | RBR no se guarda en mi bloque: es el byte de la cabeza del FIFO |
| `iir_data` | 8 | Interrupt/Event (`iir`) | La pongo en `rdata` cuando la CPU lee IIR (offset 8h) | El IIR lo calcula el bloque de interrupciones, yo solo lo presento |
 
---

## 3. SALIDAS de la Control Logic
 
### 3.1 Hacia la CPU
 
| Señal | Ancho | Qué es | Por qué la genero yo |
|---|---|---|---|
| `rdata[31:0]` | 32 | Dato de lectura. Solo los 8 bits bajos tienen valor, el resto va en 0 | Soy la ventanilla: lo que la CPU lee siempre sale de mi bloque, y yo elijo de qué registro |
| `ready` | 1 | 1 = el acceso termina ahora. 0 = la CPU debe esperar | La guía dice que escribir DLL/DLH inserta **2 estados de espera** mientras el generador de baudios carga el nuevo divisor. Yo recibo esa escritura, así que yo hago esperar |
 
### 3.2 Pulsos de acceso (duran 1 ciclo, salen en el mismo ciclo del acceso)
 
Existen porque los demás bloques **no ven el bus**. Solo yo sé cuándo la CPU tocó cada registro.
 
| Señal | Se activa cuando… | Va a | Para qué la usa el receptor del pulso |
|---|---|---|---|
| `rbr_rd` | La CPU **lee** offset 0h con DLAB=0 | Receiver FIFO (`pop`), Interrupt/Event | El FIFO saca el byte que la CPU acaba de leer. El bloque de interrupciones limpia la interrupción de "dato recibido" y reinicia el timeout |
| `thr_wr` | La CPU **escribe** offset 0h con DLAB=0 | Transmitter FIFO (`push`), Interrupt/Event | El FIFO guarda el byte (que toma de `wdata`). El bloque de interrupciones limpia la interrupción de "THR vacío" |
| `fcr_wr` | La CPU **escribe** offset 8h | *(nadie en el docx)* | Podría servir para avisar a los FIFOs, pero el docx usa `fifo_en`, `rxclr` y `txclr` |
| `iir_rd` | La CPU **lee** offset 8h | Interrupt/Event | Se limpia la interrupción de THR vacío al leer el IIR |
| `lsr_rd` | La CPU **lee** offset 14h | Interrupt/Event | Se limpia la interrupción de error de línea al leer el LSR. También yo borro mi `oe_lat` |
| `rxclr` | Escribir FCR con FIFOEN=1 y RXCLR=1 | Receiver FIFO (`clr`) | Vaciar el FIFO RX |
| `txclr` | Escribir FCR con FIFOEN=1 y TXCLR=1 | Transmitter FIFO (`clr`) | Vaciar el FIFO TX |
 
### 3.3 Configuración desde LCR (Line Control Register, offset Ch)
 
| Señal | Bit LCR | Va a | Para qué la usan |
|---|---|---|---|
| `wls[1:0]` | 1:0 | Receiver T&C, Transmitter T&C, Interrupt/Event | Cuántos bits de dato tiene cada carácter (00=5, 01=6, 10=7, 11=8). El bloque de interrupciones además lo usa para el timeout (4 tiempos de carácter) |
| `stb` | 2 | Transmitter T&C | Cuántos bits de stop se envían |
| `pen` | 3 | Receiver T&C, Transmitter T&C | Habilita la paridad |
| `eps` | 4 | Receiver T&C, Transmitter T&C | 0 = paridad impar, 1 = par |
| `sp` | 5 | Receiver T&C, Transmitter T&C | Paridad fija (*stick parity*) |
| `bc` | 6 | Transmitter T&C | Fuerza `TXD` a 0 (condición de *break*) |
| `dlab` | 7 | *(nadie fuera de mi bloque)* | Dentro de mi bloque decide si las direcciones 0h y 4h son RBR/THR/IER o DLL/DLH. Se saca como salida porque el docx la lista |
 
### 3.4 Configuración desde FCR (FIFO Control Register, offset 8h, solo escritura)
 
| Señal | Bit FCR | Va a | Para qué la usan |
|---|---|---|---|
| `fifo_en` | 0 | Receiver FIFO, Transmitter FIFO, Interrupt/Event | Activa el modo FIFO. Los eventos DMA solo existen en modo FIFO |
| `rxfiftl[1:0]` | 7:6 | Receiver FIFO | Nivel de disparo del FIFO RX (1, 4, 8 o 14 bytes) |
| `dmamode1` | 3 | Interrupt/Event | Habilita los eventos DMA |
| `rxclr`, `txclr` | 1, 2 | FIFOs | Ver sección 3.2 (son pulsos, no se guardan) |
 
> La guía dice que si `FIFOEN` no se escribe en 1, el resto de bits del FCR **no se programa**. Mi código lo respeta.
 
### 3.5 Configuración desde MCR (Modem Control Register, offset 10h)
 
| Señal | Bit MCR | Va a | Para qué la usan |
|---|---|---|---|
| `afe` | 5 | Receiver T&C, Transmitter T&C | Activa el control de flujo automático (RTS/CTS) |
| `loop` | 4 | Transmitter T&C y el multiplexor de `rxd_in` del top | Loopback: el receptor escucha al transmisor en vez del pin RXD |
| `out2` | 3 | *(nadie en el docx)* | Bit libre de usuario |
| `out1` | 2 | *(nadie en el docx)* | Bit libre de usuario |
| `rts_en` | 1 | Receiver T&C | Habilita la señal RTS (en la guía es el bit `RTS`) |
 
### 3.6 Divisor, muestreo, reset de TX/RX e interrupciones
 
| Señal | Ancho | De qué registro | Va a | Para qué la usan |
|---|---|---|---|---|
| `divisor[15:0]` | 16 | `{DLH, DLL}` | **Baud generator** | Fija la velocidad en baudios |
| `osm_sel` | 1 | MDR bit 0 | Receiver T&C, Transmitter T&C | 0 = 16× (muestreo en el tick 8), 1 = 13× (tick 6). **No lo usa el Baud generator** |
| `utrst` | 1 | PWREMU_MGMT | Transmitter T&C, Interrupt/Event | 1 = transmisor habilitado, 0 = en reset |
| `urrst` | 1 | PWREMU_MGMT | Receiver T&C, Interrupt/Event | 1 = receptor habilitado, 0 = en reset |
| `free` | 1 | PWREMU_MGMT | *(nadie en el docx)* | Modo de emulación libre |
| `erbi` | 1 | IER bit 0 | Interrupt/Event | Habilita la interrupción de dato recibido |
| `etbei` | 1 | IER bit 1 | Interrupt/Event | Habilita la interrupción de THR vacío |
| `elsi` | 1 | IER bit 2 | Interrupt/Event | Habilita la interrupción de estado de línea |
| `edssi` | 1 | IER bit 3 | Interrupt/Event | Habilita la interrupción de estado de módem (el docx no define entradas de módem) |
 
> **PWREMU_MGMT con bus de 8 bits (propuesta):** en la guía `UTRST` es el bit 14 y `URRST` el 13, pero `wdata` solo
> tiene 8 bits. Mapeé `FREE` → bit 0, `URRST` → bit 5, `UTRST` → bit 6 (los bits altos desplazados 8 posiciones).
> Hay que confirmarlo con el equipo.
 
---

## 4. Baud Generator (también mío, `baud_gen.v`)
 
**Por qué es mío:** el docx lista `divisor[15:0]` como salida de la Control Logic y `bclk_tick` como entrada del
receptor, el transmisor y las interrupciones, pero **ningún bloque produce `bclk_tick`**. Además, la guía (secciones 2.1
y 3.11) dice que las 2 esperas de la escritura del divisor ocurren "mientras el generador de baudios carga el nuevo
valor", lo que une ese generador con los registros DLL/DLH, que son míos. Es una **deducción razonable, no una
confirmación**: antes de entregar conviene avisar al equipo para que nadie lo duplique.
 
| Señal | Dirección | Ancho | Conexión | Qué hace |
|---|---|---|---|---|
| `clk` | entrada | 1 | Reloj del sistema | Reloj que se divide |
| `rst` | entrada | 1 | Reset del sistema | Detiene y pone en 0 la cuenta |
| `divisor` | entrada | 16 | Salida `divisor` de mi Control Logic | Cada cuántos ciclos de `clk` sale un pulso |
| `bclk_tick` | salida | 1 | Receiver T&C, Transmitter T&C, Interrupt/Event | Pulso de 1 ciclo. Llegan 16 (o 13) por bit |
 
Con divisor = 0 no hay pulsos (la guía: el BCLK no funciona si el divisor no se programó). Rango válido: 1 a 65535.
 
---

## 5. Ejemplo: cómo pasa un byte por mi Control Logic y el Baud Generator
 
Para hacerlo concreto se usa el byte **`0x55`** (`01010101`) con esta configuración:
 
| Dato del ejemplo | Valor | Cómo se llega a él |
|---|---|---|
| Reloj del sistema | 18,432 MHz | Se eligió para que la cuenta salga exacta |
| Velocidad | 115 200 baudios | |
| Oversampling | 16× (`osm_sel = 0`) | Valor de reset de MDR |
| **Divisor** | **10** (`0x000A`) | 18 432 000 ÷ (115 200 × 16) = 10 |
| Formato | 8 bits de dato, sin paridad, 1 bit de stop | LCR = `0x03` |
 
> **Ojo: en el ejemplo hay dos tipos de números.**
> - **`0x55` es el dato** que se quiere enviar. Se escribe en THR (fase 2) y es lo único que sale por el cable.
> - **`0x83`, `0x0A`, `0x0F`, `0x60`... son configuración.** Se escriben una sola vez al principio (fase 1) y le dicen al UART *cómo* enviar. No salen por el cable.
>
> Mi bloque trata ambos igual (guarda lo que llega por `wdata`), pero en registros distintos: la configuración se queda
> guardada en mis registros, y el dato `0x55` no se guarda en mi bloque (solo genero el pulso `thr_wr` para que el FIFO lo tome).
 
> Un carácter son 5 a 8 bits (`wls`). Un mensaje de 10 bits como `1010101011` hay que partirlo en dos caracteres.
 
### 5.1 Fase 1: configuración (una sola vez)
 
Aquí mi bloque trabaja más. Todo lo que la CPU escribe se queda **guardado en mis registros**
y se reparte a los demás bloques como señales fijas.
 
| Paso | La CPU escribe | Qué hace mi Control Logic | Qué hace el Baud Generator |
|---|---|---|---|
| 1 | **LCR** (`addr=3`) ← `0x83` | Decodifica `addr=3` y activa `wr_lcr`. Guarda `lcr_q = 0x83`. Salen **`dlab=1`**, **`wls=11`** (8 bits), `pen=0`, `stb=0` | Nada |
| 2 | **DLL** (`addr=0`, porque DLAB=1) ← `0x0A` | `sel_dll=1`, así que es una escritura al divisor. **`ready=0` durante 2 ciclos**; en el tercero (`ready=1`) guarda `dll_q = 0x0A`. Sale `divisor = 0x000A` | A partir del ciclo siguiente lee `divisor=10` y empieza a contar |
| 3 | **DLH** (`addr=1`, porque DLAB=1) ← `0x00` | Igual: 2 esperas, y guarda `dlh_q = 0x00`. `divisor` sigue en `0x000A` | Sin cambios |
| 4 | **LCR** ← `0x03` | Guarda `lcr_q = 0x03`. **`dlab=0`**: ahora `addr=0` vuelve a ser RBR/THR | Sigue contando |
| 5 | **FCR** (`addr=2`) ← `0x0F` | Pulso `fcr_wr`. Como FIFOEN=1, guarda `fifo_en=1` y `dmamode1=1`, y emite **un pulso** de `rxclr` y `txclr` (vacían los FIFOs) | Sin cambios |
| 6 | **PWREMU_MGMT** (`addr=Ch`) ← `0x60` | Guarda `utrst=1` y `urrst=1`: **habilita** el transmisor y el receptor | Sin cambios |
 
#### 5.1.1 Cómo se construye cada valor que escribe la CPU
 
**Quién elige los valores:** la CPU (el programador del software). Mi bloque **no calcula nada**: solo guarda lo que
llega por `wdata`, con una línea como `if (wr_lcr) lcr_q <= wdata;`. Cada número significa una configuración
porque la guía define qué hace cada bit.
 
**Ejemplo con el LCR = `0x83`.** Se parte de lo que se quiere y se llena cada bit:
 
| Bit | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
|---|---|---|---|---|---|---|---|---|
| Campo | DLAB | BC | SP | EPS | PEN | STB | WLS | WLS |
| Quiero | Acceder al divisor | Sin break | Sin paridad fija | (no importa) | Sin paridad | 1 bit de stop | Datos de 8 bits | Datos de 8 bits |
| **Valor** | **1** | 0 | 0 | 0 | 0 | 0 | **1** | **1** |
 
Binario `1000 0011` → hexadecimal **`0x83`** (`1000` = 8, `0011` = 3).
Codificación de `WLS`: `00` = 5 bits, `01` = 6, `10` = 7, `11` = 8.
 
**Por qué hay dos escrituras al LCR:**
- **`0x83` (DLAB=1):** abre el acceso a DLL/DLH. Con DLAB=1, las direcciones 0 y 1 apuntan al divisor.
- **`0x03` (DLAB=0):** mismo formato, pero con el bit 7 en 0. Las direcciones 0 y 1 vuelven a ser THR e IER.
**Los demás valores del ejemplo:**
 
| Registro | Valor | Binario | Significado |
|---|---|---|---|
| DLL | `0x0A` | `0000 1010` | El número 10, el divisor calculado: 18 432 000 ÷ (115 200 × 16) |
| FCR | `0x0F` | `0000 1111` | RXFIFTL=00 (nivel 1), DMAMODE1=1, TXCLR=1, RXCLR=1, FIFOEN=1 |
| PWREMU_MGMT | `0x60` | `0110 0000` | UTRST=1 (bit 6), URRST=1 (bit 5), FREE=0. Mapeo **(propuesta)** |
 
**Lo que mi bloque hace con el valor** (para `0x83`): lo guarda en `lcr_q` y las salidas son simples cables a sus bits:
`dlab = lcr_q[7] = 1`, `wls = lcr_q[1:0] = 11`, `pen = lcr_q[3] = 0`, `stb = lcr_q[2] = 0`.
 
> **Importante:** tras el reset, `utrst` y `urrst` valen 0 (el TX y el RX están en reset). Hasta el paso 6 no transmitirían nada.
> El valor `0x60` depende del mapeo de 8 bits que yo propuse para PWREMU_MGMT (ver sección 3.6).
 
**Qué hace exactamente el Baud Generator con el divisor 10:**
 
```
ciclo   :  0 1 2 3 4 5 6 7 8 9 | 0 1 2 3 4 5 6 7 8 9 | ...
cnt     :  0 1 2 3 4 5 6 7 8 9 | 0 1 2 3 4 5 6 7 8 9 | ...
tick    :  . . . . . . . . . 1 | . . . . . . . . . 1 | ...
                              ▲ pulso cuando cnt = 9 (divisor - 1)
```
 
- Un pulso `bclk_tick` cada **10 ciclos de reloj**.
- Cada bit dura **16 pulsos** = 160 ciclos de reloj.
- Un carácter completo (1 start + 8 datos + 1 stop = 10 bits) dura 1600 ciclos = 86,8 µs, es decir, 115 200 baudios.
### 5.2 Fase 2: transmitir `0x55`
 
| Paso | La CPU hace | Qué hace mi Control Logic | Baud Generator | Otros bloques |
|---|---|---|---|---|
| 7 | **Lee LSR** (`addr=5`) | Pulso `lsr_rd`. Arma el byte con los estados que recibe: `THRE=1`, `TEMT=1` → **`rdata = 0x60`** | Sigue generando ticks | El FIFO TX y el transmisor informan que están vacíos |
| 8 | **Escribe THR** (`addr=0`, DLAB=0) ← `0x55` | `ready=1` (sin espera). Genera el pulso **`thr_wr`** durante un ciclo. **El dato no se queda en mi bloque** | Sin cambios | El top conecta `wdata` al `din` del FIFO TX y `thr_wr` es el `push`: el FIFO guarda `0x55` |
| 9 | (libre, ya no espera) | **Sigo entregando `wls=11`, `pen=0`, `stb=0`, `utrst=1`** al transmisor | Entrega `bclk_tick` al transmisor | El transmisor saca el byte del FIFO (`tx_pop`), lo carga en su registro de desplazamiento y pone en `TXD`: START, `1 0 1 0 1 0 1 0` (LSB primero), STOP. Cambia de bit cada 16 ticks |
| 10 | **Lee LSR** durante el envío | Compongo `THRE=1`, `TEMT=0` → **`rdata = 0x20`** | Sigue | El FIFO ya está vacío, pero el registro de desplazamiento aún trabaja |
| 11 | **Lee LSR** al terminar | `THRE=1`, `TEMT=1` → **`rdata = 0x60`** | Sigue | El transmisor termina el STOP y vuelve a reposo |
 
**Qué hice yo con el byte `0x55`: nada más que avisar que llegó.** El `0x55` fue de la CPU al FIFO. Yo solo vi pasar `wdata` y emití `thr_wr`.
 
### 5.3 Fase 3: recibir `0x55` (el camino contrario)
 
Supón que llega por `RXD` el mismo byte.
 
| Paso | Qué ocurre | Qué hace mi Control Logic | Baud Generator |
|---|---|---|---|
| 12 | El receptor detecta el START y muestrea cada bit en el **tick 8** de los 16 de ese bit (`osm_sel=0`). Arma `0x55` y lo mete en el FIFO RX | Entrego al receptor `wls`, `pen`, `eps`, `sp`, `osm_sel`, `urrst`, que le dicen cómo interpretar el carácter | Entrega `bclk_tick` al receptor |
| 13 | El FIFO RX deja de estar vacío (`DR` pasa a 1) | Recibo `DR=1` | Sigue |
| 14 | La CPU **lee LSR** | Compongo el byte: `DR=1`, `THRE=1`, `TEMT=1` → **`rdata = 0x61`** | Sigue |
| 15 | La CPU **lee RBR** (`addr=0`, DLAB=0) | **Pongo `rbr_data` (el byte `0x55` que me da el FIFO) en `rdata`** y emito el pulso **`rbr_rd`** en el mismo ciclo | Sigue |
| 16 | El FIFO recibe `rbr_rd` como `pop` y elimina ese byte. El bloque de interrupciones limpia su aviso | — | Sigue |
| 17 | La CPU lee LSR otra vez | `DR=0` → `rdata = 0x60` | Sigue |
 
**Por qué `rbr_rd` debe salir en el mismo ciclo de la lectura:** el FIFO hace el `pop` al final de ese ciclo. Si el pulso saliera un ciclo tarde, dos lecturas seguidas podrían leer el mismo byte.
 
### 5.4 Resumen: qué hace cada uno
 
| | Mi Control Logic | Baud Generator |
|---|---|---|
| **Configuración** | Recibe lo que escribe la CPU, lo guarda y lo reparte | Recibe solo `divisor` |
| **Transmisión** | Genera `thr_wr` y arma el LSR | Da el ritmo (`bclk_tick`) con el que el transmisor mide cada bit |
| **Recepción** | Entrega `rbr_data` en la lectura, genera `rbr_rd` y arma el LSR | Da el ritmo con el que el receptor muestrea cada bit |
| **Lo que no hacen** | No convierten a serie ni a paralelo, no cuentan bits del dato | No conocen el dato ni el formato (`wls`, paridad, etc.) |
 
La división es esta: **yo configuro y aviso, el Baud Generator marca el ritmo, y el transmisor y el receptor hacen el trabajo serial.**
 
---

## 6. Cómo queda la interconexión completa
 
### 6.1 Qué recibe cada bloque de mí
 
| Bloque | Señales que le doy |
|---|---|
| Receiver FIFO | `rbr_rd` (pop), `fifo_en`, `rxclr` (clr), `rxfiftl` |
| Transmitter FIFO | `thr_wr` (push), `fifo_en`, `txclr` (clr) |
| Receiver T&C | `wls`, `pen`, `eps`, `sp`, `osm_sel`, `urrst`, `afe`, `rts_en` |
| Transmitter T&C | `wls`, `pen`, `eps`, `sp`, `stb`, `bc`, `osm_sel`, `utrst`, `afe`, `loop` |
| Interrupt / Event | `erbi`, `etbei`, `elsi`, `edssi`, `rbr_rd`, `lsr_rd`, `thr_wr`, `iir_rd`, `wls`, `urrst`, `utrst`, `fifo_en`, `dmamode1` |
| Baud generator | `divisor` |
 
### 6.2 Qué recibo yo de cada bloque
 
| Bloque | Señales que recibo |
|---|---|
| Receiver FIFO | `DR` (de `~empty`), `PE/FE/BI` (de `err_top`), `RXFIFOE` (de `any_err`), `rbr_data` (de `dout`) |
| Transmitter FIFO | `THRE` (de `empty`), y `empty` para formar `TEMT` |
| Transmitter T&C | `tsr_empty`, que con `empty` del FIFO TX forma `TEMT` |
| Receiver T&C | `OE` (de `oe`) |
| Interrupt / Event | `iir_data` (de `iir`) |
 
### 6.3 Señales que yo genero y nadie consume (según el docx)
 
`fcr_wr`, `dlab`, `out1`, `out2`, `free`. Están en el docx como salidas mías, pero ningún bloque las lista como entrada.
Se dejan sin conectar en el top. FALTA PREGUNTAR SI TIENE ALGÚN DESTINO.
 
