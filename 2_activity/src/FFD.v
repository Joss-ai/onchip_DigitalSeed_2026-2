`timescale 1ns / 1ps

module FFD(
    input [7:0] D,
    input clk,
    input rstn,
    output reg [7:0] Q
);

always @(posedge clk) begin
    if (!rstn)
        Q <= 8'b0;
    else
        Q <= D;
end

endmodule
