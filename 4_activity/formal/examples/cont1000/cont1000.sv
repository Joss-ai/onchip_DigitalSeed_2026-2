module mod1000 (
  input  logic       clk, rst,
  output logic [9:0] count   // 10 bits: hasta 1023
);
  always_ff @(posedge clk) begin
    if (rst)                  count <= '0;
    else if (count == 10'd1000) count <= '0;
    else                      count <= count + 1'b1;
  end

`ifdef FORMAL
  logic f_past_valid = 1'b0;
  always_ff @(posedge clk) f_past_valid <= 1'b1;
  always @* if (!f_past_valid) assume (rst);

  always @* if (!rst) assert (count <= 999);
`endif
endmodule