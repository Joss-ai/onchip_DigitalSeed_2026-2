# Verificación formal

Verificación formal de los módulos del receptor UART con SymbiYosys. Cada prueba tiene su propia carpeta con el módulo (`.v`, con las propiedades dentro de `` `ifdef FORMAL ``) y su archivo `.sby`.

Dentro de cada carpeta también hay una **captura de pantalla de la ejecución**, que muestra que la prueba pasó.

## Pruebas

| Carpeta | Módulo | Qué se verifica |
|---|---|---|
| `Prueba_CTICKS/` | `C_TICKS` | `tick_cnt` nunca supera 15 (16x) ni 12 (13x), y `sample` se genera solo después de un `bclk_tick`, en el tick 7 (16x) o 5 (13x). |
| `Prueba_CBITS/` | `C_BITS` | `count` nunca supera `n_bits = 5 + WLS + PEN`, `Done` sube solo cuando se contaron todos los bits, y `clr`/reset ponen `count` en 0. |
| `Prueba_FSM/` | `FSM` | Solo existen los 5 estados válidos, las salidas coinciden con el estado actual y cada transición sigue el diagrama de estados. |

## Suposiciones

| Módulo | Suposición | Razón |
|---|---|---|
| Todos | `rst` activo en el primer ciclo | Partir de un estado conocido. |
| `C_TICKS` | `osm_sel` estable | El modo 16x/13x no cambia durante la recepción. |
| `C_BITS` | `wls` y `pen` estables | `n_bits` no cambia mientras se recibe un carácter. |
| `C_BITS` | sin `bit_en` cuando `count == n_bits` | La FSM deja de contar cuando llegaron todos los bits. |

## Ejecución

Dentro de cada carpeta:

```text
sby -f ticks.sby     # Prueba_CTICKS
sby -f bits.sby      # Prueba_CBITS
sby -f fsm.sby       # Prueba_FSM
```

Cada `.sby` ejecuta tres tareas: `bmc`, `prove` y `cover`.
