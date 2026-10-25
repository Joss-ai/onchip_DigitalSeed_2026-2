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

> El diagrama a continuación fue tomado de la guía de TI.

---




