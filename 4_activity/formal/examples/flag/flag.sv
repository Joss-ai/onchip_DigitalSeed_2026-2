module sticky_flag (
  input  logic clk, rst,
  input  logic err,    // pulso de error
  input  logic clr,    // borrado
  output logic flag
);
  always_ff @(posedge clk) begin
    if (rst || clr) flag <= 1'b0;
    else            flag <= err;
  end

`ifdef FORMAL
  // $past no tiene sentido en el primer ciclo: no hay ciclo anterior
  logic f_past_valid = 1'b0;
  always_ff @(posedge clk) f_past_valid <= 1'b1;

  // Empezar en reset
  always @* if (!f_past_valid) assume (rst);

  always_ff @(posedge clk) begin
    if (f_past_valid && !$past(rst) && !$past(clr)) begin
      // Si hubo error en el ciclo anterior, la bandera debe estar activa
      if ($past(err))  assert (flag);
      // Si la bandera estaba activa, debe seguir activa
      if ($past(flag)) assert (flag);
    end
  end
`endif
endmodule