module Encoder(
// Power nodes
inout vdd, // Supply
inout vss, // GND
// Inputs
input [6:0] Comp, // Comparators outputs
input Samp, // Sampling signal
input clk, // Clock
// Outputs
output reg [2:0] Dout, // Digital ADC output
output reg eoc // End of conversion
);

// >> Encoder:
// Next Out value
reg [2:0] Bx;
always @* begin
case (Comp)
7'b0000000: Bx = 3'b000;
7'b0000001: Bx = 3'b001;
7'b0000011: Bx = 3'b010;
7'b0000111: Bx = 3'b011;
7'b0001111: Bx = 3'b100;
7'b0011111: Bx = 3'b101;
7'b0111111: Bx = 3'b110;
7'b1111111: Bx = 3'b111;
default: Bx = 3'b000;
endcase
end

always @(posedge clk) begin
if (Samp == 1'b1) begin
Dout[2:0] <= 3'd0;
eoc <= 1'd0;
end else if(Samp == 1'b0) begin
Dout[2:0] <= Bx;
eoc <= 1'd1;
end
end

endmodule