# Scoreboard del FIFO

# Descripción

# El Scoreboard es el bloque encargado de verificar que el FIFO entregue los datos en el mismo orden en que fueron escritos (Que es como se espera que se haga, ya que es su finalidad), pero para hacerlo, recibe lo que envia el Monitor, guarda los datos de escritura en una cola que representa el FIFO esperado y compara cada dato leído con el dato que debería salir, como se visualizara a continuación:

# Código

``` systemverilog
class scoreboard; # Crea la clase encargada de verificar el funcionamiento del fifo

    mailbox scb_mbx; # Por medio de este canal llega lo que envia el Monitor
    bit [7:0] fifo_model[$]; # Crea una cola de datos de 8 bits que representa el comportamiento del fifo esperado

    function new(); # Configuración de la función
    endfunction

    task run(); # Definición de la tarea principal del scoreboard

        fifo_transaction tr; # Crea una variable para almacenar cada transacción recibida

        forever begin # Mantiene el scoreboard funcionando durante todo el tiempo que corre

            scb_mbx.get(tr); # Espera y recibe una transacción enviada por el Monitor

            if(tr.wr_en && !tr.full) begin # Comprueba que se haya solicitado un dato de escritura y que el Fifo no esté lleno.

                fifo_model.push_back(tr.din); # Guarda el dato de entrada al final de la cola.

                $display("T=%0t [SCOREBOARD] WRITE DATA=%0h",
                         $time, tr.din); # Muestra en pantalla el dato que fue almacenado

            end

            if(tr.rd_en && !tr.empty) begin # Comprueba que se haya solicitado un dato de lectura y que el Fifo no esté vacío


                if(fifo_model.size() == 0) begin # Comprueba si el modelo interno no tiene datos para entregar

                    $display("T=%0t [SCOREBOARD] ERROR FIFO vacío",
                             $time); # Si es así, muestra en pantalla ERROR FIFO VACÍO

                end
                else begin

                    bit [7:0] expected; # Crea una variable para guardar el dato que debería salir

                    expected = fifo_model.pop_front(); # Obtiene y elimina el primer dato de la cola, para que el primero que entre, sea el primero que salga

                    if(expected == tr.dout) begin # Compara el dato esperado con el dato entregado por el Fifo

                        $display(
                        "T=%0t [SCOREBOARD] PASS Expected=%0h Received=%0h",
                        $time,
                        expected,
                        tr.dout
                        ); # Si coinciden muestra PASS y sigue el proceso

                    end
                    else begin

                        $display(
                        "T=%0t [SCOREBOARD] ERROR Expected=%0h Received=%0h",
                        $time,
                        expected,
                        tr.dout
                        ); # Si son diferentes, muestra ERRROR

                    end

                end

            end

        end

    endtask

endclass
```

# En resumen, el Scoreboard crea un modelo ideal del Fifo, almacena los datos que entran y verifica que los datos que salen coincidan con los esperados y mantengan el orden correcto
