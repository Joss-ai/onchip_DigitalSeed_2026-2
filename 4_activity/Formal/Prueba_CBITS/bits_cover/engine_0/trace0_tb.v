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
  reg [0:0] PI_pen;
  reg [1:0] PI_wls;
  reg [0:0] PI_clr;
  reg [0:0] PI_bit_en;
  reg [0:0] PI_rst;
  wire [0:0] PI_clk = clock;
  reg [0:0] PI_urrst;
  C_BITS UUT (
    .pen(PI_pen),
    .wls(PI_wls),
    .clr(PI_clr),
    .bit_en(PI_bit_en),
    .rst(PI_rst),
    .clk(PI_clk),
    .urrst(PI_urrst)
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
    // UUT.$auto$async2sync.\cc:116:execute$180  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$186  = 1'b1;
    UUT.Done = 1'b0;
    UUT._witness_.anyinit_procdff_135 = 2'b10;
    UUT._witness_.anyinit_procdff_136 = 1'b1;
    UUT.count = 4'b0101;
    UUT.f_past_valid = 1'b0;

    // state 0
    PI_pen = 1'b0;
    PI_wls = 2'b00;
    PI_clr = 1'b0;
    PI_bit_en = 1'b0;
    PI_rst = 1'b1;
    PI_urrst = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_pen <= 1'b0;
      PI_wls <= 2'b00;
      PI_clr <= 1'b0;
      PI_bit_en <= 1'b0;
      PI_rst <= 1'b0;
      PI_urrst <= 1'b0;
    end

    // state 2
    if (cycle == 1) begin
      PI_pen <= 1'b0;
      PI_wls <= 2'b00;
      PI_clr <= 1'b0;
      PI_bit_en <= 1'b0;
      PI_rst <= 1'b0;
      PI_urrst <= 1'b0;
    end

    genclock <= cycle < 2;
    cycle <= cycle + 1;
  end
endmodule
