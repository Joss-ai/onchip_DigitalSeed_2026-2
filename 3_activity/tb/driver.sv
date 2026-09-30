class driver;
    virtual fifo_if             vif;
    mailbox #(fifo_transaction) drv_mbx;
    mailbox #(int)              done_mbx;
    event drv_done;

    bit avoid_empty_read = 1;

    task run();
    
        fifo_transaction item;

        $display("T=%0t [Driver]", $time);

        forever begin
            $display("T=%0t [Driver] ", $time);
            drv_mbx.get(item);

            @(negedge vif.clk);
            item.print("[Driver]");
            vif.rst   = item.rst;
            vif.wr_en = item.wr_en;
            vif.din   = item.din;
            if (avoid_empty_read && vif.empty)
                vif.rd_en = 1'b0;
            else
                vif.rd_en = item.rd_en;

            @(posedge vif.clk);        
            -> drv_done;         
        end
    endtask
endclass