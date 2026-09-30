class generator;

    mailbox #(fifo_transaction) drv_mbx;
    event drv_done;

    int num = 20;

    task run();

        for (int i = 0; i < num; i++) begin

            fifo_transaction item = new;

            // Randomizamos únicamente los campos declarados como rand
            assert(item.randomize());

            // =====================================================
            // CONTROL DEL ESTÍMULO
            // =====================================================

            // Transacciones 1-3: RESET
            if (i < 3) begin

                item.rst    = 0;
                item.rd_en  = 0;
                item.wr_en  = 0;

            end

            // Transacciones 4-9: ESCRITURA
            else if (i < 9) begin

                item.rst    = 1;
                item.rd_en  = 1;
                item.wr_en  = 1;

            end

            // Transacciones 15 en adelante
            else begin

                item.rst   = 1;
                item.rd_en = 1;
                // wr_en permanece aleatorio
            end

            $display(
                "T=%0t [Generator] Loop:%0d/%0d",
                $time, i+1, num
            );

            item.print("[Generator]");

            drv_mbx.put(item);

            // Esperar a que el driver termine
            @(drv_done);
        end
        $display(
            "T=%0t [Generator] Done generation of %0d items",
            $time, num
        );
    endtask

endclass