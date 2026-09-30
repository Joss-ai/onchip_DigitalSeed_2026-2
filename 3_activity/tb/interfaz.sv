interface fifo_if (input bit clk);

    // Señales físicas conectadas al DUT (FIFO)
    logic rst;
    logic wr_en;
    logic [7:0] din;
    logic rd_en;
    logic [7:0] dout;
    logic empty;
    logic full;

endinterface