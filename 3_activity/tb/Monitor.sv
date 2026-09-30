class Monitor;

  virtual fifo_if vif;              
  mailbox #(fifo_transaction) scb_mbx;      
  //mailbox #(fifo_item) rd_mbx;      

  //function new();
  //  wr_mbx = new();
  //  rd_mbx = new();
  //endfunction();

  task run();
    if (vif == null)
      $fatal(1, "[Monitor] No se asignó la interfaz virtual vif");

    $display("T=%0t [Monitor] Inicializando ...", $time);

    //fork
    sample_write();
    // sample_read();
    //join
  endtask

  task sample_write();
    forever begin
      @(posedge vif.clk);
      // Solo cuenta si no hay reset y no esta lleno
      if (vif.rst === 1'b1 && (vif.wr_en || vif.rd_en)) begin
        fifo_transaction item = new();
        //item.op   = FIFO_WRITE;
        item.din = vif.din;
        // item.display("Monitor_WR");
        item.dout      = vif.dout;
        item.empty = vif.empty;
        item.print("Monitor_WR");
        scb_mbx.put(item);
        item.wr_en = vif.wr_en;
        item.rd_en = vif.rd_en;
        item.rst   = vif.rst;
        item.full  = vif.full;
      end
    end
  endtask

  //task sample_read();
    //forever begin
     // @(vif);
      // dout es combinacional: se captura en el mismo flanco que rd_en
      //if (vif.rst === 1'b1 && vif.rd_en) begin
      //  fifo_item item = new();
      //  item.op        = FIFO_READ;
      //  item.dout      = vif.dout;
      //  item.was_empty = vif.empty;
      //  item.display("Monitor_RD");
      //  scb_mbx.put(item);
      //end
    //end
  //endtask
endclass