// Top level testbench module to instantiate design, interface
// start clocks and run the test
module tb;
  reg clk;

  always #10 clk = ~clk;
  fifo_if 	_if (clk);
  FIFO u0 ( 	.clk(clk),
             .rst(_if.rst),
             .wr_en(_if.wr_en),
             .rd_en(_if.rd_en),
             .din(_if.din),
             .dout(_if.dout),
             .empty(_if.empty),
             .full(_if.full)
             );
  test t0;

  initial begin
    clk = 0;

    _if.rst = 0;
    _if.wr_en   = 0;
    _if.rd_en   = 0;

    repeat(2) @(posedge clk);
    _if.rst <= 1;

    t0 = new;
    t0.e0.vif = _if;

    fork
        t0.run();
    join_none

    #500;
    $finish;
end

  // System tasks to dump VCD waveform file
  initial begin
    $dumpfile ("dump.vcd");
    $dumpvars;
  end
endmodule