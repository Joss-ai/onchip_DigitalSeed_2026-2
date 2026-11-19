# Documentación interactiva

Tres páginas HTML autocontenidas: se abren con doble clic en el navegador, sin instalar nada. Cargan las fuentes desde Google Fonts, así que con conexión se ven mejor, pero funcionan igual sin ella.

| Archivo | Qué es |
|---|---|
| `01_guia_timing.html` | Primera guía del módulo: la idea general, la interfaz señal por señal, el formato de la trama, la relación entre `clk`, `bclk_tick` y el tiempo de bit, la máquina de estados, un simulador ciclo a ciclo, los casos especiales (break, loopback, CTS, `utrst`), una sección sobre verificación formal y una autoevaluación. Su RTL de referencia es una versión anterior con nombres en inglés; el código final está en `SRC/` |
| `02_diagrama_bloque.html` | El bloque con sus **16 entradas y 5 salidas** y por dentro las cuatro piezas (a) TSR, (b) contador de ticks, (c) contador de bits y (d) FSM. Botones para avanzar un tick o un bit y ver cómo se mueve todo mientras sale la letra. Los nombres coinciden con `SRC/uart_tx_ctrl.sv` |
| `03_codigo_explicado.html` | `SRC/uart_tx_ctrl.sv` explicado en 15 segmentos, con los números de línea reales, el diagrama de la máquina de estados, una tarjeta por estado (por ejemplo, qué es IDLE) y el recorrido completo de la letra `A` |

Los números de línea de `03_codigo_explicado.html` corresponden al archivo `SRC/uart_tx_ctrl.sv` tal como está en esta carpeta (205 líneas, sin comentarios).
