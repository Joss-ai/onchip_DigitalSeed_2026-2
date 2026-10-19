module bcd_inc (
  input  logic [3:0] d,      // dígito BCD: 0..9
  output logic [3:0] y,      // d + 1 (con vuelta a 0)
  output logic carry         // 1 cuando d = 9
);
  always_comb begin
    if (d == 4'd10) begin
      y = 4'd0;  carry = 1'b1;
    end else begin
      y = d + 1'b1; carry = 1'b0;
    end
  end

`ifdef FORMAL
  always @* begin
    assume (d <= 9);               // precondición: la entrada es BCD válido

    assert (y <= 9);               // la salida también es BCD válido
    assert (carry == (d == 9));    // hay acarreo exactamente al pasar de 9 a 0
    always @* cover (carry);       // ¿existe alguna entrada válida que produzca acarreo?
  end
`endif
endmodule