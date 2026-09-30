class fifo_transaction;

    // Inputs / stimulus
    rand bit       wr_en;
    rand bit [7:0] din;
    rand bit       rd_en;
    bit       rst;

    // Outputs / observed results
    bit [7:0] dout;
    bit       empty;
    bit       full;

    function void print(string tag="");
        $display(
            "T=%0t %s wr_en=%0d din=0x%0h rd_en=%0d rst=%0d dout=0x%0h empty=%0d full=%0d",
            $time, tag, wr_en, din, rd_en, rst, dout, empty, full
        );
    endfunction

endclass