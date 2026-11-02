`timescale 1ns / 1ps

module FFD2(
    input [4:0] D,       
    output reg [4:0] Q,  
    input E,             
    input rst,           
    input clk            
);

    always @(posedge clk) begin
        if (!rst) begin
            Q <= 5'b00000;
        end else if (E) begin
            Q <= D;        
        end
    end

endmodule