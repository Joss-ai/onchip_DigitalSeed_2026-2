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
  reg [0:0] PI_osm_sel;
  reg [0:0] PI_clr;
  reg [0:0] PI_urrst;
  reg [0:0] PI_rst;
  reg [0:0] PI_bclk_tick;
  wire [0:0] PI_clk = clock;
  C_TICKS UUT (
    .osm_sel(PI_osm_sel),
    .clr(PI_clr),
    .urrst(PI_urrst),
    .rst(PI_rst),
    .bclk_tick(PI_bclk_tick),
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
    // UUT.$auto$async2sync.\cc:116:execute$213  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$219  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$225  = 1'b1;
    // UUT.$auto$async2sync.\cc:116:execute$231  = 1'b1;
    UUT._witness_.anyinit_procdff_147 = 4'b0000;
    UUT._witness_.anyinit_procdff_148 = 4'b0000;
    UUT._witness_.anyinit_procdff_161 = 1'b1;
    UUT.f_past_valid = 1'b0;
    UUT.sample = 1'b0;
    UUT.tick_cnt = 4'b0000;

    // state 0
    PI_osm_sel = 1'b0;
    PI_clr = 1'b0;
    PI_urrst = 1'b0;
    PI_rst = 1'b1;
    PI_bclk_tick = 1'b0;
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
      PI_osm_sel <= 1'b0;
      PI_clr <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_bclk_tick <= 1'b1;
    end

    // state 2
    if (cycle == 1) begin
      PI_osm_sel <= 1'b0;
      PI_clr <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_bclk_tick <= 1'b1;
    end

    // state 3
    if (cycle == 2) begin
      PI_osm_sel <= 1'b0;
      PI_clr <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_bclk_tick <= 1'b1;
    end

    // state 4
    if (cycle == 3) begin
      PI_osm_sel <= 1'b0;
      PI_clr <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_bclk_tick <= 1'b1;
    end

    // state 5
    if (cycle == 4) begin
      PI_osm_sel <= 1'b0;
      PI_clr <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_bclk_tick <= 1'b1;
    end

    // state 6
    if (cycle == 5) begin
      PI_osm_sel <= 1'b0;
      PI_clr <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_bclk_tick <= 1'b1;
    end

    // state 7
    if (cycle == 6) begin
      PI_osm_sel <= 1'b0;
      PI_clr <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_bclk_tick <= 1'b1;
    end

    // state 8
    if (cycle == 7) begin
      PI_osm_sel <= 1'b0;
      PI_clr <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_bclk_tick <= 1'b1;
    end

    // state 9
    if (cycle == 8) begin
      PI_osm_sel <= 1'b0;
      PI_clr <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_bclk_tick <= 1'b0;
    end

    // state 10
    if (cycle == 9) begin
      PI_osm_sel <= 1'b0;
      PI_clr <= 1'b0;
      PI_urrst <= 1'b0;
      PI_rst <= 1'b0;
      PI_bclk_tick <= 1'b0;
    end

    genclock <= cycle < 10;
    cycle <= cycle + 1;
  end
endmodule
