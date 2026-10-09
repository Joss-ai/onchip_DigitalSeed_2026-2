# Environment + Test (Explicación de los códigos)
**A continuación se dará una breve explicación por bloques del código.** (Esto tanto para la clase environment como para test)

## 1. Clase `environment`

### Explicación por bloques
 
#### Declaraciones
 
```systemverilog
driver      d0;
Monitor     m0;
generator   g0;
scoreboard  s0;
```
En esta primera sección solo se declaran cuatro *handles* (punteros). Todavía no existen como un objeto, los cuatro valen `null` hasta que se haga `new()`.

```systemverilog
mailbox #(fifo_transaction) drv_mbx;
mailbox #(fifo_transaction) scb_mbx;
event   drv_done;
virtual fifo_if vif;
int num_transactions = 20;
```

En esta parte se tienen distintas declaraciones, y es importante saber de qué trata cada tipo, pues se inicializan distinto, y por eso conviene tenerlos presentes:
 
| Declaración | ¿Necesita `new()`? | Explicación |
|-------------|--------------------|-------------|
| `mailbox #(fifo_transaction)` | Sí | Es un objeto. El `#(fifo_transaction)` indica que solo acepta transacciones de ese tipo. |
| `event` | No | SystemVerilog ya crea el evento al declararlo. |
| `virtual fifo_if` | No | Nunca se construye. Se le **asigna** la interfaz real que existe en `tb`. |
| `int` | No | Es un valor, no un objeto. |

#### Constructor `new()`: aquí se hace el cableado

```systemverilog
function new();
        // 1) Crear los componentes
        d0 = new();
        m0 = new();
        g0 = new();
        s0 = new();
 
        // 2) Crear los canales
        drv_mbx = new();
        scb_mbx = new();
 
        // 3) generator <-> driver: el MISMO mailbox
        d0.drv_mbx = drv_mbx;
        g0.drv_mbx = drv_mbx;
 
        // 4) driver -> generator: el MISMO evento
        d0.drv_done = drv_done;
        g0.drv_done = drv_done;
 
        // 5) Monitor -> scoreboard: el MISMO mailbox
        m0.scb_mbx = scb_mbx;
        s0.scb_mbx = scb_mbx;
    endfunction
```

1. **Crear los 4 componentes.** Después de `d0 = new(); ...` existen los objetos, pero están aislados: cada uno tiene sus variables internas (`drv_mbx`, `drv_done`, `scb_mbx`) en `null`.
2. **Crear los 2 mailboxes.** Los crea `environment`, no los componentes. Él compra las "casillas postales" antes de repartir las llaves.
3. **Conectar `generator` y `driver`.** `d0.drv_mbx = drv_mbx; g0.drv_mbx = drv_mbx;` hace que ambos apunten al mismo mailbox. Lo que el generador mete con `put()`, el driver lo saca con `get()`.
4. **Conectar `driver` y `generator` con el evento.** Es la comunicación en sentido contrario: el driver dispara `-> drv_done;` y el generador espera con `@(drv_done);`. Gracias a eso el generador no se adelanta y sabe cuándo mandar la siguiente transacción.
5. **Conectar `Monitor` y `scoreboard`.** Mismo patrón que el paso 3, con `scb_mbx`.

#### Tarea `run()`
 
```systemverilog
d0.vif = vif;
m0.vif = vif;
g0.num = num_transactions;
```

Estas tres líneas están en `run()` y no en `new()` por una razón de **orden de ejecución**. A continuación se muestra una parte del código "test" para ver cómo se llama todo desde `tb`:

```systemverilog
t0 = new;                  // 1) corre test::new() y environment::new()
t0.e0.vif = _if;           // 2) recién ahora environment recibe la interfaz real
fork
    t0.run();              // 3) corre environment::run()
join_none
```
- Dentro de `new()` (paso 1) la interfaz real **todavía no se ha asignado**: `vif` vale `null`. Copiarla ahí al driver y al monitor sería copiar `null`.
- `num_transactions` es un `int`, es decir una **copia de valor**. Si se copiara dentro de `new()`, se guardaría el valor que tenía en ese instante (20) y cualquier cambio posterior, hecho por `tb` o por un `test`, llegaría tarde y el generador lo ignoraría.
- En `run()` (paso 3) ya pasó todo lo anterior, así que se copian los valores definitivos.

> `generator` y `scoreboard` no reciben `vif`: ninguno toca las señales físicas. Solo `driver` (escribe y lee) y `Monitor` (solo lee) necesitan acceso a la interfaz.

#### El `fork ... join_any`
 
```systemverilog
fork
    g0.run();
    d0.run();
    m0.run();
    s0.run();
join_any
```

Lanza los cuatro componentes **en paralelo**, como cuatro procesos concurrentes. `join_any` significa "continúa cuando termine el primero".
 
- `g0.run()` es el único que termina por sí solo: tiene un `for` finito, que se acaba cuando genera todas sus transacciones.
- `d0.run()`, `m0.run()` y `s0.run()` tienen un `forever` y nunca terminan solos.
- Cuando el generador termina, `join_any` se cumple y `run()` retorna. Los otros tres siguen corriendo en segundo plano, procesando lo que quedó pendiente.

---
 
## 2. Clase `test`

```systemverilog
class test;
    environment e0;
 
    function new();
        e0 = new();
    endfunction
 
    task run();
        e0.run();
    endtask
endclass
```
A continuación se muestra una tabla describiendo lo que hace este código:

| Línea | Qué hace |
|-------|----------|
| `environment e0;` | Declara el handle al `environment` (vale `null` todavía). |
| `e0 = new();` | Crea el `environment`. Esto dispara **en cascada** todo el constructor de la sección anterior: se crean los 4 componentes y los 2 mailboxes y se hacen todas las conexiones. |
| `e0.run();` | Delega: el `test` no hace nada propio, solo le pide al `environment` que arranque. |

### Cascada de construcción
 
Todo ocurre con una sola línea de `tb`:
 
```
tb:   t0 = new;
        └─ test::new()
             └─ e0 = new()  →  environment::new()
                                  ├─ d0, m0, g0, s0 = new()
                                  ├─ drv_mbx, scb_mbx = new()
                                  └─ conexiones de mailbox y evento
```
 
### ¿Por qué existe `test` si solo delega funciones?
 
Es una capa separada a propósito. En un proyecto más grande se pueden escribir varias clases de test (por ejemplo, uno de solo escrituras y otro de estrés mixto) que reutilicen **el mismo** `environment` y solo cambien la configuración antes de llamar a `run()`. Como `g0.num` se copia dentro de `run()`, un test podría configurar la cantidad de transacciones así:
 
```systemverilog
task configure(int n = 20);
    e0.num_transactions = n;
endtask
```
 
Esa configuración sí llegaría al generador. En la versión actual del proyecto no se usa y el test siempre corre con las 20 transacciones por defecto.
 
---
