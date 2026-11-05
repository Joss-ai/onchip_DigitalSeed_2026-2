`timescale 1ns / 1ps

module FFD(
    input [4:0] D,        
    input E,             
    input rst,           
    input clk,
    output reg [4:0] Q, 
);

initial begin
Q = 5'd0;
end    

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            Q <= 5'b00000;
        end else if (E) begin
            Q <= D;        
        end
    end

endmodule
