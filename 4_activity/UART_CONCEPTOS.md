# UART – (Cuarta Actividad: Formal Verification)

## 1. Tarea a realizar
 
Se nos pide crear el **módulo UART**, dividido en estos bloques:
 
1. Buffer (Data Bus Buffer)
2. Register File
3. Divisor latch – Baud generator
4. Receiver / Transmitter FIFO
5. Receiver timing and control
6. Transmitter timing and control
7. **Control Logic** ← *el bloque que me tocó*
8. Interrupt / Event control

El tema del reto es **verificación formal**: escribir el RTL del bloque y verificarlo con
propiedades SVA (`assume` en entradas, `assert` en salidas/estados) usando **SymbiYosys**.

---

## 2. ¿Qué es un UART?
 
**UART** = *Universal Asynchronous Receiver/Transmitter*. Es un periférico que:
 
- convierte **paralelo → serial** los datos que envía la CPU (transmisión), y
- convierte **serial → paralelo** los datos que llegan por el cable (recepción).
Es **asíncrono**: no comparte reloj con el otro dispositivo. Ambos acuerdan una velocidad
(baudios) y cada carácter viaja dentro de una trama:
 
```
línea en reposo = 1
  ┌─────┬──────────────────┬─────────┬──────────┐
  │START│ 5–8 bits de dato │ PARIDAD │ 1–2 STOP │
  │ (0) │   (LSB primero)  │ (opc.)  │   (1)    │
  └─────┴──────────────────┴─────────┴──────────┘
```
 
Pines principales: `RXD` (entrada serial), `TXD` (salida serial) y, opcionalmente,
`RTS`(Request to Send) / `CTS`(Clear tu send) para control de flujo por hardware (*autoflow*).
 
La CPU lo controla **leyendo y escribiendo registros** a través de un bus de periférico.
 
---

## 3. Diagrama de conexión de los bloques

> El diagrama a continuación fue tomado de la guía de **Texas Instruments**.


<img src="figs/UART_TI_coloreado.png" alt="Diagrama de conexiones por bloques" width="800">

---

### 3.1 Diferencias entre el diagrama de TI y el reparto del docx
 
| Tema | Figura 1-1 de TI | `UART_Signals.docx` |
|---|---|---|
| **Nombre "Control Logic"** | Es **una caja pequeña**: recibe la salida del MCR y se conecta con los bloques de timing y control y con el registro de energía/emulación. La guía no la describe en el texto. | Es **un bloque grande**: decodificación, registros, *Select* y *Data Bus Buffer*. **No es la misma caja**, solo comparte el nombre. |
| Registros (LCR, MCR, IER, FCR, DLL/DLH, etc.) | Cada uno es una caja suelta conectada al bus | Todos quedan **dentro** del Control Logic |
| Data Bus Buffer y los dos *Select* | Cajas sueltas | **Dentro** del bloque Control Logic |
| Funciones de la caja Control Logic de TI (loopback, autoflow con RTS/CTS) | Se ven conectadas al MCR y a los bloques de timing | En el docx están **repartidas** en el TX y el RX (señales `loop`, `afe`, `rts_n`, `cts_n`) |
| **Baud Generator** | Caja propia | **No aparece como bloque** en el docx: solo se menciona el `bclk_tick` y el `divisor` sale del bloque control logic. |
| Receiver FIFO y Transmitter FIFO | Cajas propias | Bloques propios (1 y 2) |
| Timing and Control + Shift Register | Cajas separadas | Cada timing and control **incluye** su registro de desplazamiento |
| Interrupt/Event Control + IIR | Caja de control + registro IIR | El bloque 6 genera el valor del IIR, y el Control Logic solo lo recibe y lo presenta en el bus |
| Eventos desde los bloques hacia Interrupt/Event Control | No se dibujan líneas | El docx sí define esas entradas (errores de línea, FIFO vacío, nivel de disparo…) |
 
> **Resumen:** el diagrama de arriba mantiene la estructura de TI, y el recuadro muestra qué parte
> del dibujo corresponde a **el** Control Logic según el UART_Signals.docx.
 
---

## 4. Cada bloque en detalle
 
> **Qué es esta sección y qué no.** Es una explicación **conceptual**: sigue la estructura de la guía de TI
> y de la diapositiva, y completa con detalles de la guía (niveles de disparo de 1/4/8/14 bytes, orden de
> prioridad de interrupciones). **No es la especificación a codificar.** Lo que se codifica son los
> **6 bloques de `UART_Signals.docx`**, que se relacionan así:
>
> | Bloque del docx | Dónde se explica aquí | Observación |
> |---|---|---|
> | 1. Receiver FIFO | 4.7 | |
> | 2. Transmitter FIFO | 4.4 | |
> | 3. Receiver Timing and Control (incluye RSR) | 4.6 | |
> | 4. Transmitter Timing and Control (incluye TSR) | 4.5 | |
> | 5. **Control Logic** (mi bloque) | 4.1, 4.2 y los latches de 4.3 | 4.2 y los latches DLL/DLH **no son bloques aparte** en el docx: están dentro del Control Logic |
> | 6. Interrupt / Event Control (incluye árbitro, timeout e **IIR**) | 4.8 | El **IIR lo genera este bloque**; tu Control Logic solo lo recibe (`iir_data`) y lo presenta en el bus |
> | *(no existe)* | 4.3 (Baud generator) | El docx **no** lo define como bloque |
 
### 4.1 Control Logic (mi bloque)
Ventanilla entre la CPU y el UART. Decodifica a qué registro apunta la CPU, guarda la configuración
y la reparte, avisa a los demás cuando la CPU leyó o escribió algo, y compone el valor de lectura.
Ver sección 5.
 
### 4.2 Data Bus Buffer y Register File
Según el docx, ambos quedan dentro de la Control Logic.
- **Data Bus Buffer:** pone y recibe los datos en el bus de la CPU de forma ordenada.
- **Register File:** el conjunto de registros que la CPU programa (formato de trama, FIFOs, interrupciones, divisor, etc.).
### 4.3 Divisor latch + Baud generator (el metrónomo)
> Nota: los latches DLL/DLH son registros del Control Logic. El **Baud generator** no tiene bloque propio en el docx.
 
- La CPU escribe un divisor de 16 bits (dos registros de 8 bits: DLL y DLH).
- El generador divide el reloj del sistema y produce **ticks** a una frecuencia fija (16× o 13× la velocidad en baudios, según el modo de sobremuestreo).
- Con eso el transmisor sabe cuánto dura cada bit y el receptor sabe cuándo muestrear.
- **Recibe de:** Control Logic (divisor y modo). **Entrega a:** transmisor y receptor (el tick).
- Velocidad aproximada: `baudios = reloj / (divisor × sobremuestreo)`.

### 4.4 Transmitter FIFO
- Cola donde la CPU va dejando bytes **en paralelo** para no tener que esperar a que cada uno termine de enviarse.
- Sin FIFO (modo no-FIFO) funciona como un solo registro, el THR.
- **Recibe de:** Control Logic (el byte y el aviso de escritura). **Entrega a:** Transmitter timing and control.

### 4.5 Transmitter timing and control (+ registro de desplazamiento TSR)
- Toma el siguiente byte del FIFO, lo carga en el **registro de desplazamiento** y lo saca bit a bit.
- Es una **máquina de estados** que arma la trama completa: START, bits de datos, paridad opcional y STOP.
- Cuenta ticks de baudios para dar a cada bit su duración.
- Informa cuándo el registro de desplazamiento está vacío (`tsr_empty`), que junto con el FIFO vacío forma **TEMT**. El bit **THRE** sale del **FIFO de transmisión** (su señal `empty`), no de este bloque. También puede enviar una condición de *break*.
- **Aquí ocurre la conversión paralelo → serial.**

### 4.6 Receiver timing and control (+ registro de desplazamiento RSR)
- Escucha `RXD`, detecta el flanco de **START**, espera medio bit y muestrea cada bit en su punto medio.
- Va armando el carácter en el **registro de desplazamiento**, revisa paridad y bit de STOP, y detecta *break* y desbordamiento.
- Cuando termina, entrega el byte (con sus banderas de error) al FIFO de recepción.
- **Aquí ocurre la conversión serial → paralelo.**

### 4.7 Receiver FIFO
- Cola que guarda los bytes recibidos junto con sus errores hasta que la CPU o el DMA los leen.
- Tiene un **nivel de disparo** (1, 4, 8 o 14 bytes) para avisar cuándo ya hay suficientes datos.
- **Recibe de:** Receiver timing and control. **Entrega a:** Control Logic (el byte que la CPU lee como RBR).

### 4.8 Interrupt / Event control (el sistema de alarmas)
- Reúne las causas posibles de interrupción y las ordena por prioridad: **1° errores de línea, 2° dato recibido o *timeout*, 3° registro de transmisión vacío**.
- Genera la señal de interrupción hacia la CPU y el valor del IIR que dice *por qué* interrumpió.
- Genera también los eventos para el DMA.
- **Recibe de:** Control Logic (qué interrupciones están habilitadas y cuándo la CPU leyó) y de los demás bloques (sus condiciones). **Entrega a:** la CPU y a la Control Logic (el IIR).


---


## 5. Para qué sirve mi Control Logic
 
> **Aviso:** En la Figura 1-1 de TI existe una cajita llamada "Control Logic" junto al MCR.
> **No es el bloque especificado en el docx.** El "Control Logic" que se trabajará en el código es la definición del docx: decodificación + registros +
> *Select* + *Data Bus Buffer*.
 
### 5.1 Tres tipos de conexión con los demás bloques
 
| Tipo | Dirección | Ejemplos |
|---|---|---|
| **Configuración** | Control Logic → otros | Formato de trama (bits de datos, paridad, stop), divisor de baudios, activar FIFOs, reset de transmisor/receptor, habilitar interrupciones |
| **Pulsos de acceso** | Control Logic → otros | "La CPU acaba de escribir un byte para enviar", "la CPU acaba de leer el dato recibido", "la CPU leyó el estado", "la CPU escribió el control de FIFO" |
| **Estado** | otros → Control Logic | Si hay dato listo, errores de recepción, si el transmisor está vacío, valor del IIR, byte recibido |
 
### 5.2 Lo que hace, en orden
 
1. **Decodifica** la dirección que pone la CPU y decide a qué registro se accede.
   Algunas direcciones se comparten: una misma dirección puede ser RBR, THR o DLL según el bit **DLAB**, y otra puede ser IIR (lectura) o FCR (escritura).
2. **Guarda** los registros de configuración: se escriben desde el bus y mantienen su valor.
3. **Reparte** esa configuración como señales hacia transmisor, receptor, FIFOs, generador de baudios e interrupciones.
4. **Avisa** con pulsos de un ciclo cuándo hubo un acceso relevante, para que los FIFOs saquen/metan un byte y las interrupciones limpien banderas.
5. **Compone la lectura:** arma el registro de estado (LSR) con bits que vienen de otros bloques y elige qué valor sale por el bus.
6. **Hace esperar a la CPU** (2 estados de espera) cuando escribe el divisor de baudios.

### 5.3 Lo que NO hace

- No convierte bits entre serial y paralelo.
- No detecta START ni cuenta tiempos de bit.
- No calcula ni revisa paridad.
- No decide cuándo interrumpir ni con qué prioridad.
- No guarda los bytes de datos (eso es de los FIFOs).

---
