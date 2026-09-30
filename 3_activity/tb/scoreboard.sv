class scoreboard;

    mailbox #(fifo_transaction) scb_mbx; 

    bit [7:0] fifo_model[$];

    task run();

        fifo_transaction tr;

        forever begin

            scb_mbx.get(tr);


            if(tr.wr_en && !tr.full) begin

                fifo_model.push_back(tr.din);

                $display("T=%0t [SCOREBOARD] WRITE DATA=%0h",
                         $time, tr.din);

            end



            if(tr.rd_en && !tr.empty) begin

                if(fifo_model.size() == 0) begin

                    $display("T=%0t [SCOREBOARD] ERROR FIFO vacío",
                             $time);

                end
                else begin

                    bit [7:0] expected;

                    expected = fifo_model.pop_front();


                    if(expected == tr.dout) begin

                        $display(
                        "T=%0t [SCOREBOARD] PASS Expected=%0h Received=%0h",
                        $time,
                        expected,
                        tr.dout
                        );

                    end
                    else begin

                        $display(
                        "T=%0t [SCOREBOARD] ERROR Expected=%0h Received=%0h",
                        $time,
                        expected,
                        tr.dout
                        );

                    end

                end

            end

        end

    endtask

endclass