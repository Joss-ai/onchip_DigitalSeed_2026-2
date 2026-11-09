`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  reg [0:0] PI_rxd_in;
  reg [0:0] PI_urrst;
  reg [0:0] PI_rst;
  reg [0:0] PI_Done;
  reg [0:0] PI_sample;
  wire [0:0] PI_clk = clock;
  FSM UUT (
    .rxd_in(PI_rxd_in),
    .urrst(PI_urrst),
    .rst(PI_rst),
    .Done(PI_Done),
    .sample(PI_sample),
    .clk(PI_clk)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif
    // UUT.$auto$async2sync.\cc:107:execute$451  = 1'b0;
    // UUT.$auto$async2sync.\cc:116:execute$455  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$461  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$467  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$473  = 1'b1;
    UUT._witness_.anyinit_procdff_345 = 3'b000;
    UUT.f_past_valid = 1'b0;
    UUT.state = 3'b000;

    // state 0
    PI_rxd_in = 1'b0;
    PI_urrst = 1'b0;
    PI_rst = 1'b1;
    PI_Done = 1'b0;
    PI_sample = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_rxd_in <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_Done <= 1'b0;
      PI_sample <= 1'b0;
    end

    // state 2
    if (cycle == 1) begin
      PI_rxd_in <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_Done <= 1'b0;
      PI_sample <= 1'b1;
    end

    // state 3
    if (cycle == 2) begin
      PI_rxd_in <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_Done <= 1'b1;
      PI_sample <= 1'b0;
    end

    // state 4
    if (cycle == 3) begin
      PI_rxd_in <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_Done <= 1'b0;
      PI_sample <= 1'b1;
    end

    // state 5
    if (cycle == 4) begin
      PI_rxd_in <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_Done <= 1'b0;
      PI_sample <= 1'b0;
    end

    genclock <= cycle < 5;
    cycle <= cycle + 1;
  end
endmodule
