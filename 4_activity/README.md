# Receiver Timing and Control del UART

Este repositorio contiene el diseño y la verificación formal del Receiver Timing and Control de un sistema UART.

## Estructura de directorios

```text
4_activity/
├── README.md
├── Formal/                # Código fuente y configuración .sby del receiver timing and control
│   ├── Prueba_CBITS/
│   ├── Prueba_CTICKS/
│   ├── Prueba_FSM/
│   └── README.md
└── SRC/                   # Código fuente del FIFO de recepción
    └── README.md
```

## Ejecución de la verificación formal

Para ejecutar la verificación formal de los módulos SystemVerilog con SymbiYosys, corre el siguiente comando dentro de cada carpeta de prueba:

```text
sby -f archivo.sby
```

| Opción | Propósito |
|---|---|
| `-f` | Obliga a SymbiYosys a sobrescribir los directorios de salida anteriores y a ejecutar una corrida limpia. |

## Estructura de la configuración `.sby`

Cada archivo `.sby` se divide en secciones:

| Sección | Propósito |
|---|---|
| `[options]` | Modo de verificación y profundidad. |
| `[engines]` | Solver usado para comprobar las propiedades. |
| `[script]` | Archivos RTL a leer y módulo superior bajo prueba. |
| `[files]` | Archivos fuente locales que se copian al espacio de trabajo de SymbiYosys. |

```text
[options]
mode bmc
depth 1

[engines]
smtbmc

[script]
read -formal bcd.sv
prep -top bcd_inc

[files]
bcd.sv
```

### `[options]`

## Comandos de verificación formal

Estas construcciones se escriben dentro de cada módulo, envueltas en `` `ifdef FORMAL ``, por lo que solo las usa SymbiYosys y se ignoran en la síntesis.

| Comando | Propósito |
|---|---|
| `assume` | Restringe las **entradas**: le indica al solver qué comportamientos de entrada están permitidos. |
| `assert` | Verifica las **salidas y el comportamiento interno**: la propiedad que debe cumplirse en cada ciclo alcanzable. |
| `cover` | Obliga al solver a encontrar al menos una ejecución que alcance una condición. Demuestra que el caso es alcanzable, es decir, que las suposiciones no son demasiado estrictas. |
| `f_past_valid` | Bandera que vale `0` solo en el primer ciclo y `1` después. Permite usar valores pasados (`$past`) y definir condiciones iniciales, por ejemplo reset activo en el primer ciclo. |

```verilog
reg f_past_valid = 1'b0;
always @(posedge clk) f_past_valid <= 1'b1;

always @* if (!f_past_valid) assume (rst);   // siempre empezar con reset
```

### `$stable`

`$stable(x)` es verdadero cuando `x` tiene el mismo valor que en el ciclo de reloj anterior. Es una forma abreviada de `x == $past(x)`.

```verilog
always @(posedge clk) if (f_past_valid) assume ($stable(osm_sel));
```

Mientras que `assume (d <= 9)` limita el **valor** de una entrada, `$stable` limita **cómo cambia en el tiempo**. En este diseño modela las señales de configuración (`osm_sel`, `wls`, `pen`) que no cambian mientras se recibe un carácter. Está envuelto en `f_past_valid` porque el primer ciclo no tiene ciclo anterior.

## Tipos de pruebas

| Tarea | Descripción |
|---|---|
| `bmc` | Verificación de modelo acotada (*bounded model checking*). Siempre parte del reset (el primer ciclo se fuerza con `f_past_valid`) y comprueba las propiedades hasta `depth` ciclos de reloj. Encuentra errores, pero no demuestra el diseño para todos los ciclos. |
| `prove` | Prueba por k-inducción. El caso base parte del reset, pero el paso inductivo puede partir de **cualquier estado**, por lo que no depende de `f_past_valid` para empezar en reset. Demuestra las propiedades para todos los ciclos. |
| `cover` | Análisis de alcanzabilidad. Comprueba que se pueda alcanzar cada sentencia `cover`. |

Si `prove` falla en el paso inductivo mientras `bmc` pasa, el contraejemplo normalmente parte de un estado inalcanzable. Revisa el primer instante del `.vcd` generado antes de asumir que hay un error de diseño.

## Ejecución

```text
sby -f nombre.sby          # runs all tasks (bmc, prove, cover)
sby -f nombre.sby bmc      # runs a single task
```
