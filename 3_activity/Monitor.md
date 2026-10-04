# FIFO UVM Testbench: Monitor

El monitor observa pasivamente los eventos de la misma interfaz virtual que utiliza el driver. En base a lo que observa, reconstruye una transacción (`transaction`) y la reenvía al scoreboard a través de un mailbox separado.


<p align="center">
<img width="768" height="321" alt="imagen" src="https://github.com/user-attachments/assets/2e4f750f-0161-4f7d-b304-f2e97e59417e" />
</p>


---

## 1. Definición de la clase

Primero se define la clase y se definen los mailboxes con los que trabajará. En este caso son la interfaz virtual, de la que provienen los datos, y el mailbox de salida, que será enviado al scoreboard.

```systemverilog
class Monitor;

  virtual fifo_if vif;
  mailbox #(fifo_transaction) scb_mbx;
```

---

## 2. Tarea de verificación: `run()`

Posteriormente se encuentra la tarea `run()`, encargada de revisar que `vif` posea información. De lo contrario, mostrará el mensaje de error: `"[Monitor] No se asignó la interfaz virtual vif"`. Si la interfaz está correctamente asignada, muestra el mensaje de inicialización del monitor e inicia la tarea de muestreo `sample_write()`.

```systemverilog
  task run();
    if (vif == null)
      $fatal(1, "[Monitor] No se asignó la interfaz virtual vif");

    $display("T=%0t [Monitor] Inicializando ...", $time);
    sample_write();
  endtask
```

---

## 3. Tarea de muestreo: `sample_write()`

Finalmente está la tarea encargada de la toma de valores de la interfaz y de la creación de la transacción que se envía al mailbox del scoreboard.

Para esto se considera la lógica del módulo. En este caso, al tratarse de un FIFO, el monitor debe leer en cada ciclo de reloj que el reset (activo en bajo) no esté activo y que la condición de escritura y/o de lectura esté activa.

```systemverilog
  task sample_write();
    forever begin
      @(posedge vif.clk);
      if (vif.rst === 1'b1 && (vif.wr_en || vif.rd_en)) begin
        fifo_transaction item = new();
        item.din   = vif.din;
        item.dout  = vif.dout;
        item.empty = vif.empty;
        item.wr_en = vif.wr_en;
        item.rd_en = vif.rd_en;
        item.rst   = vif.rst;
        item.full  = vif.full;
        item.print("Monitor_WR");
        scb_mbx.put(item);
      end
    end
  endtask

endclass
```

---

