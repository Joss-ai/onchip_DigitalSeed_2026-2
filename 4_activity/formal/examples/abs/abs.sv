module abs8 (
  input  logic signed [7:0] a,
  output logic signed [7:0] y
);
  assign y = (a < 0) ? -a : a;

`ifdef FORMAL
  always @* begin
    assert (y >= 0);   // Un valor absoluto nunca es negativo
  end
`endif
endmodule